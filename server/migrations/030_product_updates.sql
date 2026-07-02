-- Migration v30: public product update announcements
CREATE TABLE IF NOT EXISTS `product_updates` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT NOT NULL,
  `shop_id` INT NOT NULL,
  `update_type` VARCHAR(32) NOT NULL DEFAULT 'note',
  `message` TEXT NULL,
  `product_name` VARCHAR(100) NOT NULL,
  `shop_name` VARCHAR(100) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_product_updates_created` (`created_at`),
  INDEX `idx_product_updates_shop` (`shop_id`),
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
