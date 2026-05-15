# 🔧 Fix Firebase Storage 402 Error - Guide

## Problem
Your app shows HTTP 402 errors when loading images from Firebase Storage because:
- Firebase free tier quota is exceeded
- Images have already been migrated to your server (uzaapp.com)
- But the database still contains old Firebase URLs

## Solution

### Option 1: PHP Script (RECOMMENDED - Easiest)

1. **Deploy the fix script to your server:**
   - Upload `server/api/fix_firebase_urls.php` to your server
   - Location: `/path/to/your/server/api/fix_firebase_urls.php`

2. **Run the script:**
   ```
   https://uzaapp.com/api/fix_firebase_urls.php
   ```

3. **Check the output:**
   You'll see a JSON response like:
   ```json
   {
     "success": true,
     "results": {
       "shops_logo": {"fixed": 15, "total": 15},
       "shops_banner": {"fixed": 8, "total": 8},
       "products": {"fixed": 120, "total": 120},
       "stories": {"fixed": 45, "total": 45},
       "story_media": {"fixed": 20, "total": 20}
     },
     "verification": {
       "remaining_shops": 0,
       "remaining_products": 0,
       "remaining_stories": 0
     }
   }
   ```

4. **Clear app cache and sync:**
   - Users need to pull down to refresh or restart the app
   - The sync will fetch the new URLs from the server

---

### Option 2: SQL Script (Alternative)

1. **Backup your database first!**
   ```bash
   mysqldump -u your_user -p your_database > backup_before_fix.sql
   ```

2. **Run the SQL script:**
   ```bash
   mysql -u your_user -p your_database < fix_firebase_urls.sql
   ```
   
   Or via phpMyAdmin:
   - Open phpMyAdmin
   - Select your database
   - Go to SQL tab
   - Paste the content of `fix_firebase_urls.sql`
   - Click "Go"

3. **Verify the changes:**
   The script includes verification queries at the end.

---

## Important Notes

### ⚠️ Before Running:
1. **Backup your database** (always!)
2. **Verify migrated images exist** at: `https://uzaapp.com/uploads/migrated/`
3. **Test with one image first** to make sure the URL pattern is correct

### 🔍 If URLs Don't Match:
The scripts assume this Firebase URL pattern:
```
https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/FILENAME.jpg?alt=media&token=xxx
```

Converts to:
```
https://uzaapp.com/uploads/migrated/FILENAME.jpg
```

**If your migrated images have different filenames**, you may need to adjust the scripts.

### 📱 After Fixing Database:
1. Users need to **sync their app** to get new URLs
2. Old cached Firebase URLs will still show 402 errors until cache clears
3. The app has retry logic that will eventually show error widgets for cached Firebase URLs
4. **Clear app cache** if needed: Settings → Apps → UzaApp → Clear Cache

---

## Verification

After running the fix, check these in your app:

✅ Shop logos should load  
✅ Product images should load  
✅ Story images should load  
✅ No more 402 errors in logs  

Check your app logs for:
```
❌ BEFORE: HttpException: Invalid statusCode: 402, uri = https://firebasestorage.googleapis.com/...
✅ AFTER: Images load successfully from https://uzaapp.com/uploads/migrated/...
```

---

## Troubleshooting

### Images still show 402 error?
1. Check if images actually exist: `https://uzaapp.com/uploads/migrated/FILENAME.jpg`
2. If 404: The migration didn't complete - run `migrate_images.php` first
3. If still 402: Check file permissions on the uploads folder

### Database update failed?
1. Check MySQL error logs
2. Verify you have write permissions
3. Try running the SQL script manually in phpMyAdmin

### Some images still have Firebase URLs?
1. Run the verification queries from the SQL script
2. Check if there are other tables with image URLs
3. Run the PHP script again - it will only update remaining Firebase URLs

---

## Files Created

1. `fix_firebase_urls.sql` - SQL script for manual database update
2. `server/api/fix_firebase_urls.php` - PHP script for easy server execution
3. `FIX_FIREBASE_URLS_GUIDE.md` - This guide

---

## Need Help?

If you encounter issues:
1. Check the PHP script output for errors
2. Look at MySQL error logs
3. Verify image files exist in `/uploads/migrated/` folder
4. Test a single URL in browser: `https://uzaapp.com/uploads/migrated/test.jpg`
