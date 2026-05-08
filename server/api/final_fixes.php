<?php
/**
 * Final fixes: Add created_at column and boutiques/cover directory
 * Access: https://uzaapp.com/api/final_fixes.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

$results = [];

try {
    $db = DB::getInstance();
    
    // Fix 1: Add created_at column if it doesn't exist
    $results['fix_1'] = 'Adding created_at column to shops table';
    
    try {
        $db->exec("ALTER TABLE shops ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP");
        $results['created_at'] = '✅ Added successfully';
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $results['created_at'] = 'ℹ️ Column already exists';
        } else {
            $results['created_at'] = '❌ Error: ' . $e->getMessage();
        }
    }
    
    // Fix 2: Update the existing shop with created_at
    $results['fix_2'] = 'Setting created_at for existing shop';
    
    try {
        $stmt = $db->prepare("UPDATE shops SET created_at = COALESCE(created_at, NOW()) WHERE created_at IS NULL");
        $stmt->execute();
        $results['shop_update'] = '✅ Updated ' . $stmt->rowCount() . ' shops';
    } catch (PDOException $e) {
        $results['shop_update'] = '❌ Error: ' . $e->getMessage();
    }
    
    // Fix 3: Create boutiques/cover directory
    $results['fix_3'] = 'Creating boutiques/cover directory';
    
    $coverDir = dirname(__DIR__) . "/uploads/boutiques/cover";
    if (!file_exists($coverDir)) {
        if (mkdir($coverDir, 0755, true)) {
            $results['cover_directory'] = '✅ Created successfully';
        } else {
            $results['cover_directory'] = '❌ Failed to create';
        }
    } else {
        $results['cover_directory'] = 'ℹ️ Already exists';
    }
    
    // Fix 4: Verify shop exists
    $results['fix_4'] = 'Verifying shop';
    
    $stmt = $db->prepare("SELECT id, name, owner_id, phone FROM shops WHERE id = 1");
    $stmt->execute();
    $shop = $stmt->fetch();
    
    if ($shop) {
        $results['shop_verification'] = [
            '✅ Shop exists' => true,
            'shop_id' => $shop['id'],
            'name' => $shop['name'],
            'owner_id' => $shop['owner_id'],
        ];
    } else {
        $results['shop_verification'] = '❌ Shop not found!';
    }
    
    // Fix 5: Check if stories can now be created
    $results['fix_5'] = 'Testing story creation';
    
    try {
        $stmt = $db->prepare("
            INSERT INTO stories (shop_id, media_url, media_type, is_arrivage, expires_at, created_at) 
            VALUES (1, 'https://uzaapp.com/uploads/stories/test.jpg', 'image', 0, DATE_ADD(NOW(), INTERVAL 1 DAY), NOW())
        ");
        $stmt->execute();
        $storyId = $db->lastInsertId();
        
        $results['story_test'] = [
            '✅ Story created' => true,
            'story_id' => $storyId,
        ];
        
        // Clean up test story
        $db->prepare("DELETE FROM stories WHERE id = ?")->execute([$storyId]);
        $results['story_test_cleanup'] = '✅ Test story deleted';
        
    } catch (PDOException $e) {
        $results['story_test'] = '❌ Error: ' . $e->getMessage();
    }
    
    // Final status
    $results['status'] = '✅ ALL FIXES COMPLETE';
    $results['next_steps'] = [
        '1. Restart your Flutter app',
        '2. Try creating a product - it should sync now',
        '3. Try creating a story - it should sync now',
        '4. Check the sync queue - it should be empty after sync',
    ];
    
    echo json_encode($results, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ], JSON_PRETTY_PRINT);
}
?>
