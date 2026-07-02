<?php
require_once 'config.php';

// Unified CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key, X-Admin-Phone');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

class DB {
    private static $instance = null;
    private $conn;

    private function __construct() {
        try {
            $this->conn = new PDO(
                "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]
            );
        } catch (PDOException $e) {
            header('Content-Type: application/json', true, 500);
            echo json_encode(['error' => 'Connection failed: ' . $e->getMessage()]);
            exit;
        }
    }

    public static function getInstance() {
        if (!self::$instance) {
            self::$instance = new DB();
        }
        return self::$instance->conn;
    }
}

/**
 * Authenticate the request using the X-API-Key header or query parameter.
 * Skips auth for OPTIONS (CORS preflight) requests.
 * Returns 401 JSON and exits if the key is invalid or missing.
 */
function authenticate() {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        return;
    }

    $apiKey = '';
    
    // Try 1: Get API key from headers (works in most environments)
    $headers = getallheaders();
    if (isset($headers['X-API-Key'])) {
        $apiKey = $headers['X-API-Key'];
    }
    // Try 2: Fallback for FastCGI/PHP-FPM environments where headers are in $_SERVER
    elseif (isset($_SERVER['HTTP_X_API_KEY'])) {
        $apiKey = $_SERVER['HTTP_X_API_KEY'];
    }
    // Try 3: Fallback for proxy/caching layers that strip headers - use query parameter
    elseif (isset($_GET['api_key'])) {
        $apiKey = $_GET['api_key'];
    }

    if (!$apiKey || $apiKey !== API_KEY) {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode([
            'error' => 'Unauthorized: Invalid or missing API key',
            'debug' => [
                'received_key' => $apiKey ? 'present' : 'missing',
                'expected_prefix' => 'uza_sk_',
                'headers_available' => array_keys($headers)
            ]
        ]);
        exit;
    }
}

/**
 * Phone format variations (DRC) for admin lookup.
 */
function admin_phone_variations($phone) {
    $cleaned = preg_replace('/\s+/', '', trim((string) $phone));
    $digits = preg_replace('/\D+/', '', $cleaned);
    $variations = array_filter([$cleaned, $digits]);

    if (strpos($digits, '243') === 0 && strlen($digits) >= 12) {
        $local = substr($digits, 3);
        $variations[] = $local;
        $variations[] = '0' . $local;
        $variations[] = $digits;
        $variations[] = '+' . $digits;
    } elseif (strpos($digits, '0') === 0 && strlen($digits) >= 10) {
        $local = substr($digits, 1);
        $variations[] = $local;
        $variations[] = '0' . $local;
        $variations[] = '243' . $local;
        $variations[] = '+243' . $local;
    } elseif (strlen($digits) === 9) {
        $variations[] = $digits;
        $variations[] = '0' . $digits;
        $variations[] = '243' . $digits;
        $variations[] = '+243' . $digits;
    }

    return array_values(array_unique(array_filter($variations)));
}

/**
 * Require valid API key and an authenticated admin user (by phone).
 */
function authenticate_admin() {
    authenticate();

    $phone = '';
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    if (isset($headers['X-Admin-Phone'])) {
        $phone = $headers['X-Admin-Phone'];
    } elseif (isset($_SERVER['HTTP_X_ADMIN_PHONE'])) {
        $phone = $_SERVER['HTTP_X_ADMIN_PHONE'];
    } elseif (isset($_GET['admin_phone'])) {
        $phone = $_GET['admin_phone'];
    }

    if ($phone === '') {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Admin phone required']);
        exit;
    }

    $db = DB::getInstance();
    $variations = admin_phone_variations($phone);
    if (empty($variations)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Invalid admin phone']);
        exit;
    }

    $placeholders = implode(',', array_fill(0, count($variations), '?'));
    $stmt = $db->prepare(
        "SELECT id, phone, role FROM users WHERE phone IN ($placeholders) LIMIT 1"
    );
    $stmt->execute($variations);
    $user = $stmt->fetch();

    if (!$user || ($user['role'] ?? '') !== 'admin') {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Admin access denied']);
        exit;
    }

    return $user;
}
?>
