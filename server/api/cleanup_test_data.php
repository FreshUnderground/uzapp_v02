<?php
/**
 * One-time cleanup of CRUD / test artifacts left from API testing.
 * GET/POST ?api_key=...&confirm=1
 */
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

if (($_GET['confirm'] ?? $_POST['confirm'] ?? '') !== '1') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Pass confirm=1 to execute cleanup',
    ]);
    exit;
}

try {
    $db = DB::getInstance();
    $report = [];

    $shopWhere = "
        owner_id LIKE '%CRUD%'
        OR owner_id LIKE '999888%'
        OR owner_id LIKE '777666555%'
        OR name LIKE '%CRUD%'
        OR name LIKE '%MINIMAL NAME UPDATE%'
    ";

    $shopIdsStmt = $db->query("SELECT id FROM shops WHERE $shopWhere");
    $shopIds = $shopIdsStmt->fetchAll(PDO::FETCH_COLUMN);
    $report['test_shop_ids'] = array_map('intval', $shopIds);

    if (!empty($shopIds)) {
        $in = implode(',', array_map('intval', $shopIds));

        $report['products_deleted'] = $db->exec(
            "DELETE FROM products WHERE shop_id IN ($in)
             OR name LIKE '%CRUD%'
             OR name LIKE '%Promo Update Test%'
             OR name LIKE '%ID CHECK PRODUCT%'
             OR name LIKE '%Promo CRUD%'
             OR name LIKE '%ReadTimingTest%'"
        );

        $report['deliveries_deleted'] = 0;
        try {
            $report['deliveries_deleted'] = $db->exec(
                "DELETE FROM deliveries WHERE shop_id IN ($in)
                 OR buyer_phone LIKE '%CRUD%'
                 OR buyer_phone LIKE '999888%'
                 OR buyer_phone LIKE '777666555%'"
            );
        } catch (Exception $e) {
            $report['deliveries_note'] = $e->getMessage();
        }

        $report['stories_deleted'] = $db->exec(
            "DELETE FROM story_media WHERE story_id IN (SELECT id FROM stories WHERE shop_id IN ($in))"
        );
        $report['stories_deleted'] += $db->exec(
            "DELETE FROM stories WHERE shop_id IN ($in)"
        );

        $report['orders_deleted'] = 0;
        try {
            $report['orders_deleted'] = $db->exec(
                "DELETE FROM orders WHERE shop_id IN ($in)
                 OR buyer_phone LIKE '%CRUD%'
                 OR buyer_phone LIKE '999888%'"
            );
        } catch (Exception $e) {
            $report['orders_note'] = $e->getMessage();
        }

        $report['shops_deleted'] = $db->exec("DELETE FROM shops WHERE id IN ($in)");
    } else {
        $report['products_deleted'] = $db->exec(
            "DELETE FROM products WHERE name LIKE '%CRUD%'
             OR name LIKE '%Promo Update Test%'
             OR name LIKE '%ID CHECK PRODUCT%'
             OR name LIKE '%Promo CRUD%'
             OR name LIKE '%ReadTimingTest%'"
        );
        $report['shops_deleted'] = 0;
    }

    // Reset test shop promo flags on any remaining accidental matches
    $report['shops_promo_reset'] = $db->exec(
        "UPDATE shops SET boost_status = 0, banner_status = 0, banner_text = NULL
         WHERE boost_status IN (1, 2) AND (
            owner_id LIKE '%CRUD%' OR name LIKE '%CRUD%' OR name LIKE '%Test Shop%'
         )"
    );

    echo json_encode(['success' => true, 'report' => $report]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
