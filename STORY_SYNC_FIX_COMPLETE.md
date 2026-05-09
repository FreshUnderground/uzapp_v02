# Story Synchronization Fix - Complete Solution

## Problem Identified

Stories created on one device were visible online but NOT appearing on other devices.

### Root Causes Found:

1. **Missing `remote_id` in API Response**
   - Server wasn't returning `remote_id` field when fetching stories
   - Clients couldn't deduplicate or properly sync stories

2. **Missing `remote_id` on Story Creation**
   - When stories were created, `remote_id` wasn't being set
   - New stories had `NULL` remote_id values

3. **Incorrect Sync Query Logic**
   - Server filtered stories by `created_at > updated_since`
   - Older (but still active) stories were excluded from sync
   - Devices doing first sync or sync after long time got 0 stories

## Fixes Applied

### 1. Server API: `stories.php` (Both server/api/ and deploy_api_files/)

**Fix 1: Return `remote_id` in response**
```php
// Line ~196-200
foreach ($stories as &$story) {
    $story['id'] = (int)$story['id'];
    $story['shop_id'] = (int)$story['shop_id'];
    
    // Include remote_id for sync (use id if remote_id is null)
    $story['remote_id'] = $story['remote_id'] ?? $story['id'];
    // ... rest of code
}
```

**Fix 2: Set `remote_id` on creation**
```php
// Line ~80-85 (after INSERT)
$newId = $db->lastInsertId();

// Set remote_id to match the new story id for sync consistency
$stmt = $db->prepare("UPDATE stories SET remote_id = ? WHERE id = ?");
$stmt->execute([$newId, $newId]);
```

**Fix 3: Return ALL active stories in sync mode**
```php
// Line ~168-175
if ($isSyncMode) {
    // For sync mode, ALWAYS return non-expired stories (ignore updated_since filter)
    // Stories have short lifespans, so we need all active ones for proper sync
    $query = "SELECT s.*, sh.name AS shop_name 
              FROM stories s 
              LEFT JOIN shops sh ON s.shop_id = sh.id 
              WHERE s.expires_at > NOW() 
              ORDER BY s.created_at DESC";
    $params = [];
    // ... execute query
}
```

### 2. Server API: `sync.php` (Both server/api/ and deploy_api_files/)

**Fix: Set `remote_id` on story creation via sync endpoint**
```php
// Line ~307-313 (after INSERT)
$newId = $db->lastInsertId();

// Set remote_id to match the new story id for sync consistency
$stmt = $db->prepare("UPDATE stories SET remote_id = ? WHERE id = ?");
$stmt->execute([$newId, $newId]);
```

### 3. Database Fix Script

**File: `fix_story_remote_ids.sql`**
```sql
-- Fix missing remote_id for all existing stories
UPDATE stories 
SET remote_id = id 
WHERE remote_id IS NULL OR remote_id = '';

-- Verify the fix
SELECT 
    COUNT(*) as total_stories,
    SUM(CASE WHEN remote_id IS NULL OR remote_id = '' THEN 1 ELSE 0 END) as still_missing,
    SUM(CASE WHEN remote_id IS NOT NULL AND remote_id != '' THEN 1 ELSE 0 END) as has_remote_id
FROM stories;
```

### 4. Diagnostic Tool

**File: `server/api/check_story_sync.php`**
- Web endpoint to check story sync status
- Automatically fixes missing remote_id values
- Shows test sync response
- Provides debugging instructions

## Deployment Steps

### Step 1: Upload Fixed Files to Server

Upload these files to your server (`https://uzaapp.com/api/`):

1. `stories.php` (from `server/api/stories.php`)
2. `sync.php` (from `server/api/sync.php`)
3. `check_story_sync.php` (optional, for diagnostics)

OR use PowerShell script:
```powershell
.\deploy_api_files.ps1
```

### Step 2: Fix Existing Stories

**Option A: Via SQL (Recommended)**
```bash
# Connect to your MySQL database and run:
mysql -u your_username -p your_database_name < fix_story_remote_ids.sql
```

**Option B: Via Web Endpoint**
```
Visit: https://uzaapp.com/api/check_story_sync.php
```
This will automatically fix all stories with missing `remote_id`.

### Step 3: Test on Multiple Devices

1. **Device A (where stories were created):**
   - Stories should still be visible
   - Create a NEW test story

2. **Device B (where stories weren't appearing):**
   - Force close and reopen the app
   - Go to Arrivages screen
   - Pull down to force sync
   - Stories should now appear!

3. **Verify sync:**
   - Check Flutter debug logs
   - Should see: `API: Fetched X stories` (where X > 0)
   - Stories should appear in the UI

## How It Works Now

### Story Creation Flow:
1. Device A creates story
2. Story uploaded to server via `sync.php` or `stories.php`
3. Server assigns `id=123` and sets `remote_id=123`
4. Server returns: `{"success": true, "id": 123}`
5. Client maps server ID to local story's `remote_id`

### Story Sync Flow:
1. Device B starts sync
2. Calls `stories.php?include_media=1&updated_since=...`
3. Server returns **ALL non-expired stories** (ignoring updated_since)
4. Each story includes `remote_id` field
5. Device B stores stories with `remote_id` for deduplication
6. Future syncs skip stories with matching `remote_id`

### Deduplication Logic:
```dart
// In sync_service.dart line ~577-580
final String rId = story['remote_id'] ?? story['id'];

// Skip if story with this remoteId already exists (dedup)
if (rId.isNotEmpty && existingStoryRemoteIds.contains(rId)) {
    continue;
}
```

## Expected Log Output (After Fix)

**Before Fix:**
```
API: Fetching stories from https://uzaapp.com/api/stories.php?...&updated_since=2026-05-09%2012%3A31%3A39
API: Stories response status: 200
API: Fetched 0 stories  ❌
```

**After Fix:**
```
API: Fetching stories from https://uzaapp.com/api/stories.php?...&updated_since=2026-05-09%2012%3A31%3A39
API: Stories response status: 200
API: Fetched 5 stories  ✅
Story sync: inserting story remote_id=123
Story sync: inserting story remote_id=124
...
```

## Files Modified

### Server Files (Must Deploy):
- ✅ `server/api/stories.php`
- ✅ `server/api/sync.php`
- ✅ `deploy_api_files/stories.php`
- ✅ `deploy_api_files/sync.php`

### New Files Created:
- ✅ `fix_story_remote_ids.sql` - SQL fix script
- ✅ `server/api/check_story_sync.php` - Diagnostic tool

### Client Files (Already Correct):
- `lib/data/services/sync_service.dart` - Sync logic (no changes needed)
- `lib/core/services/api_service.dart` - API calls (no changes needed)

## Verification Checklist

After deployment, verify:

- [ ] All existing stories have `remote_id` set (run SQL query)
- [ ] New story creation sets `remote_id` automatically
- [ ] API returns `remote_id` in story responses
- [ ] Sync fetches ALL active stories (not just recent ones)
- [ ] Stories appear on Device B after sync
- [ ] No duplicate stories after multiple syncs
- [ ] Expired stories are cleaned up properly

## Troubleshooting

### Stories Still Not Appearing?

1. **Check server response:**
   ```
   Visit: https://uzaapp.com/api/stories.php?api_key=YOUR_KEY&include_media=1
   ```
   Verify stories have `remote_id` field.

2. **Check database:**
   ```sql
   SELECT id, remote_id, shop_id, media_url, expires_at 
   FROM stories 
   WHERE expires_at > NOW() 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```
   All `remote_id` values should be set.

3. **Check Flutter logs:**
   - Look for `API: Fetched X stories`
   - Look for any sync errors
   - Check if stories are being inserted to local DB

4. **Force full reset on device:**
   - Clear app data
   - Reinstall app
   - Let it do first sync (should fetch all stories)

### Duplicate Stories Appearing?

This shouldn't happen with the fix, but if it does:
1. Check that `remote_id` is being set correctly
2. Verify deduplication logic in `sync_service.dart`
3. Run the diagnostic endpoint to check remote_id values

## Technical Details

### Why Ignore `updated_since` for Stories?

Unlike products/shops which are permanent, stories have short lifespans (24h-4days):
- A device syncing after 12 hours needs ALL active stories
- Filtering by `created_at > updated_since` would miss stories created before last sync
- The client-side deduplication (via `remote_id`) prevents duplicates
- Server-side cleanup removes expired stories automatically

### Why `remote_id` is Critical?

- Server uses auto-increment `id` (different per server if multi-server setup)
- `remote_id` provides a stable identifier across devices
- Client maps `remote_id` to local database primary key
- Prevents duplicates during pull sync
- Enables proper conflict resolution

---

**Status:** ✅ All fixes applied and ready for deployment
**Date:** 2026-05-09
**Impact:** Story synchronization across all devices
