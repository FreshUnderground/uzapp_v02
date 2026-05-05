<?php
// db.php handles CORS and defines DB class if needed
require_once '../db.php'; 
authenticate();

header('Content-Type: application/json');

// Base upload directory (outside api folder for direct access)
$baseDir = dirname(__DIR__) . "/uploads/";
if (!file_exists($baseDir)) {
    mkdir($baseDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_FILES['file'])) {
        http_response_code(400);
        echo json_encode(['error' => 'No file uploaded']);
        exit;
    }

    $folder = isset($_POST['folder']) ? preg_replace('/[^a-zA-Z0-9_\/]/', '', $_POST['folder']) : 'general';
    $specificDir = $baseDir . $folder . "/";
    
    if (!file_exists($specificDir)) {
        mkdir($specificDir, 0755, true);
    }

    // Generate unique filename
    $extension = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
    $uniqueName = time() . '_' . bin2hex(random_bytes(8)) . '.' . $extension;
    $targetFilePath = $specificDir . $uniqueName;

    // Validate file type
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm'];
    $fileType = mime_content_type($_FILES['file']['tmp_name']);
    
    if (!in_array($fileType, $allowedTypes)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid file type. Allowed: jpg, png, gif, webp, mp4, mov, avi, webm']);
        exit;
    }

    // Limit file size: 50MB for videos, 5MB for images
    $isVideo = strpos($fileType, 'video/') === 0;
    $maxSize = $isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024;
    $maxLabel = $isVideo ? '50MB' : '5MB';
    if ($_FILES['file']['size'] > $maxSize) {
        http_response_code(400);
        echo json_encode(['error' => "File too large. Max $maxLabel for " . ($isVideo ? 'videos' : 'images')]);
        exit;
    }

    if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFilePath)) {
        // Build base URL
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host = $_SERVER['HTTP_HOST'];

        // Generate thumbnail
        $thumbDir = dirname(__DIR__) . "/uploads/" . $folder . "/thumbnails";
        if (!is_dir($thumbDir)) {
            mkdir($thumbDir, 0755, true);
        }

        $thumbPath = $thumbDir . '/' . $uniqueName;
        $thumbnailUrl = null;
        // Only generate thumbnails for images, not videos
        $imageInfo = @getimagesize($targetFilePath);
        if ($imageInfo) {
            $srcWidth = $imageInfo[0];
            $srcHeight = $imageInfo[1];
            $thumbWidth = 200;
            $thumbHeight = intval($srcHeight * ($thumbWidth / $srcWidth));

            $src = @imagecreatefromstring(file_get_contents($targetFilePath));
            if ($src) {
                $thumb = imagecreatetruecolor($thumbWidth, $thumbHeight);
                imagecopyresampled($thumb, $src, 0, 0, 0, 0, $thumbWidth, $thumbHeight, $srcWidth, $srcHeight);
                imagejpeg($thumb, $thumbPath, 50);
                imagedestroy($src);
                imagedestroy($thumb);
                $thumbnailUrl = "$protocol://$host/uploads/$folder/thumbnails/$uniqueName";
            }
        }

        // Return the full URL
        $url = "$protocol://$host/uploads/$folder/$uniqueName";
        
        $response = [
            'success' => true,
            'url' => $url,
            'filename' => $uniqueName,
            'media_type' => $isVideo ? 'video' : 'image',
        ];
        if ($thumbnailUrl) {
            $response['thumbnail_url'] = $thumbnailUrl;
        }
        echo json_encode($response);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save file', 'details' => error_get_last()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}
?>
