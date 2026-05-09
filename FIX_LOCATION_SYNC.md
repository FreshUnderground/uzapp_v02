# 🔧 Fix: Location Data Not Syncing to Server

## Problem Description
When creating or editing a shop profile, the coordinates (latitude/longitude) were **NOT** being sent to the server, even though:
- ✅ The Flutter app was correctly capturing and including the coordinates in the sync payload
- ✅ The local SQLite database had the latitude/longitude columns
- ✅ The server database schema included these columns

## Root Cause
**TWO files** had an **allowlist** of columns that filters incoming data before inserting/updating the database:

1. **`server/api/shops.php`** - Used for direct shop operations
2. **`server/api/sync.php`** - Used for synchronized operations (CREATE/UPDATE from app)

The `latitude`, `longitude`, `city`, and `commune` fields were **NOT** in either allowlist, so they were being silently filtered out before reaching the database.

### Code Locations

**File 1:** `server/api/shops.php` (lines 7-14)
**File 2:** `server/api/sync.php` (lines 7-18)

**Before:**
```php
$ALLOWED_SHOP_COLUMNS = [
    'id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 'whatsapp',
    'phone', 'email', 'instagram_url', 'tiktok_url', 'facebook_url', 'youtube_url',
    'banner_url', 'boost_status', 'banner_status', 'banner_text', 'video_url',
    'is_boosted', 'is_verified', 'verified_at', 'created_at', 'updated_at'
];
```

**After:**
```php
$ALLOWED_SHOP_COLUMNS = [
    'id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 'whatsapp',
    'phone', 'email', 'instagram_url', 'tiktok_url', 'facebook_url', 'youtube_url',
    'banner_url', 'boost_status', 'banner_status', 'banner_text', 'video_url',
    'is_boosted', 'is_verified', 'verified_at', 'created_at', 'updated_at',
    'latitude', 'longitude', 'city', 'commune'  // ← ADDED
];
```

## Solution Applied

### 1. Updated `server/api/shops.php`
Added `latitude`, `longitude`, `city`, and `commune` to the `$ALLOWED_SHOP_COLUMNS` array.

### 2. Updated `server/api/sync.php` ⭐ CRITICAL
Added `latitude`, `longitude`, `city`, and `commune` to the `$ALLOWED_COLUMNS['shops']` array.

**This is the file that actually handles shop synchronization from the app!**

### 3. Created SQL Migration Script
**File:** `server/add_location_columns_to_shops.sql`

This script ensures the database columns exist (for servers that haven't run the latest schema migration).

### 3. Created Diagnostic Test Script
**File:** `server/api/test_location_sync.php`

This comprehensive test script verifies:
- ✅ Database columns exist
- ✅ shops.php allowlist includes location fields
- ✅ Test insertion with location data works
- ✅ Shows recent shops with location data

**Usage:**
```
https://uzaapp.com/api/test_location_sync.php?api_key=YOUR_API_KEY
```

## Deployment Steps

1. **Deploy BOTH updated PHP files to your server:**
   ```bash
   # Upload the modified files
   scp server/api/shops.php user@yourserver:/path/to/uzaapp/api/
   scp server/api/sync.php user@yourserver:/path/to/uzaapp/api/
   ```
   
   ⚠️ **IMPORTANT:** `sync.php` is the critical file - it handles all shop synchronization from the app!

2. **Run the SQL migration (if needed):**
   ```bash
   mysql -u your_user -p your_database < server/add_location_columns_to_shops.sql
   ```

3. **Test the fix:**
   - Open: `https://uzaapp.com/api/test_location_sync.php?api_key=YOUR_API_KEY`
   - Verify all tests pass ✅
   
4. **Create a test shop from the app:**
   - Create a new shop with location enabled
   - Verify the coordinates appear in the server database

## Verification

### Check Server Database
```sql
SELECT id, name, city, commune, latitude, longitude, created_at 
FROM shops 
WHERE latitude IS NOT NULL 
ORDER BY created_at DESC 
LIMIT 10;
```

### Check Flutter Sync Logs
When creating a shop, look for these debug logs:
```
SHOP SYNC QUEUED: Shop ID=X, Owner ID=Y
SHOP SYNC DATA: {"id":X,"name":"...","latitude":-4.3216,"longitude":15.3123,...}
```

### Check Sync Queue
```sql
SELECT id, entity_type, action, entity_data 
FROM sync_queue 
WHERE entity_type = 'shops' 
ORDER BY id DESC 
LIMIT 5;
```

The `entity_data` JSON should include `latitude` and `longitude`.

## Impact

### Fixed Scenarios
- ✅ New shop creation with location → coordinates sync to server
- ✅ Shop profile edit with location update → coordinates sync to server
- ✅ City and commune fields now sync correctly

### No Breaking Changes
- Existing shops without location data remain unaffected
- The fields are nullable, so shops without GPS coordinates still work
- Backward compatible with older app versions

## Files Modified
1. `server/api/shops.php` - Added location fields to allowlist
2. `server/api/sync.php` - Added location fields to allowlist ⭐ **CRITICAL FIX**
3. `server/add_location_columns_to_shops.sql` - New migration script
4. `server/api/test_location_sync.php` - New diagnostic tool

## Related Files (No Changes Needed)
- `lib/ui/screens/create_shop_screen.dart` - Already sends coordinates ✅
- `lib/ui/screens/edit_shop_screen.dart` - Already sends coordinates ✅
- `lib/data/services/sync_service.dart` - Already queues coordinates ✅
- `server/database_schema.sql` - Already has columns defined ✅

## Prevention
To avoid similar issues in the future:
1. When adding new database columns, always update the allowlist arrays in **BOTH** `shops.php` AND `sync.php`
2. Run the diagnostic test script after any schema changes
3. Check sync logs to verify all expected fields are being transmitted
4. Remember: Shops/Products use `sync.php` for synchronization, not their individual endpoint files
