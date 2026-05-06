-- Add Missing Tables to Production Database
-- Run this in phpMyAdmin for database: inves2504808_11wdvwt

-- ============================================
-- 1. STORIES TABLE (Missing)
-- ============================================
CREATE TABLE IF NOT EXISTS `stories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `remote_id` VARCHAR(255) NULL,
  `shop_id` INT NOT NULL,
  `media_url` TEXT NOT NULL,
  `media_type` VARCHAR(50) NOT NULL COMMENT 'image or video',
  `expires_at` DATETIME NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 2. USERS TABLE (Missing)
-- ============================================
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `remote_id` VARCHAR(255) NULL,
  `phone` VARCHAR(20) NOT NULL UNIQUE,
  `name` VARCHAR(100) NULL,
  `avatar_url` TEXT NULL,
  `is_phone_verified` TINYINT(1) DEFAULT 0,
  `otp_code` VARCHAR(10) NULL,
  `otp_expires_at` DATETIME NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 3. PERFORMANCE INDEXES (If not already created)
-- ============================================
CREATE INDEX IF NOT EXISTS `idx_stories_shop_id` ON `stories`(`shop_id`);
CREATE INDEX IF NOT EXISTS `idx_stories_expires_at` ON `stories`(`expires_at`);
