<?php
/**
 * API Key Test Endpoint
 * Returns the expected API key for verification
 */

// Don't require authentication for this test endpoint
require_once __DIR__ . '/../config.php';

header('Content-Type: application/json');

echo json_encode([
    'status' => 'success',
    'message' => 'API Key Test',
    'expected_key' => API_KEY,
    'key_length' => strlen(API_KEY),
    'timestamp' => date('Y-m-d H:i:s')
]);
?>
