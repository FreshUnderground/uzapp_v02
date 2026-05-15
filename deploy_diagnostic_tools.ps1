# PowerShell Script: Deploy Diagnostic Tools to Server
# Usage: .\deploy_diagnostic_tools.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UZA App - Deploy Diagnostic Tools" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration - MODIFY THESE VALUES
$ftpServer = "uzaapp.com"
$ftpUser = "your_ftp_username"  # CHANGE THIS
$ftpPass = "your_ftp_password"  # CHANGE THIS
$ftpPath = "/public_html/api/"  # CHANGE THIS to your actual API directory path

# Local files to deploy
$localFiles = @(
    "server\api\check_image_urls.php",
    "server\api\find_broken_story_images.php"
)

# Function to test FTP connection
function Test-FTPConnection {
    param($server, $user, $pass)
    
    try {
        Write-Host "Testing FTP connection to $server..." -ForegroundColor Yellow
        $request = [System.Net.FtpWebRequest]::Create("ftp://$server/")
        $request.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $response = $request.GetResponse()
        $response.Close()
        Write-Host "✓ FTP connection successful!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ FTP connection failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to upload file via FTP
function Upload-FTPFile {
    param($localPath, $ftpUrl, $user, $pass)
    
    try {
        Write-Host "Uploading: $localPath" -ForegroundColor Yellow
        
        $fileBytes = [System.IO.File]::ReadAllBytes($localPath)
        $request = [System.Net.FtpWebRequest]::Create($ftpUrl)
        $request.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $request.ContentLength = $fileBytes.Length
        
        $requestStream = $request.GetRequestStream()
        $requestStream.Write($fileBytes, 0, $fileBytes.Length)
        $requestStream.Close()
        
        $response = $request.GetResponse()
        $response.Close()
        
        Write-Host "✓ Uploaded successfully!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Upload failed: $_" -ForegroundColor Red
        return $false
    }
}

# Check if files exist
Write-Host "Checking local files..." -ForegroundColor Yellow
$allFilesExist = $true
foreach ($file in $localFiles) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        Write-Host "  ✓ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "ERROR: Some files are missing. Make sure you're running this from the uzaapp directory." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test FTP connection
$connectionOk = Test-FTPConnection -server $ftpServer -user $ftpUser -pass $ftpPass

if (-not $connectionOk) {
    Write-Host ""
    Write-Host "Please update the FTP credentials in this script:" -ForegroundColor Yellow
    Write-Host "  - `$ftpUser" -ForegroundColor Yellow
    Write-Host "  - `$ftpPass" -ForegroundColor Yellow
    Write-Host "  - `$ftpPath (if different)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Upload files
Write-Host "Starting file upload..." -ForegroundColor Yellow
Write-Host ""

$uploadSuccess = 0
$uploadFailed = 0

foreach ($file in $localFiles) {
    $localPath = Join-Path $PSScriptRoot $file
    $fileName = [System.IO.Path]::GetFileName($file)
    $ftpUrl = "ftp://$ftpServer$ftpPath$fileName"
    
    $success = Upload-FTPFile -localPath $localPath -ftpUrl $ftpUrl -user $ftpUser -pass $ftpPass
    
    if ($success) {
        $uploadSuccess++
    } else {
        $uploadFailed++
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files uploaded successfully: $uploadSuccess" -ForegroundColor Green
if ($uploadFailed -gt 0) {
    Write-Host "Files failed: $uploadFailed" -ForegroundColor Red
}
Write-Host ""

if ($uploadFailed -eq 0) {
    Write-Host "✓ All files deployed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Verify files are accessible:" -ForegroundColor White
    Write-Host "   https://$ftpServer/api/check_image_urls.php" -ForegroundColor Gray
    Write-Host "   https://$ftpServer/api/find_broken_story_images.php" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run the diagnostic:" -ForegroundColor White
    Write-Host "   Open https://$ftpServer/api/check_image_urls.php in your browser" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Migrate Firebase URLs:" -ForegroundColor White
    Write-Host "   Run fix_firebase_urls.sql via phpMyAdmin" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "✗ Some files failed to upload. Check the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Upload manually via FTP client (FileZilla, WinSCP, etc.)" -ForegroundColor Yellow
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
