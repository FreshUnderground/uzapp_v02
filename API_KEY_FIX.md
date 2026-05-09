# API Key Authentication Fix

## Problem

Error received:
```json
{
  "error": "Unauthorized: Invalid or missing API key",
  "debug": {
    "received_key": "present",
    "expected_prefix": "uza_sk_",
    "headers_available": ["X-Varnish", "Via", ...]
  }
}
```

## Root Cause

**API Key Mismatch** between Flutter app and server:

- **Flutter app** uses: `uza_sk_305f0f1ab9c86b0259c876595f74fdf4`
- **Server** was generating: `uza_sk_` + MD5('uzaapp_secure_2024') = different key!

The server was dynamically generating the API key using:
```php
define('API_KEY', 'uza_sk_' . md5('uzaapp_secure_2024'));
```

This created a different key than what the Flutter app was sending.

## Fix Applied

Updated both server config files to use the **same hardcoded key** as the Flutter app:

### Files Modified:

1. **`server/config.php`** (line 8-10)
2. **`deploy_api_files/config.php`** (line 8-10)

**Before:**
```php
// API Key Authentication
define('API_KEY', 'uza_sk_' . md5('uzaapp_secure_2024'));
```

**After:**
```php
// API Key Authentication
// Hardcoded key for consistency across all clients
define('API_KEY', 'uza_sk_305f0f1ab9c86b0259c876595f74fdf4');
```

## Deployment Steps

### Step 1: Upload Fixed Config Files

Upload these files to your server:

1. `server/config.php` → `https://uzaapp.com/api/config.php`
2. `deploy_api_files/config.php` → (if used in deployment)

Or run the deployment script:
```powershell
.\deploy_api_files.ps1
```

### Step 2: Test Authentication

Visit the diagnostic endpoint:
```
https://uzaapp.com/api/check_api_key.php
```

You should see:
```
Server API_KEY: uza_sk_305f0f1ab9c86b0259c876595f74fdf4
Expected by Flutter app: uza_sk_305f0f1ab9c86b0259c876595f74fdf4

✅ Keys MATCH - authentication should work
```

### Step 3: Test Stories Sync

1. Open the app on your device
2. Go to Arrivages screen
3. Pull down to force sync
4. Check Flutter logs - you should now see:
   ```
   API: Fetching stories from https://uzaapp.com/api/stories.php?...
   API: Stories response status: 200
   API: Fetched X stories  ✅ (where X > 0)
   ```

## How Authentication Works

The server's `authenticate()` function in `db.php` tries 3 methods:

1. **Header:** `X-API-Key` header (preferred)
2. **FastCGI:** `$_SERVER['HTTP_X_API_KEY']` (some server configs)
3. **Query Param:** `?api_key=...` (fallback for proxy/caching layers)

The Flutter app sends the key **both ways** for maximum compatibility:
- In headers: `'X-API-Key': 'uza_sk_305f0f1ab9c86b0259c876595f74fdf4'`
- In URL: `?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4`

## Verification Checklist

After deployment:

- [ ] Upload `config.php` to server
- [ ] Visit `check_api_key.php` to verify keys match
- [ ] Test API endpoint manually: `https://uzaapp.com/api/stories.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4`
- [ ] Check Flutter app logs for successful API calls
- [ ] Verify stories appear on all devices

## Security Note

For production, consider:
- Storing API key in environment variables instead of hardcoded
- Using different keys for development/production
- Implementing key rotation mechanism
- Adding rate limiting to prevent abuse

## Files Created

- ✅ `server/api/check_api_key.php` - Diagnostic tool to verify API key match

## Files Modified

- ✅ `server/config.php` - Hardcoded API key to match Flutter app
- ✅ `deploy_api_files/config.php` - Hardcoded API key to match Flutter app

---

**Status:** ✅ Fix applied, ready for deployment
**Date:** 2026-05-09
**Issue:** API authentication failure due to key mismatch
