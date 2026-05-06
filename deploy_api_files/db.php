<?php
require_once 'config.php';

// Unified CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key');

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
?>
