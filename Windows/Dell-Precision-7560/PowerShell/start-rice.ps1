# =========================================================
# Windows Rice — Startup
# Komorebi + whkd + komorebi-bar
# =========================================================

$ErrorActionPreference = "Stop"

$root = Join-Path $HOME ".config"
$komorebiConfig = Join-Path $root "komorebi\komorebi.json"
$barConfig = Join-Path $root "komorebi\komorebi.bar.json"
$whkdConfig = Join-Path $root "whkd\whkdrc"

# Scoop executable paths
$komorebic = Join-Path $HOME "scoop\apps\komorebi\current\komorebic.exe"
$bar = Join-Path $HOME "scoop\apps\komorebi\current\komorebi-bar.exe"
$whkd = Join-Path $HOME "scoop\apps\whkd\current\whkd.exe"

foreach ($file in @(
    $komorebiConfig,
    $barConfig,
    $whkdConfig,
    $komorebic,
    $bar,
    $whkd
)) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Required file missing: $file"
    }
}

# Start Komorebi if not already running
if (-not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
    & $komorebic start --config $komorebiConfig --clean-state
    Start-Sleep -Seconds 2
}

# Start whkd if not already running
if (-not (Get-Process whkd -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $whkd `
        -ArgumentList "--config `"$whkdConfig`"" `
        -WindowStyle Hidden
}

# Start komorebi-bar if not already running
if (-not (Get-Process komorebi-bar -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $bar `
        -ArgumentList "--config `"$barConfig`"" `
        -WindowStyle Hidden
}

Write-Host "Windows Rice started." -ForegroundColor Green
