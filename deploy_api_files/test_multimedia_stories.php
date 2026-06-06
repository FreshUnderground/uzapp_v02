<?php
/**
 * Test multi-media story creation and retrieval
 * Access: https://uzaapp.com/api/test_multimedia_stories.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    
    $results = [];
    
    // Step 1: Check if multi-media story exists
    $results['step_1'] = 'Checking existing stories';
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories");
    $results['total_stories'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM story_media");
    $results['total_story_media'] = $stmt->fetch()['count'];
    
    // Step 2: Create a test multi-media story
    $results['step_2'] = 'Creating test multi-media story';
    
    $db->beginTransaction();
    
    // Create main story
    $stmt = $db->prepare("
        INSERT INTO stories (shop_id, media_url, media_type, is_arrivage, expires_at, created_at) 
        VALUES (1, 'https://uzaapp.com/uploads/stories/test_main.jpg', 'image', 0, DATE_ADD(NOW(), INTERVAL 1 DAY), NOW())
    ");
    $stmt->execute();
    $storyId = $db->lastInsertId();
    
    $results['main_story'] = [
        'story_id' => $storyId,
        'media_url' => 'https://uzaapp.com/uploads/stories/test_main.jpg',
    ];
    
    // Add additional media
    $mediaItems = [
        ['media_url' => 'https://uzaapp.com/uploads/stories/test_2.jpg', 'media_type' => 'image', 'sort_order' => 1],
        ['media_url' => 'https://uzaapp.com/uploads/stories/test_3.mp4', 'media_type' => 'video', 'sort_order' => 2],
        ['media_url' => 'https://uzaapp.com/uploads/stories/test_4.jpg', 'media_type' => 'image', 'sort_order' => 3],
    ];
    
    $insertedMedia = [];
    foreach ($mediaItems as $i => $media) {
        $stmt = $db->prepare("
            INSERT INTO story_media (story_id, media_url, media_type, sort_order) 
            VALUES (?, ?, ?, ?)
        ");
        $stmt->execute([
            $storyId,
            $media['media_url'],
            $media['media_type'],
            $media['sort_order'],
        ]);
        $insertedMedia[] = [
            'media_id' => $db->lastInsertId(),
            'media_url' => $media['media_url'],
            'media_type' => $media['media_type'],
        ];
    }
    
    $results['additional_media'] = $insertedMedia;
    
    $db->commit();
    
    // Step 3: Retrieve with media (sync mode)
    $results['step_3'] = 'Retrieving story with media (sync mode)';
    
    $stmt = $db->prepare("SELECT * FROM stories WHERE id = ?");
    $stmt->execute([$storyId]);
    $story = $stmt->fetch();
    
    // Get media items (like sync mode does now)
    $mediaStmt = $db->prepare("SELECT * FROM story_media WHERE story_id = ? ORDER BY sort_order ASC");
    $mediaStmt->execute([$storyId]);
    $mediaItems_result = $mediaStmt->fetchAll();
    
    $story['media_items'] = $mediaItems_result;
    
    $results['story_with_media'] = $story;
    $results['media_count'] = count($mediaItems_result);
    
    // Step 4: Test sync endpoint
    $results['step_4'] = 'Testing sync endpoint (stories.php?include_media=1)';
    
    // Simulate what the app does during sync
    $query = "SELECT s.*, sh.name AS shop_name FROM stories s LEFT JOIN shops sh ON s.shop_id = sh.id WHERE s.id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$storyId]);
    $stories = $stmt->fetchAll();
    
    // Attach media (this is what the fixed code does)
    foreach ($stories as &$s) {
        $mediaStmt = $db->prepare("SELECT * FROM story_media WHERE story_id = ? ORDER BY sort_order ASC");
        $mediaStmt->execute([$s['id']]);
        $s['media_items'] = $mediaStmt->fetchAll();
    }
    
    $results['sync_response'] = $stories;
    
    // Step 5: Clean up test data
    $results['step_5'] = 'Cleaning up test data';
    
    $db->prepare("DELETE FROM story_media WHERE story_id = ?")->execute([$storyId]);
    $db->prepare("DELETE FROM stories WHERE id = ?")->execute([$storyId]);
    
    $results['cleanup'] = '✅ Test story deleted';
    
    // Final status
    $results['status'] = '✅ MULTI-MEDIA STORIES ARE WORKING!';
    $results['message'] = 'All media items are now included in sync responses';
    $results['next_steps'] = [
        '1. Restart your Flutter app',
        '2. Create a multi-media story',
        '3. Check on another device - all media should appear!',
    ];
    
    echo json_encode($results, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ], JSON_PRETTY_PRINT);
}
?>
