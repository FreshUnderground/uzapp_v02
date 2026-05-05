<?php
require_once '../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            throw new Exception('Invalid JSON input');
        }

        // Stories are usually only created
        $keys = array_keys($input);
        $values = array_values($input);
        $placeholders = array_fill(0, count($keys), '?');
        $stmt = $db->prepare("INSERT INTO stories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
        $stmt->execute($values);
        $newId = $db->lastInsertId();
        echo json_encode(['success' => true, 'id' => $newId, 'action' => 'CREATE']);
        exit;
    }

    // GET Logic
    $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;
    $createdAfter = isset($_GET['created_after']) ? $_GET['created_after'] : null;
    $isSyncMode = $updatedSince || $createdAfter;

    if ($isSyncMode) {
        $query = "SELECT s.*, sh.name AS shop_name FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id";
        $params = [];
        if ($updatedSince) {
            $query .= " WHERE s.created_at > ?";
            $params[] = $updatedSince;
        } elseif ($createdAfter) {
            $query .= " WHERE s.created_at > ?";
            $params[] = $createdAfter;
        }
        $query .= " ORDER BY s.created_at DESC";
        $stmt = $db->prepare($query);
        $stmt->execute($params);
        $stories = $stmt->fetchAll();
    } else {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $perPage = min(max(1, (int)($_GET['per_page'] ?? 20)), 100);
        $offset = ($page - 1) * $perPage;

        $countStmt = $db->prepare("SELECT COUNT(*) as total FROM stories");
        $countStmt->execute();
        $total = (int)$countStmt->fetch()['total'];

        $query = "SELECT s.*, sh.name AS shop_name FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id ORDER BY s.created_at DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$perPage, $offset]);
        $stories = $stmt->fetchAll();
    }

    foreach ($stories as &$story) {
        $story['id'] = (int)$story['id'];
        $story['shop_id'] = (int)$story['shop_id'];
    }

    if ($isSyncMode) {
        echo json_encode($stories);
    } else {
        echo json_encode([
            'data' => $stories,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'has_more' => ($offset + count($stories)) < $total
            ]
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
