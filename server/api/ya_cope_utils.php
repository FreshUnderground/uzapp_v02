<?php
/**
 * Ya Cope listing TTL and query helpers.
 */

function ya_cope_ttl_days(): int
{
    return 4;
}

/** SQL fragment: active listings only (not sold, not expired). */
function ya_cope_active_where(): string
{
    $days = ya_cope_ttl_days();
    return "is_sold = 0 AND created_at >= DATE_SUB(NOW(), INTERVAL {$days} DAY)";
}

function ya_cope_expires_at(?string $createdAt): ?string
{
    if ($createdAt === null || trim($createdAt) === '') {
        return null;
    }
    try {
        $dt = new DateTime($createdAt);
        $dt->modify('+' . ya_cope_ttl_days() . ' days');
        return $dt->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return null;
    }
}

/** @return list<string> */
function ya_cope_parse_image_urls(?string $imageUrls): array
{
    if ($imageUrls === null || trim($imageUrls) === '') {
        return [];
    }
    $urls = [];
    foreach (explode(',', $imageUrls) as $part) {
        $url = trim($part);
        if ($url !== '') {
            $urls[] = $url;
        }
    }
    return $urls;
}

/**
 * Remove expired listings and their upload files from disk.
 */
function ya_cope_purge_expired(PDO $db): void
{
    $mediaLib = __DIR__ . '/media_lib.php';
    if (is_file($mediaLib)) {
        require_once $mediaLib;
    }

    $days = ya_cope_ttl_days();
    $stmt = $db->prepare(
        "SELECT id, image_urls FROM ya_cope_listings
         WHERE created_at < DATE_SUB(NOW(), INTERVAL {$days} DAY)"
    );
    $stmt->execute();
    $expired = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (!$expired) {
        return;
    }

    $ids = [];
    $urlsToDelete = [];
    foreach ($expired as $row) {
        $ids[] = (int) $row['id'];
        foreach (ya_cope_parse_image_urls($row['image_urls'] ?? '') as $url) {
            $urlsToDelete[] = $url;
        }
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $delete = $db->prepare("DELETE FROM ya_cope_listings WHERE id IN ({$placeholders})");
    $delete->execute($ids);

    if (!function_exists('uza_safe_unlink_uploads')) {
        return;
    }

    $uniqueUrls = array_values(array_unique($urlsToDelete));
    uza_safe_unlink_uploads($db, $uniqueUrls);

    if ($uniqueUrls !== []) {
        error_log(
            'ya_cope_purge: removed ' . count($ids) . ' listing(s), '
            . count($uniqueUrls) . ' image URL(s)'
        );
    }
}
