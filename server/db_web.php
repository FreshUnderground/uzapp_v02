<?php
require_once 'config.php';

// Unified CORS Headers - Enhanced for Flutter Web
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key, User-Agent, Accept');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Max-Age: 86400');

// Handle preflight OPTIONS request
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
 * Authenticate the request using the X-API-Key header.
 * 
 * NOTE: For Flutter Web compatibility, we skip auth for GET requests
 * since browsers cannot send custom headers on cross-origin requests.
 * POST/PUT/DELETE requests still require authentication.
 */
function authenticate() {
    // Allow GET requests without API key (for Flutter Web compatibility)
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        return;
    }
    
    // OPTIONS preflight already handled above
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        return;
    }

    // For POST/PUT/DELETE, require API key
    $headers = getallheaders();
    $apiKey = isset($headers['X-API-Key']) ? $headers['X-API-Key'] : '';

    if (!$apiKey || $apiKey !== API_KEY) {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Unauthorized: Invalid or missing API key']);
        exit;
    }
}
?>
