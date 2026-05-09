-- Fix missing remote_id for all existing stories
-- This script ensures all stories have a remote_id for proper synchronization

-- Update stories where remote_id is NULL or empty
UPDATE stories 
SET remote_id = id 
WHERE remote_id IS NULL OR remote_id = '';

-- Verify the fix
SELECT 
    COUNT(*) as total_stories,
    SUM(CASE WHEN remote_id IS NULL OR remote_id = '' THEN 1 ELSE 0 END) as still_missing,
    SUM(CASE WHEN remote_id IS NOT NULL AND remote_id != '' THEN 1 ELSE 0 END) as has_remote_id
FROM stories;

-- Show sample of fixed stories
SELECT 
    id,
    remote_id,
    shop_id,
    SUBSTRING(media_url, 1, 50) as media_url_preview,
    created_at
FROM stories 
ORDER BY created_at DESC 
LIMIT 10;
