<?php
/**
 * Safe upload file deletion — never remove a file still referenced by products.
 */

function uza_upload_relative_path($url) {
    if (!is_string($url) || $url === '') {
        return null;
    }
    if (!preg_match('#/uploads/(.+)$#', $url, $matches)) {
        return null;
    }
    return $matches[1];
}

function uza_url_like_patterns($url) {
    $relative = uza_upload_relative_path($url);
    if ($relative === null) {
        return null;
    }
    $basename = basename($relative);
    return [
        '%' . $relative . '%',
        '%' . $basename . '%',
    ];
}

/**
 * Returns true when an upload URL is still referenced outside an optional story.
 */
function uza_is_upload_url_in_use(PDO $db, $url, $excludeStoryId = null) {
    $patterns = uza_url_like_patterns($url);
    if ($patterns === null) {
        return false;
    }
    [$likeFull, $likeBase] = $patterns;

    $stmt = $db->prepare(
        'SELECT COUNT(*) FROM products WHERE image_urls LIKE ? OR image_urls LIKE ?'
    );
    $stmt->execute([$likeFull, $likeBase]);
    if ((int) $stmt->fetchColumn() > 0) {
        return true;
    }

    foreach (['logo_url', 'banner_url', 'video_url'] as $column) {
        $stmt = $db->prepare(
            "SELECT COUNT(*) FROM shops WHERE `$column` LIKE ? OR `$column` LIKE ?"
        );
        $stmt->execute([$likeFull, $likeBase]);
        if ((int) $stmt->fetchColumn() > 0) {
            return true;
        }
    }

    if ($excludeStoryId !== null) {
        $stmt = $db->prepare(
            'SELECT COUNT(*) FROM stories WHERE id != ? AND (media_url LIKE ? OR media_url LIKE ?)'
        );
        $stmt->execute([$excludeStoryId, $likeFull, $likeBase]);
    } else {
        $stmt = $db->prepare(
            'SELECT COUNT(*) FROM stories WHERE media_url LIKE ? OR media_url LIKE ?'
        );
        $stmt->execute([$likeFull, $likeBase]);
    }
    if ((int) $stmt->fetchColumn() > 0) {
        return true;
    }

    $stmt = $db->prepare(
        'SELECT COUNT(*) FROM ya_cope_listings WHERE image_urls LIKE ? OR image_urls LIKE ?'
    );
    $stmt->execute([$likeFull, $likeBase]);
    if ((int) $stmt->fetchColumn() > 0) {
        return true;
    }

    if ($excludeStoryId !== null) {
        $stmt = $db->prepare(
            'SELECT COUNT(*) FROM story_media WHERE story_id != ? AND (media_url LIKE ? OR media_url LIKE ?)'
        );
        $stmt->execute([$excludeStoryId, $likeFull, $likeBase]);
    } else {
        $stmt = $db->prepare(
            'SELECT COUNT(*) FROM story_media WHERE media_url LIKE ? OR media_url LIKE ?'
        );
        $stmt->execute([$likeFull, $likeBase]);
    }
    return (int) $stmt->fetchColumn() > 0;
}

/**
 * Delete an upload file only when no product/shop/other story still uses it.
 */
function uza_safe_unlink_upload(PDO $db, $url, $excludeStoryId = null) {
    if (uza_is_upload_url_in_use($db, $url, $excludeStoryId)) {
        error_log("uza_safe_unlink: kept (still referenced) $url");
        return false;
    }

    $relative = uza_upload_relative_path($url);
    if ($relative === null) {
        return false;
    }

    $baseDir = dirname(__DIR__);
    $path = $baseDir . '/uploads/' . $relative;
    $deleted = false;

    if (is_file($path)) {
        $deleted = @unlink($path) || $deleted;
    }

    $thumbPath = preg_replace('#^(.*)/([^/]+)$#', '$1/thumbnails/$2', $path);
    if (is_string($thumbPath) && is_file($thumbPath)) {
        $deleted = @unlink($thumbPath) || $deleted;
    }

    return $deleted;
}

function uza_safe_unlink_uploads(PDO $db, array $urls, $excludeStoryId = null) {
    foreach ($urls as $url) {
        uza_safe_unlink_upload($db, $url, $excludeStoryId);
    }
}
