<?php
require_once __DIR__ . '/../db.php';

// Get the image URL from query parameter
$url = isset($_GET['url']) ? $_GET['url'] : '';

if (empty($url)) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing url parameter']);
    exit;
}

// Decode the URL (it may be URL encoded)
$url = urldecode($url);

// Validate that it's a Firebase Storage URL or other allowed domains
$allowedDomains = [
    'firebasestorage.googleapis.com',
    'storage.googleapis.com',
];

$parsedUrl = parse_url($url);
$host = isset($parsedUrl['host']) ? $parsedUrl['host'] : '';

$isAllowed = false;
foreach ($allowedDomains as $domain) {
    if (strpos($host, $domain) !== false) {
        $isAllowed = true;
        break;
    }
}

if (!$isAllowed) {
    http_response_code(403);
    echo json_encode(['error' => 'Domain not allowed: ' . $host]);
    exit;
}

// Try to fetch the image using cURL or file_get_contents
$imageData = false;
$contentType = 'image/jpeg';

if (function_exists('curl_init')) {
    // Use cURL
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');

    $imageData = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($httpCode !== 200 || $imageData === false) {
        http_response_code(502);
        echo json_encode(['error' => 'Failed to fetch image via cURL', 'http_code' => $httpCode, 'details' => $error]);
        exit;
    }
} else {
    // Fallback to file_get_contents
    $context = stream_context_create([
        'http' => [
            'method' => 'GET',
            'header' => 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'timeout' => 30,
        ],
        'ssl' => [
            'verify_peer' => false,
            'verify_peer_name' => false,
        ],
    ]);

    $imageData = @file_get_contents($url, false, $context);
    
    if ($imageData === false) {
        http_response_code(502);
        echo json_encode(['error' => 'Failed to fetch image via file_get_contents']);
        exit;
    }

    // Try to determine content type from URL
    if (strpos($url, '.png') !== false) {
        $contentType = 'image/png';
    } elseif (strpos($url, '.gif') !== false) {
        $contentType = 'image/gif';
    } elseif (strpos($url, '.webp') !== false) {
        $contentType = 'image/webp';
    } else {
        $contentType = 'image/jpeg';
    }
}

// Set proper headers
header('Content-Type: ' . $contentType);
header('Cache-Control: public, max-age=86400'); // Cache for 24 hours
header('Access-Control-Allow-Origin: *');

// Output the image
echo $imageData;
?>
