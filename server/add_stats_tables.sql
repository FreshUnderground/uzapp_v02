-- Migration: Add product_likes and shop_follows tables
-- Date: 2026-05-09

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- PRODUCT_LIKES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `product_likes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT NOT NULL,
  `user_phone` VARCHAR(20) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_product_user` (`product_id`, `user_phone`),
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- SHOP_FOLLOWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS `shop_follows` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `shop_id` INT NOT NULL,
  `user_phone` VARCHAR(20) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_shop_user` (`shop_id`, `user_phone`),
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- USER_CONTACTS TABLE (if not exists)
-- ============================================
CREATE TABLE IF NOT EXISTS `user_contacts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `shop_id` INT NOT NULL,
  `user_phone` VARCHAR(20) NOT NULL,
  `user_name` VARCHAR(100) NULL,
  `contact_type` VARCHAR(20) NOT NULL DEFAULT 'whatsapp',
  `product_id` INT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX `idx_product_likes_product_id` ON `product_likes`(`product_id`);
CREATE INDEX `idx_product_likes_user_phone` ON `product_likes`(`user_phone`);
CREATE INDEX `idx_shop_follows_shop_id` ON `shop_follows`(`shop_id`);
CREATE INDEX `idx_shop_follows_user_phone` ON `shop_follows`(`user_phone`);
CREATE INDEX `idx_user_contacts_shop_id` ON `user_contacts`(`shop_id`);
