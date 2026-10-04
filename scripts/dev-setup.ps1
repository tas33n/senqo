# dev-setup.ps1
# Patches repo-root .env for local development (no Docker).
# Run once before starting the stack: .\scripts\dev-setup.ps1

param(
  [string]$DbPassword = "senqo",
  [string]$DbUser     = "senqo",
  [string]$DbName     = "senqo",
  [string]$DbHost     = "localhost",
  [int]   $DbPort     = 5432
)

$root    = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
  Write-Host "[dev-setup] .env not found - copying from .env.example" -ForegroundColor Yellow
  Copy-Item (Join-Path $root ".env.example") $envFile
}

$content = Get-Content $envFile -Raw

function Set-EnvVar {
  param([string]$Key, [string]$Value, [ref]$Text)
  $escaped = [regex]::Escape($Key)
  $pattern = "(?m)^$escaped=.*$"
  if ($Text.Value -match $pattern) {
    $Text.Value = [regex]::Replace($Text.Value, $pattern, "$Key=$Value")
  } else {
    $Text.Value = $Text.Value.TrimEnd() + "`r`n$Key=$Value`r`n"
  }
}

function Get-RandomHex {
  $bytes = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  return -join ($bytes | ForEach-Object { $_.ToString("x2") })
}

$dbUrl = "postgresql://${DbUser}:${DbPassword}@${DbHost}:${DbPort}/${DbName}"

Set-EnvVar -Key "NODE_ENV"                     -Value "development"                              -Text ([ref]$content)
Set-EnvVar -Key "DATABASE_URL"                 -Value $dbUrl                                    -Text ([ref]$content)
Set-EnvVar -Key "FRONTEND_URL"                 -Value "http://localhost:5173"                    -Text ([ref]$content)
Set-EnvVar -Key "AUTH_COOKIE_SECURE"           -Value "false"                                   -Text ([ref]$content)
Set-EnvVar -Key "ALLOWED_PRODUCTION_ORIGINS"   -Value "localhost"                               -Text ([ref]$content)
Set-EnvVar -Key "WHATSAPP_SERVICE_URL"         -Value "http://localhost:3002"                   -Text ([ref]$content)
Set-EnvVar -Key "WHATSAPP_MEDIA_ALLOWED_HOSTS" -Value "localhost"                               -Text ([ref]$content)
Set-EnvVar -Key "BACKEND_WEBHOOK_URL"          -Value "http://localhost:3001/api/whatsapp/events" -Text ([ref]$content)

$secretKeys = @("JWT_SECRET", "API_KEY_PEPPER", "WORKSPACE_SECRETS_KEY", "WHATSAPP_SERVICE_API_KEY", "WHATSAPP_WEBHOOK_AUTHORIZATION")
foreach ($key in $secretKeys) {
  if ($content -match "(?m)^$key=change-me") {
    $hex = Get-RandomHex
    Set-EnvVar -Key $key -Value $hex -Text ([ref]$content)
    Write-Host "[dev-setup] Generated secret for $key" -ForegroundColor Cyan
  }
}

if ($content -match "(?m)^BOOTSTRAP_ADMIN_EMAIL=admin@yourcompany") {
  Set-EnvVar -Key "BOOTSTRAP_ADMIN_EMAIL"    -Value "admin@dev.local" -Text ([ref]$content)
  Set-EnvVar -Key "BOOTSTRAP_ADMIN_PASSWORD" -Value "devpassword123"  -Text ([ref]$content)
  Set-EnvVar -Key "BOOTSTRAP_WORKSPACE_NAME" -Value "Dev Workspace"   -Text ([ref]$content)
}

if ($content -match "(?m)^ALLOW_PUBLIC_REGISTRATION=false") {
  Set-EnvVar -Key "ALLOW_PUBLIC_REGISTRATION" -Value "true" -Text ([ref]$content)
}

[System.IO.File]::WriteAllText($envFile, $content, [System.Text.Encoding]::UTF8)
Write-Host "[dev-setup] .env updated for local development." -ForegroundColor Green
Write-Host ""
Write-Host "  DATABASE_URL = $dbUrl"
Write-Host "  FRONTEND_URL = http://localhost:5173"
Write-Host "  NODE_ENV     = development"
