-- Platform visit / app open tracking for admin dashboard
CREATE TABLE IF NOT EXISTS `platform_visits` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_type` VARCHAR(32) NOT NULL COMMENT 'app_open, session_resume, web_visit',
  `platform` VARCHAR(16) NOT NULL DEFAULT 'unknown' COMMENT 'android, ios, web',
  `visitor_id` VARCHAR(64) DEFAULT NULL,
  `user_phone` VARCHAR(32) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_visitor_id` (`visitor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
