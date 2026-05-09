<?php
// Database Configuration
define('DB_HOST', '91.216.107.185');
define('DB_NAME', 'inves2504808_11wdvwt');
define('DB_USER', 'inves2504808');
define('DB_PASS', '31nzzasdnh');

// API Key Authentication
// In production, this should come from environment variables instead of hardcoded.
// Hardcoded key for consistency across all clients
define('API_KEY', 'uza_sk_305f0f1ab9c86b0259c876595f74fdf4');

// Optional: Enable error reporting for development
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set timezone
date_default_timezone_set('UTC');

// FCM Server Key (legacy API) for push notifications
// Get this from Firebase Console > Project Settings > Cloud Messaging
// define('FCM_SERVER_KEY', 'YOUR_LEGACY_SERVER_KEY_HERE');
?>
