-- ============================================
-- Add latitude and longitude columns to shops table
-- Run this if these columns don't exist in your database
-- ============================================

-- Check and add latitude column
ALTER TABLE shops 
ADD COLUMN IF NOT EXISTS `latitude` DECIMAL(10,8) NULL DEFAULT NULL 
COMMENT 'Shop latitude coordinate';

-- Check and add longitude column  
ALTER TABLE shops 
ADD COLUMN IF NOT EXISTS `longitude` DECIMAL(11,8) NULL DEFAULT NULL 
COMMENT 'Shop longitude coordinate';

-- Check and add city column
ALTER TABLE shops
ADD COLUMN IF NOT EXISTS `city` VARCHAR(100) NULL DEFAULT NULL
COMMENT 'Shop city';

-- Check and add commune column
ALTER TABLE shops
ADD COLUMN IF NOT EXISTS `commune` VARCHAR(100) NULL DEFAULT NULL
COMMENT 'Shop commune';

-- Verify the columns were added
SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'shops' 
  AND COLUMN_NAME IN ('latitude', 'longitude', 'city', 'commune')
ORDER BY COLUMN_NAME;
