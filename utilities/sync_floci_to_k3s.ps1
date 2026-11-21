# ==============================================================================
# File: utilities/sync_floci_to_k3s.ps1
# Mục đích: Đồng bộ động Bí mật (Secrets Manager, SSM Parameter Store) và Thông số
#           hạ tầng Terraform Outputs từ Floci AWS Emulator sang cụm Kubernetes K3s.
# Nguyên tắc bảo mật: KHÔNG hardcode mật khẩu trong mã nguồn. Các Secret được lấy trực tiếp
# từ Floci API (Control Plane) hoặc biến môi trường / sinh ngẫu nhiên trong RAM lúc chạy.
# AWS Production Parity: Tương đương AWS Secrets Store CSI Driver / External Secrets Operator.
# ==============================================================================
[CmdletBinding()]
param(
    [string]$AwsProfile = "floci",
    [string]$FlociEndpoint = "http://localhost:4566",
    [string]$Environment = "floci",
    [string]$Kubeconfig = "$PSScriptRoot\..\floci\k3s-kubeconfig\kubeconfig.yaml",
    [string]$TerraformDir = "$PSScriptRoot\..\terraform\environments\floci",
    [string]$DemoUser = $env:DEMO_USERNAME,
    [string]$DemoPassword = $env:DEMO_PASSWORD,
    [string]$GrafanaUser = $(if ($env:GRAFANA_ADMIN_USER) { $env:GRAFANA_ADMIN_USER } else { "admin" }),
    [string]$GrafanaPassword = $env:GRAFANA_ADMIN_PASSWORD,
    [switch]$EnableDemoSeed
)

$ErrorActionPreference = "Stop"

# Hàm sinh chuỗi mật khẩu ngẫu nhiên an toàn trong RAM nếu chưa truyền từ biến môi trường
function New-EphemeralSecret {
    param([int]$ByteLength = 18)
    $bytes = New-Object byte[] $ByteLength
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ([Convert]::ToBase64String($bytes) -replace '[+/=]', 'x').Substring(0, 16)
}

Write-Host "[1/4] Dang doc thong tin DB & JWT tu Floci Secrets Manager / SSM..." -ForegroundColor Cyan
$dbSecretRaw = aws --profile $AwsProfile --endpoint-url $FlociEndpoint secretsmanager get-secret-value `
    --secret-id "/trading/$Environment/database/credentials" `
    --query "SecretString" --output text
$dbSecret = $dbSecretRaw | ConvertFrom-Json

$jwtSecret = aws --profile $AwsProfile --endpoint-url $FlociEndpoint ssm get-parameter `
    --name "/trading/$Environment/jwt/secret" `
    --with-decryption `
    --query "Parameter.Value" --output text

if (-not $dbSecret.username -or -not $dbSecret.password -or -not $jwtSecret) {
    throw "Khong doc duoc Secrets tu Floci. Hay dam bao da chay 'terraform apply' thanh cong."
}

$dbName = "userdb"
$dsn = "postgresql://$($dbSecret.username):$($dbSecret.password)@localhost:5432/${dbName}?sslmode=disable"

# Xu ly tai khoan Demo Seeder & Grafana Admin an toan khong hardcode
$seedEnabled = if ($EnableDemoSeed -or ($env:APP_DEMO_SEED_ENABLED -eq "true")) { "true" } else { "false" }
if (-not $DemoUser) { $DemoUser = "demo_trader" }
if (-not $DemoPassword) {
    $DemoPassword = New-EphemeralSecret
    $generatedDemoPass = $true
} else {
    $generatedDemoPass = $false
}

if (-not $GrafanaPassword) {
    $GrafanaPassword = New-EphemeralSecret
    $generatedGrafanaPass = $true
} else {
    $generatedGrafanaPass = $false
}

Write-Host "[2/4] Dang doc Terraform Outputs tu '$TerraformDir'..." -ForegroundColor Cyan
$tfOutRaw = terraform "-chdir=$TerraformDir" output -json
$tfOut = $tfOutRaw | ConvertFrom-Json

Write-Host "[3/4] Dang dong bo Secret 'trading-cloud-secrets' va 'grafana-admin-secret' len K3s..." -ForegroundColor Cyan
kubectl --kubeconfig $Kubeconfig create secret generic trading-cloud-secrets `
    --namespace default `
    --from-literal="POSTGRES_USER=$($dbSecret.username)" `
    --from-literal="POSTGRES_PASSWORD=$($dbSecret.password)" `
    --from-literal="POSTGRES_DB=$dbName" `
    --from-literal="DATA_SOURCE_NAME=$dsn" `
    --from-literal="JWT_SECRET=$jwtSecret" `
    --from-literal="APP_DEMO_SEED_ENABLED=$seedEnabled" `
    --from-literal="APP_DEMO_USERNAME=$DemoUser" `
    --from-literal="APP_DEMO_PASSWORD=$DemoPassword" `
    --dry-run=client -o yaml | kubectl --kubeconfig $Kubeconfig apply -f -

kubectl --kubeconfig $Kubeconfig create secret generic grafana-admin-secret `
    --namespace default `
    --from-literal="GF_SECURITY_ADMIN_USER=$GrafanaUser" `
    --from-literal="GF_SECURITY_ADMIN_PASSWORD=$GrafanaPassword" `
    --dry-run=client -o yaml | kubectl --kubeconfig $Kubeconfig apply -f -

Write-Host "[4/4] Dang tao ConfigMap 'trading-aws-config' tu Terraform Outputs..." -ForegroundColor Cyan
kubectl --kubeconfig $Kubeconfig create configmap trading-aws-config `
    --namespace default `
    --from-literal="AWS_ENDPOINT_URL=http://devops04-floci-aws:4566" `
    --from-literal="AWS_REGION=ap-southeast-1" `
    --from-literal="S3_BUCKET=$($tfOut.s3_bucket_id.value)" `
    --from-literal="SQS_QUEUE_URL=$($tfOut.order_queue_url.value)" `
    --from-literal="SNS_TOPIC_ARN=$($tfOut.sns_topic_arn.value)" `
    --from-literal="RDS_ENDPOINT=$($tfOut.rds_endpoint.value)" `
    --from-literal="REDIS_ENDPOINT=$($tfOut.redis_endpoint.value)" `
    --from-literal="EKS_CLUSTER_NAME=$($tfOut.eks_cluster_name.value)" `
    --from-literal="ALB_DNS_NAME=$($tfOut.alb_dns_name.value)" `
    --dry-run=client -o yaml | kubectl --kubeconfig $Kubeconfig apply -f -

Write-Host "`nDong bo Floci -> K3s hoan tat 100%!" -ForegroundColor Green
if ($generatedGrafanaPass) {
    Write-Host "  - Grafana Admin ($GrafanaUser) runtime password: $GrafanaPassword" -ForegroundColor Yellow
}
if ($seedEnabled -eq "true" -and $generatedDemoPass) {
    Write-Host "  - Trading Demo User ($DemoUser) runtime password: $DemoPassword" -ForegroundColor Yellow
}
