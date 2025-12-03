param(
  [string]$LogPath = "logs/mcp/mcp-events.log",
  [string]$OutJson = "logs/mcp/metrics/summary.json",
  [string]$OutCsv = "logs/mcp/metrics/summary.csv"
)

# Fallback to mcp-shell logs
if (!(Test-Path $LogPath)) {
  $alt = "mcp-shell/logs/mcp/mcp-events.log"
  if (Test-Path $alt) { $LogPath = $alt } else { Write-Error "Log file not found"; exit 1 }
}

$lines = Get-Content $LogPath -ErrorAction Stop
$durations = @(); $success = 0; $fail = 0; $openCount = 0; $retries = 0

foreach ($l in $lines) {
  if ($l -match 'SUCCESS durationMs=(\d+)') { $durations += [int]$matches[1]; $success++ }
  elseif ($l -match 'FAIL ') { $fail++ }
  if ($l -match 'STATE_CHANGE CLOSED→OPEN') { $openCount++ }
  if ($l -match 'RETRY') { $retries++ }
}

$sorted = $durations | Sort-Object
$p95Index = [math]::Ceiling(0.95 * ($sorted.Count)) - 1; if ($p95Index -lt 0) { $p95Index = 0 }
$p99Index = [math]::Ceiling(0.99 * ($sorted.Count)) - 1; if ($p99Index -lt 0) { $p99Index = 0 }
$p95 = if ($sorted.Count) { $sorted[$p95Index] } else { 0 }
$p99 = if ($sorted.Count) { $sorted[$p99Index] } else { 0 }
$avg = if ($sorted.Count) { [math]::Round(($sorted | Measure-Object -Average).Average, 2) } else { 0 }

$summary = [pscustomobject]@{
  timestamp = (Get-Date).ToString('s')
  logPath = $LogPath
  success = $success
  failure = $fail
  p95_ms = $p95
  p99_ms = $p99
  avg_ms = $avg
  breaker_open_events = $openCount
  retry_events = $retries
}

$metricsDir = Split-Path $OutJson -Parent
if (!(Test-Path $metricsDir)) { New-Item -ItemType Directory -Path $metricsDir | Out-Null }
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $OutJson -Encoding UTF8
$summary | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

Write-Host "Metrics written:" -ForegroundColor Green
Write-Host "JSON: $OutJson" -ForegroundColor Cyan
Write-Host "CSV:  $OutCsv" -ForegroundColor Cyan
