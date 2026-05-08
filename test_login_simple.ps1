# Simple connectivity test for login.php
$apiUrl = "https://uzaapp.com/api/login.php"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Login API Connectivity Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if the URL is accessible
Write-Host "Test 1: Checking if login.php is accessible..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $apiUrl -Method Options -TimeoutSec 10
    Write-Host "✓ Server is reachable" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Cannot reach server" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "  1. login.php not uploaded correctly" -ForegroundColor Yellow
    Write-Host "  2. Server is down" -ForegroundColor Yellow
    Write-Host "  3. URL is incorrect" -ForegroundColor Yellow
    exit
}

Write-Host ""

# Test 2: Try GET request (should return 405 Method Not Allowed)
Write-Host "Test 2: Testing GET request (should fail with 405)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $apiUrl -Method Get -TimeoutSec 10
    Write-Host "  Response: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    if ($_.Exception.Response.StatusCode -eq 405) {
        Write-Host "✓ Correct! GET returns 405 (Method Not Allowed)" -ForegroundColor Green
    } else {
        Write-Host "  Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 3: Try POST with missing data (should return error)
Write-Host "Test 3: Testing POST with empty data..." -ForegroundColor Yellow
try {
    $headers = @{
        "Content-Type" = "application/json"
        "X-API-Key" = "uza_sk_305f0f1ab9c86b0259c876595f74fdf4"
    }
    $body = "{}"
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
    Write-Host "  Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
} catch {
    Write-Host "  Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "  Body: $responseBody" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
