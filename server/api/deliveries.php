<?php
/**
 * Deliveries API — client delivery requests for UzaApp.
 *
 * GET  ?buyer_phone=... | ?shop_id=... [&updated_since=...]
 * POST { action, data } — CREATE | UPDATE
 */
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

$db = DB::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

$ALLOWED_COLUMNS = [
    'id', 'buyer_phone', 'buyer_name', 'shop_id', 'product_id', 'items_json',
    'status', 'delivery_address', 'delivery_commune', 'latitude', 'longitude',
    'location_mode', 'note',
];

function filterDeliveryData(array $data, array $allowed): array {
    return array_intersect_key($data, array_flip($allowed));
}

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS deliveries (
            id INT AUTO_INCREMENT PRIMARY KEY,
            buyer_phone VARCHAR(32) NOT NULL,
            buyer_name VARCHAR(120) NULL,
            shop_id INT NOT NULL,
            product_id INT NULL,
            items_json TEXT NOT NULL DEFAULT '[]',
            status VARCHAR(32) NOT NULL DEFAULT 'pending',
            delivery_address TEXT NULL,
            delivery_commune VARCHAR(100) NULL,
            latitude DECIMAL(10,8) NULL,
            longitude DECIMAL(11,8) NULL,
            location_mode VARCHAR(16) NOT NULL DEFAULT 'commune',
            note TEXT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_deliveries_buyer (buyer_phone),
            INDEX idx_deliveries_shop (shop_id),
            INDEX idx_deliveries_status (status),
            INDEX idx_deliveries_updated (updated_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    if ($method === 'GET') {
        $buyerPhone = isset($_GET['buyer_phone']) ? trim($_GET['buyer_phone']) : null;
        $shopId = isset($_GET['shop_id']) ? (int) $_GET['shop_id'] : null;
        $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;

        $sql = 'SELECT * FROM deliveries WHERE 1=1';
        $params = [];

        if ($buyerPhone) {
            $sql .= ' AND buyer_phone = ?';
            $params[] = $buyerPhone;
        }
        if ($shopId) {
            $sql .= ' AND shop_id = ?';
            $params[] = $shopId;
        }
        if ($updatedSince) {
            $sql .= ' AND updated_at >= ?';
            $params[] = $updatedSince;
        }

        $sql .= ' ORDER BY updated_at DESC LIMIT 500';
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll();

        echo json_encode(['success' => true, 'data' => $rows]);
        exit;
    }

    if ($method === 'POST') {
        $raw = file_get_contents('php://input');
        $input = json_decode($raw, true);
        if (!$input) {
            $input = $_POST;
        }

        $action = strtoupper($input['action'] ?? 'CREATE');
        $data = filterDeliveryData($input['data'] ?? $input, $ALLOWED_COLUMNS);

        $buyerPhone = trim($data['buyer_phone'] ?? '');
        $shopId = (int) ($data['shop_id'] ?? 0);
        $id = isset($data['id']) ? (int) $data['id'] : null;

        if ($buyerPhone === '' || $shopId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'buyer_phone and shop_id required']);
            exit;
        }

        $itemsJson = $data['items_json'] ?? '[]';
        if (is_array($itemsJson)) {
            $itemsJson = json_encode($itemsJson);
        }

        $fields = [
            'buyer_phone' => $buyerPhone,
            'buyer_name' => $data['buyer_name'] ?? null,
            'shop_id' => $shopId,
            'product_id' => isset($data['product_id']) ? (int) $data['product_id'] : null,
            'items_json' => $itemsJson,
            'status' => $data['status'] ?? 'pending',
            'delivery_address' => $data['delivery_address'] ?? null,
            'delivery_commune' => $data['delivery_commune'] ?? null,
            'latitude' => isset($data['latitude']) ? (float) $data['latitude'] : null,
            'longitude' => isset($data['longitude']) ? (float) $data['longitude'] : null,
            'location_mode' => $data['location_mode'] ?? 'commune',
            'note' => $data['note'] ?? null,
        ];

        if ($action === 'UPDATE' && $id) {
            $sets = [];
            $params = [];
            foreach ($fields as $col => $val) {
                $sets[] = "`$col` = ?";
                $params[] = $val;
            }
            $params[] = $id;
            $stmt = $db->prepare(
                'UPDATE deliveries SET ' . implode(', ', $sets) . ', updated_at = NOW() WHERE id = ?'
            );
            $stmt->execute($params);
            echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);
            exit;
        }

        $cols = array_keys($fields);
        $placeholders = array_fill(0, count($cols), '?');
        $stmt = $db->prepare(
            'INSERT INTO deliveries (`' . implode('`, `', $cols) . '`) VALUES (' .
            implode(', ', $placeholders) . ')'
        );
        $stmt->execute(array_values($fields));
        $newId = (int) $db->lastInsertId();

        // Notify shop owner via FCM
        $pushSent = 0;
        try {
            $pushSent = delivery_notify_shop_owner(
                $db,
                $shopId,
                $newId,
                $buyerPhone,
                $fields['buyer_name'] ?? null
            );
        } catch (Exception $pushEx) {
            error_log('Delivery push error: ' . $pushEx->getMessage());
        }

        echo json_encode([
            'success' => true,
            'id' => $newId,
            'action' => 'CREATE',
            'push_sent' => $pushSent,
        ]);
        exit;
    }

    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

/**
 * Push notification to shop owner device(s) for a new delivery request.
 */
function delivery_notify_shop_owner(PDO $db, int $shopId, int $deliveryId, string $buyerPhone, ?string $buyerName): int {
    if (!defined('FCM_SERVER_KEY') || empty(FCM_SERVER_KEY)) {
        return 0;
    }

    $shopStmt = $db->prepare('SELECT name, owner_id FROM shops WHERE id = ? LIMIT 1');
    $shopStmt->execute([$shopId]);
    $shop = $shopStmt->fetch(PDO::FETCH_ASSOC);
    $shopName = $shop['name'] ?? 'Votre boutique';
    $ownerId = $shop['owner_id'] ?? null;

    $tokenStmt = $db->prepare('
        SELECT DISTINCT ft.token FROM fcm_tokens ft
        WHERE ft.shop_id = ?
        UNION
        SELECT ft.token FROM fcm_tokens ft
        INNER JOIN users u ON u.id = ft.user_id
        WHERE u.phone = ?
    ');
    $tokenStmt->execute([$shopId, $ownerId]);
    $tokens = $tokenStmt->fetchAll(PDO::FETCH_COLUMN);

    if (empty($tokens) && $ownerId) {
        $altStmt = $db->prepare('
            SELECT DISTINCT ft.token FROM fcm_tokens ft
            WHERE ft.user_id IN (SELECT id FROM users WHERE phone LIKE ?)
        ');
        $altStmt->execute(['%' . preg_replace('/\D/', '', $ownerId)]);
        $tokens = $altStmt->fetchAll(PDO::FETCH_COLUMN);
    }

    $label = trim($buyerName ?? '') !== '' ? $buyerName : $buyerPhone;
    $title = 'Nouvelle livraison';
    $body = $label . ' demande une livraison — ' . $shopName;
    $sent = 0;

    foreach ($tokens as $token) {
        if (delivery_send_fcm($token, $title, $body, $deliveryId, $shopId)) {
            $sent++;
        }
    }
    return $sent;
}

function delivery_send_fcm(string $token, string $title, string $body, int $deliveryId, int $shopId): bool {
    $payload = [
        'to' => $token,
        'priority' => 'high',
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
        ],
        'data' => [
            'type' => 'delivery',
            'id' => $deliveryId,
            'shop_id' => $shopId,
        ],
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

    if ($httpCode !== 200) {
        return false;
    }
    $decoded = json_decode($response, true);
    return isset($decoded['success']) && (int) $decoded['success'] >= 1;
}
