<?php
/**
 * Test script to verify location data (latitude/longitude) is being saved
 * Access: https://uzaapp.com/api/test_location_sync.php?api_key=YOUR_API_KEY
 */

require_once __DIR__ . '/../db.php';

// Authenticate
authenticate();

// Get database instance
$db = DB::getInstance();

header('Content-Type: text/html; charset=utf-8');

echo "<h2>🔍 Location Sync Diagnostic</h2>";
echo "<hr>";

// 1. Check if columns exist
echo "<h3>1. Checking Database Columns</h3>";
$columns = $db->query("
    SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'shops' 
      AND COLUMN_NAME IN ('latitude', 'longitude', 'city', 'commune')
    ORDER BY ORDINAL_POSITION
")->fetchAll();

if (empty($columns)) {
    echo "<p style='color:red;'>❌ Location columns do NOT exist in shops table!</p>";
    echo "<p><strong>Action needed:</strong> Run the SQL migration: <code>add_location_columns_to_shops.sql</code></p>";
} else {
    echo "<p style='color:green;'>✅ Location columns exist:</p>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Column</th><th>Type</th><th>Nullable</th><th>Default</th></tr>";
    foreach ($columns as $col) {
        echo "<tr>";
        echo "<td>{$col['COLUMN_NAME']}</td>";
        echo "<td>{$col['COLUMN_TYPE']}</td>";
        echo "<td>{$col['IS_NULLABLE']}</td>";
        $default = isset($col['COLUMN_DEFAULT']) ? $col['COLUMN_DEFAULT'] : 'NULL';
        echo "<td>{$default}</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// 2. Check allowed columns in shops.php
echo "<h3>2. Checking shops.php Allowed Columns</h3>";
$shopsPhpFile = __DIR__ . '/shops.php';
if (file_exists($shopsPhpFile)) {
    $content = file_get_contents($shopsPhpFile);
    $hasLatitude = strpos($content, "'latitude'") !== false || strpos($content, '"latitude"') !== false;
    $hasLongitude = strpos($content, "'longitude'") !== false || strpos($content, '"longitude"') !== false;
    
    if ($hasLatitude && $hasLongitude) {
        echo "<p style='color:green;'>✅ latitude and longitude are in ALLOWED_SHOP_COLUMNS</p>";
    } else {
        echo "<p style='color:red;'>❌ latitude and/or longitude are MISSING from ALLOWED_SHOP_COLUMNS</p>";
        echo "<p><strong>Action needed:</strong> Add 'latitude' and 'longitude' to the \$ALLOWED_SHOP_COLUMNS array in shops.php</p>";
    }
} else {
    echo "<p style='color:red;'>❌ shops.php not found</p>";
}

// 3. Test inserting a shop with location data
echo "<h3>3. Testing Shop Creation with Location</h3>";
try {
    $testShop = [
        'name' => 'Test Location Shop ' . time(),
        'type' => 'retail',
        'owner_id' => 'test_location_' . time(),
        'latitude' => -4.3216,
        'longitude' => 15.3123,
        'city' => 'Kinshasa',
        'commune' => 'Gombe'
    ];
    
    // Filter like shops.php does
    $ALLOWED_SHOP_COLUMNS = [
        'id', 'name', 'description', 'logo_url', 'type', 'owner_id', 'address', 'whatsapp',
        'phone', 'email', 'instagram_url', 'tiktok_url', 'facebook_url', 'youtube_url',
        'banner_url', 'boost_status', 'banner_status', 'banner_text', 'video_url',
        'is_boosted', 'is_verified', 'verified_at', 'created_at', 'updated_at',
        'latitude', 'longitude', 'city', 'commune'
    ];
    
    $filteredInput = array_intersect_key($testShop, array_flip($ALLOWED_SHOP_COLUMNS));
    $filteredInput['created_at'] = date('Y-m-d H:i:s');
    $filteredInput['updated_at'] = date('Y-m-d H:i:s');
    
    $keys = array_keys($filteredInput);
    $values = array_values($filteredInput);
    $placeholders = array_fill(0, count($keys), '?');
    
    $sql = "INSERT INTO shops (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")";
    $stmt = $db->prepare($sql);
    $stmt->execute($values);
    $newId = $db->lastInsertId();
    
    echo "<p style='color:green;'>✅ Test shop created with ID: $newId</p>";
    echo "<p><strong>Data sent:</strong></p>";
    echo "<pre>" . json_encode($testShop, JSON_PRETTY_PRINT) . "</pre>";
    
    // Verify it was saved
    $verifyStmt = $db->prepare("SELECT name, latitude, longitude, city, commune FROM shops WHERE id = ?");
    $verifyStmt->execute([$newId]);
    $savedShop = $verifyStmt->fetch();
    
    if ($savedShop) {
        echo "<p style='color:green;'>✅ Shop retrieved from database:</p>";
        echo "<pre>" . json_encode($savedShop, JSON_PRETTY_PRINT) . "</pre>";
        
        if ($savedShop['latitude'] != null && $savedShop['longitude'] != null) {
            echo "<p style='color:green;'><strong>✅ SUCCESS: Location data was saved correctly!</strong></p>";
        } else {
            echo "<p style='color:red;'><strong>❌ FAILED: Location data was NOT saved!</strong></p>";
        }
    }
    
    // Clean up test shop
    $deleteStmt = $db->prepare("DELETE FROM shops WHERE id = ?");
    $deleteStmt->execute([$newId]);
    echo "<p>🗑️ Test shop deleted</p>";
    
} catch (Exception $e) {
    echo "<p style='color:red;'>❌ Test failed: " . $e->getMessage() . "</p>";
}

// 4. Show recent shops with location data
echo "<h3>4. Recent Shops with Location Data</h3>";
$recentShops = $db->query("
    SELECT id, name, city, commune, latitude, longitude, created_at 
    FROM shops 
    WHERE latitude IS NOT NULL OR longitude IS NOT NULL
    ORDER BY created_at DESC 
    LIMIT 10
")->fetchAll();

if (empty($recentShops)) {
    echo "<p>No shops with location data found yet.</p>";
} else {
    echo "<p style='color:green;'>✅ Found " . count($recentShops) . " shops with location data:</p>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>City</th><th>Commune</th><th>Latitude</th><th>Longitude</th><th>Created</th></tr>";
    foreach ($recentShops as $shop) {
        echo "<tr>";
        echo "<td>{$shop['id']}</td>";
        echo "<td>{$shop['name']}</td>";
        $city = isset($shop['city']) ? $shop['city'] : '-';
        echo "<td>{$city}</td>";
        $commune = isset($shop['commune']) ? $shop['commune'] : '-';
        echo "<td>{$commune}</td>";
        $lat = isset($shop['latitude']) ? $shop['latitude'] : '-';
        echo "<td>{$lat}</td>";
        $lng = isset($shop['longitude']) ? $shop['longitude'] : '-';
        echo "<td>{$lng}</td>";
        echo "<td>{$shop['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
}

echo "<hr>";
echo "<h3>Summary</h3>";
echo "<ul>";
echo "<li>If all tests pass ✅, location sync is working correctly</li>";
echo "<li>If any test fails ❌, follow the action items above</li>";
echo "<li>After fixing, create a shop from the app and verify it appears in section 4</li>";
echo "</ul>";
?>
