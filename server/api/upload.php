<?php
// db.php handles CORS and defines DB class if needed
require_once __DIR__ . '/../db.php'; 
authenticate();

header('Content-Type: application/json');

// Base upload directory (outside api folder for direct access)
$baseDir = dirname(__DIR__) . "/uploads/";
if (!file_exists($baseDir)) {
    mkdir($baseDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
        $uploadError = $_FILES['file']['error'] ?? UPLOAD_ERR_NO_FILE;
        $errorMessages = [
            UPLOAD_ERR_INI_SIZE => 'Fichier trop volumineux (limite serveur)',
            UPLOAD_ERR_FORM_SIZE => 'Fichier trop volumineux',
            UPLOAD_ERR_PARTIAL => 'Upload incomplet, réessayez',
            UPLOAD_ERR_NO_FILE => 'Aucun fichier reçu',
        ];
        http_response_code(400);
        echo json_encode([
            'error' => $errorMessages[$uploadError] ?? 'Erreur lors de l\'upload du fichier',
            'upload_error_code' => $uploadError,
        ]);
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
    $allowedTypes = [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'image/heic', 'image/heif',
        'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm',
        'application/octet-stream',
    ];
    $fileType = mime_content_type($_FILES['file']['tmp_name']);

    // Fallback: detect from extension when MIME is generic
    if ($fileType === 'application/octet-stream' || empty($fileType)) {
        $ext = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
        $extToMime = [
            'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg',
            'png' => 'image/png', 'gif' => 'image/gif', 'webp' => 'image/webp',
            'heic' => 'image/heic', 'heif' => 'image/heif',
            'mp4' => 'video/mp4', 'mov' => 'video/quicktime',
            'avi' => 'video/x-msvideo', 'webm' => 'video/webm',
        ];
        if (isset($extToMime[$ext])) {
            $fileType = $extToMime[$ext];
        }
    }

    // Last resort: sniff JPEG/PNG magic bytes
    if ($fileType === 'application/octet-stream') {
        $header = file_get_contents($_FILES['file']['tmp_name'], false, null, 0, 12);
        if (strncmp($header, "\xFF\xD8\xFF", 3) === 0) {
            $fileType = 'image/jpeg';
        } elseif (strncmp($header, "\x89PNG\r\n\x1a\n", 8) === 0) {
            $fileType = 'image/png';
        }
    }

    $allowedFinal = [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'image/heic', 'image/heif',
        'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm',
    ];
    if (!in_array($fileType, $allowedFinal)) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Type de fichier non supporté. Utilisez jpg, png, webp, heic ou mp4.',
            'detected_type' => $fileType,
        ]);
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
        // Convert HEIC/HEIF → JPEG when possible (iPhone photos)
        if (in_array($fileType, ['image/heic', 'image/heif'], true)) {
            $jpgName = preg_replace('/\.(heic|heif|hif)$/i', '.jpg', $uniqueName);
            $jpgPath = $specificDir . $jpgName;
            $converted = false;

            if (extension_loaded('imagick')) {
                try {
                    $imagick = new Imagick($targetFilePath);
                    $imagick->setImageFormat('jpeg');
                    $imagick->setImageCompressionQuality(85);
                    $imagick->writeImage($jpgPath);
                    $imagick->clear();
                    $imagick->destroy();
                    if (file_exists($jpgPath)) {
                        @unlink($targetFilePath);
                        $targetFilePath = $jpgPath;
                        $uniqueName = $jpgName;
                        $fileType = 'image/jpeg';
                        $converted = true;
                    }
                } catch (Exception $e) {
                    // fall through
                }
            }

            if (!$converted) {
                $convertCmd = null;
                if (shell_exec('which heif-convert 2>/dev/null')) {
                    $convertCmd = 'heif-convert ' . escapeshellarg($targetFilePath)
                        . ' ' . escapeshellarg($jpgPath) . ' 2>/dev/null';
                } elseif (shell_exec('which magick 2>/dev/null')) {
                    $convertCmd = 'magick ' . escapeshellarg($targetFilePath)
                        . ' ' . escapeshellarg($jpgPath) . ' 2>/dev/null';
                }
                if ($convertCmd) {
                    @exec($convertCmd, $out, $code);
                    if ($code === 0 && file_exists($jpgPath)) {
                        @unlink($targetFilePath);
                        $targetFilePath = $jpgPath;
                        $uniqueName = $jpgName;
                        $fileType = 'image/jpeg';
                    }
                }
            }
        }

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
