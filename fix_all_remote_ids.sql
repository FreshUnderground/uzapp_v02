-- Fix NULL remote_id values in shops table
UPDATE shops 
SET remote_id = CAST(id AS CHAR) 
WHERE remote_id IS NULL;

-- Fix NULL remote_id values in categories table  
UPDATE categories 
SET remote_id = CAST(id AS CHAR) 
WHERE remote_id IS NULL;

-- Fix NULL remote_id values in stories table
UPDATE stories 
SET remote_id = CAST(id AS CHAR) 
WHERE remote_id IS NULL;

-- Verify all tables
SELECT 'products' as table_name, COUNT(*) as count_with_null_remote_id 
FROM products WHERE remote_id IS NULL
UNION ALL
SELECT 'shops', COUNT(*) FROM shops WHERE remote_id IS NULL
UNION ALL
SELECT 'categories', COUNT(*) FROM categories WHERE remote_id IS NULL
UNION ALL
SELECT 'stories', COUNT(*) FROM stories WHERE remote_id IS NULL;
