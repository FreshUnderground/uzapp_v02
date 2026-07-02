<?php
/**
 * Detect and remove products (and related rows) whose shop_id has no matching shop.
 *
 * GET  ?api_key=...              → dry-run report only
 * GET  ?api_key=...&confirm=1    → execute cleanup
 * GET  ?api_key=...&phone=243... → also target orphan shop_id = former user row id
 */
require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/phone_utils.php';
authenticate();

header('Content-Type: application/json');

$confirm = ($_GET['confirm'] ?? $_POST['confirm'] ?? '') === '1';
$phoneFilter = trim((string) ($_GET['phone'] ?? $_POST['phone'] ?? ''));

try {
    $db = DB::getInstance();

    $orphanSql = "
        SELECT p.id, p.name, p.shop_id, p.updated_at
        FROM products p
        LEFT JOIN shops s ON s.id = p.shop_id
        WHERE s.id IS NULL
        ORDER BY p.id
    ";
    $orphans = $db->query($orphanSql)->fetchAll(PDO::FETCH_ASSOC);

    $phoneOrphans = [];
    if ($phoneFilter !== '') {
        $keys = phone_lookup_keys($phoneFilter);
        if (!empty($keys)) {
            $placeholders = implode(',', array_fill(0, count($keys), '?'));
            $userStmt = $db->prepare(
                "SELECT id, phone, name FROM users WHERE phone IN ($placeholders) LIMIT 1"
            );
            $userStmt->execute($keys);
            $user = $userStmt->fetch(PDO::FETCH_ASSOC);

            $candidateShopIds = [];
            if ($user) {
                $candidateShopIds[] = (int) $user['id'];
            }
            foreach ($keys as $k) {
                if (ctype_digit($k)) {
                    $candidateShopIds[] = (int) $k;
                }
            }
            $candidateShopIds = array_values(array_unique(array_filter($candidateShopIds)));

            if (!empty($candidateShopIds)) {
                $in = implode(',', array_map('intval', $candidateShopIds));
                $phoneOrphans = $db->query(
                    "SELECT p.id, p.name, p.shop_id, p.updated_at
                     FROM products p
                     LEFT JOIN shops s ON s.id = p.shop_id
                     WHERE s.id IS NULL AND p.shop_id IN ($in)
                     ORDER BY p.id"
                )->fetchAll(PDO::FETCH_ASSOC);
            }
        }
    }

    $report = [
        'dry_run' => !$confirm,
        'orphan_products' => array_map(function ($row) {
            return [
                'id' => (int) $row['id'],
                'name' => $row['name'],
                'shop_id' => (int) $row['shop_id'],
                'updated_at' => $row['updated_at'],
            ];
        }, $orphans),
        'orphan_count' => count($orphans),
        'phone_filter' => $phoneFilter !== '' ? $phoneFilter : null,
        'phone_orphan_products' => array_map(function ($row) {
            return [
                'id' => (int) $row['id'],
                'name' => $row['name'],
                'shop_id' => (int) $row['shop_id'],
                'updated_at' => $row['updated_at'],
            ];
        }, $phoneOrphans),
    ];

    if (!$confirm) {
        $report['hint'] = 'Add confirm=1 to delete listed orphan products';
        echo json_encode(['success' => true, 'report' => $report]);
        exit;
    }

    $orphanIds = array_column($orphans, 'id');
    if (empty($orphanIds)) {
        $report['deleted'] = [
            'products' => 0,
            'product_likes' => 0,
            'product_updates' => 0,
            'stories' => 0,
        ];
        echo json_encode(['success' => true, 'report' => $report]);
        exit;
    }

    $in = implode(',', array_map('intval', $orphanIds));

    $deleted = ['products' => 0, 'product_likes' => 0, 'product_updates' => 0, 'stories' => 0];

    try {
        $deleted['product_likes'] = $db->exec(
            "DELETE FROM product_likes WHERE product_id IN ($in)"
        );
    } catch (Exception $e) {
        $deleted['product_likes_note'] = $e->getMessage();
    }

    try {
        $deleted['product_updates'] = $db->exec(
            "DELETE FROM product_updates WHERE product_id IN ($in)"
        );
    } catch (Exception $e) {
        $deleted['product_updates_note'] = $e->getMessage();
    }

    $orphanShopIds = array_values(array_unique(array_map('intval', array_column($orphans, 'shop_id'))));
    if (!empty($orphanShopIds)) {
        $shopIn = implode(',', $orphanShopIds);
        try {
            $db->exec(
                "DELETE FROM story_media WHERE story_id IN (
                    SELECT id FROM stories WHERE shop_id IN ($shopIn)
                 )"
            );
            $deleted['stories'] = $db->exec(
                "DELETE FROM stories WHERE shop_id IN ($shopIn)"
            );
        } catch (Exception $e) {
            $deleted['stories_note'] = $e->getMessage();
        }
    }

    $deleted['products'] = $db->exec(
        "DELETE p FROM products p
         LEFT JOIN shops s ON s.id = p.shop_id
         WHERE s.id IS NULL"
    );

    $report['deleted'] = $deleted;
    echo json_encode(['success' => true, 'report' => $report]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
