<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

// Allowed columns per entity type to prevent SQL errors from unknown fields
$ALLOWED_COLUMNS = [
    'users'    => ['id', 'phone', 'name', 'email', 'role', 'firebase_uid', 'avatar_url', 'created_at', 'updated_at'],
    'shops'    => ['id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 'whatsapp', 'phone', 'email',
                   'instagram_url', 'tiktok_url', 'facebook_url', 'youtube_url', 'banner_url', 'boost_status',
                   'banner_status', 'banner_text', 'video_url', 'is_boosted', 'is_verified', 'verified_at',
                   'created_at', 'updated_at'],
    'products' => ['id', 'shop_id', 'category_id', 'name', 'description', 'price', 'image_urls',
                   'is_arrival', 'is_promotion', 'boost_status', 'hide_price', 'show_stock', 'stock_count',
                   'views_count', 'shares_count', 'ratings_count', 'rating_avg', 'created_at', 'updated_at'],
    'stories'  => ['id', 'shop_id', 'media_url', 'media_type', 'is_arrivage', 'expires_at', 'created_at'],
];

/**
 * Filter $data to only include keys present in the allowed list for $entityType.
 * Returns the filtered associative array.
 */
function filterColumns(array $data, string $entityType, array $allowedMap): array {
    if (!isset($allowedMap[$entityType])) return $data;
    $allowed = $allowedMap[$entityType];
    return array_intersect_key($data, array_flip($allowed));
}

try {
    $db = DB::getInstance();
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);

    if (!$input || !isset($input['entityType'], $input['action'], $input['data'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid input: entityType, action, and data are required']);
        exit;
    }

    $entityType = $input['entityType'];
    $action = $input['action'];
    $data = $input['data'];

    error_log("Sync request: entityType=$entityType action=$action data=" . json_encode($data));

    if (!is_array($data)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'data must be an object']);
        exit;
    }

    // ── USERS ────────────────────────────────────────────────────────────────
    if ($entityType === 'users') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
             $phone = isset($data['phone']) ? $data['phone'] : null;
             if (!$phone) {
                 http_response_code(400);
                 echo json_encode(['success' => false, 'error' => 'Phone number required for users sync']);
                 exit;
             }

             $data = filterColumns($data, 'users', $ALLOWED_COLUMNS);

             $stmt = $db->prepare("SELECT id FROM users WHERE phone = ?");
             $stmt->execute([$phone]);
             $exists = $stmt->fetch();

             if ($exists) {
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
                 echo json_encode(['success' => true, 'id' => $exists['id'], 'action' => 'UPDATE']);
                 exit;
             } else {
                 $keys = array_keys($data); $values = array_values($data);
                 $placeholders = array_fill(0, count($keys), '?');
                 $stmt = $db->prepare("INSERT INTO users (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                 $stmt->execute($values);
                 $newId = $db->lastInsertId();
                 echo json_encode(['success' => true, 'id' => $newId, 'action' => 'CREATE']);
                 exit;
             }
        }

    // ── SHOPS ────────────────────────────────────────────────────────────────
    } else if ($entityType === 'shops') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
             $id = isset($data['id']) ? $data['id'] : null;
             $ownerId = isset($data['owner_id']) ? $data['owner_id'] : null;

             if (empty($data['name'])) {
                 http_response_code(400);
                 echo json_encode(['success' => false, 'error' => 'Shop name is required']);
                 exit;
             }

             $data = filterColumns($data, 'shops', $ALLOWED_COLUMNS);

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
                 if (!isset($data['created_at'])) {
                     $data['created_at'] = date('Y-m-d H:i:s');
                 }
                 $keys = array_keys($data); $values = array_values($data);
                 $placeholders = array_fill(0, count($keys), '?');
                 $stmt = $db->prepare("INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                 $stmt->execute($values);
                 $newId = $db->lastInsertId();
                 echo json_encode(['success' => true, 'id' => $newId, 'action' => 'CREATE']);
                 exit;
             }
        }

    // ── PRODUCTS ─────────────────────────────────────────────────────────────
    } else if ($entityType === 'products') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
             $id = isset($data['id']) ? $data['id'] : null;

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

             $data = filterColumns($data, 'products', $ALLOWED_COLUMNS);

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
                 if (!isset($data['created_at'])) {
                     $data['created_at'] = date('Y-m-d H:i:s');
                 }
                 $keys = array_keys($data);
                 $values = array_values($data);
                 $placeholders = array_fill(0, count($keys), '?');
                 $stmt = $db->prepare("INSERT INTO products (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                 $stmt->execute($values);
                 $newId = $db->lastInsertId();
                 echo json_encode(['success' => true, 'id' => $newId, 'action' => 'CREATE']);
                 exit;
             }
        } else if ($action === 'DELETE') {
            $id = isset($data['id']) ? $data['id'] : null;
            if ($id) {
                $stmt = $db->prepare("DELETE FROM products WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true, 'id' => $id, 'action' => 'DELETE']);
                exit;
            } else {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Product id required for DELETE']);
                exit;
            }
        } else if ($action === 'INCREMENT_STAT') {
            $id = isset($data['id']) ? (int)$data['id'] : null;
            $type = isset($data['type']) ? $data['type'] : null;

            if (!$id || !$type) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'id and type are required for INCREMENT_STAT']);
                exit;
            }

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
            echo json_encode(['success' => true, 'id' => $id, 'action' => 'INCREMENT_STAT', 'type' => $type]);
            exit;
        }

    // ── STORIES ──────────────────────────────────────────────────────────────
    } else if ($entityType === 'stories') {
        if ($action === 'CREATE' || $action === 'UPDATE') {
            $data = filterColumns($data, 'stories', $ALLOWED_COLUMNS);

            if (empty($data['media_url'])) {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'media_url is required for stories']);
                exit;
            }

            $id = isset($data['id']) ? $data['id'] : null;

            // Check if story exists (for UPDATE)
            $exists = false;
            if ($id) {
                $stmt = $db->prepare("SELECT id FROM stories WHERE id = ?");
                $stmt->execute([$id]);
                $exists = (bool)$stmt->fetch();
            }

            if ($exists && $action === 'UPDATE') {
                // UPDATE existing story
                $fields = []; $params = [];
                foreach ($data as $key => $value) {
                    if ($key !== 'id') {
                        $fields[] = "`$key` = ?"; $params[] = $value;
                    }
                }
                if (!empty($fields)) {
                    $params[] = $id;
                    $stmt = $db->prepare("UPDATE stories SET " . implode(', ', $fields) . " WHERE id = ?");
                    $stmt->execute($params);
                }
                error_log("Sync stories UPDATE: id=$id");
                echo json_encode(['success' => true, 'id' => $id, 'action' => 'UPDATE']);
                exit;
            } else {
                // INSERT new story — remove client-provided id so server auto-assigns
                unset($data['id']);
                // NOTE: stories table has NO updated_at column; only set created_at
                if (!isset($data['created_at'])) {
                    $data['created_at'] = date('Y-m-d H:i:s');
                }
                $keys = array_keys($data);
                $values = array_values($data);
                $placeholders = array_fill(0, count($keys), '?');
                error_log("Sync stories INSERT: keys=" . implode(',', $keys) . " values=" . json_encode($values));
                $stmt = $db->prepare("INSERT INTO stories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
                $stmt->execute($values);
                $newId = $db->lastInsertId();
                error_log("Sync stories INSERT success: newId=$newId");
                echo json_encode(['success' => true, 'id' => (int)$newId, 'action' => 'CREATE']);
                exit;
            }
        } else if ($action === 'DELETE') {
            $id = isset($data['id']) ? $data['id'] : null;
            if ($id) {
                $stmt = $db->prepare("DELETE FROM stories WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true, 'id' => $id, 'action' => 'DELETE']);
                exit;
            } else {
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Story id required for DELETE']);
                exit;
            }
        }

    // ── UNKNOWN ENTITY ───────────────────────────────────────────────────────
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => "Unknown entityType: $entityType"]);
        exit;
    }

    // If we reach here, the action wasn't handled
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => "Unhandled action '$action' for entityType '$entityType'"]);

} catch (PDOException $e) {
    error_log("Sync DB error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    error_log("Sync error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
