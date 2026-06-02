-- Add role column for admin RBAC
ALTER TABLE `users`
  ADD COLUMN IF NOT EXISTS `role` VARCHAR(20) NOT NULL DEFAULT 'user'
  AFTER `is_phone_verified`;

-- Example: grant admin to a phone number
-- UPDATE users SET role = 'admin' WHERE phone = '+243XXXXXXXXX';
