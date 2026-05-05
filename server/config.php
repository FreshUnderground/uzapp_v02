<?php
// Database Configuration
define('DB_HOST', '91.216.107.185');
define('DB_NAME', 'inves2504808_11wdvwt');
define('DB_USER', 'inves2504808');
define('DB_PASS', '31nzzasdnh');

// API Key Authentication
// In production, this should come from environment variables instead of hardcoded.
define('API_KEY', 'uza_sk_' . md5('uzaapp_secure_2024'));

// Optional: Enable error reporting for development
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set timezone
date_default_timezone_set('UTC');
?>
