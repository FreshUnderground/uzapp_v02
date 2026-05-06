# PowerShell Deployment Script for UzaApp Server API Files
# This script copies the fixed API files to a deployment folder
# Then you can upload them to your server via FTP/cPanel

$sourceDir = "c:\Users\DIEU-MERCI\Music\uzaapp\server\api"
$deployDir = "c:\Users\DIEU-MERCI\Music\uzaapp\deploy_api_files"

# Create deployment directory
if (!(Test-Path $deployDir)) {
    New-Item -ItemType Directory -Path $deployDir
    Write-Host "[OK] Created deployment folder: $deployDir" -ForegroundColor Green
}

# Copy all PHP files
$phpFiles = Get-ChildItem -Path $sourceDir -Filter "*.php"
foreach ($file in $phpFiles) {
    Copy-Item -Path $file.FullName -Destination $deployDir -Force
    Write-Host "[FILE] Copied: $($file.Name)" -ForegroundColor Cyan
}

# Also copy config.php and db.php from parent directory
Copy-Item -Path "c:\Users\DIEU-MERCI\Music\uzaapp\server\config.php" -Destination $deployDir -Force
Copy-Item -Path "c:\Users\DIEU-MERCI\Music\uzaapp\server\db.php" -Destination $deployDir -Force
Write-Host "[FILE] Copied: config.php" -ForegroundColor Cyan
Write-Host "[FILE] Copied: db.php" -ForegroundColor Cyan

Write-Host "`n[SUCCESS] All files ready for deployment!" -ForegroundColor Green
Write-Host "[LOCATION] $deployDir" -ForegroundColor Yellow
Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "1. Connect to your server via FTP or cPanel" -ForegroundColor White
Write-Host "2. Navigate to /htdocs/uzaapp.com/api/" -ForegroundColor White
Write-Host "3. Upload all .php files from the deployment folder" -ForegroundColor White
Write-Host "4. Test: https://uzaapp.com/api/stories.php" -ForegroundColor White

# Open the deployment folder
explorer $deployDir
