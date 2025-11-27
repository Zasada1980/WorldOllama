# Project Cleanup Script — TD-010v2 Production Finalization
# Purpose: Move production model, archive legacy, remove invalid experiments
# Date: 27 ноября 2025 г.

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PROJECT CLEANUP & FINALIZATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# === 1. Define Paths ===
$root = "E:\WORLD_OLLAMA\services\llama_factory\saves"
$prod = "E:\WORLD_OLLAMA\production"
$arch = "E:\WORLD_OLLAMA\archive"

Write-Host "📁 Paths Configuration:" -ForegroundColor Yellow
Write-Host "  ├─ Source: $root" -ForegroundColor White
Write-Host "  ├─ Production: $prod" -ForegroundColor Green
Write-Host "  └─ Archive: $arch`n" -ForegroundColor Magenta

# === 2. Create Destination Directories ===
Write-Host "🔧 Creating destination directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $prod | Out-Null
New-Item -ItemType Directory -Force -Path $arch | Out-Null
Write-Host "  └─ ✅ Directories created`n" -ForegroundColor Green

# === 3. Production Model (triz_full) ===
Write-Host "🚀 Moving production model (TD-010v2 triz_full)..." -ForegroundColor Cyan
$trizFull = "$root\Qwen2.5-1.5B-Instruct\lora\triz_full"
$prodDest = "$prod\TD010v2_triz_full"

if (Test-Path $trizFull) {
    if (Test-Path $prodDest) {
        Write-Host "  ⚠️ Production destination already exists, removing old..." -ForegroundColor Yellow
        Remove-Item $prodDest -Recurse -Force
    }
    Move-Item $trizFull $prodDest -Force
    
    # Verify
    $adapterSize = [math]::Round((Get-Item "$prodDest\adapter_model.safetensors").Length/1MB, 2)
    Write-Host "  ├─ Moved to: $prodDest" -ForegroundColor Green
    Write-Host "  ├─ Adapter Size: $adapterSize MB" -ForegroundColor Green
    Write-Host "  └─ ✅ Production model secured`n" -ForegroundColor Green
} else {
    Write-Host "  └─ ⚠️ WARNING: triz_full not found at $trizFull`n" -ForegroundColor Yellow
}

# === 4. Archive Legacy Version (triz_extended) ===
Write-Host "📦 Archiving legacy TD-010v2 (triz_extended)..." -ForegroundColor Cyan
$trizExtended = "$root\Qwen2.5-1.5B\lora\triz_extended"
$archDest = "$arch\TD010v2_triz_extended"

if (Test-Path $trizExtended) {
    if (Test-Path $archDest) {
        Remove-Item $archDest -Recurse -Force
    }
    Move-Item $trizExtended $archDest -Force
    Write-Host "  └─ ✅ Archived to: $archDest`n" -ForegroundColor Green
} else {
    Write-Host "  └─ ⚠️ triz_extended not found (may be already archived)`n" -ForegroundColor Yellow
}

# === 5. Remove Invalid/Experimental Models ===
Write-Host "🗑️ Removing invalid experimental models..." -ForegroundColor Red
$toRemove = @(
    "*td010v1*",
    "*td010v3*",
    "*td010v4*",
    "*rank16*",
    "*triz_minimal_test*"
)

$removedCount = 0
foreach ($pattern in $toRemove) {
    $found = Get-ChildItem -Path $root -Recurse -Directory -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -like $pattern -or $_.FullName -like $pattern }
    
    if ($found) {
        foreach ($item in $found) {
            Write-Host "  ├─ Removing: $($item.Name)" -ForegroundColor DarkGray
            Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $removedCount++
        }
    }
}
Write-Host "  └─ ✅ Removed $removedCount invalid models`n" -ForegroundColor Green

# === 6. Archive 7B Checkpoint (R&D potential) ===
Write-Host "🧩 Archiving Qwen2-7B checkpoint (R&D potential)..." -ForegroundColor Cyan
$qwen7b = "$root\Qwen2-7B-Instruct"
$qwen7bDest = "$arch\Qwen2-7B_checkpoint"

if (Test-Path $qwen7b) {
    if (Test-Path $qwen7bDest) {
        Remove-Item $qwen7bDest -Recurse -Force
    }
    Move-Item $qwen7b $qwen7bDest -Force
    
    $adapter7bSize = 0
    $adapters = Get-ChildItem "$qwen7bDest" -Recurse -Filter "adapter_model.safetensors" -ErrorAction SilentlyContinue
    if ($adapters) {
        $adapter7bSize = [math]::Round(($adapters | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    }
    Write-Host "  ├─ Moved to: $qwen7bDest" -ForegroundColor Green
    Write-Host "  ├─ Total Adapters Size: $adapter7bSize MB" -ForegroundColor Green
    Write-Host "  └─ ✅ 7B checkpoint archived for future use`n" -ForegroundColor Green
} else {
    Write-Host "  └─ ⚠️ Qwen2-7B not found (may be already archived)`n" -ForegroundColor Yellow
}

# === 7. Verification Report ===
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CLEANUP VERIFICATION REPORT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📊 Production Models:" -ForegroundColor Green
if (Test-Path $prod) {
    Get-ChildItem $prod -Directory | ForEach-Object {
        $adapterFile = Get-ChildItem $_.FullName -Recurse -Filter "adapter_model.safetensors" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($adapterFile) {
            $size = [math]::Round($adapterFile.Length/1MB, 2)
            Write-Host "  ├─ $($_.Name): $size MB" -ForegroundColor White
        }
    }
} else {
    Write-Host "  └─ No production models found" -ForegroundColor Yellow
}

Write-Host "`n📦 Archived Models:" -ForegroundColor Magenta
if (Test-Path $arch) {
    Get-ChildItem $arch -Directory | ForEach-Object {
        $adapterFiles = Get-ChildItem $_.FullName -Recurse -Filter "adapter_model.safetensors" -ErrorAction SilentlyContinue
        if ($adapterFiles) {
            $totalSize = [math]::Round(($adapterFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
            Write-Host "  ├─ $($_.Name): $totalSize MB ($(($adapterFiles | Measure-Object).Count) adapters)" -ForegroundColor White
        }
    }
} else {
    Write-Host "  └─ No archived models" -ForegroundColor Yellow
}

Write-Host "`n🗑️ Remaining in saves/ (should be minimal):" -ForegroundColor Yellow
if (Test-Path $root) {
    $remaining = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue
    if ($remaining) {
        $remaining | ForEach-Object {
            Write-Host "  ├─ $($_.Name)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  └─ ✅ Clean (no remaining models)" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test production model: ollama run triz-td010v2" -ForegroundColor White
Write-Host "  2. Create audit log: TD010_AUDIT_OK.log" -ForegroundColor White
Write-Host "  3. Integrate with Neuro-Terminal`n" -ForegroundColor White
