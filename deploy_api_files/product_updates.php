<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

$ALLOWED_COLUMNS = [
    'id', 'product_id', 'shop_id', 'update_type', 'message',
    'product_name', 'shop_name', 'created_at',
];

try {
    $db = DB::getInstance();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid JSON input']);
            exit;
        }

        if (empty($input['product_id']) || empty($input['shop_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'product_id and shop_id are required']);
            exit;
        }

        $filtered = array_intersect_key($input, array_flip($ALLOWED_COLUMNS));
        if (!isset($filtered['update_type'])) {
            $filtered['update_type'] = 'note';
        }
        if (!isset($filtered['created_at'])) {
            $filtered['created_at'] = date('Y-m-d H:i:s');
        }
        if (!isset($filtered['product_name'])) {
            $filtered['product_name'] = 'Produit';
        }
        if (!isset($filtered['shop_name'])) {
            $filtered['shop_name'] = 'Boutique';
        }

        $keys = array_keys($filtered);
        $values = array_values($filtered);
        $placeholders = array_fill(0, count($keys), '?');
        $stmt = $db->prepare(
            'INSERT INTO product_updates (' . implode(', ', $keys) . ') VALUES (' . implode(', ', $placeholders) . ')'
        );
        $stmt->execute($values);
        $newId = (int)$db->lastInsertId();

        echo json_encode(['success' => true, 'id' => $newId, 'action' => 'CREATE']);
        exit;
    }

    $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;
    $limit = min(max(1, (int)($_GET['limit'] ?? 50)), 200);

    if ($updatedSince) {
        $stmt = $db->prepare(
            'SELECT * FROM product_updates WHERE created_at > ? ORDER BY created_at DESC LIMIT ?'
        );
        $stmt->execute([$updatedSince, $limit]);
    } else {
        $stmt = $db->prepare(
            'SELECT * FROM product_updates ORDER BY created_at DESC LIMIT ?'
        );
        $stmt->execute([$limit]);
    }

    $rows = $stmt->fetchAll();
    echo json_encode(['success' => true, 'data' => $rows]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
