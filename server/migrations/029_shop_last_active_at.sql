-- Migration v29: shop activity tracking for visibility features
-- Run on production MySQL before deploying updated shops.php

ALTER TABLE `shops`
  ADD COLUMN `last_active_at` DATETIME NULL DEFAULT NULL
  COMMENT 'Last seller post/product/story activity'
  AFTER `longitude`;
