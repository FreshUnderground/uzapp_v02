<?php
require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/media_lib.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();

    if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        $input = json_decode(file_get_contents('php://input'), true);
        $id = isset($input['id']) ? $input['id'] : null;

        if (!$id) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Product id is required']);
            exit;
        }

        $mediaUrls = [];
        $urlStmt = $db->prepare('SELECT image_urls FROM products WHERE id = ?');
        $urlStmt->execute([$id]);
        $row = $urlStmt->fetch(PDO::FETCH_ASSOC);
        if ($row && !empty($row['image_urls'])) {
            foreach (explode(',', $row['image_urls']) as $part) {
                $u = trim($part);
                if ($u !== '') {
                    $mediaUrls[] = $u;
                }
            }
        }

        $stmt = $db->prepare("DELETE FROM products WHERE id = ?");
        $stmt->execute([$id]);
        if (!empty($mediaUrls)) {
            uza_safe_unlink_uploads($db, $mediaUrls);
        }
        echo json_encode(['success' => true, 'action' => 'DELETE', 'id' => $id]);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid JSON input']);
            exit;
        }

        $id = isset($input['id']) ? $input['id'] : null;

        // --- Validation ---
        if (empty($input['name'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Product name is required']);
            exit;
        }
        if (empty($input['shop_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'shop_id is required']);
            exit;
        }
        if (!isset($input['price'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Price is required']);
            exit;
        }

        // Verify the referenced shop exists
        $shopId = $input['shop_id'];
        $stmt = $db->prepare("SELECT id FROM shops WHERE id = ?");
        $stmt->execute([$shopId]);
        if (!$stmt->fetch()) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Referenced shop_id does not exist']);
            exit;
        }

        // --- Determine upsert target ---
        $exists = false;
        if ($id) {
            $stmt = $db->prepare("SELECT id FROM products WHERE id = ?");
            $stmt->execute([$id]);
            $exists = $stmt->fetch();
        }

        // Add updated_at timestamp
        $input['updated_at'] = date('Y-m-d H:i:s');

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
            $stmt = $db->prepare("UPDATE products SET " . implode(', ', $fields) . " WHERE id = ?");
            $stmt->execute($params);
            echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);
        } else {
            // INSERT — no created_at column in products table; MySQL handles updated_at via DEFAULT
            $keys = array_keys($input);
            $values = array_values($input);
            $placeholders = array_fill(0, count($keys), '?');
            $stmt = $db->prepare("INSERT INTO products (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
            $stmt->execute($values);
            $newId = $db->lastInsertId();
            echo json_encode(['success' => true, 'id' => $id ? $id : $newId, 'action' => 'CREATE']);
        }
        exit;
    }

    // GET Logic — only products linked to an existing shop
    $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;
    $shopJoin = 'INNER JOIN shops s ON s.id = p.shop_id';
    $fromClause = "FROM products p $shopJoin";

    if ($updatedSince) {
        $query = "SELECT p.* $fromClause ORDER BY p.id DESC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $products = $stmt->fetchAll();
    } else {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $perPage = min(max(1, (int)($_GET['per_page'] ?? 20)), 100);
        $offset = ($page - 1) * $perPage;

        $countStmt = $db->prepare("SELECT COUNT(*) as total $fromClause");
        $countStmt->execute();
        $total = (int)$countStmt->fetch()['total'];

        $query = "SELECT p.* $fromClause ORDER BY p.id DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$perPage, $offset]);
        $products = $stmt->fetchAll();
    }

    foreach ($products as &$product) {
        $product['id'] = (int)$product['id'];
        $product['remote_id'] = $product['remote_id'] ?? $product['id'];
        $product['shop_id'] = (int)$product['shop_id'];
        $product['category_id'] = $product['category_id'] !== null ? (int)$product['category_id'] : null;
        $product['price'] = (double)$product['price'];
        $product['is_arrival'] = (bool)$product['is_arrival'];
        $product['is_promotion'] = (bool)$product['is_promotion'];
        $product['is_boosted'] = (bool)$product['is_boosted'];
        $product['hide_price'] = (bool)$product['hide_price'];
        $product['show_stock'] = (bool)$product['show_stock'];
        $product['stock_count'] = $product['stock_count'] !== null ? (int)$product['stock_count'] : null;
        $product['boost_status'] = (int)$product['boost_status'];
        $product['views_count'] = (int)$product['views_count'];
        $product['shares_count'] = (int)$product['shares_count'];
        $product['ratings_count'] = (int)$product['ratings_count'];
        $product['rating_avg'] = (double)$product['rating_avg'];
    }

    if ($updatedSince) {
        echo json_encode($products);
    } else {
        echo json_encode([
            'data' => $products,
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'has_more' => ($offset + count($products)) < $total
            ]
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
