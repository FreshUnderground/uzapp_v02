-- Migration to add password_hash column to users table
-- Run this on your existing database to support password authentication

ALTER TABLE `users` 
ADD COLUMN `password_hash` VARCHAR(255) NULL AFTER `avatar_url`;
