-- Compte administrateur INVESTEE / mot de passe INVESTEE
-- Hash SHA-256 de "INVESTEE" (identique à l'app Flutter)
INSERT INTO `users` (`phone`, `name`, `password_hash`, `is_phone_verified`, `role`)
VALUES (
  'INVESTEE',
  'INVESTEE',
  '36ec0d6033dc6c7455e83ef762f33b57499511307199e0374159a92b80441e46',
  1,
  'admin'
)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `password_hash` = VALUES(`password_hash`),
  `is_phone_verified` = VALUES(`is_phone_verified`),
  `role` = VALUES(`role`);
