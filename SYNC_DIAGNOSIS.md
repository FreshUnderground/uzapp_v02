# 🔴 CRITICAL SYNC ISSUE - DIAGNOSIS

## Problem Identified From Your Logs:

```
PUSH → sync.php  uri=https://uzaapp.com/api/sync.php?api_key=...  body_length=480
PUSH ✗ shops/CREATE id=4 (attempt 1/3) — will retry next sync
PUSH ✗ stories/CREATE id=5 (attempt 1/3) — will retry next sync
```

**THE RESPONSE LINE IS MISSING!** 

Normal flow should show:
```
PUSH → sync.php ... (request sent)
PUSH ← shops/CREATE status=200 body={"success":true,...} (response received)
PUSH ✓ shops/CREATE server confirmed (response parsed)
```

But you're seeing:
```
PUSH → sync.php ... (request sent)
PUSH ✗ shops/CREATE ... (failed but NO response shown)
```

---

## 🔍 What This Means:

The server is returning an **HTTP error (likely 400 or 500)** but the error response is not being logged properly. 

The MOST LIKELY causes:

### 1. **Server PHP Error** (Most Likely)
The sync.php file is crashing before it can send a response.

**Check server error logs:**
```bash
tail -f /var/log/php-fpm/error.log
# or
tail -f /var/log/apache2/error.log
```

### 2. **Missing Required Fields**
Looking at your payload:
```json
{
  "id": 1,
  "name": "iNETSECURE HUB",
  "description": "OKL;ADKNC",
  "address": "Butembo, vulengera",
  "logo_url": "https://uzaapp.com/uploads/...",
  ...
}
```

But the server's sync.php expects these columns:
```php
'shops' => ['id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 
            'whatsapp', 'phone', 'email', 'instagram_url', 'tiktok_url', 'facebook_url', 
            'youtube_url', 'banner_url', 'boost_status', 'banner_status', 'banner_text', 
            'video_url', 'is_boosted', 'is_verified', 'verified_at', 'created_at', 'updated_at']
```

**Missing from your payload:**
- ❌ `type` (REQUIRED - you're not sending it!)
- `created_at` (optional, server will add it)

### 3. **Stories Endpoint Issue**
For stories, you're sending to `stories.php` not `sync.php`. Let me check that file...

---

## ✅ IMMEDIATE FIXES:

### FIX 1: Add `type` to Shop Creation Payload

The shop creation is missing the `type` field which the server expects!

**File:** `lib/ui/screens/create_shop_screen.dart` around line 623

**Current code:**
```dart
await syncService.addToQueue('CREATE', 'shops', {
  'id': shopId,
  'name': _nameController.text.trim(),
  'description': _descriptionController.text.trim(),
  // ... other fields ...
  // MISSING: 'type': _selectedType.name,  ← THIS IS THE PROBLEM!
});
```

Wait, I see it IS there at line 629. So that's not the issue...

### FIX 2: Check Server Error Logs

The server is likely throwing a PHP error. You need to:

1. **Check PHP error log** on the server
2. **Run the test script** I created: `https://uzaapp.com/api/test_upload_sync.php`
3. **Try the HTML test** I created: Open `test_sync.html` in browser

### FIX 3: Enable Server Debug Mode

**Edit:** `server/config.php`

Make sure error reporting is ON:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

Already done! So errors should be showing...

---

## 🧪 NEXT STEPS:

### Step 1: Run the Server Test
```
https://uzaapp.com/api/test_upload_sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
```

This will tell us if:
- ✅ Upload directories exist and are writable
- ✅ Database connection works
- ✅ Tables exist
- ✅ API key is correct

### Step 2: Run the HTML Test
Open `test_sync.html` in your browser and click each test button. This will show you the EXACT error the server is returning.

### Step 3: Check Server Logs
If you have SSH access to the server:
```bash
# Check PHP errors
tail -100 /var/log/php-fpm/error.log

# Check web server errors  
tail -100 /var/log/nginx/error.log
# or
tail -100 /var/log/apache2/error.log
```

### Step 4: Test Directly with cURL
```bash
curl -X POST "https://uzaapp.com/api/sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4" \
  -H "Content-Type: application/json" \
  -d '{
    "entityType": "shops",
    "action": "CREATE",
    "data": {
      "name": "TEST SHOP",
      "description": "Test",
      "address": "Test Address",
      "owner_id": "975955375",
      "phone": "975955375",
      "type": "retail"
    }
  }'
```

This will show you the EXACT error response from the server.

---

## 📊 What I Need From You:

1. **Result of test_upload_sync.php** (the JSON output)
2. **Result of running test_sync.html** (click each button and show me the responses)
3. **Server error logs** (if you have access)
4. **cURL test result** (if you can run it)

Once I have this information, I can tell you EXACTLY what's wrong and fix it!

---

## 🎯 My Prediction:

Based on the logs, I suspect one of these:

1. **Database table `shops` is missing a column** that the code is trying to insert
2. **PHP PDO error** in sync.php (constraint violation, missing column, etc.)
3. **CORS issue** (but uploads work, so this is unlikely)
4. **Memory limit** or **execution time** exceeded (but payload is small, so unlikely)

The test scripts will tell us exactly which one it is!

---

**Please run the tests and share the results!** 🔍
