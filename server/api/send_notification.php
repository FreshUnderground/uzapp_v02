<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

/**
 * UzaApp Push Notification Sender
 * 
 * This endpoint sends push notifications via Firebase Cloud Messaging (FCM).
 * It supports both the FCM HTTP v1 API and the legacy FCM API.
 * 
 * Required server configuration in config.php:
 *   define('FCM_SERVER_KEY', 'YOUR_LEGACY_SERVER_KEY');
 *   // OR for HTTP v1:
 *   define('FCM_ACCESS_TOKEN', 'YOUR_OAUTH_ACCESS_TOKEN');
 *   define('FCM_PROJECT_ID', 'your-firebase-project-id');
 * 
 * POST body:
 * {
 *   "tokens": ["token1", "token2"],
 *   "title": "Nouveaux arrivages!",
 *   "body": "Decouvrez les nouveaux arrivages sur UzaApp!",
 *   "data": { "type": "shop", "id": 123 }
 * }
 */

try {
    $db = DB::getInstance();
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        throw new Exception('Invalid JSON input');
    }

    $tokens = isset($input['tokens']) && is_array($input['tokens']) ? $input['tokens'] : [];
    $title = isset($input['title']) ? $input['title'] : 'Nouveaux arrivages!';
    $body = isset($input['body']) ? $input['body'] : 'Decouvrez les nouveaux arrivages sur UzaApp!';
    $data = isset($input['data']) && is_array($input['data']) ? $input['data'] : [];

    if (empty($tokens)) {
        throw new Exception('At least one FCM token is required');
    }

    $results = [];

    foreach ($tokens as $token) {
        $result = sendFcmLegacy($token, $title, $body, $data);
        $results[] = ['token' => substr($token, 0, 20) . '...', 'success' => $result['success'], 'response' => $result['response']];
    }

    echo json_encode(['success' => true, 'results' => $results]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

/**
 * Send a push notification using the legacy FCM HTTP API.
 * 
 * @param string $token   Target FCM device token
 * @param string $title   Notification title
 * @param string $body    Notification body
 * @param array  $data    Custom key-value data payload
 * @return array ['success' => bool, 'response' => mixed]
 */
function sendFcmLegacy($token, $title, $body, $data = []) {
    // Check if FCM_SERVER_KEY is defined in config.php
    if (!defined('FCM_SERVER_KEY') || empty(FCM_SERVER_KEY)) {
        return [
            'success' => false,
            'response' => 'FCM_SERVER_KEY not configured in config.php. Add: define("FCM_SERVER_KEY", "your_key_here");'
        ];
    }

    $payload = [
        'to' => $token,
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
        ],
        'data' => $data,
        'priority' => 'high',
    ];

    $ch = curl_init('https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: key=' . FCM_SERVER_KEY,
        'Content-Type: application/json',
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $decoded = json_decode($response, true);
        $success = isset($decoded['success']) && $decoded['success'] === 1;
        return ['success' => $success, 'response' => $decoded];
    }

    return ['success' => false, 'response' => ['http_code' => $httpCode, 'raw' => $response]];
}
?>
