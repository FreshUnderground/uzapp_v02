<?php
/**
 * Upload & Sync Test Script
 * Place this in: /api/test_upload_sync.php
 * Access via: https://uzaapp.com/api/test_upload_sync.php
 */

header('Content-Type: application/json');

// Include database config
require_once __DIR__ . '/../db.php';

try {
    $results = [];
    
    // 1. Test API Key Authentication
    $apiKey = isset($_GET['api_key']) ? $_GET['api_key'] : '';
    $expectedKey = 'uza_sk_' . md5('uzaapp_secure_2024');
    
    $results['auth_test'] = [
        'provided_key' => $apiKey ? 'Yes' : 'No',
        'key_matches' => ($apiKey === $expectedKey) ? 'Yes' : 'No',
        'expected_key' => $expectedKey,
    ];
    
    // 2. Test Database Connection
    $db = DB::getInstance();
    $results['db_connection'] = 'OK';
    
    // 3. Test Upload Directory
    $baseDir = dirname(__DIR__) . "/uploads/";
    $uploadDirExists = file_exists($baseDir);
    $uploadDirWritable = is_writable($baseDir);
    
    $results['upload_directory'] = [
        'path' => $baseDir,
        'exists' => $uploadDirExists ? 'Yes' : 'No',
        'writable' => $uploadDirWritable ? 'Yes' : 'No',
    ];
    
    // 4. Test Subdirectories
    $folders = ['stories', 'produits', 'boutiques/profil', 'boutiques/cover'];
    $folderStatus = [];
    
    foreach ($folders as $folder) {
        $folderPath = $baseDir . $folder . "/";
        $folderStatus[$folder] = [
            'exists' => file_exists($folderPath) ? 'Yes' : 'No',
            'writable' => is_writable($folderPath) ? 'Yes' : 'No',
        ];
    }
    
    $results['subdirectories'] = $folderStatus;
    
    // 5. Test Tables Exist
    $tables = ['shops', 'products', 'stories', 'categories', 'users'];
    $tableStatus = [];
    
    foreach ($tables as $table) {
        try {
            $stmt = $db->prepare("SELECT COUNT(*) as count FROM $table");
            $stmt->execute();
            $count = $stmt->fetch()['count'];
            $tableStatus[$table] = "OK ($count records)";
        } catch (Exception $e) {
            $tableStatus[$table] = "ERROR: " . $e->getMessage();
        }
    }
    
    $results['database_tables'] = $tableStatus;
    
    // 6. Test Recent Sync Activity
    try {
        $stmt = $db->query("SELECT COUNT(*) as count FROM products WHERE updated_at > NOW() - INTERVAL 1 HOUR");
        $recentProducts = $stmt->fetch()['count'];
        $results['recent_activity']['products_last_hour'] = $recentProducts;
        
        $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE created_at > NOW() - INTERVAL 1 HOUR");
        $recentStories = $stmt->fetch()['count'];
        $results['recent_activity']['stories_last_hour'] = $recentStories;
    } catch (Exception $e) {
        $results['recent_activity'] = "Error: " . $e->getMessage();
    }
    
    // 7. PHP Info
    $results['php_info'] = [
        'version' => phpversion(),
        'upload_max_filesize' => ini_get('upload_max_filesize'),
        'post_max_size' => ini_get('post_max_size'),
        'max_execution_time' => ini_get('max_execution_time') . 's',
        'memory_limit' => ini_get('memory_limit'),
    ];
    
    echo json_encode([
        'success' => true,
        'test_results' => $results,
        'timestamp' => date('Y-m-d H:i:s'),
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ], JSON_PRETTY_PRINT);
}
?>
