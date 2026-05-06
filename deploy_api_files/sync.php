<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || !isset($input['entityType'], $input['action'], $input['data'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid input']);
        exit;
    }

    $entityType = $input['entityType'];
    $action = $input['action'];
    $data = $input['data'];

    // Basic sync logic: handle 'shops', 'products', 'stories'
    // This is a simplified version. A production version would need better validation and security.

    if ($entityType === 'users') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
             $phone = isset($data['phone']) ? $data['phone'] : null;
             if (!$phone) throw new Exception('Phone number required for users sync');

             $stmt = $db->prepare("SELECT id FROM users WHERE phone = ?");
             $stmt->execute([$phone]);
             $exists = $stmt->fetch();

             if ($exists) {
                 // UPDATE
                 $fields = []; $params = [];
                 foreach ($data as $key => $value) {
                     if ($key !== 'id' && $key !== 'phone') {
                         $fields[] = "`$key` = ?"; $params[] = $value;
                     }
                 }
                 if (!empty($fields)) {
                     $params[] = $phone;
                     $stmt = $db->prepare("UPDATE users SET " . implode(', ', $fields) . " WHERE phone = ?");
                     $stmt->execute($params);
                 }
             } else {
                 // INSERT
                 $keys = array_keys($data); $values = array_values($data);
                 $placeholders = array_fill(0, count($keys), '?');
                 $stmt = $db->prepare("INSERT INTO users (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                 $stmt->execute($values);
             }
        }
    } else if ($entityType === 'shops') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
             $id = isset($data['id']) ? $data['id'] : null;
             $ownerId = isset($data['owner_id']) ? $data['owner_id'] : null;

             // Validation
             if (empty($data['name'])) {
                 http_response_code(400);
                 echo json_encode(['success' => false, 'error' => 'Shop name is required']);
                 exit;
             }

             // Add updated_at timestamp
             $data['updated_at'] = date('Y-m-d H:i:s');

             // Check if shop exists by ID
             $stmt = $db->prepare("SELECT id FROM shops WHERE id = ?");
             $stmt->execute([$id]);
             $existsById = $stmt->fetch();

             // Also check by owner_id for upsert
             $existsByOwner = null;
             if (!$existsById && $ownerId) {
                 $stmt = $db->prepare("SELECT id FROM shops WHERE owner_id = ?");
                 $stmt->execute([$ownerId]);
                 $existsByOwner = $stmt->fetch();
             }

             if ($existsById) {
                 // UPDATE by ID
                 $fields = []; $params = [];
                 foreach ($data as $key => $value) {
                     if ($key !== 'id') {
                         $fields[] = "`$key` = ?"; $params[] = $value;
                     }
                 }
                 $params[] = $id;
                 $stmt = $db->prepare("UPDATE shops SET " . implode(', ', $fields) . " WHERE id = ?");
                 $stmt->execute($params);
                 echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);
                 exit;
             } else if ($existsByOwner) {
                 // UPSERT: owner already has a shop — update it instead
                 $existingId = $existsByOwner['id'];
                 $fields = []; $params = [];
                 foreach ($data as $key => $value) {
                     if ($key !== 'id') {
                         $fields[] = "`$key` = ?"; $params[] = $value;
                     }
                 }
                 $params[] = $existingId;
                 $stmt = $db->prepare("UPDATE shops SET " . implode(', ', $fields) . " WHERE id = ?");
                 $stmt->execute($params);
                 echo json_encode(['success' => true, 'id' => $existingId, 'action' => 'UPDATE']);
                 exit;
             } else {
                 // INSERT — ensure created_at is set
                 if (!isset($data['created_at'])) {
                     $data['created_at'] = date('Y-m-d H:i:s');
                 }
                 $keys = array_keys($data); $values = array_values($data);
                 $placeholders = array_fill(0, count($keys), '?');
                 $stmt = $db->prepare("INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                 $stmt->execute($values);
                 $newId = $db->lastInsertId();
                 echo json_encode(['success' => true, 'id' => $id ? $id : $newId, 'action' => 'CREATE']);
                 exit;
             }
        }
    } else if ($entityType === 'products') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
             $id = isset($data['id']) ? $data['id'] : null;

             // Validation
             if (empty($data['name'])) {
                 http_response_code(400);
                 echo json_encode(['success' => false, 'error' => 'Product name is required']);
                 exit;
             }
             if (empty($data['shop_id'])) {
                 http_response_code(400);
                 echo json_encode(['success' => false, 'error' => 'shop_id is required']);
                 exit;
             }

             // Add updated_at timestamp
             $data['updated_at'] = date('Y-m-d H:i:s');

             $stmt = $db->prepare("SELECT id FROM products WHERE id = ?");
             $stmt->execute([$id]);
             $exists = $stmt->fetch();

             if ($exists) {
                 $fields = [];
                 $params = [];
                 foreach ($data as $key => $value) {
                     if ($key !== 'id') {
                         $fields[] = "`$key` = ?";
                         $params[] = $value;
                     }
                 }
                 $params[] = $id;
                 $stmt = $db->prepare("UPDATE products SET " . implode(', ', $fields) . " WHERE id = ?");
                 $stmt->execute($params);
                 echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);
                 exit;
             } else {
                 // INSERT — ensure created_at is set
                 if (!isset($data['created_at'])) {
                     $data['created_at'] = date('Y-m-d H:i:s');
                 }
                 $keys = array_keys($data);
                 $values = array_values($data);
                 $placeholders = array_fill(0, count($keys), '?');
                 $stmt = $db->prepare("INSERT INTO products (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                 $stmt->execute($values);
                 $newId = $db->lastInsertId();
                 echo json_encode(['success' => true, 'id' => $id ? $id : $newId, 'action' => 'CREATE']);
                 exit;
             }
        } else if ($action === 'DELETE') {
            $id = isset($data['id']) ? $data['id'] : null;
            if ($id) {
                $stmt = $db->prepare("DELETE FROM products WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true, 'action' => 'DELETE']);
                exit;
            }
        } else if ($action === 'INCREMENT_STAT') {
            $id = isset($data['id']) ? (int)$data['id'] : null;
            $type = isset($data['type']) ? $data['type'] : null; // 'view', 'share', 'rate'
            
            if ($id && $type) {
                if ($type === 'view') {
                    $stmt = $db->prepare("UPDATE products SET views_count = views_count + 1 WHERE id = ?");
                    $stmt->execute([$id]);
                } else if ($type === 'share') {
                    $stmt = $db->prepare("UPDATE products SET shares_count = shares_count + 1 WHERE id = ?");
                    $stmt->execute([$id]);
                } else if ($type === 'rate') {
                    $rating = isset($data['rating']) ? (double)$data['rating'] : 0;
                    if ($rating > 0) {
                       $stmt = $db->prepare("UPDATE products SET 
                            rating_avg = (rating_avg * ratings_count + ?) / (ratings_count + 1),
                            ratings_count = ratings_count + 1 
                            WHERE id = ?");
                       $stmt->execute([$rating, $id]);
                    }
                }
            }
        }
    } else if ($entityType === 'stories') {
        // Similar logic for stories...
        if ($action === 'CREATE') {
             $keys = array_keys($data);
             $values = array_values($data);
             $placeholders = array_fill(0, count($keys), '?');
             $stmt = $db->prepare("INSERT INTO stories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
             $stmt->execute($values);
        }
    }

    echo json_encode(['success' => true]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
