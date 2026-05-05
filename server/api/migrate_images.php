<?php
/**
 * Image Migration Script
 * Migrates images from Firebase Storage to local server
 * 
 * Usage: Call via POST with 'urls' array containing Firebase URLs to migrate
 * OR run as CLI with table/column parameters to batch migrate
 */
require_once '../db.php';

header('Content-Type: application/json');

$baseDir = dirname(__DIR__) . "/uploads/";
$migratedFolder = "migrated/";
$targetDir = $baseDir . $migratedFolder;

if (!file_exists($targetDir)) {
    mkdir($targetDir, 0755, true);
}

/**
 * Download and save an image from URL
 */
function migrateImage($url, $targetDir) {
    if (empty($url)) return null;
    
    // Skip if already local
    if (strpos($url, 'uzaapp.com') !== false && strpos($url, 'firebasestorage') === false) {
        return $url;
    }
    
    // Only migrate Firebase URLs
    if (strpos($url, 'firebasestorage.googleapis.com') === false) {
        return $url;
    }

    try {
        // Generate unique filename
        $extension = 'jpg';
        if (strpos($url, '.png') !== false) $extension = 'png';
        if (strpos($url, '.gif') !== false) $extension = 'gif';
        if (strpos($url, '.webp') !== false) $extension = 'webp';
        
        $uniqueName = time() . '_' . bin2hex(random_bytes(8)) . '.' . $extension;
        $targetPath = $targetDir . $uniqueName;

        // Download image
        $context = stream_context_create([
            'http' => [
                'timeout' => 30,
                'user_agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            ],
            'ssl' => [
                'verify_peer' => false,
                'verify_peer_name' => false,
            ],
        ]);

        $imageData = @file_get_contents($url, false, $context);
        
        if ($imageData === false) {
            return ['error' => 'Failed to download', 'url' => $url];
        }

        // Save locally
        if (file_put_contents($targetPath, $imageData) === false) {
            return ['error' => 'Failed to save', 'url' => $url];
        }

        // Return new URL
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host = $_SERVER['HTTP_HOST'] ?? 'uzaapp.com';
        return "$protocol://$host/uploads/migrated/$uniqueName";

    } catch (Exception $e) {
        return ['error' => $e->getMessage(), 'url' => $url];
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Option 1: Migrate single URLs
    if (isset($input['urls']) && is_array($input['urls'])) {
        $results = [];
        foreach ($input['urls'] as $url) {
            $newUrl = migrateImage($url, $targetDir);
            $results[] = [
                'original' => $url,
                'migrated' => $newUrl
            ];
        }
        echo json_encode(['success' => true, 'results' => $results]);
        exit;
    }
    
    // Option 2: Batch migrate a database table
    if (isset($input['table']) && isset($input['column'])) {
        $table = preg_replace('/[^a-zA-Z0-9_]/', '', $input['table']);
        $column = preg_replace('/[^a-zA-Z0-9_]/', '', $input['column']);
        $idColumn = isset($input['id_column']) ? preg_replace('/[^a-zA-Z0-9_]/', '', $input['id_column']) : 'id';
        
        try {
            $db = DB::getInstance();
            
            // Get all rows with Firebase URLs
            $stmt = $db->query("SELECT `$idColumn`, `$column` FROM `$table` WHERE `$column` LIKE '%firebasestorage.googleapis.com%'");
            $rows = $stmt->fetchAll();
            
            $migrated = 0;
            $errors = [];
            
            foreach ($rows as $row) {
                $oldUrl = $row[$column];
                $newUrl = migrateImage($oldUrl, $targetDir);
                
                if (is_string($newUrl) && strpos($newUrl, 'uzaapp.com') !== false) {
                    // Update database
                    $updateStmt = $db->prepare("UPDATE `$table` SET `$column` = ? WHERE `$idColumn` = ?");
                    $updateStmt->execute([$newUrl, $row[$idColumn]]);
                    $migrated++;
                } else {
                    $errors[] = $newUrl;
                }
            }
            
            echo json_encode([
                'success' => true,
                'total' => count($rows),
                'migrated' => $migrated,
                'errors' => $errors
            ]);
            exit;
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }
    }
    
    http_response_code(400);
    echo json_encode(['error' => 'Invalid request. Provide "urls" array or "table"/"column" for batch migration']);
    
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Show usage instructions
    echo json_encode([
        'usage' => [
            'single' => 'POST with {"urls": ["firebase_url1", "firebase_url2"]}',
            'batch' => 'POST with {"table": "shops", "column": "logo_url", "id_column": "id"}',
        ],
        'examples' => [
            'Migrate shop logos' => '{"table": "shops", "column": "logo_url"}',
            'Migrate product images' => '{"table": "products", "column": "image_urls"}',
            'Migrate category icons' => '{"table": "categories", "column": "icon"}',
        ]
    ]);
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}
?>
