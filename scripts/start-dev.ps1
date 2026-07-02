# AgriSmartAI — Start development servers
# Usage: .\scripts\start-dev.ps1

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  AgriSmartAI - Starting Development Servers" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

# ── 1. Backend API ────────────────────────────────────────────────────────────

Write-Host "[1/3] Starting Backend API (port 8000)..." -ForegroundColor Cyan
$backendDir = Join-Path $ProjectRoot "backend"

# Install Python dependencies if needed
if (-not (Get-Command flask -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing Python dependencies..." -ForegroundColor Yellow
    pip install -r (Join-Path $backendDir "requirements.txt") -q
}

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$backendDir'; python app.py"
) -WindowStyle Normal

Start-Sleep -Seconds 2

# ── 2. Flutter Farmer App (Web) ───────────────────────────────────────────────

Write-Host "[2/3] Starting Farmer App (port 8081)..." -ForegroundColor Cyan
$mobileDir = Join-Path $ProjectRoot "frontend\mobile_app"
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$mobileDir'; flutter run -d chrome --web-port 8081"
) -WindowStyle Normal

Start-Sleep -Seconds 2

# ── 3. Flutter Admin Dashboard (Web) ─────────────────────────────────────────

Write-Host "[3/3] Starting Admin Dashboard (port 8080)..." -ForegroundColor Cyan
$adminDir = Join-Path $ProjectRoot "frontend\admin_dashboard"
if (Test-Path $adminDir) {
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "cd '$adminDir'; flutter run -d chrome --web-port 8080"
    ) -WindowStyle Normal
} else {
    Write-Host "    Admin dashboard not yet implemented — skipping." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  OPEN THESE URLs" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Backend API  : http://localhost:8000" -ForegroundColor White
Write-Host "  Farmer App   : http://localhost:8081" -ForegroundColor White
Write-Host "  Admin Panel  : http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "  Wait 2-3 minutes for Flutter to compile on first run." -ForegroundColor Yellow
Write-Host "  Stop servers: .\scripts\stop-dev.ps1" -ForegroundColor Gray
Write-Host ""
