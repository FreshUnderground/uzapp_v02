<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

// Allowed columns for stories to prevent SQL errors from unknown fields
$ALLOWED_STORY_COLUMNS = ['id', 'shop_id', 'media_url', 'media_type', 'is_arrivage', 'expires_at', 'created_at'];

try {
    $db = DB::getInstance();

    // DELETE: Remove a story and its media items
    if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        $rawInput = file_get_contents('php://input');
        $input = json_decode($rawInput, true);
        
        if (!$input) {
            error_log("Stories DELETE: Invalid JSON input");
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid JSON input']);
            exit;
        }

        $id = isset($input['id']) ? $input['id'] : null;

        if (!$id) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Story id is required']);
            exit;
        }

        // Delete story_media first, then the story
        $mediaStmt = $db->prepare("DELETE FROM story_media WHERE story_id = ?");
        $mediaStmt->execute([$id]);
        
        $storyStmt = $db->prepare("DELETE FROM stories WHERE id = ?");
        $storyStmt->execute([$id]);
        
        error_log("Stories DELETE success: id=$id");
        echo json_encode(['success' => true, 'action' => 'DELETE', 'id' => $id]);
        exit;
    }

    // Log incoming POST for debugging
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $rawInput = file_get_contents('php://input');
        error_log("Stories POST raw: " . $rawInput);
        $input = json_decode($rawInput, true);
        if (!$input) {
            error_log("Stories POST: Invalid JSON input");
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid JSON input']);
            exit;
        }

        // Extract media items if provided (not a column in stories table)
        $mediaItems = [];
        if (isset($input['media']) && is_array($input['media'])) {
            $mediaItems = $input['media'];
            unset($input['media']);
        }

        // Filter to only allowed columns
        $filteredInput = array_intersect_key($input, array_flip($ALLOWED_STORY_COLUMNS));

        if (empty($filteredInput)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'No valid story data provided']);
            exit;
        }

        $id = isset($filteredInput['id']) ? $filteredInput['id'] : null;

        // Check if story exists (for UPDATE)
        $exists = false;
        if ($id) {
            $stmt = $db->prepare("SELECT id FROM stories WHERE id = ?");
            $stmt->execute([$id]);
            $exists = (bool)$stmt->fetch();
        }

        if ($exists) {
            // UPDATE existing story
            $fields = []; $params = [];
            foreach ($filteredInput as $key => $value) {
                if ($key !== 'id') {
                    $fields[] = "`$key` = ?";
                    $params[] = $value;
                }
            }
            if (!empty($fields)) {
                $params[] = $id;
                $stmt = $db->prepare("UPDATE stories SET " . implode(', ', $fields) . " WHERE id = ?");
                $stmt->execute($params);
            }
            echo json_encode(['success' => true, 'id' => (int)$id, 'action' => 'UPDATE']);
            exit;
        }

        // INSERT new story — remove client-provided id so server auto-assigns
        unset($filteredInput['id']);
        if (!isset($filteredInput['created_at'])) {
            $filteredInput['created_at'] = date('Y-m-d H:i:s');
        }
        $keys = array_keys($filteredInput);
        $values = array_values($filteredInput);
        $placeholders = array_fill(0, count($keys), '?');
        error_log("Stories INSERT: keys=" . implode(',', $keys) . " values=" . json_encode($values));
        $stmt = $db->prepare("INSERT INTO stories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
        $stmt->execute($values);
        $newId = $db->lastInsertId();
        
        // Set remote_id to match the new story id for sync consistency
        $stmt = $db->prepare("UPDATE stories SET remote_id = ? WHERE id = ?");
        $stmt->execute([$newId, $newId]);
        
        error_log("Stories INSERT success: newId=$newId");

        // Insert story_media items if provided
        $insertedMediaCount = 0;
        foreach ($mediaItems as $i => $media) {
            $mediaStmt = $db->prepare("INSERT INTO story_media (story_id, media_url, media_type, sort_order) VALUES (?, ?, ?, ?)");
            $mediaStmt->execute([
                $newId,
                $media['media_url'] ?? '',
                $media['media_type'] ?? 'image',
                $media['sort_order'] ?? $i,
            ]);
            $insertedMediaCount++;
        }

        // ── Send push notifications to followers of this shop ──
        $pushResults = [];
        try {
            $shopId = isset($filteredInput['shop_id']) ? (int)$filteredInput['shop_id'] : null;
            if ($shopId) {
                // Get shop name
                $shopStmt = $db->prepare("SELECT name FROM shops WHERE id = ?");
                $shopStmt->execute([$shopId]);
                $shop = $shopStmt->fetch();
                $shopName = $shop ? $shop['name'] : 'Une boutique';

                // Find tokens for users who follow this shop
                // (followed_shops links user -> shop; we look up fcm_tokens by user_id)
                $tokenStmt = $db->prepare("
                    SELECT ft.token 
                    FROM fcm_tokens ft
                    INNER JOIN followed_shops fs ON fs.user_id = ft.user_id
                    WHERE fs.shop_id = ?
                ");
                $tokenStmt->execute([$shopId]);
                $tokens = $tokenStmt->fetchAll(PDO::FETCH_COLUMN);

                if (!empty($tokens) && defined('FCM_SERVER_KEY') && !empty(FCM_SERVER_KEY)) {
                    foreach ($tokens as $token) {
                        $result = sendFcmToToken($token, $shopName, $newId);
                        $pushResults[] = $result;
                    }
                }
            }
        } catch (Exception $pushEx) {
            // Non-fatal: don't fail story creation if push fails
            $pushResults[] = ['error' => $pushEx->getMessage()];
        }

        echo json_encode([
            'success' => true,
            'id' => (int)$newId,
            'action' => 'CREATE',
            'media_count' => $insertedMediaCount,
            'push_sent' => count($pushResults),
        ]);
        exit;
    }

    // GET Logic
    $updatedSince = isset($_GET['updated_since']) ? $_GET['updated_since'] : null;
    $createdAfter = isset($_GET['created_after']) ? $_GET['created_after'] : null;
    $includeMedia = isset($_GET['include_media']) && $_GET['include_media'] === '1';
    $isSyncMode = $updatedSince || $createdAfter;
    
    // ALWAYS include media in sync mode to support multi-media stories
    if ($isSyncMode) {
        $includeMedia = true;
    }

    // Clean up expired stories before fetching (server-side cleanup)
    try {
        $deleteStmt = $db->prepare("DELETE FROM stories WHERE expires_at < NOW()");
        $deleteStmt->execute();
        $deletedCount = $deleteStmt->rowCount();
        if ($deletedCount > 0) {
            error_log("Cleaned up $deletedCount expired stories");
        }
    } catch (PDOException $e) {
        error_log("Story cleanup error: " . $e->getMessage());
    }

    if ($isSyncMode) {
        // For sync mode, ALWAYS return non-expired stories (ignore updated_since filter)
        // Stories have short lifespans, so we need all active ones for proper sync
        $query = "SELECT s.*, sh.name AS shop_name, sh.owner_id AS owner_id FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id WHERE s.expires_at > NOW() ORDER BY s.created_at DESC";
        $params = [];
        $stmt = $db->prepare($query);
        $stmt->execute($params);
        $stories = $stmt->fetchAll();
    } else {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $perPage = min(max(1, (int)($_GET['per_page'] ?? 20)), 100);
        $offset = ($page - 1) * $perPage;

        $countStmt = $db->prepare("SELECT COUNT(*) as total FROM stories WHERE expires_at > NOW()");
        $countStmt->execute();
        $total = (int)$countStmt->fetch()['total'];

        $query = "SELECT s.*, sh.name AS shop_name, sh.owner_id AS owner_id FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id WHERE s.expires_at > NOW() ORDER BY s.id DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$perPage, $offset]);
        $stories = $stmt->fetchAll();
    }

    foreach ($stories as &$story) {
        $story['id'] = (int)$story['id'];
        $story['shop_id'] = (int)$story['shop_id'];
        
        // Include remote_id for sync (use id if remote_id is null)
        $story['remote_id'] = $story['remote_id'] ?? $story['id'];

        // Attach story_media items if requested
        if ($includeMedia) {
            $mediaStmt = $db->prepare("SELECT * FROM story_media WHERE story_id = ? ORDER BY sort_order ASC");
            $mediaStmt->execute([$story['id']]);
            $mediaRows = $mediaStmt->fetchAll();
            foreach ($mediaRows as &$m) {
                $m['id'] = (int)$m['id'];
                $m['story_id'] = (int)$m['story_id'];
                $m['sort_order'] = (int)$m['sort_order'];
            }
            unset($m);
            $story['media_items'] = $mediaRows;
        }
    }
    unset($story);

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
} catch (PDOException $e) {
    error_log("Stories DB error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    error_log("Stories error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

/**
 * Send FCM push notification to a single device token.
 *
 * @param string $token   FCM device token
 * @param string $shopName Name of the shop that posted the story
 * @param int    $storyId  ID of the newly created story
 * @return array ['success' => bool, 'response' => mixed]
 */
function sendFcmToToken($token, $shopName, $storyId) {
    if (!defined('FCM_SERVER_KEY') || empty(FCM_SERVER_KEY)) {
        return ['success' => false, 'response' => 'FCM_SERVER_KEY not configured'];
    }

    $payload = [
        'to' => $token,
        'notification' => [
            'title' => 'Nouveaux arrivages!',
            'body'  => $shopName . ' a publie un nouvel arrivage sur UzaApp!',
            'sound' => 'default',
        ],
        'data' => [
            'type' => 'arrivage',
            'id'   => (int)$storyId,
        ],
        'priority' => 'high',
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

    if ($httpCode === 200) {
        $decoded = json_decode($response, true);
        $success = isset($decoded['success']) && $decoded['success'] === 1;
        return ['success' => $success, 'response' => $decoded];
    }

    return ['success' => false, 'response' => ['http_code' => $httpCode, 'raw' => $response]];
}
?>
