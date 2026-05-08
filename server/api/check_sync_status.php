<?php
/**
 * Check sync status and fix remote_id for existing stories/products
 * Access: https://uzaapp.com/api/check_sync_status.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    
    $results = [];
    
    // 1. Check shops
    $stmt = $db->query("SELECT COUNT(*) as count FROM shops");
    $results['shops'] = $stmt->fetch()['count'];
    
    // 2. Check stories with and without remote_id
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories");
    $results['stories_total'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NULL");
    $results['stories_without_remote_id'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NOT NULL");
    $results['stories_with_remote_id'] = $stmt->fetch()['count'];
    
    // 3. Check products
    $stmt = $db->query("SELECT COUNT(*) as count FROM products");
    $results['products_total'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM products WHERE remote_id IS NULL");
    $results['products_without_remote_id'] = $stmt->fetch()['count'];
    
    // 4. Show recent stories
    $stmt = $db->query("SELECT id, remote_id, shop_id, media_url, created_at FROM stories ORDER BY id DESC LIMIT 5");
    $results['recent_stories'] = $stmt->fetchAll();
    
    // 5. Auto-fix: Set remote_id = id for stories that don't have it
    $results['fix_stories'] = 'Setting remote_id = id for stories without remote_id';
    
    $stmt = $db->exec("UPDATE stories SET remote_id = id WHERE remote_id IS NULL");
    $results['stories_fixed'] = "✅ Updated $stmt stories";
    
    // 6. Auto-fix: Set remote_id = id for products that don't have it
    $results['fix_products'] = 'Setting remote_id = id for products without remote_id';
    
    $stmt = $db->exec("UPDATE products SET remote_id = id WHERE remote_id IS NULL");
    $results['products_fixed'] = "✅ Updated $stmt products";
    
    // 7. Verify the fix
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NULL");
    $results['stories_still_missing'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM products WHERE remote_id IS NULL");
    $results['products_still_missing'] = $stmt->fetch()['count'];
    
    // 8. Final status
    if ($results['stories_still_missing'] == 0) {
        $results['status'] = '✅ ALL STORIES NOW HAVE remote_id';
        $results['next_steps'] = [
            'Stories are now visible on other devices!',
            'Run a manual sync in the app to pull the updates',
            'New stories will automatically get remote_id assigned',
        ];
    } else {
        $results['status'] = '⚠️ Some stories still missing remote_id';
    }
    
    echo json_encode($results, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
    ], JSON_PRETTY_PRINT);
}
?>
