-- UzaApp Production Database Schema
-- MySQL Schema for https://uzaapp.com/api/
-- Database: inves2504808_11wdvwt

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 1. CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `categories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `remote_id` VARCHAR(255) NULL,
  `name` VARCHAR(100) NOT NULL,
  `icon` TEXT NULL,
  `parent_id` INT NULL DEFAULT NULL,
  `level` TINYINT NOT NULL DEFAULT 0 COMMENT '0=root category, 1=subcategory, 2=sub-subcategory',
  `sort_order` INT NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 2. SHOPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `shops` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `remote_id` VARCHAR(255) NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `logo_url` TEXT NULL,
  `type` ENUM('retail', 'wholesale') DEFAULT 'retail',
  `owner_id` VARCHAR(255) NULL,
  `address` TEXT NULL,
  `whatsapp` VARCHAR(50) NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(100) NULL,
  `instagram_url` TEXT NULL,
  `tiktok_url` TEXT NULL,
  `facebook_url` TEXT NULL,
  `youtube_url` TEXT NULL,
  `banner_url` TEXT NULL,
  `video_url` TEXT NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_boosted` TINYINT(1) DEFAULT 0,
  `boost_status` INT DEFAULT 0 COMMENT '0: None, 1: Pending, 2: Active, 3: Rejected',
  `banner_status` INT DEFAULT 0,
  `banner_text` TEXT NULL,
  `is_verified` TINYINT(1) NOT NULL DEFAULT 0,
  `verified_at` DATETIME NULL DEFAULT NULL,
  `response_time_minutes` INT NULL,
  `commune` VARCHAR(100) NULL,
  `city` VARCHAR(100) NULL,
  `latitude` DECIMAL(10,8) NULL DEFAULT NULL,
  `longitude` DECIMAL(11,8) NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 3. PRODUCTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `products` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `remote_id` VARCHAR(255) NULL,
  `shop_id` INT NOT NULL,
  `category_id` INT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `price` DECIMAL(10, 2) NULL,
  `category` VARCHAR(100) NULL COMMENT 'Legacy string category',
  `image_urls` TEXT NOT NULL COMMENT 'JSON string of image URLs',
  `is_arrival` TINYINT(1) DEFAULT 0,
  `is_promotion` TINYINT(1) DEFAULT 0,
  `stock_count` INT NULL,
  `hide_price` TINYINT(1) DEFAULT 0,
  `show_stock` TINYINT(1) DEFAULT 0,
  `is_boosted` TINYINT(1) DEFAULT 0,
  `promotion_message` TEXT NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `views_count` INT DEFAULT 0,
  `shares_count` INT DEFAULT 0,
  `ratings_count` INT DEFAULT 0,
  `rating_avg` DECIMAL(3, 2) DEFAULT 0.00,
  `boost_status` INT DEFAULT 0 COMMENT '0: None, 1: Pending, 2: Active, 3: Rejected',
  `condition` VARCHAR(50) DEFAULT 'new',
  `metadata` JSON NULL DEFAULT NULL COMMENT 'Category-specific fields stored as JSON',
  `report_count` INT DEFAULT 0,
  `is_sold` TINYINT(1) DEFAULT 0,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 4. STORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `stories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `remote_id` VARCHAR(255) NULL,
  `shop_id` INT NOT NULL,
  `media_url` TEXT NOT NULL,
  `media_type` VARCHAR(50) NOT NULL COMMENT 'image or video',
  `is_arrivage` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0=story (24h), 1=arrivage (4 days)',
  `expires_at` DATETIME NOT NULL COMMENT '24h for stories, 4 days for arrivages',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 5. STORY_MEDIA TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `story_media` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `story_id` INT NOT NULL,
  `media_url` TEXT NOT NULL,
  `media_type` VARCHAR(10) NOT NULL DEFAULT 'image',
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`story_id`) REFERENCES `stories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 6. USERS TABLE
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
-- 7. FCM_TOKENS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `fcm_tokens` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NULL,
  `shop_id` INT NULL,
  `token` TEXT NOT NULL,
  `platform` VARCHAR(20) NOT NULL DEFAULT 'android',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX `idx_products_shop_id` ON `products`(`shop_id`);
CREATE INDEX `idx_products_category_id` ON `products`(`category_id`);
CREATE INDEX `idx_products_updated_at` ON `products`(`updated_at`);
CREATE INDEX `idx_stories_shop_id` ON `stories`(`shop_id`);
CREATE INDEX `idx_stories_expires_at` ON `stories`(`expires_at`);
CREATE INDEX `idx_shops_owner_id` ON `shops`(`owner_id`);
CREATE INDEX `idx_shops_updated_at` ON `shops`(`updated_at`);
CREATE INDEX `idx_categories_parent_id` ON `categories`(`parent_id`);
CREATE INDEX `idx_shops_latitude_longitude` ON `shops`(`latitude`, `longitude`);
CREATE INDEX `idx_story_media_story_id` ON `story_media`(`story_id`);
CREATE INDEX `idx_fcm_tokens_user_id` ON `fcm_tokens`(`user_id`);
