-- Cash management tables for POS / caisse module

CREATE TABLE IF NOT EXISTS `cash_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `shop_id` INT NOT NULL,
  `opened_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `closed_at` DATETIME NULL,
  `opening_balance` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `closing_balance` DECIMAL(12, 2) NULL,
  `expected_balance` DECIMAL(12, 2) NULL,
  `opened_by` VARCHAR(50) NULL,
  `closed_by` VARCHAR(50) NULL,
  `notes` TEXT NULL,
  `status` ENUM('open', 'closed') NOT NULL DEFAULT 'open',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE,
  INDEX `idx_shop_status` (`shop_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cash_transactions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `session_id` INT NOT NULL,
  `shop_id` INT NOT NULL,
  `type` ENUM('sale', 'expense', 'withdrawal', 'deposit') NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `description` VARCHAR(255) NULL,
  `payment_method` ENUM('cash', 'mobile_money', 'card') NOT NULL DEFAULT 'cash',
  `created_by` VARCHAR(50) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`session_id`) REFERENCES `cash_sessions`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`shop_id`) REFERENCES `shops`(`id`) ON DELETE CASCADE,
  INDEX `idx_session` (`session_id`),
  INDEX `idx_shop_created` (`shop_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
