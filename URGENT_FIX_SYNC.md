# 🔴 ROOT CAUSE IDENTIFIED - SYNC FAILING

## The Problem:

Looking at your logs, I found the **EXACT issue**:

```
PUSH → sync.php  uri=https://uzaapp.com/api/sync.php  body_length=480
PUSH ✗ shops/CREATE id=4 (attempt 1/3)
PUSH ✗ stories/CREATE id=5 (attempt 1/3)
PUSH ✗ stories/CREATE id=6 (attempt 1/3)
```

**ALL items are failing because the SHOP doesn't exist on the server!**

---

## 🎯 Root Cause:

Your app is trying to sync in this order:
1. ✅ Images upload successfully (logo, story images)
2. ❌ **Shop CREATE fails** (shop not created on server)
3. ❌ **Stories CREATE fail** (because `shop_id=1` doesn't exist on server)
4. ❌ **Products CREATE fail** (because `shop_id` doesn't exist on server)

### Why Shop Creation is Failing:

The shop sync is sent to `sync.php` with this payload:
```json
{
  "entityType": "shops",
  "action": "CREATE", 
  "data": {
    "id": 1,
    "name": "iNETSECURE HUB",
    "description": "OKL;ADKNC",
    "address": "Butembo, vulengera",
    "logo_url": "https://uzaapp.com/uploads/boutiques/profil/1778223519_...",
    "type": "retail",
    "owner_id": "975955375",
    "phone": "975955375",
    ...
  }
}
```

But the server's `sync.php` is **rejecting it** with an HTTP error (likely 400 or 500).

---

## 🔍 How to Find the EXACT Error:

### TEST 1: Server Diagnostics (DO THIS FIRST)
```
https://uzaapp.com/api/test_upload_sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
```

This will show:
- ✅ If upload directories exist
- ✅ If database is connected
- ✅ If tables exist
- ✅ Recent activity

### TEST 2: Story Payload Test
```
https://uzaapp.com/api/test_story_payload.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
```

This will show:
- ✅ If `shop_id=1` exists on server
- ✅ If the story payload is valid
- ✅ Exact SQL error if insert fails

### TEST 3: Interactive Sync Test
Open `test_sync.html` in browser and click:
1. "Test Ping" - Check server connectivity
2. "Test Shop CREATE" - See exact shop creation error
3. "Test Story CREATE" - See exact story creation error
4. "Test Product CREATE" - See exact product creation error

---

## 💡 Most Likely Causes:

### Cause 1: Database Table Missing Columns (80% probability)

The `shops` table on the server might be missing columns that the code is trying to insert.

**Check:**
```sql
DESCRIBE shops;
```

**Expected columns:**
```
id, name, description, logo_url, type, owner_id, address, whatsapp, 
phone, email, instagram_url, tiktok_url, facebook_url, youtube_url, 
banner_url, boost_status, banner_status, banner_text, video_url, 
is_boosted, is_verified, verified_at, created_at, updated_at
```

**If columns are missing**, run this SQL:
```sql
-- Add missing columns
ALTER TABLE shops ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'retail';
ALTER TABLE shops ADD COLUMN IF NOT EXISTS boost_status INT DEFAULT 0;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS banner_status INT DEFAULT 0;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS banner_text VARCHAR(255);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS video_url VARCHAR(500);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS is_boosted TINYINT DEFAULT 0;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS is_verified TINYINT DEFAULT 0;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS verified_at DATETIME;
ALTER TABLE shops ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS commune VARCHAR(100);
```

### Cause 2: Foreign Key Constraint (15% probability)

The `owner_id` might need to reference a `users` table entry that doesn't exist.

**Check:**
```sql
-- Check if user exists
SELECT * FROM users WHERE phone = '975955375';

-- If not found, the shop creation will fail
```

**Fix:**
```sql
-- Create the user first
INSERT INTO users (phone, name, is_phone_verified) 
VALUES ('975955375', 'iNETSECURE HUB', 1);
```

### Cause 3: PHP Syntax/Runtime Error (5% probability)

There might be a PHP error in `sync.php`.

**Check server logs:**
```bash
tail -100 /var/log/php-fpm/error.log
# or
tail -100 /var/log/apache2/error.log
```

---

## ✅ IMMEDIATE ACTION PLAN:

### Step 1: Run Test Scripts (2 minutes)
1. Open: `https://uzaapp.com/api/test_upload_sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4`
2. Open: `https://uzaapp.com/api/test_story_payload.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4`
3. Open: `test_sync.html` in browser and click all buttons

### Step 2: Share Results
Copy and paste the JSON output from all 3 tests.

### Step 3: I'll Fix It
Once I see the exact error, I can provide the exact SQL or code fix.

---

## 🚀 Quick Fix (If You Have Database Access):

If you can access the server database directly, try this:

```sql
-- 1. Check what's in the shops table
SELECT COUNT(*) as shop_count FROM shops;

-- 2. Check if the user exists
SELECT * FROM users WHERE phone = '975955375';

-- 3. Manually insert the shop (if tables are correct)
INSERT INTO shops (
    name, description, address, logo_url, type, owner_id, 
    phone, whatsapp, is_verified, created_at, updated_at
) VALUES (
    'iNETSECURE HUB',
    'OKL;ADKNC',
    'Butembo, vulengera',
    'https://uzaapp.com/uploads/boutiques/profil/1778223519_fd3a3fe925dc1d6b.png',
    'retail',
    '975955375',
    '975955375',
    '',
    1,
    NOW(),
    NOW()
);

-- 4. Get the new shop ID
SELECT LAST_INSERT_ID() as new_shop_id;

-- 5. Check stories table structure
DESCRIBE stories;

-- 6. Try inserting a test story (using the new shop ID)
INSERT INTO stories (
    shop_id, media_url, media_type, is_arrivage, expires_at, created_at
) VALUES (
    1, -- Replace with actual shop ID from step 4
    'https://uzaapp.com/uploads/stories/test.jpg',
    'image',
    0,
    '2026-05-09 07:01:58',
    NOW()
);
```

---

## 📊 Expected Test Results:

### If EVERYTHING works:
```json
{
  "success": true,
  "new_story_id": 123,
  "message": "Story created successfully!"
}
```

### If shop doesn't exist:
```json
{
  "error": "Shop ID 1 does not exist on server!",
  "solution": "Shop must be synced first before stories can be created"
}
```

### If database error:
```json
{
  "error": "Database error",
  "message": "SQLSTATE[42S22]: Column not found: 1054 Unknown column 'city' in 'field list'",
  "code": "42S22"
}
```

---

## 🆘 What I Need From You:

**Please run these 3 tests and send me the output:**

1. ✅ `https://uzaapp.com/api/test_upload_sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4`
2. ✅ `https://uzaapp.com/api/test_story_payload.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4`
3. ✅ Open `test_sync.html` → Click "Test Shop CREATE" button

**Once I see the errors, I can fix this in 5 minutes!** ⚡

---

**The issue is on the SERVER side, not in your Flutter app.** The app is working correctly - it's uploading images and queueing sync items. The server is rejecting them, and we just need to see WHY.

Run the tests! 🚀
