# Deployment Guide: Image Diagnostic Tools

## 📦 Files to Deploy to Server

Upload these files to your server's `api/` directory:

### 1. Diagnostic Scripts
- ✅ `check_image_urls.php` - Visual diagnostic interface
- ✅ `find_broken_story_images.php` - Story/arrivage URL checker

### 2. Migration Script (if not already deployed)
- 📄 `migrate_images.php` - PHP migration alternative

### 3. SQL Script (run via phpMyAdmin)
- 📄 `fix_firebase_urls.sql` - Database migration script

---

## 🚀 Quick Deployment Steps

### Step 1: Upload PHP Scripts via FTP/SFTP

**Connect to your server:**
```bash
# Using FTP
ftp uzaapp.com
# Username: [your FTP username]
# Password: [your FTP password]

# OR using SFTP (recommended)
sftp user@uzaapp.com
```

**Upload the files:**
```bash
# Navigate to your API directory
cd /path/to/your/website/api/

# Upload diagnostic scripts
put c:/Users/DIEU-MERCI/Music/uzaapp/server/api/check_image_urls.php
put c:/Users/DIEU-MERCI/Music/uzaapp/server/api/find_broken_story_images.php

# Set correct permissions
chmod 644 check_image_urls.php
chmod 644 find_broken_story_images.php
```

**Alternative: Using PowerShell with PSCP:**
```powershell
# Download PSCP from PuTTY if you don't have it
# Then upload:
pscp -pw "your_password" `
  "c:\Users\DIEU-MERCI\Music\uzaapp\server\api\check_image_urls.php" `
  user@uzaapp.com:/path/to/api/

pscp -pw "your_password" `
  "c:\Users\DIEU-MERCI\Music\uzaapp\server\api\find_broken_story_images.php" `
  user@uzaapp.com:/path/to/api/
```

---

### Step 2: Verify Files are Accessible

Test in your browser:
```
https://uzaapp.com/api/check_image_urls.php
https://uzaapp.com/api/find_broken_story_images.php
```

You should see the diagnostic interface (not a 404 error).

---

### Step 3: Run the Diagnostic

**Open in browser:**
```
https://uzaapp.com/api/check_image_urls.php
```

**What to look for:**
- 📊 Total records count
- 🔴 Number of Firebase URLs (should be > 0 if you have the problem)
- 🟢 Number of Server URLs
- ⚠️ Warning message if Firebase URLs exist
- 📋 List of specific records with Firebase URLs

---

### Step 4: Run SQL Migration

**Option A: Via phpMyAdmin (Recommended)**

1. **Login to phpMyAdmin:**
   ```
   https://uzaapp.com/phpmyadmin
   # or your hosting control panel
   ```

2. **Select your database** (uzaapp or similar)

3. **Click "SQL" tab**

4. **Open the SQL file:**
   - Open `c:\Users\DIEU-MERCI\Music\uzaapp\fix_firebase_urls.sql` in a text editor
   - Copy ALL the content

5. **Paste and Execute:**
   - Paste into the SQL textarea
   - Click "Go" or "Execute"

6. **Verify Results:**
   - The script includes verification queries at the end
   - Check that Firebase URL counts are now 0

**Option B: Via Command Line**

```bash
# Connect to your server via SSH
ssh user@uzaapp.com

# Navigate to the directory where you uploaded the SQL file
cd /path/to/sql/files/

# Import the SQL file
mysql -u [username] -p[password] [database_name] < fix_firebase_urls.sql
```

---

### Step 5: Verify Migration Success

**Run diagnostic again:**
```
https://uzaapp.com/api/check_image_urls.php
```

**Expected result:**
- ✅ Firebase URLs: 0
- ✅ Server URLs: [all your records]
- ✅ Green success message

**Run story checker:**
```
https://uzaapp.com/api/find_broken_story_images.php
```

**Expected result:**
- ✅ No Firebase URLs found
- ✅ HTTP status 200 for tested URLs

---

### Step 6: Clear App Cache

**Android:**
```
Settings → Apps → UZA App → Storage → Clear Cache
Force Stop the app
Reopen the app
```

**Web:**
```
Press Ctrl + Shift + Delete
Select "Cached images and files"
Click "Clear data"
OR simply press Ctrl + F5
```

**iOS:**
```
Delete the app
Reinstall from TestFlight/App Store
```

---

### Step 7: Test in App

1. **Open the app**
2. **Navigate to:**
   - ✅ Arrivages screen
   - ✅ Stories section
   - ✅ Discover feed
   
3. **Verify:**
   - All images load correctly
   - No "Image non disponible" messages
   - No broken image icons

---

## 🔍 Troubleshooting Deployment

### Problem: 404 Error when accessing diagnostic scripts

**Solution:**
```bash
# Check if files were uploaded correctly
ls -la /path/to/api/check_image_urls.php
ls -la /path/to/api/find_broken_story_images.php

# Verify file permissions
chmod 644 /path/to/api/*.php

# Check Apache/Nginx configuration allows .php files
```

### Problem: Database connection error in scripts

**Solution:**
1. Check `config.php` has correct database credentials:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'your_database');
   define('DB_USER', 'your_username');
   define('DB_PASS', 'your_password');
   ```

2. Test database connection:
   ```php
   <?php
   require_once 'config.php';
   try {
       $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
       echo "✅ Database connection successful!";
   } catch (PDOException $e) {
       echo "❌ Connection failed: " . $e->getMessage();
   }
   ?>
   ```

### Problem: SQL script fails with REGEXP_REPLACE error

**Solution:**
Your MySQL version is < 8.0. Use the alternative provided in the SQL file:

Replace:
```sql
SET image_urls = REGEXP_REPLACE(image_urls, '\\?alt=media&token=[^,&]+', '')
```

With:
```sql
SET image_urls = SUBSTRING_INDEX(image_urls, '?', 1)
```

### Problem: Images still not showing after migration

**Checklist:**
- [ ] Verify files exist: `ls -la /uploads/migrated/`
- [ ] Check file permissions: `chmod 644 /uploads/migrated/*`
- [ ] Test direct URL: `https://uzaapp.com/uploads/migrated/[filename].jpg`
- [ ] Clear app cache completely
- [ ] Force stop and restart app
- [ ] Check `.htaccess` in uploads folder allows access

---

## 📊 Expected Timeline

| Step | Time | Status |
|------|------|--------|
| Upload PHP scripts | 2 min | ⬜ |
| Verify access | 1 min | ⬜ |
| Run diagnostic | 2 min | ⬜ |
| Execute SQL migration | 3 min | ⬜ |
| Verify migration | 2 min | ⬜ |
| Clear app cache | 1 min | ⬜ |
| Test in app | 5 min | ⬜ |
| **Total** | **~16 min** | |

---

## ✅ Success Criteria

After completing all steps, you should have:

1. ✅ **Diagnostic shows 0 Firebase URLs**
   ```
   https://uzaapp.com/api/check_image_urls.php
   → Firebase URLs: 0
   ```

2. ✅ **All images load in the app**
   - Arrivages: All thumbnails visible
   - Stories: All circles show images
   - Discover feed: All media loads

3. ✅ **No errors in app logs**
   ```
   No "⚠️ FIREBASE STORAGE QUOTA EXCEEDED"
   No "Image load failed" with 402 errors
   ```

4. ✅ **Direct URL test works**
   ```
   https://uzaapp.com/uploads/migrated/[any-image].jpg
   → Image displays in browser
   ```

---

## 🆘 Need Help?

If you encounter issues:

1. **Collect diagnostics:**
   - Screenshot of `check_image_urls.php`
   - Screenshot of any error messages
   - App logs showing image errors

2. **Check server logs:**
   ```bash
   # Apache
   tail -f /var/log/apache2/error.log
   
   # Nginx
   tail -f /var/log/nginx/error.log
   ```

3. **Verify database state:**
   ```sql
   SELECT COUNT(*) FROM stories WHERE media_url LIKE '%firebasestorage%';
   SELECT COUNT(*) FROM story_media WHERE media_url LIKE '%firebasestorage%';
   SELECT COUNT(*) FROM products WHERE image_urls LIKE '%firebasestorage%';
   ```

All counts should be **0** after successful migration.

---

**Last Updated:** May 2026  
**Status:** Ready to Deploy ✅
