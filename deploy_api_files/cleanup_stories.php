<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();

    // Find expired story IDs
    $stmt = $db->prepare("SELECT id FROM stories WHERE expires_at < NOW()");
    $stmt->execute();
    $expiredIds = $stmt->fetchAll(PDO::FETCH_COLUMN, 0);

    if (empty($expiredIds)) {
        echo json_encode([
            'success' => true,
            'deleted_stories' => 0,
            'deleted_media' => 0,
            'message' => 'No expired stories to clean up'
        ]);
        exit;
    }

    $idPlaceholders = implode(',', array_fill(0, count($expiredIds), '?'));

    // Delete story_media for expired stories
    $mediaStmt = $db->prepare("DELETE FROM story_media WHERE story_id IN ($idPlaceholders)");
    $mediaStmt->execute($expiredIds);
    $deletedMedia = $mediaStmt->rowCount();

    // Delete the expired stories
    $storyStmt = $db->prepare("DELETE FROM stories WHERE id IN ($idPlaceholders)");
    $storyStmt->execute($expiredIds);
    $deletedStories = $storyStmt->rowCount();

    // Optionally: clean up uploaded files for expired stories
    // This would require tracking file paths in the story_media table
    // For now, we rely on a separate cron job or manual cleanup for files

    echo json_encode([
        'success' => true,
        'deleted_stories' => $deletedStories,
        'deleted_media' => $deletedMedia,
        'expired_ids' => array_map('intval', $expiredIds),
        'message' => "Cleaned up $deletedStories expired stories and $deletedMedia media items"
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
