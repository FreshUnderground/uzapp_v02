<?php
/**
 * Admin platform statistics API (JSON).
 *
 * GET /api/admin_stats.php?preset=30d
 * Requires X-API-Key and X-Admin-Phone (admin user).
 */
require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/platform_stats_lib.php';

authenticate_admin();

header('Content-Type: application/json; charset=utf-8');

try {
    $range = platform_stats_parse_range($_GET);
    $db = DB::getInstance();
    $stats = platform_stats_collect($db, $range);
    echo json_encode(['success' => true, 'data' => $stats], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
