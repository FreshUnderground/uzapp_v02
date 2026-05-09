<?php
/**
 * Force Sync Categories Script
 * 
 * This script forces a complete refresh of all categories from the server.
 * Use this when categories are missing or have incorrect hierarchy.
 * 
 * Usage: GET /api/force_sync_categories.php
 */

require_once __DIR__ . '/../db.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = DB::getInstance();
    
    // Fetch all categories ordered by hierarchy
    $stmt = $pdo->prepare('
        SELECT 
            id,
            remote_id,
            name,
            icon,
            parent_id,
            level,
            sort_order,
            updated_at
        FROM categories
        ORDER BY level ASC, sort_order ASC, name ASC
    ');
    $stmt->execute();
    $categories = $stmt->fetchAll();
    
    // Format response
    foreach ($categories as &$category) {
        $category['id'] = (int)$category['id'];
        $category['level'] = (int)$category['level'];
        $category['sort_order'] = (int)$category['sort_order'];
        $category['parent_id'] = $category['parent_id'] !== null 
            ? (int)$category['parent_id'] 
            : null;
    }
    
    echo json_encode([
        'success' => true,
        'count' => count($categories),
        'data' => $categories,
        'message' => 'Full category sync - ' . count($categories) . ' categories returned'
    ]);
    
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
    ]);
}
