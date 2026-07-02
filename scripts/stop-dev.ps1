# AgriSmartAI — Stop all development servers
# Usage: .\scripts\stop-dev.ps1

Write-Host ""
Write-Host "Stopping AgriSmartAI development servers..." -ForegroundColor Yellow

# Kill Python processes running app.py
Get-Process -Name python -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*app.py*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Kill Flutter web processes on ports 8080 and 8081
$ports = @(8000, 8080, 8081)
foreach ($port in $ports) {
    $conn = netstat -ano | Select-String ":$port " | Select-String "LISTENING"
    if ($conn) {
        $pid = ($conn -split "\s+")[-1]
        if ($pid -match "^\d+$") {
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Write-Host "  Stopped process on port $port (PID: $pid)" -ForegroundColor Gray
        }
    }
}

Write-Host "Done. All servers stopped." -ForegroundColor Green
Write-Host ""
