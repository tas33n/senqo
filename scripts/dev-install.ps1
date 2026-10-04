# dev-install.ps1
# Installs npm dependencies for all packages (backend, frontend, whatsapp).
# Run from repo root: .\scripts\dev-install.ps1

$root = Split-Path $PSScriptRoot -Parent
$packages = @("backend", "frontend", "whatsapp")

foreach ($pkg in $packages) {
  $pkgPath = Join-Path $root $pkg
  Write-Host ""
  Write-Host "==> Installing $pkg dependencies..." -ForegroundColor Cyan
  Push-Location $pkgPath
  npm install
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[dev-install] npm install failed for $pkg" -ForegroundColor Red
    Pop-Location
    exit 1
  }
  Pop-Location
}

Write-Host ""
Write-Host "[dev-install] All dependencies installed." -ForegroundColor Green
