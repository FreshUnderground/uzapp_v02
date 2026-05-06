<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            throw new Exception('Invalid JSON input');
        }

        $id = isset($input['id']) ? $input['id'] : null;

        $exists = false;
        if ($id) {
            $stmt = $db->prepare("SELECT id FROM categories WHERE id = ?");
            $stmt->execute([$id]);
            $exists = $stmt->fetch();
        }

        if ($exists) {
            // UPDATE
            $fields = [];
            $params = [];
            foreach ($input as $key => $value) {
                if ($key !== 'id') {
                    $fields[] = "`$key` = ?";
                    $params[] = $value;
                }
            }
            $params[] = $id;
            $stmt = $db->prepare("UPDATE categories SET " . implode(', ', $fields) . " WHERE id = ?");
            $stmt->execute($params);
            echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);
        } else {
            // INSERT
            $keys = array_keys($input);
            $values = array_values($input);
            $placeholders = array_fill(0, count($keys), '?');
            $stmt = $db->prepare("INSERT INTO categories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
            $stmt->execute($values);
            $newId = $db->lastInsertId();
            echo json_encode(['success' => true, 'id' => $id ? $id : $newId, 'action' => 'CREATE']);
        }
        exit;
    }

    // GET Logic
    $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;

    if ($updatedSince) {
        $query = "SELECT * FROM categories WHERE updated_at > ? ORDER BY id DESC";
        $stmt = $db->prepare($query);
        $stmt->execute([$updatedSince]);
        $categories = $stmt->fetchAll();
    } else {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $perPage = min(max(1, (int)($_GET['per_page'] ?? 100)), 200);
        $offset = ($page - 1) * $perPage;

        $countStmt = $db->prepare("SELECT COUNT(*) as total FROM categories");
        $countStmt->execute();
        $total = (int)$countStmt->fetch()['total'];

        $query = "SELECT * FROM categories ORDER BY id DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$perPage, $offset]);
        $categories = $stmt->fetchAll();
    }

    foreach ($categories as &$category) {
        $category['id'] = (int)$category['id'];
    }

    if ($updatedSince) {
        echo json_encode($categories);
    } else {
        echo json_encode([
            'data' => $categories,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'has_more' => ($offset + count($categories)) < $total
            ]
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
