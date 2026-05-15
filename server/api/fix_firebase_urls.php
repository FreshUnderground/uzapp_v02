<?php
/**
 * Fix Firebase Storage 402 Error
 * Replaces all Firebase Storage URLs with local server URLs
 * 
 * Run: https://uzaapp.com/api/fix_firebase_urls.php
 */
require_once __DIR__ . '/../db.php';

header('Content-Type: application/json');

try {
    $db = DB::getInstance();
    $results = [];
    
    // ========================================================================
    // 1. Fix shops.logo_url
    // ========================================================================
    $stmt = $db->query("SELECT id, name, logo_url FROM shops WHERE logo_url LIKE '%firebasestorage.googleapis.com%'");
    $shops = $stmt->fetchAll();
    $fixed = 0;
    
    foreach ($shops as $shop) {
        $oldUrl = $shop['logo_url'];
        // Extract filename from Firebase URL
        $pathParts = explode('/', $oldUrl);
        $filenameWithToken = end($pathParts);
        $filename = explode('?', $filenameWithToken)[0];
        
        $newUrl = 'https://uzaapp.com/uploads/migrated/' . $filename;
        
        $update = $db->prepare("UPDATE shops SET logo_url = ? WHERE id = ?");
        $update->execute([$newUrl, $shop['id']]);
        $fixed++;
    }
    
    $results['shops_logo'] = [
        'fixed' => $fixed,
        'total' => count($shops)
    ];
    
    // ========================================================================
    // 2. Fix shops.banner_url
    // ========================================================================
    $stmt = $db->query("SELECT id, name, banner_url FROM shops WHERE banner_url LIKE '%firebasestorage.googleapis.com%'");
    $shops = $stmt->fetchAll();
    $fixed = 0;
    
    foreach ($shops as $shop) {
        $oldUrl = $shop['banner_url'];
        $pathParts = explode('/', $oldUrl);
        $filenameWithToken = end($pathParts);
        $filename = explode('?', $filenameWithToken)[0];
        
        $newUrl = 'https://uzaapp.com/uploads/migrated/' . $filename;
        
        $update = $db->prepare("UPDATE shops SET banner_url = ? WHERE id = ?");
        $update->execute([$newUrl, $shop['id']]);
        $fixed++;
    }
    
    $results['shops_banner'] = [
        'fixed' => $fixed,
        'total' => count($shops)
    ];
    
    // ========================================================================
    // 3. Fix products.image_urls (may contain multiple comma-separated URLs)
    // ========================================================================
    $stmt = $db->query("SELECT id, name, image_urls FROM products WHERE image_urls LIKE '%firebasestorage.googleapis.com%'");
    $products = $stmt->fetchAll();
    $fixed = 0;
    
    foreach ($products as $product) {
        $imageUrls = $product['image_urls'];
        
        // Split by comma if multiple URLs
        $urlArray = explode(',', $imageUrls);
        $newUrls = [];
        
        foreach ($urlArray as $url) {
            $url = trim($url);
            
            if (strpos($url, 'firebasestorage.googleapis.com') !== false) {
                // Replace Firebase base path
                $url = str_replace(
                    'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/',
                    'https://uzaapp.com/uploads/migrated/',
                    $url
                );
                
                // Remove token parameter
                if (strpos($url, '?') !== false) {
                    $url = explode('?', $url)[0];
                }
                
                // URL decode filename (Firebase encodes spaces as %20 etc.)
                $url = urldecode($url);
            }
            
            $newUrls[] = $url;
        }
        
        $newImageUrls = implode(',', $newUrls);
        
        if ($newImageUrls !== $imageUrls) {
            $update = $db->prepare("UPDATE products SET image_urls = ? WHERE id = ?");
            $update->execute([$newImageUrls, $product['id']]);
            $fixed++;
        }
    }
    
    $results['products'] = [
        'fixed' => $fixed,
        'total' => count($products)
    ];
    
    // ========================================================================
    // 4. Fix stories.media_url
    // ========================================================================
    $stmt = $db->query("SELECT id, shop_id, media_url FROM stories WHERE media_url LIKE '%firebasestorage.googleapis.com%'");
    $stories = $stmt->fetchAll();
    $fixed = 0;
    
    foreach ($stories as $story) {
        $oldUrl = $story['media_url'];
        $pathParts = explode('/', $oldUrl);
        $filenameWithToken = end($pathParts);
        $filename = explode('?', $filenameWithToken)[0];
        
        $newUrl = 'https://uzaapp.com/uploads/migrated/' . $filename;
        
        $update = $db->prepare("UPDATE stories SET media_url = ? WHERE id = ?");
        $update->execute([$newUrl, $story['id']]);
        $fixed++;
    }
    
    $results['stories'] = [
        'fixed' => $fixed,
        'total' => count($stories)
    ];
    
    // ========================================================================
    // 5. Fix story_media.media_url
    // ========================================================================
    $stmt = $db->query("SELECT id, story_id, media_url FROM story_media WHERE media_url LIKE '%firebasestorage.googleapis.com%'");
    $storyMedia = $stmt->fetchAll();
    $fixed = 0;
    
    foreach ($storyMedia as $media) {
        $oldUrl = $media['media_url'];
        $pathParts = explode('/', $oldUrl);
        $filenameWithToken = end($pathParts);
        $filename = explode('?', $filenameWithToken)[0];
        
        $newUrl = 'https://uzaapp.com/uploads/migrated/' . $filename;
        
        $update = $db->prepare("UPDATE story_media SET media_url = ? WHERE id = ?");
        $update->execute([$newUrl, $media['id']]);
        $fixed++;
    }
    
    $results['story_media'] = [
        'fixed' => $fixed,
        'total' => count($storyMedia)
    ];
    
    // ========================================================================
    // Verification: Check remaining Firebase URLs
    // ========================================================================
    $verification = [];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM shops WHERE logo_url LIKE '%firebasestorage.googleapis.com%' OR banner_url LIKE '%firebasestorage.googleapis.com%'");
    $verification['remaining_shops'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM products WHERE image_urls LIKE '%firebasestorage.googleapis.com%'");
    $verification['remaining_products'] = $stmt->fetch()['count'];
    
    $stmt = $db->query("SELECT COUNT(*) as count FROM stories WHERE media_url LIKE '%firebasestorage.googleapis.com%'");
    $verification['remaining_stories'] = $stmt->fetch()['count'];
    
    // ========================================================================
    // Return results
    // ========================================================================
    echo json_encode([
        'success' => true,
        'message' => 'Firebase URLs have been replaced with server URLs',
        'results' => $results,
        'verification' => $verification,
        'note' => 'Users need to sync their app to get the updated URLs'
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ], JSON_PRETTY_PRINT);
}
?>
