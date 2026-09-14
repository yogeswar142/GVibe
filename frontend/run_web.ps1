# GVibe Chrome Port-Selector Runner
# Tests ports 3000, 5000, and 8080 in order.
# If a port is free, launches Flutter Web on that specific port.
# If all ports are occupied, alerts the user.

$AllowedPorts = @(3000, 5000, 8080)
$SelectedPort = $null

Write-Host "Checking port availability among: $($AllowedPorts -join ', ')..." -ForegroundColor Cyan

foreach ($port in $AllowedPorts) {
    $occupied = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if (-not $occupied) {
        try {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
            $listener.Start()
            $listener.Stop()
            $SelectedPort = $port
            break
        } catch {
            Write-Host "Port $port is in use or reserved." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Port $port is busy." -ForegroundColor Yellow
    }
}

if ($null -eq $SelectedPort) {
    Write-Host ""
    Write-Host "Error: None of the allowed ports (3000, 5000, 8080) are free!" -ForegroundColor Red
    Write-Host "Please close any existing applications or servers running on ports 3000, 5000, or 8080 and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found available port: $SelectedPort" -ForegroundColor Green
Write-Host "Launching Flutter Web on http://localhost:$SelectedPort ..." -ForegroundColor Cyan
Write-Host ""

Set-Location -Path "$PSScriptRoot"
flutter run -d chrome --web-port=$SelectedPort
