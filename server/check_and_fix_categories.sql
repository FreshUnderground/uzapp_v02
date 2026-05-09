-- ============================================================
-- Category Data Integrity Check & Fix Script
-- ============================================================
-- This script diagnoses and fixes category hierarchy issues:
-- 1. Checks if level values are correct
-- 2. Checks if parent_id values are correct
-- 3. Fixes any inconsistencies
-- ============================================================

-- STEP 1: Display all categories with their hierarchy info
SELECT 
    id,
    name,
    parent_id,
    level,
    sort_order,
    CASE 
        WHEN level = 0 THEN 'ROOT CATEGORY'
        WHEN level = 1 THEN 'SUBCATEGORY'
        WHEN level = 2 THEN 'SUB-SUBCATEGORY'
        ELSE 'INVALID LEVEL'
    END as category_type
FROM categories
ORDER BY level ASC, parent_id ASC, sort_order ASC, name ASC;

-- STEP 2: Check for orphaned subcategories (parent_id points to non-existent category)
SELECT 
    c.id,
    c.name as subcategory_name,
    c.parent_id,
    'ORPHANED - Parent does not exist' as issue
FROM categories c
LEFT JOIN categories p ON c.parent_id = p.id
WHERE c.parent_id IS NOT NULL 
  AND p.id IS NULL;

-- STEP 3: Check for incorrect level values
-- Subcategories (level should be 1) that have parent_id pointing to root categories
SELECT 
    c.id,
    c.name,
    c.parent_id,
    c.level as current_level,
    1 as correct_level,
    'INCORRECT LEVEL - Should be 1' as issue
FROM categories c
INNER JOIN categories p ON c.parent_id = p.id
WHERE p.level = 0 
  AND c.level != 1;

-- STEP 4: Check for root categories that incorrectly have a parent_id
SELECT 
    id,
    name,
    parent_id,
    level,
    'ROOT CATEGORY with parent_id - Should be NULL' as issue
FROM categories
WHERE level = 0 
  AND parent_id IS NOT NULL;

-- ============================================================
-- FIX SCRIPTS (Uncomment to execute fixes)
-- ============================================================

-- FIX 1: Correct level for direct subcategories of root categories
-- UPDATE categories c
-- INNER JOIN categories p ON c.parent_id = p.id
-- SET c.level = 1
-- WHERE p.level = 0 
--   AND c.level != 1;

-- FIX 2: Correct level for sub-subcategories (children of level 1)
-- UPDATE categories c
-- INNER JOIN categories p ON c.parent_id = p.id
-- SET c.level = 2
-- WHERE p.level = 1 
--   AND c.level != 2;

-- FIX 3: Clear parent_id for root categories
-- UPDATE categories
-- SET parent_id = NULL
-- WHERE level = 0 
--   AND parent_id IS NOT NULL;

-- FIX 4: Mark orphaned categories as root (if their parent doesn't exist)
-- UPDATE categories
-- SET parent_id = NULL, level = 0
-- WHERE parent_id IS NOT NULL 
--   AND parent_id NOT IN (SELECT id FROM categories);

-- ============================================================
-- VERIFICATION QUERY (Run after fixes)
-- ============================================================
-- SELECT 
--     level,
--     COUNT(*) as count,
--     GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') as categories
-- FROM categories
-- GROUP BY level
-- ORDER BY level;
