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

        // Extract media items if provided
        $mediaItems = [];
        if (isset($input['media']) && is_array($input['media'])) {
            $mediaItems = $input['media'];
            unset($input['media']);
        }

        // Insert the story
        $keys = array_keys($input);
        $values = array_values($input);
        $placeholders = array_fill(0, count($keys), '?');
        $stmt = $db->prepare("INSERT INTO stories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
        $stmt->execute($values);
        $newId = $db->lastInsertId();

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
            $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
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

    if ($isSyncMode) {
        $query = "SELECT s.*, sh.name AS shop_name FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id";
        $params = [];
        if ($updatedSince) {
            $query .= " WHERE s.id > ?";
            $params[] = $updatedSince;
        } elseif ($createdAfter) {
            $query .= " WHERE s.id > ?";
            $params[] = $createdAfter;
        }
        $query .= " ORDER BY s.id DESC";
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

        $query = "SELECT s.*, sh.name AS shop_name FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id ORDER BY s.id DESC LIMIT ? OFFSET ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$perPage, $offset]);
        $stories = $stmt->fetchAll();
    }

    foreach ($stories as &$story) {
        $story['id'] = (int)$story['id'];
        $story['shop_id'] = (int)$story['shop_id'];

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
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
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
