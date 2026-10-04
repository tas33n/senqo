# dev-start.ps1
# Starts backend, frontend, and whatsapp dev servers in separate PowerShell windows.
# Run from repo root: .\scripts\dev-start.ps1

$root    = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

function Read-EnvVar([string]$Key) {
  if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
      if ($line -match "^$Key=(.+)$") { return $matches[1].Trim() }
    }
  }
  return $null
}

$waApiKey      = Read-EnvVar "WHATSAPP_SERVICE_API_KEY"
$waWebhookAuth = Read-EnvVar "WHATSAPP_WEBHOOK_AUTHORIZATION"

function Start-DevServer {
  param(
    [string]$Title,
    [string]$WorkDir,
    [string]$Command,
    [int]$Port = 0,
    [string[]]$EnvStatements = @()
  )
  if ($Port -gt 0) {
    $existing = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($existing) {
      Write-Host "[dev-start] $Title is already running on port $Port (skipping window)" -ForegroundColor Yellow
      return
    }
  }
  $envBlock = ($EnvStatements -join "; ")
  if ($envBlock) { $envBlock = $envBlock + "; " }
  $fullCmd = "Push-Location '$WorkDir'; $envBlock$Command; Read-Host 'Press Enter to close'"
  Start-Process powershell -ArgumentList "-NoExit", "-Command", $fullCmd
  Write-Host "[dev-start] Opened window: $Title" -ForegroundColor Green
}

$backendDir  = Join-Path $root "backend"
$frontendDir = Join-Path $root "frontend"
$waDir       = Join-Path $root "whatsapp"

# Backend
Start-DevServer `
  -Title   "Backend :3001" `
  -WorkDir $backendDir `
  -Command "npm run dev" `
  -Port    3001

Start-Sleep -Seconds 2

# Frontend
Start-DevServer `
  -Title   "Frontend :5173" `
  -WorkDir $frontendDir `
  -Command "npm run dev" `
  -Port    5173

# WhatsApp
$waEnv = @(
  "`$env:PORT = '3002'",
  "`$env:WHATSAPP_SERVICE_API_KEY = '$waApiKey'",
  "`$env:WHATSAPP_WEBHOOK_AUTHORIZATION = '$waWebhookAuth'",
  "`$env:BACKEND_WEBHOOK_URL = 'http://localhost:3001/api/whatsapp/events'",
  "`$env:SESSIONS_DIR = './sessions'",
  "`$env:LOG_LEVEL = 'debug'",
  "`$env:LOG_FILE = './logs/whatsapp.log'"
)

Start-DevServer `
  -Title          "WhatsApp :3002" `
  -WorkDir        $waDir `
  -Command        "npm run dev" `
  -Port           3002 `
  -EnvStatements  $waEnv

Write-Host ""
Write-Host "=== Dev servers starting ===" -ForegroundColor Cyan
Write-Host "  Frontend  ->  http://localhost:5173"
Write-Host "  Backend   ->  http://localhost:3001"
Write-Host "  WhatsApp  ->  http://localhost:3002"
Write-Host ""
Write-Host "Log in with credentials from your .env (BOOTSTRAP_ADMIN_EMAIL / BOOTSTRAP_ADMIN_PASSWORD)"
