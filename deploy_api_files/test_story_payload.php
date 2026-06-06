<?php
/**
 * Direct test of stories.php with exact payload from logs
 * Place in: /api/test_story_payload.php
 * Access: https://uzaapp.com/api/test_story_payload.php
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

// Exact payload from user's logs
$testPayload = [
    'shop_id' => 1,
    'media_url' => 'https://uzaapp.com/uploads/stories/1778223767_7d44b2665482d7f2.jpeg',
    'media_type' => 'image',
    'is_arrivage' => 0,
    'expires_at' => '2026-05-09T07:01:58.721Z'
];

$ALLOWED_STORY_COLUMNS = ['id', 'shop_id', 'media_url', 'media_type', 'is_arrivage', 'expires_at', 'created_at'];

echo json_encode([
    'test_name' => 'Story Payload Test',
    'original_payload' => $testPayload,
], JSON_PRETTY_PRINT);

echo "\n\n--- FILTERING TEST ---\n\n";

$filteredInput = array_intersect_key($testPayload, array_flip($ALLOWED_STORY_COLUMNS));

echo json_encode([
    'filtered_payload' => $filteredInput,
    'is_empty' => empty($filteredInput),
    'allowed_columns' => $ALLOWED_STORY_COLUMNS,
], JSON_PRETTY_PRINT);

echo "\n\n--- DATABASE CHECKS ---\n\n";

try {
    $db = DB::getInstance();
    
    // Check if shop_id=1 exists
    $stmt = $db->prepare("SELECT id, name FROM shops WHERE id = ?");
    $stmt->execute([1]);
    $shop = $stmt->fetch();
    
    echo json_encode([
        'shop_exists' => $shop ? true : false,
        'shop_data' => $shop,
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- ATTEMPTING INSERT ---\n\n";
    
    if (!$shop) {
        echo json_encode([
            'error' => 'Shop ID 1 does not exist on server!',
            'solution' => 'Shop must be synced first before stories can be created'
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    // Try the insert
    unset($filteredInput['id']);
    if (!isset($filteredInput['created_at'])) {
        $filteredInput['created_at'] = date('Y-m-d H:i:s');
    }
    
    $keys = array_keys($filteredInput);
    $values = array_values($filteredInput);
    $placeholders = array_fill(0, count($keys), '?');
    
    $sql = "INSERT INTO stories (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")";
    
    echo json_encode([
        'sql' => $sql,
        'keys' => $keys,
        'values' => $values,
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- EXECUTING ---\n\n";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($values);
    $newId = $db->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'new_story_id' => $newId,
        'message' => 'Story created successfully!'
    ], JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    echo json_encode([
        'error' => 'Database error',
        'message' => $e->getMessage(),
        'code' => $e->getCode(),
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
    ], JSON_PRETTY_PRINT);
}
?>
