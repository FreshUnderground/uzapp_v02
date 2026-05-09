-- Shop Creation Diagnostic and Fix SQL
-- Run this on your MySQL database to identify and fix shops not being created

-- ========================================
-- DIAGNOSTIC QUERIES
-- ========================================

-- 1. Find users who don't have a shop
-- These are users created through the app but their shops weren't synced
SELECT 
    u.id AS user_id,
    u.phone,
    u.name AS user_name,
    u.created_at AS user_created,
    'NO SHOP' AS status
FROM users u
LEFT JOIN shops s ON u.id = s.owner_id
WHERE s.id IS NULL
ORDER BY u.created_at DESC;

-- 2. Find all shops with their owners
SELECT 
    s.id AS shop_id,
    s.name AS shop_name,
    s.type,
    s.owner_id,
    u.phone AS owner_phone,
    u.name AS owner_name,
    s.created_at AS shop_created,
    CASE 
        WHEN u.id IS NULL THEN 'ORPHANED (no owner)'
        ELSE 'LINKED'
    END AS relationship_status
FROM shops s
LEFT JOIN users u ON s.owner_id = u.id
ORDER BY s.created_at DESC;

-- 3. Check for shops with missing required fields
SELECT 
    s.id,
    s.name,
    s.owner_id,
    s.type,
    s.phone,
    CASE WHEN s.name IS NULL OR s.name = '' THEN 'MISSING' ELSE 'OK' END AS name_check,
    CASE WHEN s.owner_id IS NULL THEN 'MISSING' ELSE 'OK' END AS owner_check,
    CASE WHEN s.type IS NULL OR s.type = '' THEN 'MISSING' ELSE 'OK' END AS type_check
FROM shops s
WHERE s.name IS NULL 
   OR s.owner_id IS NULL 
   OR s.type IS NULL
ORDER BY s.created_at DESC;

-- 4. Count shops by type
SELECT 
    type,
    COUNT(*) AS shop_count
FROM shops
GROUP BY type;

-- 5. Recent activity (last 24 hours)
SELECT 
    'users' AS table_name,
    COUNT(*) AS new_records,
    MAX(created_at) AS latest
FROM users
WHERE created_at >= NOW() - INTERVAL 24 HOUR

UNION ALL

SELECT 
    'shops' AS table_name,
    COUNT(*) AS new_records,
    MAX(created_at) AS latest
FROM shops
WHERE created_at >= NOW() - INTERVAL 24 HOUR;

-- ========================================
-- FIX QUERIES (USE WITH CAUTION)
-- ========================================

-- 6. Create missing shops for users (MANUAL FIX)
-- Replace the values below with actual user data
-- Run this for EACH user that needs a shop:

/*
INSERT INTO shops (
    name,
    description,
    type,
    owner_id,
    phone,
    address,
    city,
    commune,
    is_verified,
    created_at,
    updated_at
) VALUES (
    'Shop Name Here',                    -- name
    'Shop Description',                  -- description
    'retail',                            -- type (retail or wholesale)
    USER_ID_HERE,                        -- owner_id (from users table)
    'PHONE_NUMBER',                      -- phone
    'City, Commune',                     -- address
    'City',                              -- city
    'Commune',                           -- commune
    1,                                   -- is_verified
    NOW(),                               -- created_at
    NOW()                                -- updated_at
);
*/

-- Example: Create shop for user with ID 123
/*
INSERT INTO shops (
    name, description, type, owner_id, phone, address, city, commune, is_verified, created_at, updated_at
) VALUES (
    'My Shop',
    'Amazing products',
    'retail',
    123,
    '+243XXXXXXXXX',
    'Butembo, Vulengera',
    'Butembo',
    'Vulengera',
    1,
    NOW(),
    NOW()
);
*/

-- 7. Fix orphaned shops (shops without valid owner_id)
-- First, find them:
SELECT s.id, s.name, s.owner_id
FROM shops s
LEFT JOIN users u ON s.owner_id = u.id
WHERE u.id IS NULL;

-- Then either delete them or update owner_id:
-- UPDATE shops SET owner_id = CORRECT_USER_ID WHERE id = SHOP_ID;

-- 8. Fix shops with missing type
UPDATE shops 
SET type = 'retail' 
WHERE type IS NULL OR type = '';

-- 9. Add missing remote_id for sync
-- If shops were created directly in MySQL, they might need remote_id
UPDATE shops 
SET remote_id = id 
WHERE remote_id IS NULL;

-- ========================================
-- MAINTENANCE QUERIES
-- ========================================

-- 10. Clean up old test shops (be careful!)
-- DELETE FROM shops WHERE name LIKE 'Test Shop%' AND created_at < NOW() - INTERVAL 7 DAY;

-- 11. Verify data integrity after fixes
SELECT 
    'Total Users' AS metric,
    COUNT(*) AS count
FROM users

UNION ALL

SELECT 
    'Total Shops' AS metric,
    COUNT(*) AS count
FROM shops

UNION ALL

SELECT 
    'Users with Shops' AS metric,
    COUNT(DISTINCT s.owner_id) AS count
FROM shops s
INNER JOIN users u ON s.owner_id = u.id

UNION ALL

SELECT 
    'Orphaned Shops' AS metric,
    COUNT(*) AS count
FROM shops s
LEFT JOIN users u ON s.owner_id = u.id
WHERE u.id IS NULL;

-- ========================================
-- SYNC QUEUE CHECK (if using app's sync system)
-- ========================================

-- The app uses a sync_queue table to track pending changes
-- Check if there are pending shop creations:

/*
SELECT 
    id,
    entity_type,
    action,
    entity_data,
    created_at
FROM sync_queue
WHERE entity_type = 'shops'
  AND action = 'CREATE'
ORDER BY created_at DESC
LIMIT 20;
*/

-- Clear stuck sync queue items (if needed):
-- DELETE FROM sync_queue WHERE entity_type = 'shops' AND created_at < NOW() - INTERVAL 7 DAY;
