<?php
require_once __DIR__ . '/config.php';

header('Content-Type: text/plain');

echo "Server API_KEY: " . API_KEY . "\n";
echo "Expected by Flutter app: uza_sk_305f0f1ab9c86b0259c876595f74fdf4\n";
echo "\n";

if (API_KEY === 'uza_sk_305f0f1ab9c86b0259c876595f74fdf4') {
    echo "✅ Keys MATCH - authentication should work\n";
} else {
    echo "❌ Keys DO NOT MATCH - this is the problem!\n";
    echo "\n";
    echo "To fix, update the API key in:\n";
    echo "lib/core/services/api_service.dart\n";
    echo "Change line 8-9 to:\n";
    echo "static const String _apiKey = '" . API_KEY . "';\n";
}
?>
