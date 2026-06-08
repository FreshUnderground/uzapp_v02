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

        // Find-or-create: deduplicate user-contributed categories under a parent
        if (isset($input['action']) && $input['action'] === 'find_or_create') {
            $name = isset($input['name']) ? trim($input['name']) : '';
            $parentId = isset($input['parent_id']) ? (int)$input['parent_id'] : null;
            $level = isset($input['level']) ? (int)$input['level'] : 1;
            $remoteId = isset($input['remote_id']) ? trim($input['remote_id']) : null;

            if ($name === '') {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Category name is required']);
                exit;
            }
            if ($parentId === null) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'parent_id is required']);
                exit;
            }

            $stmt = $db->prepare(
                "SELECT * FROM categories WHERE parent_id = ? AND LOWER(TRIM(name)) = LOWER(?) LIMIT 1"
            );
            $stmt->execute([$parentId, $name]);
            $existing = $stmt->fetch();

            if ($existing) {
                echo json_encode([
                    'success' => true,
                    'action' => 'FOUND',
                    'category' => [
                        'id' => (int)$existing['id'],
                        'name' => $existing['name'],
                        'icon' => $existing['icon'],
                        'parent_id' => $existing['parent_id'] !== null ? (int)$existing['parent_id'] : null,
                        'level' => isset($existing['level']) ? (int)$existing['level'] : $level,
                        'sort_order' => isset($existing['sort_order']) ? (int)$existing['sort_order'] : 0,
                        'remote_id' => $existing['remote_id'],
                        'updated_at' => $existing['updated_at'],
                    ],
                ]);
                exit;
            }

            if (!$remoteId) {
                $remoteId = sprintf(
                    '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                    mt_rand(0, 0xffff), mt_rand(0, 0xffff),
                    mt_rand(0, 0xffff),
                    mt_rand(0, 0x0fff) | 0x4000,
                    mt_rand(0, 0x3fff) | 0x8000,
                    mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
                );
            }

            $stmt = $db->prepare(
                "INSERT INTO categories (name, icon, parent_id, level, sort_order, remote_id) VALUES (?, ?, ?, ?, 0, ?)"
            );
            $stmt->execute([$name, '', $parentId, $level, $remoteId]);
            $newId = (int)$db->lastInsertId();

            $stmt = $db->prepare("SELECT * FROM categories WHERE id = ?");
            $stmt->execute([$newId]);
            $created = $stmt->fetch();

            echo json_encode([
                'success' => true,
                'action' => 'CREATE',
                'category' => [
                    'id' => $newId,
                    'name' => $created['name'],
                    'icon' => $created['icon'],
                    'parent_id' => $created['parent_id'] !== null ? (int)$created['parent_id'] : null,
                    'level' => isset($created['level']) ? (int)$created['level'] : $level,
                    'sort_order' => isset($created['sort_order']) ? (int)$created['sort_order'] : 0,
                    'remote_id' => $created['remote_id'],
                    'updated_at' => $created['updated_at'],
                ],
            ]);
            exit;
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
    $tree = isset($_GET['tree']) && $_GET['tree'] == '1';
    $parentId = isset($_GET['parent_id']) ? (int)$_GET['parent_id'] : null;
    $level = isset($_GET['level']) ? (int)$_GET['level'] : null;

    $buildCategoryTree = function (array $categories, ?int $parentId = null) use (&$buildCategoryTree) {
        $tree = [];
        foreach ($categories as $category) {
            $catParentId = $category['parent_id'] !== null ? (int)$category['parent_id'] : null;
            if ($catParentId === $parentId) {
                $children = $buildCategoryTree($categories, $category['id']);
                if (!empty($children)) {
                    $category['children'] = $children;
                }
                $tree[] = $category;
            }
        }
        return $tree;
    };

    if ($tree) {
        $stmt = $db->prepare("SELECT * FROM categories ORDER BY sort_order ASC, name ASC");
        $stmt->execute();
        $allCategories = $stmt->fetchAll();

        foreach ($allCategories as &$category) {
            $category['id'] = (int)$category['id'];
            $category['level'] = isset($category['level']) ? (int)$category['level'] : 0;
            $category['sort_order'] = isset($category['sort_order']) ? (int)$category['sort_order'] : 0;
            $category['parent_id'] = $category['parent_id'] !== null ? (int)$category['parent_id'] : null;
        }

        $treeData = $buildCategoryTree($allCategories);
        echo json_encode(['success' => true, 'data' => $treeData]);
        exit;
    }

    $where = [];
    $params = [];
    if ($parentId !== null) {
        $where[] = "parent_id = ?";
        $params[] = $parentId;
    }
    if ($level !== null) {
        $where[] = "level = ?";
        $params[] = $level;
    }
    $whereClause = $where ? "WHERE " . implode(" AND ", $where) : "";

    if ($updatedSince) {
        $updatedWhere = $where ? $whereClause . " AND updated_at > ?" : "WHERE updated_at > ?";
        $updatedParams = array_merge($params, [$updatedSince]);
        $query = "SELECT * FROM categories $updatedWhere ORDER BY id DESC";
        $stmt = $db->prepare($query);
        $stmt->execute($updatedParams);
        $categories = $stmt->fetchAll();
    } else {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $perPage = min(max(1, (int)($_GET['per_page'] ?? 100)), 200);
        $offset = ($page - 1) * $perPage;

        $countStmt = $db->prepare("SELECT COUNT(*) as total FROM categories $whereClause");
        $countStmt->execute($params);
        $total = (int)$countStmt->fetch()['total'];

        $query = "SELECT * FROM categories $whereClause ORDER BY id DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute(array_merge($params, [$perPage, $offset]));
        $categories = $stmt->fetchAll();
    }

    foreach ($categories as &$category) {
        $category['id'] = (int)$category['id'];
        $category['level'] = isset($category['level']) ? (int)$category['level'] : 0;
        $category['sort_order'] = isset($category['sort_order']) ? (int)$category['sort_order'] : 0;
        $category['parent_id'] = $category['parent_id'] !== null ? (int)$category['parent_id'] : null;
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
