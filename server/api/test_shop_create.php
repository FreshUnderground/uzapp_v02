<?php
/**
 * Test Shop CREATE with exact payload from logs
 * Access: https://uzaapp.com/api/test_shop_create.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    
    // Step 1: Show shops table structure
    $stmt = $db->query("DESCRIBE shops");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $columnNames = array_map(function($col) {
        return $col['Field'];
    }, $columns);
    
    echo json_encode([
        'test' => 'Shop CREATE Test',
        'current_shops_table_columns' => $columnNames,
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- CHECKING USER ---\n\n";
    
    // Step 2: Check if user exists
    $stmt = $db->prepare("SELECT id, phone, name FROM users WHERE phone = ?");
    $stmt->execute(['975955375']);
    $user = $stmt->fetch();
    
    echo json_encode([
        'user_found' => $user ? true : false,
        'user_data' => $user,
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- PREPARING SHOP INSERT ---\n\n";
    
    // Exact payload from create_shop_screen.dart
    $ALLOWED_COLUMNS = ['id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 
                       'whatsapp', 'phone', 'email', 'instagram_url', 'tiktok_url', 'facebook_url', 
                       'youtube_url', 'banner_url', 'boost_status', 'banner_status', 'banner_text', 
                       'video_url', 'is_boosted', 'is_verified', 'verified_at', 'created_at', 'updated_at'];
    
    $payload = [
        'id' => 1,
        'name' => 'iNETSECURE HUB',
        'description' => 'OKL;ADKNC',
        'address' => 'Butembo, vulengera',
        'logo_url' => 'https://uzaapp.com/uploads/boutiques/profil/1778223519_fd3a3fe925dc1d6b.png',
        'type' => 'retail',
        'owner_id' => '975955375',
        'phone' => '975955375',
        'whatsapp' => '',
        'facebook_url' => '',
        'instagram_url' => '',
        'tiktok_url' => '',
        'youtube_url' => '',
        'is_verified' => 1,
        'verified_at' => date('c'),
        'city' => 'Butembo',  // THIS MIGHT NOT BE IN ALLOWED_COLUMNS!
        'commune' => 'Vulengera',  // THIS MIGHT NOT BE IN ALLOWED_COLUMNS!
    ];
    
    echo json_encode([
        'original_payload' => $payload,
        'payload_keys' => array_keys($payload),
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- FILTERING ---\n\n";
    
    // Filter to allowed columns
    $filteredData = array_intersect_key($payload, array_flip($ALLOWED_COLUMNS));
    
    echo json_encode([
        'filtered_payload' => $filteredData,
        'filtered_keys' => array_keys($filteredData),
        'removed_keys' => array_diff(array_keys($payload), array_keys($filteredData)),
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- CHECKING FOR MISSING COLUMNS ---\n\n";
    
    // Check which payload columns are NOT in the database
    $missingColumns = array_diff(array_keys($filteredData), $columnNames);
    $extraColumns = array_diff($columnNames, array_keys($filteredData));
    
    echo json_encode([
        'columns_in_payload_but_not_in_db' => $missingColumns,
        'columns_in_db_but_not_in_payload' => $extraColumns,
    ], JSON_PRETTY_PRINT);
    
    if (!empty($missingColumns)) {
        echo "\n\n⚠️ ERROR: These columns are in the payload but NOT in the database!\n";
        echo "This will cause the INSERT to fail with 'Unknown column' error.\n\n";
        
        echo "SQL to add missing columns:\n";
        foreach ($missingColumns as $col) {
            echo "ALTER TABLE shops ADD COLUMN `$col` VARCHAR(255) DEFAULT NULL;\n";
        }
        echo "\n";
    }
    
    echo "\n\n--- ATTEMPTING INSERT ---\n\n";
    
    // Remove 'id' for INSERT (auto-increment)
    unset($filteredData['id']);
    
    // Add timestamps
    if (!isset($filteredData['created_at'])) {
        $filteredData['created_at'] = date('Y-m-d H:i:s');
    }
    $filteredData['updated_at'] = date('Y-m-d H:i:s');
    
    $keys = array_keys($filteredData);
    $values = array_values($filteredData);
    $placeholders = array_fill(0, count($keys), '?');
    
    $sql = "INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")";
    
    echo json_encode([
        'sql_query' => $sql,
        'keys' => $keys,
        'values_count' => count($values),
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- EXECUTING ---\n\n";
    
    try {
        $stmt = $db->prepare($sql);
        $stmt->execute($values);
        $newId = $db->lastInsertId();
        
        echo json_encode([
            '✅ SUCCESS' => true,
            'new_shop_id' => $newId,
            'message' => 'Shop created successfully!',
        ], JSON_PRETTY_PRINT);
        
    } catch (PDOException $e) {
        echo json_encode([
            '❌ INSERT FAILED' => true,
            'error' => $e->getMessage(),
            'error_code' => $e->getCode(),
            'sql_state' => $e->errorInfo[0] ?? 'unknown',
        ], JSON_PRETTY_PRINT);
        
        echo "\n\n💡 SOLUTION:\n";
        if (strpos($e->getMessage(), 'Unknown column') !== false) {
            echo "The database table is missing columns. Run the ALTER TABLE statements above.\n";
        } elseif (strpos($e->getMessage(), 'Duplicate entry') !== false) {
            echo "A shop with this owner_id or ID already exists. Check the shops table.\n";
        } else {
            echo "Check the error message above and fix the database schema.\n";
        }
    }
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ], JSON_PRETTY_PRINT);
}
?>
