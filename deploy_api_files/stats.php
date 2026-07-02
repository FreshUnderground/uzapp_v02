<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

function stats_shop_analytics_table_exists(PDO $db): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $stmt = $db->query("SHOW TABLES LIKE 'shop_analytics'");
        $exists = (bool)$stmt->fetch();
    } catch (Exception $e) {
        $exists = false;
    }
    return $exists;
}

function stats_allowed_shop_interactions(): array
{
    return [
        'view',
        'share',
        'catalog_share',
        'qr_share',
        'story_share',
        'whatsapp_status',
        'facebook_status',
        'tiktok_status',
    ];
}

function stats_shop_share_types_sql(): string
{
    $types = array_filter(
        stats_allowed_shop_interactions(),
        fn($t) => $t !== 'view'
    );
    return "'" . implode("','", $types) . "'";
}

function stats_record_shop_interaction(PDO $db, int $shopId, string $interactionType): bool
{
    if (!stats_shop_analytics_table_exists($db)) {
        return false;
    }
    if (!in_array($interactionType, stats_allowed_shop_interactions(), true)) {
        return false;
    }
    $stmt = $db->prepare(
        'INSERT INTO shop_analytics (shop_id, interaction_type, created_at) VALUES (?, ?, NOW())'
    );
    $stmt->execute([$shopId, $interactionType]);
    return true;
}

function stats_fetch_shop_engagement(PDO $db, int $shopId): array
{
    $result = ['shop_views' => 0, 'shop_shares' => 0];
    if (!stats_shop_analytics_table_exists($db)) {
        return $result;
    }

    $stmt = $db->prepare(
        "SELECT COUNT(*) AS cnt FROM shop_analytics WHERE shop_id = ? AND interaction_type = 'view'"
    );
    $stmt->execute([$shopId]);
    $result['shop_views'] = (int)$stmt->fetch()['cnt'];

    $shareTypes = stats_shop_share_types_sql();
    $stmt = $db->prepare(
        "SELECT COUNT(*) AS cnt FROM shop_analytics WHERE shop_id = ? AND interaction_type IN ($shareTypes)"
    );
    $stmt->execute([$shopId]);
    $result['shop_shares'] = (int)$stmt->fetch()['cnt'];

    return $result;
}

try {
    $db = DB::getInstance();

    // ── GET: Fetch aggregated stats for a shop ──────────────────────────────
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $shopId = isset($_GET['shop_id']) ? (int)$_GET['shop_id'] : null;
        if (!$shopId) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'shop_id is required']);
            exit;
        }

        // Verify shop exists
        $stmt = $db->prepare("SELECT id FROM shops WHERE id = ?");
        $stmt->execute([$shopId]);
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'error' => 'Shop not found']);
            exit;
        }

        // Product IDs for this shop
        $stmt = $db->prepare("SELECT id FROM products WHERE shop_id = ?");
        $stmt->execute([$shopId]);
        $productIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

        // Followers count
        $stmt = $db->prepare("SELECT COUNT(*) as cnt FROM shop_follows WHERE shop_id = ?");
        $stmt->execute([$shopId]);
        $followers = (int)$stmt->fetch()['cnt'];

        // Likes count across all products of this shop
        $totalLikes = 0;
        if (!empty($productIds)) {
            $placeholders = implode(',', array_fill(0, count($productIds), '?'));
            $stmt = $db->prepare("SELECT COUNT(*) as cnt FROM product_likes WHERE product_id IN ($placeholders)");
            $stmt->execute($productIds);
            $totalLikes = (int)$stmt->fetch()['cnt'];
        }

        // Contacts breakdown
        $stmt = $db->prepare("SELECT contact_type, COUNT(*) as cnt FROM user_contacts WHERE shop_id = ? GROUP BY contact_type");
        $stmt->execute([$shopId]);
        $contactRows = $stmt->fetchAll();
        $whatsappContacts = 0;
        $callContacts = 0;
        $smsContacts = 0;
        foreach ($contactRows as $row) {
            switch ($row['contact_type']) {
                case 'whatsapp': $whatsappContacts = (int)$row['cnt']; break;
                case 'call': $callContacts = (int)$row['cnt']; break;
                case 'sms': $smsContacts = (int)$row['cnt']; break;
            }
        }

        // Unique clients
        $stmt = $db->prepare("SELECT COUNT(DISTINCT user_phone) as cnt FROM user_contacts WHERE shop_id = ?");
        $stmt->execute([$shopId]);
        $uniqueClients = (int)$stmt->fetch()['cnt'];

        // Product views and shares from products table
        $totalViews = 0;
        $totalShares = 0;
        if (!empty($productIds)) {
            $placeholders = implode(',', array_fill(0, count($productIds), '?'));
            $stmt = $db->prepare("SELECT COALESCE(SUM(views_count),0) as views, COALESCE(SUM(shares_count),0) as shares FROM products WHERE id IN ($placeholders)");
            $stmt->execute($productIds);
            $row = $stmt->fetch();
            $totalViews = (int)$row['views'];
            $totalShares = (int)$row['shares'];
        }

        $shopEngagement = stats_fetch_shop_engagement($db, $shopId);

        echo json_encode([
            'success' => true,
            'stats' => [
                'followers' => $followers,
                'likes' => $totalLikes,
                'whatsapp_contacts' => $whatsappContacts,
                'call_contacts' => $callContacts,
                'sms_contacts' => $smsContacts,
                'total_contacts' => $whatsappContacts + $callContacts + $smsContacts,
                'unique_clients' => $uniqueClients,
                'product_views' => $totalViews,
                'product_shares' => $totalShares,
                'shop_views' => $shopEngagement['shop_views'],
                'shop_shares' => $shopEngagement['shop_shares'],
            ],
        ]);
        exit;
    }

    // ── POST: Record a like, follow, view, share, or contact action ─────────
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input || !isset($input['action'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'action is required']);
            exit;
        }

        $action = $input['action'];

        switch ($action) {
            // ── LIKE ─────────────────────────────────────────────────────
            case 'like':
                $productId = isset($input['product_id']) ? (int)$input['product_id'] : null;
                $userPhone = isset($input['user_phone']) ? trim($input['user_phone']) : '';
                if (!$productId || empty($userPhone)) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'product_id and user_phone are required']);
                    exit;
                }
                // Check if already liked
                $stmt = $db->prepare("SELECT id FROM product_likes WHERE product_id = ? AND user_phone = ?");
                $stmt->execute([$productId, $userPhone]);
                if ($stmt->fetch()) {
                    echo json_encode(['success' => true, 'action' => 'like', 'status' => 'already_liked']);
                    exit;
                }
                $stmt = $db->prepare("INSERT INTO product_likes (product_id, user_phone, created_at) VALUES (?, ?, NOW())");
                $stmt->execute([$productId, $userPhone]);
                echo json_encode(['success' => true, 'action' => 'like', 'id' => (int)$db->lastInsertId()]);
                exit;

            // ── UNLIKE ───────────────────────────────────────────────────
            case 'unlike':
                $productId = isset($input['product_id']) ? (int)$input['product_id'] : null;
                $userPhone = isset($input['user_phone']) ? trim($input['user_phone']) : '';
                if (!$productId || empty($userPhone)) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'product_id and user_phone are required']);
                    exit;
                }
                $stmt = $db->prepare("DELETE FROM product_likes WHERE product_id = ? AND user_phone = ?");
                $stmt->execute([$productId, $userPhone]);
                echo json_encode(['success' => true, 'action' => 'unlike']);
                exit;

            // ── FOLLOW ───────────────────────────────────────────────────
            case 'follow':
                $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
                $userPhone = isset($input['user_phone']) ? trim($input['user_phone']) : '';
                if (!$shopId || empty($userPhone)) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'shop_id and user_phone are required']);
                    exit;
                }
                // Check if already following
                $stmt = $db->prepare("SELECT id FROM shop_follows WHERE shop_id = ? AND user_phone = ?");
                $stmt->execute([$shopId, $userPhone]);
                if ($stmt->fetch()) {
                    echo json_encode(['success' => true, 'action' => 'follow', 'status' => 'already_following']);
                    exit;
                }
                $stmt = $db->prepare("INSERT INTO shop_follows (shop_id, user_phone, created_at) VALUES (?, ?, NOW())");
                $stmt->execute([$shopId, $userPhone]);
                echo json_encode(['success' => true, 'action' => 'follow', 'id' => (int)$db->lastInsertId()]);
                exit;

            // ── UNFOLLOW ─────────────────────────────────────────────────
            case 'unfollow':
                $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
                $userPhone = isset($input['user_phone']) ? trim($input['user_phone']) : '';
                if (!$shopId || empty($userPhone)) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'shop_id and user_phone are required']);
                    exit;
                }
                $stmt = $db->prepare("DELETE FROM shop_follows WHERE shop_id = ? AND user_phone = ?");
                $stmt->execute([$shopId, $userPhone]);
                echo json_encode(['success' => true, 'action' => 'unfollow']);
                exit;

            // ── TRACK VIEW ───────────────────────────────────────────────
            case 'track_view':
                $entityType = isset($input['entity_type']) ? $input['entity_type'] : 'product';
                $entityId = isset($input['entity_id']) ? (int)$input['entity_id'] : null;
                if (!$entityId) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'entity_id is required']);
                    exit;
                }
                if ($entityType === 'product') {
                    $stmt = $db->prepare("UPDATE products SET views_count = views_count + 1 WHERE id = ?");
                    $stmt->execute([$entityId]);
                } elseif ($entityType === 'shop') {
                    stats_record_shop_interaction($db, $entityId, 'view');
                }
                echo json_encode(['success' => true, 'action' => 'track_view']);
                exit;

            // ── TRACK SHOP INTERACTION (view, catalog/story/QR/status share…) ─
            case 'track_shop_interaction':
                $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
                $interactionType = isset($input['interaction_type'])
                    ? trim((string)$input['interaction_type'])
                    : '';
                if (!$shopId || $interactionType === '') {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'shop_id and interaction_type are required']);
                    exit;
                }
                if (!stats_record_shop_interaction($db, $shopId, $interactionType)) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'Invalid shop interaction type']);
                    exit;
                }
                echo json_encode(['success' => true, 'action' => 'track_shop_interaction', 'type' => $interactionType]);
                exit;

            // ── TRACK SHARE ──────────────────────────────────────────────
            case 'track_share':
                $entityType = isset($input['entity_type']) ? $input['entity_type'] : 'product';
                $entityId = isset($input['entity_id']) ? (int)$input['entity_id'] : null;
                if (!$entityId) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'entity_id is required']);
                    exit;
                }
                if ($entityType === 'shop') {
                    $shareType = isset($input['interaction_type'])
                        ? trim((string)$input['interaction_type'])
                        : 'share';
                    if (!stats_record_shop_interaction($db, $entityId, $shareType)) {
                        http_response_code(400);
                        echo json_encode(['success' => false, 'error' => 'Invalid shop share type']);
                        exit;
                    }
                } else {
                    $stmt = $db->prepare("UPDATE products SET shares_count = shares_count + 1 WHERE id = ?");
                    $stmt->execute([$entityId]);
                }
                echo json_encode(['success' => true, 'action' => 'track_share']);
                exit;

            // ── TRACK CONTACT ────────────────────────────────────────────
            case 'track_contact':
                $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
                $userPhone = isset($input['user_phone']) ? trim($input['user_phone']) : '';
                $contactType = isset($input['contact_type']) ? $input['contact_type'] : 'whatsapp';
                $productId = isset($input['product_id']) ? (int)$input['product_id'] : null;
                if (!$shopId || empty($userPhone)) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'shop_id and user_phone are required']);
                    exit;
                }
                $stmt = $db->prepare("INSERT INTO user_contacts (shop_id, user_phone, contact_type, product_id, created_at) VALUES (?, ?, ?, ?, NOW())");
                $stmt->execute([$shopId, $userPhone, $contactType, $productId]);
                echo json_encode(['success' => true, 'action' => 'track_contact', 'id' => (int)$db->lastInsertId()]);
                exit;

            default:
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => "Unknown action: $action"]);
                exit;
        }
    }

    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);

} catch (PDOException $e) {
    error_log("Stats DB error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    error_log("Stats error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
