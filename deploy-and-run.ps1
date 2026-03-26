param(
  [string]$FrontendPort = "3000",
  [string]$BackendPort = "8000"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $projectRoot "frontend"
$backendDir = Join-Path $projectRoot "flower_backend"

Write-Host "Starting backend (Django) + frontend (React)..."

function Test-Port {
  param([string]$Port)
  try {
    return (Test-NetConnection -ComputerName "127.0.0.1" -Port $Port -InformationLevel Quiet)
  } catch {
    return $false
  }
}

if (-not (Test-Path $frontendDir\node_modules)) {
  Write-Host "Installing frontend dependencies (npm install)..."
  Push-Location $frontendDir
  npm install
  Pop-Location
}

Write-Host "Building frontend (npm run build)..."
Push-Location $frontendDir
$env:PORT = $FrontendPort
npm run build
Pop-Location

# Start backend if needed
if (-not (Test-Port -Port $BackendPort)) {
  Write-Host "Starting backend on port $BackendPort..."
  Push-Location $backendDir
  python manage.py migrate
  Pop-Location

  $backendProc = Start-Process -FilePath "python" -ArgumentList @(
    (Join-Path $backendDir "manage.py"),
    "runserver",
    "127.0.0.1:$BackendPort"
  ) -WorkingDirectory $backendDir -NoNewWindow -PassThru
}
else {
  Write-Host "Backend already running on port $BackendPort."
}

# Wait for backend API
Write-Host "Waiting for backend API at /api/flowers/ ..."
$apiUrl = "http://127.0.0.1:$BackendPort/api/flowers/"
for ($i = 0; $i -lt 90; $i++) {
  try {
    $res = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 2
    Write-Host "Backend is up. Flowers loaded: $($res.Count)"
    break
  } catch {
    Start-Sleep -Milliseconds 500
    if ($i -eq 89) { throw "Backend did not become ready in time." }
  }
}

# Start frontend if needed
if (-not (Test-Port -Port $FrontendPort)) {
  Write-Host "Starting frontend on port $FrontendPort..."
  Push-Location $frontendDir
  $env:PORT = $FrontendPort
  Start-Process -FilePath "npm" -ArgumentList @("start") -WorkingDirectory $frontendDir -NoNewWindow
  Pop-Location
}
else {
  Write-Host "Frontend already running on port $FrontendPort."
}

Write-Host "Opening frontend in browser..."
Start-Process "http://127.0.0.1:$FrontendPort/"

Write-Host "Done. Backend: $BackendPort | Frontend: $FrontendPort"

