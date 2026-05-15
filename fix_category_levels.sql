-- ============================================================
-- Fix Category Hierarchy Levels
-- ============================================================
-- This script recalculates category levels based on parent_id
-- to ensure the hierarchy is correct:
-- level=0: Root categories (parent_id IS NULL)
-- level=1: Subcategories (parent points to level=0)
-- level=2: Sub-subcategories (parent points to level=1)
-- ============================================================

-- STEP 1: Set level=0 for all categories with NULL parent_id
UPDATE categories
SET level = 0
WHERE parent_id IS NULL;

-- STEP 2: Set level=1 for categories whose parent is level=0
UPDATE categories c
INNER JOIN categories p ON c.parent_id = p.id
SET c.level = 1
WHERE p.level = 0;

-- STEP 3: Set level=2 for categories whose parent is level=1
UPDATE categories c
INNER JOIN categories p ON c.parent_id = p.id
SET c.level = 2
WHERE p.level = 1;

-- STEP 4: Verify the fix
SELECT 
    level,
    COUNT(*) as count,
    GROUP_CONCAT(name ORDER BY sort_order, name SEPARATOR ', ') as categories
FROM categories
GROUP BY level
ORDER BY level;

-- STEP 5: Check for any remaining inconsistencies
SELECT 
    c.id,
    c.name,
    c.parent_id,
    c.level as current_level,
    p.level as parent_level,
    'INCONSISTENT: Parent level should be current_level - 1' as issue
FROM categories c
INNER JOIN categories p ON c.parent_id = p.id
WHERE c.level != p.level + 1;
