# AgriSmartAI — Check development server status
# Usage: .\scripts\check-dev.ps1

Write-Host ""
Write-Host "AgriSmartAI Server Status" -ForegroundColor Cyan
Write-Host "─────────────────────────" -ForegroundColor Gray

function Test-Port {
    param($Port, $Label)
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("localhost", $Port)
        $tcp.Close()
        Write-Host "  ✓ $Label (port $Port) — RUNNING" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $Label (port $Port) — NOT RUNNING" -ForegroundColor Red
    }
}

Test-Port 8000 "Backend API"
Test-Port 8081 "Farmer App"
Test-Port 8080 "Admin Dashboard"

Write-Host ""
Write-Host "Start: .\scripts\start-dev.ps1" -ForegroundColor Gray
Write-Host "Stop : .\scripts\stop-dev.ps1" -ForegroundColor Gray
Write-Host ""
