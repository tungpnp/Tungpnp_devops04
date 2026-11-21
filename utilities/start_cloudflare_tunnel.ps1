# ==============================================================================
# File: utilities/start_cloudflare_tunnel.ps1
# Mục đích: Kết nối cụm Kubernetes Ingress (cổng 80) ra Internet thông qua
#           Cloudflare Zero Trust Tunnel cho domain thật: *.tungpnp.org.uk
# Hỗ trợ linh hoạt cả cụm Floci K3s lẫn cụm On-Premise bằng HTTP Host Header mapping.
# ==============================================================================
[CmdletBinding()]
param(
    [string]$TunnelToken = $env:CLOUDFLARE_TUNNEL_TOKEN,
    [string]$Domain = "tungpnp.org.uk",
    # Mặc định trỏ về Ingress cổng 80 của *.tungpnp.local (tương thích cả Floci K3s và On-Premise)
    [string]$LocalIngressUrl = "http://tungpnp.local",
    [string]$TunnelName = "devops04-k3s-tunnel",
    [switch]$QuickTryCloudflare
)

$ErrorActionPreference = "Stop"

# Kiểm tra cloudflared đã được cài đặt trên hệ thống chưa (kể cả fallback đường dẫn mặc định Windows)
$cfExe = $null
$cfCmd = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($cfCmd) {
    $cfExe = $cfCmd.Source
} else {
    $candidates = @(
        "${env:ProgramFiles(x86)}\cloudflared\cloudflared.exe",
        "${env:ProgramFiles}\cloudflared\cloudflared.exe"
    )
    $cfExe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $cfExe) {
    Write-Warning "Chua tim thay 'cloudflared' trong PATH hoac Program Files."
    Write-Host "Ban co the cai dat nhanh bang Winget:" -ForegroundColor Yellow
    Write-Host "  winget install --id Cloudflare.cloudflared -e" -ForegroundColor Cyan
    exit 1
}

if ($QuickTryCloudflare) {
    Write-Host "Dang mo Quick Tunnel tam thoi tro ve Traefik ($LocalIngressUrl)..." -ForegroundColor Cyan
    & $cfExe tunnel --url $LocalIngressUrl --http-host-header "tungpnp.local"
    exit $LASTEXITCODE
}

if ($TunnelToken) {
    Write-Host "Dang khoi chay Cloudflare Tunnel bang Token cho domain *.$Domain -> $LocalIngressUrl..." -ForegroundColor Green
    Write-Host "Dam bao trong Cloudflare Zero Trust Dashboard -> Public Hostname da map (kem HTTP Host Header):" -ForegroundColor Gray
    Write-Host "  - trading.$Domain -> $LocalIngressUrl (httpHostHeader: tungpnp.local)"
    Write-Host "  - grafana.$Domain -> $LocalIngressUrl (httpHostHeader: grafana.tungpnp.local)"
    Write-Host "  - kibana.$Domain  -> $LocalIngressUrl (httpHostHeader: kibana.tungpnp.local)"
    Write-Host "  - argocd.$Domain  -> $LocalIngressUrl (httpHostHeader: argocd.tungpnp.local)"
    & $cfExe tunnel --no-autoupdate run --token $TunnelToken
    exit $LASTEXITCODE
}

# Neu da login Cloudflare va tao Named Tunnel cuc bo, sinh file config anh xa HTTP Host Header sang *.tungpnp.local
$cfDir = Join-Path $env:USERPROFILE ".cloudflared"
$credFiles = Get-ChildItem -Path $cfDir -Filter "*.json" -ErrorAction SilentlyContinue
if ($credFiles -and $credFiles.Count -gt 0) {
    $tunnelId = $credFiles[0].BaseName
    $tmpCfg = Join-Path $env:TEMP "k3s-cloudflared-config.yml"
    @"
tunnel: $tunnelId
credentials-file: $($credFiles[0].FullName)

ingress:
  - hostname: trading.$Domain
    service: $LocalIngressUrl
    originRequest:
      httpHostHeader: tungpnp.local
  - hostname: grafana.$Domain
    service: $LocalIngressUrl
    originRequest:
      httpHostHeader: grafana.tungpnp.local
  - hostname: kibana.$Domain
    service: $LocalIngressUrl
    originRequest:
      httpHostHeader: kibana.tungpnp.local
  - hostname: argocd.$Domain
    service: $LocalIngressUrl
    originRequest:
      httpHostHeader: argocd.tungpnp.local
  - service: http_status:404
"@ | Set-Content -Path $tmpCfg -Encoding UTF8

    Write-Host "Dang chay Named Tunnel ($tunnelId) cho *.$Domain -> $LocalIngressUrl..." -ForegroundColor Green
    & $cfExe tunnel --config $tmpCfg run
    exit $LASTEXITCODE
}

Write-Host @"
=== HUONG DAN KICH HOAT CLOUDFLARE TUNNEL CHO DOMAIN '$Domain' ===
Cach 1 (Don gian nhat - Cloudflare Zero Trust Token):
  1. Vao https://one.dash.cloudflare.com -> Networks -> Tunnels -> Create a tunnel (Cloudflared).
  2. Them 4 Public Hostnames tro ve $LocalIngressUrl (chon HTTP Host Header tuong ung trong Additional application settings):
       - trading.$Domain -> $LocalIngressUrl  (HTTP Host Header: tungpnp.local)
       - grafana.$Domain -> $LocalIngressUrl  (HTTP Host Header: grafana.tungpnp.local)
       - kibana.$Domain  -> $LocalIngressUrl  (HTTP Host Header: kibana.tungpnp.local)
       - argocd.$Domain  -> $LocalIngressUrl  (HTTP Host Header: argocd.tungpnp.local)
  3. Copy Token va chay:
       `$env:CLOUDFLARE_TUNNEL_TOKEN = "<PASTE_TOKEN_HERE>"
       .\utilities\start_cloudflare_tunnel.ps1

Cach 2 (Dung CLI cuc bo):
  1. cloudflared tunnel login
  2. cloudflared tunnel create $TunnelName
  3. cloudflared tunnel route dns $TunnelName trading.$Domain
  4. cloudflared tunnel route dns $TunnelName grafana.$Domain
  5. cloudflared tunnel route dns $TunnelName kibana.$Domain
  6. cloudflared tunnel route dns $TunnelName argocd.$Domain
  7. .\utilities\start_cloudflare_tunnel.ps1
"@ -ForegroundColor Yellow
