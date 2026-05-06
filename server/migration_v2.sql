-- ============================================================
-- UzaApp Migration V2
-- Adds: category hierarchy, product metadata, shop verification &
--        geolocation, story_media, fcm_tokens
-- ============================================================

-- Helper: add column only if it does not already exist
DELIMITER //
DROP PROCEDURE IF EXISTS _add_col//
CREATE PROCEDURE _add_col(
  IN p_table  VARCHAR(64),
  IN p_column VARCHAR(64),
  IN p_def    VARCHAR(255)
)
BEGIN
  SET @exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = p_table
      AND COLUMN_NAME  = p_column
  );
  IF @exists = 0 THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_column, '` ', p_def);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END//
DELIMITER ;

-- ============================================================
-- 1. CATEGORIES: add hierarchy support
-- ============================================================
CALL _add_col('categories', 'parent_id',  'INT NULL DEFAULT NULL AFTER icon');
CALL _add_col('categories', 'level',       'TINYINT NOT NULL DEFAULT 0 AFTER parent_id');
CALL _add_col('categories', 'sort_order',  'INT NOT NULL DEFAULT 0 AFTER level');

-- Self-referencing foreign key (add only if not yet present)
SET @fk_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'categories'
    AND CONSTRAINT_NAME = 'fk_categories_parent'
);
SET @fk_sql = IF(@fk_exists = 0,
  'ALTER TABLE `categories` ADD CONSTRAINT `fk_categories_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL',
  'SELECT 1'
);
PREPARE stmt FROM @fk_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Index for parent_id lookups
SET @idx_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'categories'
    AND INDEX_NAME   = 'idx_categories_parent_id'
);
SET @idx_sql = IF(@idx_exists = 0,
  'CREATE INDEX `idx_categories_parent_id` ON `categories`(`parent_id`)',
  'SELECT 1'
);
PREPARE stmt FROM @idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2. PRODUCTS: add metadata JSON column
-- ============================================================
CALL _add_col('products', 'metadata', 'JSON NULL DEFAULT NULL AFTER `condition`');

-- ============================================================
-- 3. SHOPS: add verification & geolocation columns
--    (is_verified already exists, so we skip it)
-- ============================================================
CALL _add_col('shops', 'verified_at', 'DATETIME NULL DEFAULT NULL AFTER is_verified');
CALL _add_col('shops', 'latitude',    'DECIMAL(10,8) NULL DEFAULT NULL AFTER commune');
CALL _add_col('shops', 'longitude',   'DECIMAL(11,8) NULL DEFAULT NULL AFTER latitude');

-- Index for geolocation queries
SET @geo_idx_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'shops'
    AND INDEX_NAME   = 'idx_shops_latitude_longitude'
);
SET @geo_idx_sql = IF(@geo_idx_exists = 0,
  'CREATE INDEX `idx_shops_latitude_longitude` ON `shops`(`latitude`, `longitude`)',
  'SELECT 1'
);
PREPARE stmt FROM @geo_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 4. STORIES: comment noting 7-day expiry enforced at app level
-- ============================================================
ALTER TABLE `stories` MODIFY COLUMN `expires_at` DATETIME NOT NULL COMMENT '7-day expiry enforced at app level; calculated as created_at + 7 days';

-- ============================================================
-- 5. NEW TABLE: story_media
-- ============================================================
CREATE TABLE IF NOT EXISTS `story_media` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `story_id`   INT NOT NULL,
  `media_url`  TEXT NOT NULL,
  `media_type` VARCHAR(10) NOT NULL DEFAULT 'image',
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`story_id`) REFERENCES `stories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for story_media lookups
SET @sm_idx_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'story_media'
    AND INDEX_NAME   = 'idx_story_media_story_id'
);
SET @sm_idx_sql = IF(@sm_idx_exists = 0,
  'CREATE INDEX `idx_story_media_story_id` ON `story_media`(`story_id`)',
  'SELECT 1'
);
PREPARE stmt FROM @sm_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 6. NEW TABLE: fcm_tokens
-- ============================================================
CREATE TABLE IF NOT EXISTS `fcm_tokens` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`    INT NULL,
  `shop_id`    INT NULL,
  `token`      TEXT NOT NULL,
  `platform`   VARCHAR(20) NOT NULL DEFAULT 'android',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for token lookups
SET @ft_idx_exists = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'fcm_tokens'
    AND INDEX_NAME   = 'idx_fcm_tokens_user_id'
);
SET @ft_idx_sql = IF(@ft_idx_exists = 0,
  'CREATE INDEX `idx_fcm_tokens_user_id` ON `fcm_tokens`(`user_id`)',
  'SELECT 1'
);
PREPARE stmt FROM @ft_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- Cleanup helper procedure
-- ============================================================
DROP PROCEDURE IF EXISTS _add_col;
