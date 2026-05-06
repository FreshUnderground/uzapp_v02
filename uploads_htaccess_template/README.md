# CORS Fix for Image Uploads

## Problem
Flutter Web app cannot load images from `https://uzaapp.com/uploads/` due to missing CORS headers.

## Solution

### Step 1: Upload .htaccess to Server
Copy the `.htaccess` file from this directory to your server at:
```
/htdocs/uzaapp.com/uploads/.htaccess
```

### Step 2: Verify Upload
After uploading, test by opening browser DevTools Console while loading your Flutter Web app. The CORS errors should be gone.

### What This Does
- Adds `Access-Control-Allow-Origin: *` header to all files in `/uploads/` directory
- Allows Flutter Web (localhost or any domain) to load images
- Adds caching headers for better performance
- Prevents directory listing for security

### Alternative: If uploads directory doesn't exist on server
If the `/uploads/` directory doesn't exist on your server yet, create it first:
```bash
mkdir -p /htdocs/uzaapp.com/uploads
```
Then upload the `.htaccess` file.

## Testing
1. Deploy the `.htaccess` file to `/uploads/`
2. Clear browser cache (Ctrl+Shift+Delete)
3. Reload your Flutter Web app
4. Check browser console - CORS errors should be resolved
