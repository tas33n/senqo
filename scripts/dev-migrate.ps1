# dev-migrate.ps1
# Reads DATABASE_URL from repo-root .env and runs Drizzle migrations.
# Run from repo root: .\scripts\dev-migrate.ps1

$root       = Split-Path $PSScriptRoot -Parent
$envFile    = Join-Path $root ".env"
$backendDir = Join-Path $root "backend"

$dbUrl = $null
if (Test-Path $envFile) {
  foreach ($line in Get-Content $envFile) {
    if ($line -match "^DATABASE_URL=(.+)$") {
      $dbUrl = $matches[1].Trim()
      break
    }
  }
}

if (-not $dbUrl) {
  $dbUrl = "postgresql://senqo:senqo@localhost:5432/senqo"
  Write-Host "[dev-migrate] DATABASE_URL not found in .env, using default: $dbUrl" -ForegroundColor Yellow
} else {
  Write-Host "[dev-migrate] Using DATABASE_URL: $dbUrl" -ForegroundColor Cyan
}

$env:DATABASE_URL = $dbUrl

Write-Host "[dev-migrate] Running Drizzle migrations..." -ForegroundColor Cyan
Push-Location $backendDir
npx drizzle-kit migrate
$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -ne 0) {
  Write-Host "[dev-migrate] Migration failed (exit $exitCode)" -ForegroundColor Red
  Write-Host ""
  Write-Host "Make sure PostgreSQL is running and the database exists."
  Write-Host "Run these commands in psql as the postgres superuser:"
  Write-Host "  CREATE USER senqo WITH PASSWORD 'senqo';"
  Write-Host "  CREATE DATABASE senqo OWNER senqo;"
  exit $exitCode
}

Write-Host "[dev-migrate] Migrations applied successfully." -ForegroundColor Green
