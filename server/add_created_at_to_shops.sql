-- Add created_at column to shops table
-- This is needed for proper tracking of when shops were created
-- Run this ONCE on your MySQL database

-- Add created_at column if it doesn't exist
ALTER TABLE shops 
ADD COLUMN created_at DATETIME NULL DEFAULT NULL;

-- Set created_at to updated_at for existing shops (approximation)
UPDATE shops 
SET created_at = updated_at 
WHERE created_at IS NULL;

-- Verify the column was added
DESCRIBE shops;

-- Check the results
SELECT id, name, created_at, updated_at 
FROM shops 
ORDER BY updated_at DESC 
LIMIT 10;
