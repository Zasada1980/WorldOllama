# PowerShell Deployment Script для CompanyCheck
# Использование: .\deploy.ps1

param(
    [string]$ServerIP = "46.224.36.109",
    [string]$ServerUser = "root",
    [string]$RemotePath = "/var/www/html/company-check"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   CompanyCheck Deployment Script v1.0       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build
Write-Host "📦 Step 1/5: Building production..." -ForegroundColor Yellow
Set-Location "e:\WORLD_OLLAMA\temp\company-check-local"

npm run build 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed! Check errors above." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build complete (dist/ folder created)" -ForegroundColor Green

# Step 2: Create archive
Write-Host ""
Write-Host "📁 Step 2/5: Creating deployment archive..." -ForegroundColor Yellow

if (Test-Path "company-check-dist.zip") {
    Remove-Item "company-check-dist.zip" -Force
}

Compress-Archive -Path "dist\*" -DestinationPath "company-check-dist.zip" -CompressionLevel Optimal

$archiveSize = (Get-Item "company-check-dist.zip").Length / 1MB
Write-Host "✅ Archive created: company-check-dist.zip ($([math]::Round($archiveSize, 2)) MB)" -ForegroundColor Green

# Step 3: Test SSH connection
Write-Host ""
Write-Host "🔐 Step 3/5: Testing SSH connection..." -ForegroundColor Yellow

$sshTest = ssh -o BatchMode=yes -o ConnectTimeout=5 ${ServerUser}@${ServerIP} "echo 'Connection OK'" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ SSH connection failed!" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. Server IP: $ServerIP" -ForegroundColor Yellow
    Write-Host "  2. SSH keys configured" -ForegroundColor Yellow
    Write-Host "  3. Server is online" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Use manual upload (see DEPLOYMENT.md)" -ForegroundColor Cyan
    exit 1
}
Write-Host "✅ SSH connection successful" -ForegroundColor Green

# Step 4: Upload to server
Write-Host ""
Write-Host "⬆️  Step 4/5: Uploading to server..." -ForegroundColor Yellow

scp -o ConnectTimeout=10 company-check-dist.zip ${ServerUser}@${ServerIP}:/tmp/

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Upload complete" -ForegroundColor Green

# Step 5: Deploy on server
Write-Host ""
Write-Host "🔧 Step 5/5: Deploying on server..." -ForegroundColor Yellow

$deployScript = @"
#!/bin/bash
set -e

echo '📦 Extracting files...'
mkdir -p $RemotePath
cd /tmp
unzip -o company-check-dist.zip -d $RemotePath

echo '🔒 Setting permissions...'
chown -R www-data:www-data $RemotePath
chmod -R 755 $RemotePath

echo '🧹 Cleaning up...'
rm /tmp/company-check-dist.zip

echo '✅ Deployment complete!'
echo ''
echo 'Files deployed to: $RemotePath'
echo 'Access at: http://$ServerIP/company-check'
"@

ssh ${ServerUser}@${ServerIP} $deployScript

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed on server!" -ForegroundColor Red
    exit 1
}

# Cleanup local archive
Write-Host ""
Write-Host "🧹 Cleaning up local files..." -ForegroundColor Yellow
Remove-Item "company-check-dist.zip" -Force
Write-Host "✅ Cleanup complete" -ForegroundColor Green

# Success message
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          ✅ DEPLOYMENT SUCCESSFUL!           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your app is now live at:" -ForegroundColor Cyan
Write-Host "   http://$ServerIP/company-check" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Configure Nginx (see DEPLOYMENT.md)" -ForegroundColor White
Write-Host "   2. Setup SSL certificate (optional)" -ForegroundColor White
Write-Host "   3. Configure domain name (optional)" -ForegroundColor White
Write-Host ""
