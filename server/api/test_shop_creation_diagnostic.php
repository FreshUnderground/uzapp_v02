<?php
/**
 * Shop Creation Diagnostic Tool
 * Access: https://uzaapp.com/api/test_shop_creation_diagnostic.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
 * 
 * This script tests:
 * 1. Database connection
 * 2. Shops table structure
 * 3. Users table relationship
 * 4. Shop creation with exact payload from app
 * 5. Returns detailed diagnostic information
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    $db = DB::getInstance();
    
    $diagnostic = [
        'test_name' => 'Shop Creation Diagnostic',
        'timestamp' => date('Y-m-d H:i:s'),
        'steps' => [],
    ];
    
    // STEP 1: Check database connection
    $diagnostic['steps'][] = [
        'step' => 1,
        'name' => 'Database Connection',
        'status' => 'PASS',
        'message' => 'Successfully connected to database',
    ];
    
    // STEP 2: Check shops table structure
    $stmt = $db->query("DESCRIBE shops");
    $shopColumns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $shopColumnNames = array_column($shopColumns, 'Field');
    
    $diagnostic['steps'][] = [
        'step' => 2,
        'name' => 'Shops Table Structure',
        'status' => 'PASS',
        'message' => 'Found ' . count($shopColumnNames) . ' columns',
        'columns' => $shopColumnNames,
    ];
    
    // STEP 3: Check users table
    $stmt = $db->query("DESCRIBE users");
    $userColumns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $userColumnNames = array_column($userColumns, 'Field');
    
    $diagnostic['steps'][] = [
        'step' => 3,
        'name' => 'Users Table Structure',
        'status' => 'PASS',
        'message' => 'Found ' . count($userColumnNames) . ' columns',
        'columns' => $userColumnNames,
    ];
    
    // STEP 4: Check recent users (last 5)
    $stmt = $db->query("SELECT id, phone, name, created_at FROM users ORDER BY created_at DESC LIMIT 5");
    $recentUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $diagnostic['steps'][] = [
        'step' => 4,
        'name' => 'Recent Users',
        'status' => 'INFO',
        'message' => 'Found ' . count($recentUsers) . ' recent users',
        'users' => $recentUsers,
    ];
    
    // STEP 5: Check recent shops (last 5)
    // Note: shops table may not have created_at, use updated_at instead
    $stmt = $db->query("SELECT id, name, owner_id, phone, updated_at FROM shops ORDER BY updated_at DESC LIMIT 5");
    $recentShops = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $diagnostic['steps'][] = [
        'step' => 5,
        'name' => 'Recent Shops',
        'status' => 'INFO',
        'message' => 'Found ' . count($recentShops) . ' recent shops',
        'shops' => $recentShops,
    ];
    
    // STEP 6: Test shop creation with sample data
    if (count($recentUsers) > 0) {
        $testUser = $recentUsers[0]; // Use most recent user
        $testOwnerId = $testUser['id'];
        $testPhone = $testUser['phone'];
        
        $testShopData = [
            'name' => 'Test Shop ' . date('Y-m-d H:i:s'),
            'description' => 'Diagnostic test shop',
            'type' => 'retail',
            'owner_id' => $testOwnerId,
            'phone' => $testPhone,
            'address' => 'Test Address',
            'city' => 'Test City',
            'commune' => 'Test Commune',
            'is_verified' => 1,
            'verified_at' => date('Y-m-d H:i:s'),
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s'),
        ];
        
        // Filter to only existing columns
        $filteredData = array_intersect_key($testShopData, array_flip($shopColumnNames));
        
        try {
            $keys = array_keys($filteredData);
            $values = array_values($filteredData);
            $placeholders = array_fill(0, count($keys), '?');
            
            $sql = "INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")";
            
            $stmt = $db->prepare($sql);
            $stmt->execute($values);
            $newShopId = $db->lastInsertId();
            
            // Verify the shop was created
            $stmt = $db->prepare("SELECT id, name, owner_id, phone, updated_at FROM shops WHERE id = ?");
            $stmt->execute([$newShopId]);
            $createdShop = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $diagnostic['steps'][] = [
                'step' => 6,
                'name' => 'Test Shop Creation',
                'status' => 'PASS',
                'message' => 'Successfully created test shop with ID: ' . $newShopId,
                'sql_executed' => $sql,
                'data_sent' => $filteredData,
                'shop_created' => $createdShop,
            ];
            
            // Clean up test shop
            $stmt = $db->prepare("DELETE FROM shops WHERE id = ?");
            $stmt->execute([$newShopId]);
            
            $diagnostic['steps'][] = [
                'step' => 7,
                'name' => 'Cleanup Test Shop',
                'status' => 'PASS',
                'message' => 'Test shop deleted successfully',
            ];
            
        } catch (PDOException $e) {
            $diagnostic['steps'][] = [
                'step' => 6,
                'name' => 'Test Shop Creation',
                'status' => 'FAIL',
                'message' => 'Failed to create test shop',
                'error' => $e->getMessage(),
                'error_code' => $e->getCode(),
                'sql_state' => $e->errorInfo[0] ?? 'unknown',
                'sql_attempted' => $sql ?? 'N/A',
                'data_sent' => $filteredData ?? $testShopData,
            ];
        }
    } else {
        $diagnostic['steps'][] = [
            'step' => 6,
            'name' => 'Test Shop Creation',
            'status' => 'SKIP',
            'message' => 'No users found to test shop creation',
        ];
    }
    
    // STEP 8: Check for common issues
    $issues = [];
    
    // Check if 'type' column exists
    if (!in_array('type', $shopColumnNames)) {
        $issues[] = 'MISSING: shops.type column - This is REQUIRED by the app';
    }
    
    // Check if 'owner_id' column exists
    if (!in_array('owner_id', $shopColumnNames)) {
        $issues[] = 'MISSING: shops.owner_id column - This links shops to users';
    }
    
    // Check if 'remote_id' column exists
    if (!in_array('remote_id', $shopColumnNames)) {
        $issues[] = 'MISSING: shops.remote_id column - This is used for sync';
    }
    
    // Check foreign key relationship
    $stmt = $db->query("
        SELECT COUNT(*) as orphaned_shops 
        FROM shops s 
        LEFT JOIN users u ON s.owner_id = u.id 
        WHERE u.id IS NULL
    ");
    $orphanedShops = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($orphanedShops['orphaned_shops'] > 0) {
        $issues[] = 'WARNING: ' . $orphanedShops['orphaned_shops'] . ' shops have no matching user in users table';
    }
    
    $diagnostic['steps'][] = [
        'step' => 8,
        'name' => 'Common Issues Check',
        'status' => empty($issues) ? 'PASS' : 'WARNING',
        'message' => empty($issues) ? 'No common issues detected' : 'Found ' . count($issues) . ' issue(s)',
        'issues' => $issues,
    ];
    
    // Final summary
    $passCount = 0;
    $failCount = 0;
    foreach ($diagnostic['steps'] as $step) {
        if ($step['status'] === 'PASS') $passCount++;
        if ($step['status'] === 'FAIL') $failCount++;
    }
    
    $diagnostic['summary'] = [
        'total_steps' => count($diagnostic['steps']),
        'passed' => $passCount,
        'failed' => $failCount,
        'overall_status' => $failCount > 0 ? 'FAIL' : 'PASS',
        'recommendation' => $failCount > 0 
            ? 'Check failed steps and fix issues before creating shops'
            : 'Shop creation should work correctly. If not, check app logs.',
    ];
    
    echo json_encode($diagnostic, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'test_name' => 'Shop Creation Diagnostic',
        'status' => 'ERROR',
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
    ], JSON_PRETTY_PRINT);
}
?>
