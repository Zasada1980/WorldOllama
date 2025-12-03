# Phase 2.3: Encoding Edge Cases Tests

Write-Host "=== Encoding Edge Cases ===" -ForegroundColor Cyan

function Test-Case {
  param($Command, $Desc)
  Write-Host "Test: $Desc" -ForegroundColor Yellow
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
  $enc = [Convert]::ToBase64String($bytes)
  try {
    $out = powershell -NoProfile -NonInteractive -EncodedCommand $enc 2>&1
    $ec = $LASTEXITCODE
    if ($ec -eq 0) { Write-Host "  ✅ PASS" -ForegroundColor Green } else { Write-Host "  ❌ FAIL ($ec)" -ForegroundColor Red }
  } catch { Write-Host "  ❌ EXCEPTION: $_" -ForegroundColor Red }
  Write-Host ""
}

# 1) CRLF handling
$cmd1 = "Write-Host 'Line1'`r`nWrite-Host 'Line2'"
Test-Case $cmd1 "CRLF newlines"

# 2) Unicode (Cyrillic + Emoji)
$cmd2 = "Write-Host 'Привет мир 🌍'"
Test-Case $cmd2 "Unicode Cyrillic + Emoji"

# 3) Long pipeline with quotes and braces
$cmd3 = "Get-ChildItem | Where-Object { `$_.Name -match 'log' } | Select-Object FullName | Out-String"
Test-Case $cmd3 "Long pipeline with quotes/braces"

# 4) Escaped backticks and dollars
$cmd4 = "Write-Host 'Tick `` Dollar `$ Var $_'"
Test-Case $cmd4 "Backtick and dollar escapes"

Write-Host "=== Done ===" -ForegroundColor Cyan
