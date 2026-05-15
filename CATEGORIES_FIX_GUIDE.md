# Fix: Categories Not Displaying in Mobile App

## Problem
Categories are synced to the local database (97 total, 6 root) but not displaying on the home screen.

## Root Cause
Category `level` values in the database are incorrect. The app queries for `level = 0` (root categories), but some categories have wrong level assignments.

## Solution Applied

### 1. Client-Side Auto-Correction (Already Implemented)
The sync services now automatically calculate correct category levels based on parent-child relationships:
- `level = 0`: Categories with `parent_id = NULL` (root categories)
- `level = 1`: Categories whose parent is level 0
- `level = 2`: Categories whose parent is level 1

Files modified:
- `lib/data/services/sync_service.dart` - Added level calculation logic
- `lib/data/services/sync_manager.dart` - Added level calculation logic
- `lib/ui/screens/home_screen.dart` - Added debug logging

### 2. Server-Side Fix (Optional but Recommended)
Run the SQL script to fix the database permanently:
```bash
mysql -u your_username -p your_database_name < fix_category_levels.sql
```

## Steps to Rebuild and Test the APK

### Step 1: Clean the Project
```powershell
flutter clean
```

### Step 2: Get Dependencies
```powershell
flutter pub get
```

### Step 3: Build the APK
```powershell
flutter build apk --release
```

### Step 4: Install on Device
```powershell
# Uninstall old version first
flutter uninstall

# Install new APK
flutter install
```

OR manually install:
```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Step 5: Test the App

1. **Open the app** on your device
2. **Pull down to refresh** on the home screen to trigger sync
3. **Check the logs**:
   ```powershell
   flutter logs
   ```

4. **Look for these log messages**:
   ```
   ensureCategoriesSynced: starting...
   ensureCategoriesSynced: fetched XX from server
   ensureCategoriesSynced: calculated levels for XX categories
     Category: Phones, remote_id=1, calculated_level=0, server_level=0
     Category: Style, remote_id=5, calculated_level=0, server_level=0
     ...
   ensureCategoriesSynced: now XX total categories, 6 root (level=0)
   Categories stream emitted: 6 root categories
   Root categories: 6, connectionState=ConnectionState.active
     Category[0]: id=1, name=Phones, level=0
     Category[1]: id=2, name=Ordi., level=0
     Category[2]: id=3, name=Gadgets, level=0
   ```

5. **Verify categories display** on the home screen (should show 6 category icons)

## Troubleshooting

### If Categories Still Don't Display:

1. **Check if sync is happening**:
   - Look for "ensureCategoriesSynced: starting..." in logs
   - If not found, the sync isn't being triggered

2. **Check API response**:
   ```
   API: Fetching categories from https://your-server.com/api/categories.php?api_key=XXX
   API: Categories response status: 200
   API: Fetched XX categories
   ```

3. **Check database content**:
   - Look for "ensureCategoriesSynced: now XX total categories"
   - Should show at least 6 root (level=0) categories

4. **Force sync manually**:
   - Pull down on home screen
   - Or tap the "Sync Categories" button if visible

5. **Clear app data and retry**:
   ```powershell
   adb shell pm clear com.example.uzaapp
   ```
   Then reinstall the app

### Expected Root Categories:
Based on `seed_categories.php`, these should be your 6 root categories:
1. Phones (level=0)
2. Ordi. (level=0)
3. Gadgets (level=0)
4. Restau. (level=0)
5. Style (level=0)
6. Auto (level=0)

## Verification After Fix

When the fix is working correctly, you should see:
- ✅ 6 category icons on the home screen
- ✅ Tapping a category opens the category products screen
- ✅ Logs show correct level calculations
- ✅ No categories with incorrect level values

## Additional Notes

- The client-side fix ensures categories display correctly even if the server has wrong data
- Running the SQL script (`fix_category_levels.sql`) on the server is still recommended for data consistency
- The level calculation is done during every sync, so categories will auto-correct on next sync
