<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    
    $results = [];
    
    // Step 1: Check all stories and their remote_id values
    $stmt = $db->query("SELECT id, remote_id, shop_id, media_url, created_at FROM stories ORDER BY created_at DESC LIMIT 20");
    $stories = $stmt->fetchAll();
    
    $results['total_stories'] = count($stories);
    $results['stories'] = [];
    
    $missingRemoteId = 0;
    foreach ($stories as $story) {
        $hasRemoteId = !empty($story['remote_id']);
        if (!$hasRemoteId) {
            $missingRemoteId++;
        }
        
        $results['stories'][] = [
            'id' => (int)$story['id'],
            'remote_id' => $story['remote_id'],
            'shop_id' => (int)$story['shop_id'],
            'media_url' => substr($story['media_url'], 0, 80) . '...',
            'created_at' => $story['created_at'],
            'has_remote_id' => $hasRemoteId,
        ];
    }
    
    $results['stories_missing_remote_id'] = $missingRemoteId;
    
    // Step 2: Fix stories missing remote_id
    if ($missingRemoteId > 0) {
        $results['fix_step'] = 'Fixing stories with missing remote_id...';
        $stmt = $db->exec("UPDATE stories SET remote_id = id WHERE remote_id IS NULL OR remote_id = ''");
        $results['fixed_count'] = "Updated $stmt stories";
        
        // Verify fix
        $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE remote_id IS NULL OR remote_id = ''");
        $results['still_missing'] = $stmt->fetch()['count'];
    } else {
        $results['fix_step'] = 'All stories have remote_id - no fix needed';
    }
    
    // Step 3: Test sync endpoint response
    $results['test_sync_response'] = 'Fetching stories with include_media=1 (simulating sync)...';
    $stmt = $db->prepare("
        SELECT s.*, sh.name AS shop_name 
        FROM stories s 
        LEFT JOIN shops sh ON s.shop_id = sh.id 
        ORDER BY s.created_at DESC 
        LIMIT 5
    ");
    $stmt->execute();
    $testStories = $stmt->fetchAll();
    
    foreach ($testStories as &$story) {
        $story['id'] = (int)$story['id'];
        $story['shop_id'] = (int)$story['shop_id'];
        // This is what the fixed code does:
        $story['remote_id'] = $story['remote_id'] ?? $story['id'];
        
        // Get media
        $mediaStmt = $db->prepare("SELECT * FROM story_media WHERE story_id = ? ORDER BY sort_order ASC");
        $mediaStmt->execute([$story['id']]);
        $story['media_items'] = $mediaStmt->fetchAll();
    }
    unset($story);
    
    $results['test_stories'] = $testStories;
    
    // Step 4: Instructions
    $results['instructions'] = [
        '1' => 'Check if all stories now have remote_id values',
        '2' => 'On other devices, force sync by pulling down on Arrivages screen',
        '3' => 'Stories should now appear on all devices',
        '4' => 'If still not showing, check Flutter debug logs for sync errors',
    ];
    
    echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Database error: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Error: ' . $e->getMessage()
    ]);
}
?>
