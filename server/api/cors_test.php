<?php
/**
 * CORS Test Endpoint
 * Simple test to verify CORS headers are working
 */

// Add comprehensive CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key');
header('Access-Control-Max-Age: 86400'); // 24 hours
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['status' => 'CORS OK']);
    exit;
}

echo json_encode([
    'status' => 'success',
    'message' => 'CORS is working!',
    'timestamp' => date('Y-m-d H:i:s'),
    'your_ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
]);
?>
