<?php
/**
 * Track platform opens and visits.
 *
 * POST { event_type, platform?, visitor_id?, user_phone? }
 */
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json; charset=utf-8');

function platform_visits_ensure_table(PDO $db): void
{
    $db->exec("
        CREATE TABLE IF NOT EXISTS platform_visits (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT,
            event_type VARCHAR(32) NOT NULL,
            platform VARCHAR(16) NOT NULL DEFAULT 'unknown',
            visitor_id VARCHAR(64) DEFAULT NULL,
            user_phone VARCHAR(32) DEFAULT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_event_type (event_type),
            KEY idx_created_at (created_at),
            KEY idx_visitor_id (visitor_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
}

try {
    $db = DB::getInstance();
    platform_visits_ensure_table($db);

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['success' => false, 'error' => 'Method not allowed']);
        exit;
    }

    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    $eventType = isset($input['event_type']) ? trim((string) $input['event_type']) : '';
    $allowed = ['app_open', 'session_resume', 'web_visit'];
    if (!in_array($eventType, $allowed, true)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid event_type']);
        exit;
    }

    $platform = isset($input['platform']) ? trim((string) $input['platform']) : 'unknown';
    if (strlen($platform) > 16) {
        $platform = substr($platform, 0, 16);
    }

    $visitorId = isset($input['visitor_id']) ? trim((string) $input['visitor_id']) : null;
    if ($visitorId !== null && strlen($visitorId) > 64) {
        $visitorId = substr($visitorId, 0, 64);
    }

    $userPhone = isset($input['user_phone']) ? trim((string) $input['user_phone']) : null;
    if ($userPhone !== null && strlen($userPhone) > 32) {
        $userPhone = substr($userPhone, 0, 32);
    }

    $stmt = $db->prepare(
        'INSERT INTO platform_visits (event_type, platform, visitor_id, user_phone, created_at)
         VALUES (?, ?, ?, ?, NOW())'
    );
    $stmt->execute([$eventType, $platform ?: 'unknown', $visitorId, $userPhone]);

    echo json_encode([
        'success' => true,
        'id' => (int) $db->lastInsertId(),
        'event_type' => $eventType,
    ]);
} catch (PDOException $e) {
    error_log('platform_visits DB error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error']);
} catch (Exception $e) {
    error_log('platform_visits error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
