param(
  [string]$LogPath = "logs/mcp/mcp-events.log"
)

# Try default path; if missing, try mirrored mcp-shell location
if (!(Test-Path $LogPath)) {
  $alt = "mcp-shell/logs/mcp/mcp-events.log"
  if (Test-Path $alt) {
    Write-Host "Using alternate log path: $alt" -ForegroundColor Cyan
    $LogPath = $alt
  } else {
    Write-Error "Log file not found: $LogPath"; exit 1
  }
}

$lines = Get-Content $LogPath -ErrorAction Stop

# Extract durations and classifications
$durations = @()
$fail = 0; $success = 0
foreach ($l in $lines) {
  if ($l -match 'SUCCESS durationMs=(\d+)') {
    $durations += [int]$matches[1]
    $success++
  }
  elseif ($l -match '^\[.+\] FAIL ' -or $l -match 'TIMEOUT ') {
    $fail++
  }
}

if ($durations.Count -gt 0) {
  $sorted = $durations | Sort-Object
  $p95Index = [math]::Ceiling(0.95 * $sorted.Count) - 1
  if ($p95Index -lt 0) { $p95Index = 0 }
  $p95 = $sorted[$p95Index]
  $avg = [math]::Round(($sorted | Measure-Object -Average).Average, 2)
  Write-Host "SUCCESS count: $success" -ForegroundColor Green
  Write-Host "FAILURE count: $fail" -ForegroundColor Red
  Write-Host "Avg duration: $avg ms" -ForegroundColor Gray
  Write-Host "p95 duration: $p95 ms" -ForegroundColor Yellow
} else {
  Write-Host "No SUCCESS entries yet. Failures: $fail" -ForegroundColor DarkYellow
}
