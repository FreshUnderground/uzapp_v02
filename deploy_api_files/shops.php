<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

// Allowed columns for shops to prevent SQL errors from unknown fields
$ALLOWED_SHOP_COLUMNS = [
    'id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 'whatsapp',
    'phone', 'email', 'instagram_url', 'tiktok_url', 'facebook_url', 'youtube_url',
    'banner_url', 'boost_status', 'banner_status', 'banner_text', 'video_url',
    'is_boosted', 'is_verified', 'verified_at', 'created_at', 'updated_at'
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

        // --- Validation ---
        if (empty($input['name'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Shop name is required']);
            exit;
        }

        $id = isset($input['id']) ? $input['id'] : null;
        $ownerId = isset($input['owner_id']) ? $input['owner_id'] : null;

        // --- Determine upsert target ---
        $exists = false;
        $existingShop = null;

        // 1. Check by ID first (exact match)
        if ($id) {
            $stmt = $db->prepare("SELECT id, owner_id FROM shops WHERE id = ?");
            $stmt->execute([$id]);
            $existingShop = $stmt->fetch();
            if ($existingShop) {
                $exists = true;
            }
        }

        // 2. If no ID match but owner_id provided, check by owner_id (upsert)
        if (!$exists && $ownerId) {
            $stmt = $db->prepare("SELECT id, owner_id FROM shops WHERE owner_id = ?");
            $stmt->execute([$ownerId]);
            $existingShop = $stmt->fetch();
            if ($existingShop) {
                $exists = true;
                $id = $existingShop['id']; // use existing ID for update
            }
        }

        // Filter to only allowed columns BEFORE building SQL
        $filteredInput = array_intersect_key($input, array_flip($ALLOWED_SHOP_COLUMNS));

        // Add updated_at timestamp
        $filteredInput['updated_at'] = date('Y-m-d H:i:s');

        if ($exists) {
            // UPDATE
            $fields = [];
            $params = [];
            foreach ($filteredInput as $key => $value) {
                if ($key !== 'id') {
                    $fields[] = "`$key` = ?";
                    $params[] = $value;
                }
            }
            $params[] = $id;
            $stmt = $db->prepare("UPDATE shops SET " . implode(', ', $fields) . " WHERE id = ?");
            $stmt->execute($params);
            echo json_encode(['success' => true, 'id' => (int)$id, 'action' => 'UPDATE']);
        } else {
            // INSERT — ensure created_at is set
            if (!isset($filteredInput['created_at'])) {
                $filteredInput['created_at'] = date('Y-m-d H:i:s');
            }
            $keys = array_keys($filteredInput);
            $values = array_values($filteredInput);
            $placeholders = array_fill(0, count($keys), '?');
            $stmt = $db->prepare("INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
            $stmt->execute($values);
            $newId = $db->lastInsertId();
            echo json_encode(['success' => true, 'id' => (int)$newId, 'action' => 'CREATE']);
        }
        exit;
    }

    // GET Logic
    $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;

    if ($updatedSince) {
        $query = "SELECT * FROM shops WHERE updated_at > ? ORDER BY id DESC";
        $stmt = $db->prepare($query);
        $stmt->execute([$updatedSince]);
        $shops = $stmt->fetchAll();
    } else {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $perPage = min(max(1, (int)($_GET['per_page'] ?? 20)), 100);
        $offset = ($page - 1) * $perPage;

        $countStmt = $db->prepare("SELECT COUNT(*) as total FROM shops");
        $countStmt->execute();
        $total = (int)$countStmt->fetch()['total'];

        $query = "SELECT * FROM shops ORDER BY id DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$perPage, $offset]);
        $shops = $stmt->fetchAll();
    }

    foreach ($shops as &$shop) {
        $shop['id'] = (int)$shop['id'];
        $shop['boost_status'] = (int)$shop['boost_status'];
        $shop['banner_status'] = (int)$shop['banner_status'];
        $shop['is_boosted'] = (bool)$shop['is_boosted'];
        $shop['is_verified'] = (bool)$shop['is_verified'];
        if ($shop['verified_at']) {
            $shop['verified_at'] = date('c', strtotime($shop['verified_at']));
        }
    }

    if ($updatedSince) {
        echo json_encode($shops);
    } else {
        echo json_encode([
            'data' => $shops,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'has_more' => ($offset + count($shops)) < $total
            ]
        ]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
