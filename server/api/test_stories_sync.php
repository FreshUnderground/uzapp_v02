<?php
/**
 * Test stories sync - simulate what the app does during pull sync
 * Access: https://uzaapp.com/api/test_stories_sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    
    $results = [];
    
    // Step 1: Check stories in database
    $results['step_1'] = 'Checking stories in database';
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories");
    $results['total_stories'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NULL");
    $results['stories_without_remote_id'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NOT NULL");
    $results['stories_with_remote_id'] = $stmt->fetch()['count'];
    
    // Step 2: Simulate what API returns during sync
    $results['step_2'] = 'Simulating API sync response (stories.php?include_media=1&updated_since=...)';
    
    // Get all stories (like sync does)
    $query = "SELECT s.*, sh.name AS shop_name FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id ORDER BY s.created_at DESC";
    $stmt = $db->query($query);
    $stories = $stmt->fetchAll();
    
    // Attach media (like the fixed code does)
    foreach ($stories as &$story) {
        $story['id'] = (int)$story['id'];
        $story['shop_id'] = (int)$story['shop_id'];
        
        // Attach media items
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
    unset($story);
    
    $results['stories_from_api'] = $stories;
    $results['story_count'] = count($stories);
    
    // Step 3: Check if remote_id is being set
    $results['step_3'] = 'Checking remote_id values';
    
    foreach ($stories as $story) {
        $results['story_' . $story['id']] = [
            'id' => $story['id'],
            'remote_id' => $story['remote_id'],
            'shop_id' => $story['shop_id'],
            'media_url' => substr($story['media_url'], 0, 50) . '...',
            'media_items_count' => count($story['media_items'] ?? []),
        ];
    }
    
    // Step 4: Fix remote_id if NULL
    $results['step_4'] = 'Fixing remote_id for stories without it';
    
    $stmt = $db->exec("UPDATE stories SET remote_id = id WHERE remote_id IS NULL");
    $results['stories_fixed'] = "Updated $stmt stories";
    
    // Step 5: Verify fix
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NULL");
    $results['still_missing_remote_id'] = $stmt->fetch()['count'];
    
    // Step 6: Final check - simulate exact sync payload
    $results['step_6'] = 'Final sync simulation (after fix)';
    
    $stmt = $db->query("SELECT * FROM stories ORDER BY created_at DESC LIMIT 10");
    $finalStories = $stmt->fetchAll();
    
    foreach ($finalStories as &$story) {
        $story['id'] = (int)$story['id'];
        $story['shop_id'] = (int)$story['shop_id'];
        
        // Get media
        $mediaStmt = $db->prepare("SELECT * FROM story_media WHERE story_id = ? ORDER BY sort_order ASC");
        $mediaStmt->execute([$story['id']]);
        $story['media_items'] = $mediaStmt->fetchAll();
    }
    unset($story);
    
    $results['final_stories_for_sync'] = $finalStories;
    
    // Instructions
    $results['instructions'] = [
        'If stories have remote_id=NULL, the app cannot sync them properly',
        'The fix above sets remote_id = id for all stories',
        'Now run sync on the other device - stories should appear!',
        'If still not showing, check the app logs for "PULL" messages',
    ];
    
    echo json_encode($results, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
    ], JSON_PRETTY_PRINT);
}
?>
