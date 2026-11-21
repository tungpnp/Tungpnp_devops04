# ==============================================================================
# File: utilities/simulate_api_traffic.ps1
# Mục đích: Bắn lưu lượng HTTP thực tế vào cụm K3s qua Traefik Ingress (cổng 80)
#           để lấp đầy Metrics (Prometheus/Grafana), Traces (Tempo) và Logs (Kibana).
# Bảo mật: Tài khoản test (nếu cần test luồng Auth Login) đọc qua biến môi trường
#          $env:DEMO_USERNAME / $env:DEMO_PASSWORD hoặc tham số dòng lệnh.
# ==============================================================================
[CmdletBinding()]
param(
    [string]$BaseUrl = "http://tungpnp.local",
    [string]$HostHeader = "tungpnp.local",
    [string]$Username = $env:DEMO_USERNAME,
    [string]$Password = $env:DEMO_PASSWORD,
    [int]$Rounds = 20
)

# Chuẩn hóa cấu hình HTTP cho PowerShell 5.1 để JSON body khớp Content-Length với API Gateway
[System.Net.ServicePointManager]::Expect100Continue = $false
Write-Host "=== Bat dau gia lap Traffic vao '$BaseUrl' (Host: $HostHeader) trong $Rounds luot ===" -ForegroundColor Cyan

$headers = @{ "Host" = $HostHeader }
$jwtToken = $null

# 1. Thu dang nhap lay JWT neu co cung cap thong tin tai khoan demo
if ($Username -and $Password) {
    try {
        $loginBody = @{ username = $Username; password = $Password } | ConvertTo-Json -Compress
        $loginResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST `
            -Headers $headers -ContentType "application/json" -Body $loginBody
        if ($loginResp.token) {
            $jwtToken = $loginResp.token
            Write-Host "[Auth OK] Da nhan JWT Token tu Backend Java qua API Gateway." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Dang nhap demo that bai hoac user chua duoc seed: $($_.Exception.Message)"
    }
}

# 2. Gui chuoi request da dich vu (Frontend -> API Gateway -> Java Backend/Kafka & Python FastAPI)
for ($i = 1; $i -le $Rounds; $i++) {
    try {
        $r1 = Invoke-WebRequest -Uri "$BaseUrl/" -Headers $headers -UseBasicParsing
        $r2 = Invoke-RestMethod -Uri "$BaseUrl/api/python/hello" -Headers $headers

        $authStatus = "Skipped(no creds)"
        if ($Username -and $Password) {
            $loginBody = @{ username = $Username; password = $Password } | ConvertTo-Json -Compress
            $r3 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/auth/login" -Method POST `
                -Headers $headers -ContentType "application/json" -Body $loginBody
            if ($r3.token) { $authStatus = "200 OK (JWT+Kafka)" }
        }

        Write-Host ("[{0}/{1}] Frontend={2} | Python='{3}' | Auth={4}" -f $i, $Rounds, $r1.StatusCode, $r2.message, $authStatus) -ForegroundColor Gray
    } catch {
        Write-Host ("[{0}/{1}] Request error: {2}" -f $i, $Rounds, $_.Exception.Message) -ForegroundColor DarkYellow
    }
    Start-Sleep -Milliseconds 300
}

Write-Host "`nHoan tat gia lap Traffic! Hay mo Grafana & Kibana de xem Bieu do va Distributed Traces." -ForegroundColor Green
