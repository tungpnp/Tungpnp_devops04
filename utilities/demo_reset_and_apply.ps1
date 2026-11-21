# ==============================================================================
# File: utilities/demo_reset_and_apply.ps1
# Mục đích: Kịch bản 1-Click dựng lại toàn bộ hệ thống Floci + Terraform + K3s + ArgoCD
#           phục vụ tái dựng môi trường sạch hoặc quay Video Demo DevOps04.
# ==============================================================================
[CmdletBinding()]
param(
    [string]$DbPassword = $env:TF_VAR_db_password,
    [string]$JwtSecret = $env:TF_VAR_jwt_secret,
    [switch]$EnableDemoSeed
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
$FlociComposeDir = Join-Path $RootDir "floci"
$TfDir = Join-Path $RootDir "terraform\environments\floci"
$Kubeconfig = Join-Path $FlociComposeDir "k3s-kubeconfig\kubeconfig.yaml"
$ManifestDir = Join-Path $RootDir "k8s-manifests"

# Hàm sinh giá trị bí mật động trong RAM nếu người chạy chưa truyền qua biến môi trường
function New-RandomKey([int]$len = 32) {
    $bytes = New-Object byte[] $len
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ([Convert]::ToBase64String($bytes) -replace '[+/=]', 'a').Substring(0, $len)
}

if (-not $DbPassword) { $DbPassword = New-RandomKey 20 }
if (-not $JwtSecret)  { $JwtSecret  = New-RandomKey 40 }

Write-Host "=== BUOC 1: Khoi chay Floci AWS Emulator + Floci UI + Floci K3s ===" -ForegroundColor Cyan
Push-Location $FlociComposeDir
docker compose up -d
Pop-Location

Write-Host "Dang cho Floci (:4566) va K3s API (:6443) san sang..." -ForegroundColor Gray
for ($i = 0; $i -lt 45; $i++) {
    if (Test-Path $Kubeconfig) {
        $n = cmd /c "kubectl --kubeconfig `"$Kubeconfig`" get nodes --no-headers 2>nul"
        if ($LASTEXITCODE -eq 0 -and $n) { break }
    }
    Start-Sleep -Seconds 2
}
kubectl --kubeconfig $Kubeconfig wait --for=condition=Ready node --all --timeout=90s
for ($i = 0; $i -lt 60; $i++) {
    $dep = cmd /c "kubectl --kubeconfig `"$Kubeconfig`" -n kube-system get deployment traefik --no-headers 2>nul"
    if ($LASTEXITCODE -eq 0 -and $dep) { break }
    Start-Sleep -Seconds 2
}
kubectl --kubeconfig $Kubeconfig -n kube-system wait --for=condition=Available deployment/coredns --timeout=180s
kubectl --kubeconfig $Kubeconfig -n kube-system wait --for=condition=Available deployment/traefik --timeout=180s

Write-Host "=== BUOC 2: Chay Terraform Apply (7 Modules) len Floci ===" -ForegroundColor Cyan
$env:TF_VAR_db_password = $DbPassword
$env:TF_VAR_jwt_secret  = $JwtSecret
terraform "-chdir=$TfDir" init
terraform "-chdir=$TfDir" apply -auto-approve

Write-Host "=== BUOC 3: Gan nhan Node Hard-Tenancy, Nap Docker Images & Dong bo Secret ===" -ForegroundColor Cyan
kubectl --kubeconfig $Kubeconfig label nodes --all coreback=true web=true monitor=true --overwrite

# Build neu thieu va nap truc tiep 4 container image local vao containerd cua K3s (binary-safe pipe qua cmd /c)
$SourceDir = Join-Path $RootDir "source"
$svcList = @("frontend-react", "api-gateway", "backend-java", "backend-python")
foreach ($svc in $svcList) {
    $img = "ghcr.io/tungpnp/${svc}:v1.0.0"
    if (-not (docker images -q $img)) {
        docker build -t $img (Join-Path $SourceDir $svc)
    }
}
cmd /c "docker save ghcr.io/tungpnp/frontend-react:v1.0.0 ghcr.io/tungpnp/api-gateway:v1.0.0 ghcr.io/tungpnp/backend-java:v1.0.0 ghcr.io/tungpnp/backend-python:v1.0.0 | docker exec -i devops04-floci-k3s ctr -n k8s.io images import -"

if ($EnableDemoSeed) {
    & "$PSScriptRoot\sync_floci_to_k3s.ps1" -EnableDemoSeed
} else {
    & "$PSScriptRoot\sync_floci_to_k3s.ps1"
}

Write-Host "=== BUOC 4: Trien khai Ha tang, Microservices, Observability, ArgoCD & Ingress ===" -ForegroundColor Cyan
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\infrastructure\postgres.yaml"
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\infrastructure\redis.yaml"
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\infrastructure\kafka.yaml"
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\apps\"
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\observability\"

kubectl --kubeconfig $Kubeconfig create namespace argocd --dry-run=client -o yaml | kubectl --kubeconfig $Kubeconfig apply -f -
kubectl --kubeconfig $Kubeconfig apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl --kubeconfig $Kubeconfig -n argocd create configmap argocd-cmd-params-cm --from-literal="server.insecure=true" --dry-run=client -o yaml | kubectl --kubeconfig $Kubeconfig apply -f -
kubectl --kubeconfig $Kubeconfig -n argocd rollout restart deployment/argocd-server

kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\network\ingress.yaml"
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\management\argocd-ingress.yaml"
kubectl --kubeconfig $Kubeconfig apply -f "$ManifestDir\argocd-apps\"

Write-Host "=== BUOC 5: Kiem tra trang thai Pods toan cum ===" -ForegroundColor Green
kubectl --kubeconfig $Kubeconfig get pods -A -o wide
