# ✅ Quick Action Checklist: Fix Missing Images

## 🎯 Objective
Fix "Image non disponible" errors in arrivages and stories

---

## 📋 Pre-Flight Checklist

- [ ] I have access to my server (FTP/SFTP credentials)
- [ ] I have access to phpMyAdmin or MySQL
- [ ] I can access https://uzaapp.com
- [ ] I have backed up my database (IMPORTANT!)

---

## 🚀 Step-by-Step Process

### STEP 1: Deploy Diagnostic Scripts ⏱️ 5 min

**Option A: Using PowerShell Script (Automated)**
- [ ] Open `deploy_diagnostic_tools.ps1` in a text editor
- [ ] Update FTP credentials (lines 11-13):
  ```powershell
  $ftpUser = "YOUR_FTP_USERNAME"
  $ftpPass = "YOUR_FTP_PASSWORD"  
  $ftpPath = "/YOUR_API_PATH/"
  ```
- [ ] Save the file
- [ ] Right-click → "Run with PowerShell"
- [ ] Wait for "All files deployed successfully!" message

**Option B: Manual FTP Upload**
- [ ] Open FileZilla/WinSCP
- [ ] Connect to uzaapp.com
- [ ] Navigate to `/api/` directory
- [ ] Upload these files:
  - [ ] `server/api/check_image_urls.php`
  - [ ] `server/api/find_broken_story_images.php`
- [ ] Set permissions to 644

---

### STEP 2: Verify Deployment ⏱️ 2 min

- [ ] Open in browser: `https://uzaapp.com/api/check_image_urls.php`
- [ ] You should see a colorful diagnostic page (not 404 error)
- [ ] If you see an error, check:
  - File uploaded to correct directory?
  - File permissions are 644?
  - PHP is enabled on server?

---

### STEP 3: Run Diagnostic ⏱️ 3 min

- [ ] Open: `https://uzaapp.com/api/check_image_urls.php`
- [ ] Note these numbers:
  - Total Records: ______
  - Firebase URLs: ______ (this should be > 0)
  - Server URLs: ______
- [ ] Take a screenshot for reference
- [ ] Scroll down to see which records have Firebase URLs

**Expected Result:**
- If Firebase URLs > 0: ✅ This confirms the problem
- If Firebase URLs = 0: ❌ Different issue (contact support)

---

### STEP 4: Backup Database ⏱️ 5 min

**⚠️ CRITICAL: Do not skip this step!**

**Via phpMyAdmin:**
- [ ] Login to phpMyAdmin
- [ ] Select your database
- [ ] Click "Export" tab
- [ ] Choose "Quick" export method
- [ ] Format: SQL
- [ ] Click "Go"
- [ ] Save the .sql file to a safe location

**Via Command Line:**
```bash
mysqldump -u username -p database_name > backup_$(date +%Y%m%d_%H%M%S).sql
```

- [ ] Verify backup file exists and has content (> 0 KB)

---

### STEP 5: Run SQL Migration ⏱️ 5 min

**Via phpMyAdmin:**
- [ ] Login to phpMyAdmin
- [ ] Select your database
- [ ] Click "SQL" tab
- [ ] Open file: `c:\Users\DIEU-MERCI\Music\uzaapp\fix_firebase_urls.sql`
- [ ] Copy ALL content (Ctrl+A, Ctrl+C)
- [ ] Paste into SQL textarea (Ctrl+V)
- [ ] Click "Go" or "Execute"
- [ ] Wait for success message
- [ ] Scroll down to see verification results

**Via Command Line:**
```bash
mysql -u username -p database_name < fix_firebase_urls.sql
```

**Check Results:**
- [ ] Look for these messages at the bottom:
  - `shops_with_firebase_urls` should be 0
  - `products_with_firebase_urls` should be 0
  - `stories_with_firebase_urls` should be 0

---

### STEP 6: Verify Migration ⏱️ 3 min

- [ ] Refresh: `https://uzaapp.com/api/check_image_urls.php`
- [ ] Verify:
  - Firebase URLs: **0** ✅
  - Server URLs: [same as Total Records] ✅
  - Green success message visible ✅
- [ ] Take a screenshot for comparison

**If Firebase URLs > 0:**
- [ ] Check for SQL errors in Step 5
- [ ] Try running SQL again
- [ ] Check if uploaded files exist on server

---

### STEP 7: Verify Files on Server ⏱️ 5 min

**Via SSH/FTP:**
- [ ] Connect to server
- [ ] Navigate to: `/uploads/migrated/`
- [ ] List files: `ls -la`
- [ ] You should see many image files
- [ ] Check permissions (should be 644 for files, 755 for folders)

**Test a URL directly:**
- [ ] Pick a filename from the directory
- [ ] Open in browser: `https://uzaapp.com/uploads/migrated/[filename].jpg`
- [ ] Image should display ✅
- [ ] If you get 404: Files are missing, need to run migrate_images.php

**If files are missing:**
- [ ] Upload `server/api/migrate_images.php` to your server
- [ ] Run: `https://uzaapp.com/api/migrate_images.php`
- [ ] Wait for migration to complete
- [ ] Check `/uploads/migrated/` again

---

### STEP 8: Clear App Cache ⏱️ 2 min

**Android:**
- [ ] Open Settings
- [ ] Go to Apps/Applications
- [ ] Find "UZA App"
- [ ] Tap "Storage"
- [ ] Tap "Clear Cache"
- [ ] Force Stop the app
- [ ] Reopen the app

**Web:**
- [ ] Press `Ctrl + Shift + Delete`
- [ ] Select "Cached images and files"
- [ ] Click "Clear data"
- [ ] OR press `Ctrl + F5` to force refresh

**iOS:**
- [ ] Delete the app
- [ ] Reinstall from TestFlight/App Store

---

### STEP 9: Test in App ⏱️ 5 min

**Open the app and test:**

- [ ] Navigate to Arrivages screen
  - [ ] All arrivages show thumbnail images ✅
  - [ ] No "Image non disponible" messages ✅
  
- [ ] Navigate to Stories section
  - [ ] All story circles show images ✅
  - [ ] No broken image icons ✅
  
- [ ] Navigate to Discover feed
  - [ ] All media (images/videos) loads ✅
  - [ ] Swipe through several pages ✅

**Check app logs (if in debug mode):**
- [ ] No "⚠️ FIREBASE STORAGE QUOTA EXCEEDED" messages ✅
- [ ] No "Image load failed" with error 402 ✅

---

### STEP 10: Final Verification ⏱️ 2 min

- [ ] Run diagnostic one more time:
  - `https://uzaapp.com/api/check_image_urls.php`
- [ ] Confirm Firebase URLs still = 0
- [ ] Run story checker:
  - `https://uzaapp.com/api/find_broken_story_images.php`
- [ ] Confirm no Firebase URLs in stories
- [ ] Confirm HTTP status = 200 for tested URLs

---

## ✅ Success Criteria

You have successfully fixed the issue when:

- [x] Diagnostic shows 0 Firebase URLs
- [x] All arrivages display images correctly
- [x] All stories display images correctly  
- [x] Discover feed shows all media
- [x] No "Image non disponible" errors
- [x] No 402 errors in app logs
- [x] Direct URL test works: `https://uzaapp.com/uploads/migrated/[file].jpg`

---

## 🆘 Troubleshooting

### Problem: "404 Not Found" on diagnostic scripts
**Solution:**
- [ ] Check files uploaded to correct directory
- [ ] Verify file permissions (644)
- [ ] Check server allows .php execution

### Problem: Database connection error
**Solution:**
- [ ] Verify `config.php` has correct credentials
- [ ] Test database connection separately
- [ ] Check if database server is running

### Problem: SQL script fails with syntax error
**Solution:**
- [ ] Check MySQL version (REGEXP_REPLACE needs MySQL 8.0+)
- [ ] Use alternative SUBSTRING_INDEX method
- [ ] See TROUBLESHOOTING_IMAGES.md for details

### Problem: Images still not showing after migration
**Solution:**
- [ ] Verify files exist in `/uploads/migrated/`
- [ ] Check file permissions
- [ ] Clear app cache again
- [ ] Force stop and restart app
- [ ] Check `.htaccess` in uploads folder

### Problem: Some images work, others don't
**Solution:**
- [ ] Run diagnostic to see which URLs still use Firebase
- [ ] Re-run SQL migration
- [ ] Check if specific files are missing from server

---

## 📊 Time Estimate

| Step | Estimated Time |
|------|---------------|
| Deploy scripts | 5 min |
| Verify deployment | 2 min |
| Run diagnostic | 3 min |
| Backup database | 5 min |
| Run SQL migration | 5 min |
| Verify migration | 3 min |
| Check server files | 5 min |
| Clear app cache | 2 min |
| Test in app | 5 min |
| Final verification | 2 min |
| **TOTAL** | **~37 min** |

---

## 📞 Support Resources

If you get stuck:

1. **Check detailed guides:**
   - `TROUBLESHOOTING_IMAGES.md` - Complete troubleshooting
   - `RESUME_PROBLEME_IMAGES.md` - French summary
   - `DEPLOY_DIAGNOSTIC_TOOLS.md` - Deployment guide

2. **Collect diagnostic info:**
   - Screenshot of `check_image_urls.php`
   - Screenshot of any error messages
   - App logs showing image errors
   - Results from `find_broken_story_images.php`

3. **Run these SQL queries:**
   ```sql
   SELECT COUNT(*) FROM stories WHERE media_url LIKE '%firebasestorage%';
   SELECT COUNT(*) FROM story_media WHERE media_url LIKE '%firebasestorage%';
   SELECT COUNT(*) FROM products WHERE image_urls LIKE '%firebasestorage%';
   SELECT COUNT(*) FROM shops WHERE logo_url LIKE '%firebasestorage%';
   ```
   All should return 0 after successful migration.

---

## 🎉 After Success

**Maintenance tasks to prevent future issues:**

- [ ] Monitor Firebase Storage usage monthly
- [ ] Run `check_image_urls.php` monthly to verify no new Firebase URLs
- [ ] Configure app to upload new images to server (not Firebase)
- [ ] Set up regular database backups
- [ ] Set up regular image file backups

**Monthly Checklist:**
- [ ] Run diagnostic script
- [ ] Verify Firebase URLs = 0
- [ ] Check Firebase Console for quota usage
- [ ] Test a few random images in app
- [ ] Verify backup completed successfully

---

**Status:** Ready to Execute ✅  
**Priority:** High  
**Estimated Completion:** 30-40 minutes  
**Difficulty:** Easy (follow steps carefully)

---

**Start Date:** ____________  
**Completion Date:** ____________  
**Notes:** _________________________________________
