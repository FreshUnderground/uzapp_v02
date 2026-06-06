<?php
/**
 * Auto-detect shops table columns and create the shop
 * Access: https://uzaapp.com/api/fix_shop_create.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    
    // Step 1: Get actual table structure
    $stmt = $db->query("DESCRIBE shops");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $columnNames = [];
    $columnDetails = [];
    foreach ($columns as $col) {
        $columnNames[] = $col['Field'];
        $columnDetails[$col['Field']] = [
            'type' => $col['Type'],
            'null' => $col['Null'],
            'default' => $col['Default'],
        ];
    }
    
    echo json_encode([
        'step_1' => 'Checking shops table structure',
        'actual_columns' => $columnNames,
        'total_columns' => count($columnNames),
        'column_details' => $columnDetails,
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- STEP 2: PREPARING DATA ---\n\n";
    
    // Step 2: Build insert data based on ACTUAL columns
    $allData = [
        'name' => 'iNETSECURE HUB',
        'description' => 'OKL;ADKNC',
        'address' => 'Butembo, vulengera',
        'logo_url' => 'https://uzaapp.com/uploads/boutiques/profil/1778223519_fd3a3fe925dc1d6b.png',
        'type' => 'retail',
        'owner_id' => '975955375',
        'phone' => '975955375',
        'whatsapp' => '',
        'email' => '',
        'instagram_url' => '',
        'tiktok_url' => '',
        'facebook_url' => '',
        'youtube_url' => '',
        'banner_url' => null,
        'boost_status' => 0,
        'banner_status' => 0,
        'banner_text' => null,
        'video_url' => null,
        'is_boosted' => 0,
        'is_verified' => 1,
        'verified_at' => date('Y-m-d H:i:s'),
        'city' => 'Butembo',
        'commune' => 'Vulengera',
        'created_at' => date('Y-m-d H:i:s'),
        'updated_at' => date('Y-m-d H:i:s'),
    ];
    
    // Filter to ONLY columns that exist in the table
    $insertData = array_intersect_key($allData, array_flip($columnNames));
    $missingColumns = array_diff(array_keys($allData), array_keys($insertData));
    
    echo json_encode([
        'will_insert_columns' => array_keys($insertData),
        'missing_from_table' => $missingColumns,
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- STEP 3: ATTEMPTING INSERT ---\n\n";
    
    // Step 3: Try the insert
    $keys = array_keys($insertData);
    $values = array_values($insertData);
    $placeholders = array_fill(0, count($keys), '?');
    
    $sql = "INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")";
    
    echo json_encode([
        'sql_query' => $sql,
        'column_count' => count($keys),
        'value_count' => count($values),
    ], JSON_PRETTY_PRINT);
    
    echo "\n\n--- STEP 4: EXECUTING ---\n\n";
    
    try {
        $stmt = $db->prepare($sql);
        $stmt->execute($values);
        $newId = $db->lastInsertId();
        
        echo json_encode([
            '✅ SUCCESS' => true,
            'new_shop_id' => $newId,
            'shop_name' => $insertData['name'],
            'message' => 'Shop created successfully! Now your app can sync products and stories.',
        ], JSON_PRETTY_PRINT);
        
        echo "\n\n--- STEP 5: VERIFYING ---\n\n";
        
        // Verify the shop was created
        $stmt = $db->prepare("SELECT id, name, owner_id, created_at FROM shops WHERE id = ?");
        $stmt->execute([$newId]);
        $shop = $stmt->fetch();
        
        echo json_encode([
            'verification' => $shop,
        ], JSON_PRETTY_PRINT);
        
    } catch (PDOException $e) {
        echo json_encode([
            '❌ INSERT FAILED' => true,
            'error' => $e->getMessage(),
            'error_code' => $e->getCode(),
            'sql_state' => $e->errorInfo[0] ?? 'unknown',
            'sql' => $sql,
            'keys' => $keys,
            'values_count' => count($values),
        ], JSON_PRETTY_PRINT);
        
        echo "\n\n💡 NEXT STEPS:\n";
        echo "1. Check if all required columns exist\n";
        echo "2. Check for NOT NULL constraints without defaults\n";
        echo "3. Check data types match the values\n";
    }
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ], JSON_PRETTY_PRINT);
}
?>
