-- ============================================================================
-- Fix Firebase Storage 402 Error - Replace Firebase URLs with Server URLs
-- ============================================================================
-- This script updates all image URLs in the database from Firebase Storage
-- to your local server (uzaapp.com)
-- ============================================================================

-- 1. Update shops.logo_url - Replace Firebase URLs with local server URLs
UPDATE shops 
SET logo_url = CONCAT('https://uzaapp.com/uploads/migrated/', 
                      SUBSTRING_INDEX(SUBSTRING_INDEX(logo_url, '/', -1), '?', 1))
WHERE logo_url LIKE '%firebasestorage.googleapis.com%'
  AND logo_url IS NOT NULL 
  AND logo_url != '';

-- 2. Update shops.banner_url - Replace Firebase URLs
UPDATE shops 
SET banner_url = CONCAT('https://uzaapp.com/uploads/migrated/', 
                        SUBSTRING_INDEX(SUBSTRING_INDEX(banner_url, '/', -1), '?', 1))
WHERE banner_url LIKE '%firebasestorage.googleapis.com%'
  AND banner_url IS NOT NULL 
  AND banner_url != '';

-- 3. Update shops.video_url - Replace Firebase URLs  
UPDATE shops 
SET video_url = CONCAT('https://uzaapp.com/uploads/migrated/', 
                       SUBSTRING_INDEX(SUBSTRING_INDEX(video_url, '/', -1), '?', 1))
WHERE video_url LIKE '%firebasestorage.googleapis.com%'
  AND video_url IS NOT NULL 
  AND video_url != '';

-- 4. Update products.image_urls - Replace Firebase URLs (may contain multiple URLs)
-- For comma-separated URLs, we need to replace each one
UPDATE products 
SET image_urls = REPLACE(image_urls, 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/', 
                         'https://uzaapp.com/uploads/migrated/')
WHERE image_urls LIKE '%firebasestorage.googleapis.com%'
  AND image_urls IS NOT NULL 
  AND image_urls != '';

-- Remove the token parameter from product image URLs
UPDATE products 
SET image_urls = REGEXP_REPLACE(image_urls, '\\?alt=media&token=[^,&]+', '')
WHERE image_urls LIKE '%?alt=media&token=%';

-- 5. Update stories.media_url - Replace Firebase URLs
UPDATE stories 
SET media_url = CONCAT('https://uzaapp.com/uploads/migrated/', 
                       SUBSTRING_INDEX(SUBSTRING_INDEX(media_url, '/', -1), '?', 1))
WHERE media_url LIKE '%firebasestorage.googleapis.com%'
  AND media_url IS NOT NULL 
  AND media_url != '';

-- 6. Update story_media.media_url - Replace Firebase URLs
UPDATE story_media 
SET media_url = CONCAT('https://uzaapp.com/uploads/migrated/', 
                       SUBSTRING_INDEX(SUBSTRING_INDEX(media_url, '/', -1), '?', 1))
WHERE media_url LIKE '%firebasestorage.googleapis.com%'
  AND media_url IS NOT NULL 
  AND media_url != '';

-- ============================================================================
-- Verify the changes
-- ============================================================================

-- Check how many shops still have Firebase URLs
SELECT COUNT(*) as shops_with_firebase_urls 
FROM shops 
WHERE logo_url LIKE '%firebasestorage.googleapis.com%'
   OR banner_url LIKE '%firebasestorage.googleapis.com%';

-- Check how many products still have Firebase URLs
SELECT COUNT(*) as products_with_firebase_urls 
FROM products 
WHERE image_urls LIKE '%firebasestorage.googleapis.com%';

-- Check how many stories still have Firebase URLs  
SELECT COUNT(*) as stories_with_firebase_urls 
FROM stories 
WHERE media_url LIKE '%firebasestorage.googleapis.com%';

-- Show sample of updated shop URLs
SELECT id, name, logo_url 
FROM shops 
WHERE logo_url LIKE '%uzaapp.com%' 
LIMIT 5;

-- Show sample of updated product URLs
SELECT id, name, SUBSTRING(image_urls, 1, 100) as image_urls_preview 
FROM products 
WHERE image_urls LIKE '%uzaapp.com%' 
LIMIT 5;

-- ============================================================================
-- IMPORTANT NOTES:
-- ============================================================================
-- 1. BACKUP your database before running this script!
-- 2. Make sure the migrated images actually exist at:
--    https://uzaapp.com/uploads/migrated/
-- 3. If images have different filenames, you may need to adjust the SQL
-- 4. REGEXP_REPLACE requires MySQL 8.0+ or MariaDB 10.0.5+
--    If you get an error, run this alternative for products:
--    
--    UPDATE products 
--    SET image_urls = SUBSTRING_INDEX(image_urls, '?', 1)
--    WHERE image_urls LIKE '%?alt=media&token=%';
-- ============================================================================
