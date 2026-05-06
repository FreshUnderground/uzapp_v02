<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input || !isset($input['token'])) {
            throw new Exception('Token is required');
        }

        $token = $input['token'];
        $userId = isset($input['user_id']) ? (int)$input['user_id'] : null;
        $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
        $platform = isset($input['platform']) ? $input['platform'] : 'android';

        // Validate platform
        $allowedPlatforms = ['android', 'ios', 'web'];
        if (!in_array($platform, $allowedPlatforms, true)) {
            $platform = 'android';
        }

        // Upsert: update if token exists, insert otherwise
        $stmt = $db->prepare("SELECT id FROM fcm_tokens WHERE token = ?");
        $stmt->execute([$token]);
        $existing = $stmt->fetch();

        if ($existing) {
            // Update existing token
            $fields = ["platform = ?", "updated_at = NOW()"];
            $params = [$platform];

            if ($userId !== null) {
                $fields[] = "user_id = ?";
                $params[] = $userId;
            }
            if ($shopId !== null) {
                $fields[] = "shop_id = ?";
                $params[] = $shopId;
            }

            $params[] = $token;
            $stmt = $db->prepare("UPDATE fcm_tokens SET " . implode(', ', $fields) . " WHERE token = ?");
            $stmt->execute($params);

            echo json_encode(['success' => true, 'action' => 'UPDATE']);
        } else {
            // Insert new token
            $stmt = $db->prepare("INSERT INTO fcm_tokens (user_id, shop_id, token, platform, updated_at) VALUES (?, ?, ?, ?, NOW())");
            $stmt->execute([$userId, $shopId, $token, $platform]);

            echo json_encode(['success' => true, 'action' => 'CREATE', 'id' => (int)$db->lastInsertId()]);
        }
        exit;
    }

    if ($method === 'DELETE') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input || !isset($input['token'])) {
            throw new Exception('Token is required');
        }

        $token = $input['token'];
        $stmt = $db->prepare("DELETE FROM fcm_tokens WHERE token = ?");
        $stmt->execute([$token]);
        $deleted = $stmt->rowCount();

        echo json_encode(['success' => true, 'deleted' => $deleted]);
        exit;
    }

    // GET: list tokens (optionally filtered by user_id or shop_id)
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
    $shopId = isset($_GET['shop_id']) ? (int)$_GET['shop_id'] : null;

    $query = "SELECT id, user_id, shop_id, token, platform, updated_at FROM fcm_tokens WHERE 1=1";
    $params = [];

    if ($userId !== null) {
        $query .= " AND user_id = ?";
        $params[] = $userId;
    }
    if ($shopId !== null) {
        $query .= " AND shop_id = ?";
        $params[] = $shopId;
    }

    $stmt = $db->prepare($query);
    $stmt->execute($params);
    $tokens = $stmt->fetchAll();

    echo json_encode(['success' => true, 'data' => $tokens]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
