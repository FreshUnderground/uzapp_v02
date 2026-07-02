-- Ya Cope: petites annonces occasion sans compte vendeur
CREATE TABLE IF NOT EXISTS `ya_cope_listings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(50) NOT NULL,
  `address` TEXT NULL,
  `image_urls` TEXT NOT NULL COMMENT 'Comma-separated image URLs',
  `condition` VARCHAR(50) NOT NULL DEFAULT 'used',
  `views_count` INT NOT NULL DEFAULT 0,
  `shares_count` INT NOT NULL DEFAULT 0,
  `is_sold` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_ya_cope_active` (`is_sold`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
