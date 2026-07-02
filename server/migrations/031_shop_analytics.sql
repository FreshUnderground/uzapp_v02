-- Shop-level analytics: profile views, catalog/story/QR/status shares (cross-device).
CREATE TABLE IF NOT EXISTS shop_analytics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shop_id INT NOT NULL,
  interaction_type VARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_shop_analytics_shop (shop_id),
  INDEX idx_shop_analytics_type (shop_id, interaction_type),
  INDEX idx_shop_analytics_created (created_at),
  CONSTRAINT fk_shop_analytics_shop
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
