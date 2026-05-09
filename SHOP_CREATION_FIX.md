# Shop Creation Issue: User Created but Shop Not Going Online

## 🔍 Problem Description

When creating a shop through the app:
- ✅ User is created in the `users` table
- ✅ Shop is created in local SQLite database
- ❌ Shop is NOT created in the remote `shops` table (MySQL)

## 📊 How Shop Creation Works

The shop creation process follows these steps:

```
1. User Registration (users table) ✅
   ↓
2. Local Shop Creation (SQLite) ✅
   ↓
3. Queue Shop for Sync (sync_queue table) ✅
   ↓
4. Push to Remote Server (sync.php or shops.php) ❌ FAILING HERE
   ↓
5. Shop appears online in shops table
```

## 🐛 Common Causes

### 1. **Missing or Incorrect `type` Field**
The server requires a `type` field (either 'retail' or 'wholesale').

**Check:** Line 635 in `create_shop_screen.dart`
```dart
'type': _selectedType.name,  // This must be sent
```

### 2. **Sync Queue Not Processing**
The shop is queued but never pushed to the server.

**Debug:** Check app logs for:
```
PUSH: Starting push of X items
PUSH ✓ shops/CREATE id=XXX removed from queue
```

### 3. **Server-Side Validation Error**
The PHP API is rejecting the shop data.

**Common validation errors:**
- Missing required fields (name, type, owner_id)
- Invalid column names in the payload
- Database constraint violations

### 4. **Authentication/API Key Issue**
The sync request is not authenticated properly.

**Check:** API key in requests
```dart
api.pushChange('shops', 'CREATE', shopData)
```

## 🛠️ Solutions

### Solution 1: Run Diagnostic Script

Access this URL in your browser:
```
https://uzaapp.com/api/test_shop_creation_diagnostic.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
```

This will show:
- ✅ Database connection status
- ✅ Table structures (shops, users)
- ✅ Recent users and shops
- ✅ Test shop creation
- ✅ Common issues

### Solution 2: Check App Logs

When creating a shop, look for these log messages:

```
SHOP SYNC QUEUED: Shop ID=XXX, Owner ID=XXX
SHOP SYNC DATA: {"id":XXX,"name":"...","type":"retail",...}
PUSH: Starting push of X items
PUSH [1/X] shops/CREATE id=XXX
PUSH DATA (full): {...}
```

**If you see errors:**
- `PUSH ✗ FAILED RESPONSE` - Server rejected the data
- `PUSH ⏱ TIMEOUT` - Server didn't respond in time
- `PUSH ✗ ERROR` - Network or other error

### Solution 3: Manual Shop Creation via API

If the sync is failing, you can manually create the shop:

1. Get the user ID from the `users` table
2. Use this SQL:
```sql
INSERT INTO shops (
    name, description, type, owner_id, phone, 
    address, city, commune, is_verified, created_at, updated_at
) VALUES (
    'Your Shop Name',
    'Shop Description',
    'retail',
    USER_ID_HERE,
    'PHONE_NUMBER',
    'City, Commune',
    'City',
    'Commune',
    1,
    NOW(),
    NOW()
);
```

### Solution 4: Force Sync from App

1. Open the app
2. Go to Settings or Debug screen
3. Look for "Force Push All" or "Manual Sync" button
4. Click it to retry all pending sync operations

### Solution 5: Check Server Error Logs

On your server, check PHP error logs:
```bash
# Common locations:
/var/log/php-fpm/error.log
/var/log/apache2/error.log
/var/log/nginx/error.log
```

Look for errors related to:
- `shops.php`
- `sync.php`
- PDO errors
- Validation errors

## 📋 Verification Steps

After applying fixes, verify:

1. **Check remote shops table:**
```sql
SELECT id, name, owner_id, phone, created_at 
FROM shops 
ORDER BY created_at DESC 
LIMIT 10;
```

2. **Verify shop-owner relationship:**
```sql
SELECT s.id, s.name, s.owner_id, u.phone, u.name as owner_name
FROM shops s
JOIN users u ON s.owner_id = u.id
ORDER BY s.created_at DESC;
```

3. **Check for orphaned shops:**
```sql
SELECT s.id, s.name, s.owner_id
FROM shops s
LEFT JOIN users u ON s.owner_id = u.id
WHERE u.id IS NULL;
```

## 🔧 Code Changes Made

### 1. Enhanced Debug Logging
**File:** `lib/ui/screens/create_shop_screen.dart`

Added detailed logging when shop is queued for sync:
```dart
debugPrint('SHOP SYNC QUEUED: Shop ID=$shopId, Owner ID=$userId');
debugPrint('SHOP SYNC DATA: ${jsonEncode({...})}');
```

### 2. Added Location Fields
**File:** `lib/ui/screens/create_shop_screen.dart`

Now includes latitude and longitude in sync payload:
```dart
'latitude': _latitude,
'longitude': _longitude,
```

### 3. Diagnostic Script
**File:** `server/api/test_shop_creation_diagnostic.php`

Comprehensive diagnostic tool to test:
- Database structure
- Shop creation flow
- Common issues

## 🎯 Quick Fix Checklist

- [ ] Run diagnostic script and check results
- [ ] Check app logs when creating shop
- [ ] Verify `type` field is being sent ('retail' or 'wholesale')
- [ ] Check server PHP error logs
- [ ] Verify API key is correct
- [ ] Test with manual SQL insert
- [ ] Force sync from app
- [ ] Check network connectivity

## 📞 Next Steps

If the issue persists after trying all solutions:

1. **Share diagnostic results** from the test script
2. **Share app logs** from shop creation attempt
3. **Share server error logs** from the same time period
4. **Check database** for recent users without shops:
```sql
SELECT u.id, u.phone, u.name, u.created_at,
       s.id as shop_id, s.name as shop_name
FROM users u
LEFT JOIN shops s ON u.id = s.owner_id
WHERE s.id IS NULL
ORDER BY u.created_at DESC
LIMIT 20;
```

## 🔗 Related Files

- `lib/ui/screens/create_shop_screen.dart` - Shop creation UI
- `lib/data/services/sync_service.dart` - Sync queue management
- `lib/core/services/api_service.dart` - API communication
- `server/api/sync.php` - Server sync endpoint
- `server/api/shops.php` - Server shops endpoint
- `server/api/test_shop_creation_diagnostic.php` - Diagnostic tool
