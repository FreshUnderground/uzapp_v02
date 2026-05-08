# Test Login API Endpoint
# This script tests the login.php endpoint

$apiUrl = "https://uzaapp.com/api/login.php"
$apiKey = "uza_sk_305f0f1ab9c86b0259c876595f74fdf4"

# Test data
$phone = "975955375"
$password = "test123" # Change this to your actual password

# Hash the password using SHA-256
$passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash($passwordBytes)
$passwordHash = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Login API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "URL: $apiUrl" -ForegroundColor Yellow
Write-Host "Phone: $phone" -ForegroundColor Yellow
Write-Host "Password Hash: $passwordHash" -ForegroundColor Yellow
Write-Host ""

# Create the request body
$body = @{
    phone = $phone
    password_hash = $passwordHash
} | ConvertTo-Json

# Set headers
$headers = @{
    "Content-Type" = "application/json"
    "X-API-Key" = $apiKey
}

try {
    Write-Host "Sending request..." -ForegroundColor Green
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Response Received!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error Occurred!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
