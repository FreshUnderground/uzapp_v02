<?php

/**

 * Orders API — sync buyer/seller purchase requests from UzaApp.

 *

 * GET  ?buyer_phone=... | ?shop_id=... [&updated_since=ISO8601]

 * POST { action, data } — CREATE | UPDATE

 */

require_once __DIR__ . '/../db.php';

authenticate();



header('Content-Type: application/json');



$db = DB::getInstance();

$method = $_SERVER['REQUEST_METHOD'];



try {

    // Ensure table exists (safe migration on first call)

    $db->exec("

        CREATE TABLE IF NOT EXISTS orders (

            id INT AUTO_INCREMENT PRIMARY KEY,

            buyer_phone VARCHAR(32) NOT NULL,

            shop_id INT NOT NULL,

            status VARCHAR(32) NOT NULL DEFAULT 'requested',

            items_json TEXT NOT NULL,

            note TEXT NULL,

            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

            INDEX idx_orders_buyer (buyer_phone),

            INDEX idx_orders_shop (shop_id),

            INDEX idx_orders_updated (updated_at)

        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4

    ");



    if ($method === 'GET') {

        $buyerPhone = isset($_GET['buyer_phone']) ? trim($_GET['buyer_phone']) : null;

        $shopId = isset($_GET['shop_id']) ? (int) $_GET['shop_id'] : null;

        $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;



        $sql = 'SELECT * FROM orders WHERE 1=1';

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

        $data = $input['data'] ?? $input;



        if (!is_array($data)) {

            http_response_code(400);

            echo json_encode(['success' => false, 'error' => 'Invalid data']);

            exit;

        }



        $buyerPhone = trim($data['buyer_phone'] ?? '');

        $shopId = (int) ($data['shop_id'] ?? 0);

        $itemsJson = $data['items_json'] ?? '[]';

        if (is_array($itemsJson)) {

            $itemsJson = json_encode($itemsJson);

        }

        $status = $data['status'] ?? 'requested';

        $note = $data['note'] ?? null;

        $id = isset($data['id']) ? (int) $data['id'] : null;



        if ($buyerPhone === '' || $shopId <= 0) {

            http_response_code(400);

            echo json_encode(['success' => false, 'error' => 'buyer_phone and shop_id required']);

            exit;

        }



        if ($action === 'UPDATE' && $id) {

            $stmt = $db->prepare(

                'UPDATE orders SET status = ?, items_json = ?, note = ?, updated_at = NOW() WHERE id = ?'

            );

            $stmt->execute([$status, $itemsJson, $note, $id]);

            echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);

            exit;

        }



        $stmt = $db->prepare(

            'INSERT INTO orders (buyer_phone, shop_id, status, items_json, note) VALUES (?, ?, ?, ?, ?)'

        );

        $stmt->execute([$buyerPhone, $shopId, $status, $itemsJson, $note]);

        $newId = (int) $db->lastInsertId();

        echo json_encode(['success' => true, 'id' => $newId, 'action' => 'CREATE']);

        exit;

    }



    http_response_code(405);

    echo json_encode(['success' => false, 'error' => 'Method not allowed']);

} catch (Exception $e) {

    http_response_code(500);

    echo json_encode(['success' => false, 'error' => $e->getMessage()]);

}

