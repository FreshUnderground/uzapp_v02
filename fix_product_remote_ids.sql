-- Fix NULL remote_id values in products table
-- This ensures sync service can match local products with server

UPDATE products 
SET remote_id = CAST(id AS CHAR) 
WHERE remote_id IS NULL;

-- Verify the update
SELECT id, remote_id, name, shop_id 
FROM products 
ORDER BY id 
LIMIT 20;
