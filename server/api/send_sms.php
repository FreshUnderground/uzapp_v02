<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

/**
 * UzaApp SMS Proxy Endpoint
 * 
 * Forwards SMS requests to Africa's Talking API server-side.
 * This avoids CORS errors when the app runs on the web platform,
 * since browsers block direct calls to api.africastalking.com.
 * 
 * Required configuration in config.php:
 *   define('AT_API_KEY', 'atsk_xxxxx');
 *   define('AT_USERNAME', 'UzaApp');
 *   define('AT_SENDER_ID', 'UzaApp');
 * 
 * POST body (JSON):
 * {
 *   "to": "+243xxxxxxxxx"  (comma-separated for multiple recipients),
 *   "message": "Your message here"
 * }
 */

// Africa's Talking configuration
$atApiKey = defined('AT_API_KEY') ? AT_API_KEY : 'atsk_630e7712eae43b599076a099966ab0c552ac8c4f0be256ccd98552837d4abefb2edb51e0';
$atUsername = defined('AT_USERNAME') ? AT_USERNAME : 'UzaApp';
$atSenderId = defined('AT_SENDER_ID') ? AT_SENDER_ID : 'UzaApp';

// Determine live vs sandbox endpoint
$apiUrl = ($atUsername === 'sandbox')
    ? 'https://api.sandbox.africastalking.com/version1/messaging'
    : 'https://api.africastalking.com/version1/messaging';

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON input']);
        exit;
    }

    $to = isset($input['to']) ? trim($input['to']) : '';
    $message = isset($input['message']) ? trim($input['message']) : '';

    if (empty($to)) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing "to" field (phone number)']);
        exit;
    }

    if (empty($message)) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing "message" field']);
        exit;
    }

    // Truncate message to 160 characters (GSM-7 limit)
    if (mb_strlen($message) > 160) {
        $message = mb_substr($message, 0, 157) . '...';
    }

    // Build form-encoded body for Africa's Talking
    $postFields = http_build_query([
        'username' => $atUsername,
        'to'       => $to,
        'message'  => $message,
        'from'     => $atSenderId,
        'enqueue'  => '1',
    ]);

    // Forward request to Africa's Talking via cURL (server-side, no CORS)
    if (!function_exists('curl_init')) {
        http_response_code(500);
        echo json_encode(['error' => 'cURL extension is not available on this server']);
        exit;
    }

    $ch = curl_init($apiUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Accept: application/json',
        'Content-Type: application/x-www-form-urlencoded; charset=utf-8',
        'apiKey: ' . $atApiKey,
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postFields);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        http_response_code(502);
        echo json_encode([
            'success' => false,
            'error'   => 'cURL error forwarding to Africa\'s Talking: ' . $curlError,
        ]);
        exit;
    }

    if ($httpCode === 200 || $httpCode === 201) {
        $data = json_decode($response, true);

        // Check individual recipient status codes
        $success = false;
        $statusInfo = '';

        if (isset($data['SMSMessageData']['Recipients']) && is_array($data['SMSMessageData']['Recipients'])) {
            $recipients = $data['SMSMessageData']['Recipients'];
            if (!empty($recipients)) {
                $statusCode = isset($recipients[0]['statusCode']) ? (int)$recipients[0]['statusCode'] : 0;
                $status = isset($recipients[0]['status']) ? $recipients[0]['status'] : '';
                // 100 = Sent, 101 = Sent with scheduling, 102 = Queued
                $success = in_array($statusCode, [100, 101, 102]);
                $statusInfo = "Status: $status, Code: $statusCode";
            }
        } else {
            // If we can't parse recipients, consider 200/201 as success
            $success = true;
        }

        echo json_encode([
            'success'  => $success,
            'status'   => $statusInfo,
            'response' => $data,
        ]);
    } else {
        http_response_code($httpCode);
        echo json_encode([
            'success'  => false,
            'error'    => "Africa's Talking returned HTTP $httpCode",
            'response' => json_decode($response, true) ?: $response,
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
