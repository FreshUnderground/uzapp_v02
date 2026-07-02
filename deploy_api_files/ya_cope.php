<?php
/**
 * Ya Cope — listings occasion sans compte (public read, open create).
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$dbFile = __DIR__ . '/db.php';
if (!is_file($dbFile)) {
    $dbFile = __DIR__ . '/../db.php';
}
require_once $dbFile;
require_once __DIR__ . '/ya_cope_utils.php';

function ya_cope_row(array $row): array
{
    $createdAt = $row['created_at'] ?? null;
    return [
        'id' => (int)$row['id'],
        'name' => $row['name'],
        'phone' => $row['phone'],
        'address' => $row['address'],
        'image_urls' => $row['image_urls'],
        'condition' => $row['condition'] ?? 'used',
        'views_count' => (int)($row['views_count'] ?? 0),
        'shares_count' => (int)($row['shares_count'] ?? 0),
        'is_sold' => (bool)($row['is_sold'] ?? 0),
        'created_at' => $createdAt,
        'expires_at' => ya_cope_expires_at($createdAt),
        'updated_at' => $row['updated_at'] ?? null,
    ];
}

function ya_cope_normalize_phone(?string $phone): ?string
{
    if ($phone === null || trim($phone) === '') {
        return null;
    }
    $digits = preg_replace('/\D/', '', $phone);
    if ($digits === '') {
        return null;
    }
    if (strlen($digits) === 9) {
        return '243' . $digits;
    }
    if (strpos($digits, '243') === 0) {
        return $digits;
    }
    if ($digits[0] === '0' && strlen($digits) >= 10) {
        return '243' . substr($digits, 1);
    }
    return $digits;
}

try {
    $db = DB::getInstance();
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'GET') {
        ya_cope_purge_expired($db);

        $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
        if ($id > 0) {
            $activeWhere = ya_cope_active_where();
            $stmt = $db->prepare(
                "SELECT * FROM ya_cope_listings WHERE id = ? AND {$activeWhere} LIMIT 1"
            );
            $stmt->execute([$id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) {
                http_response_code(404);
                echo json_encode(['success' => false, 'listing' => null]);
                exit;
            }
            $db->prepare('UPDATE ya_cope_listings SET views_count = views_count + 1 WHERE id = ?')
                ->execute([$id]);
            echo json_encode(['success' => true, 'listing' => ya_cope_row($row)]);
            exit;
        }

        $limit = min(100, max(1, (int)($_GET['limit'] ?? 50)));
        $activeWhere = ya_cope_active_where();
        $stmt = $db->prepare(
            "SELECT * FROM ya_cope_listings WHERE {$activeWhere} ORDER BY created_at DESC LIMIT ?"
        );
        $stmt->bindValue(1, $limit, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $listings = array_map('ya_cope_row', $rows);
        echo json_encode(['success' => true, 'listings' => $listings]);
        exit;
    }

    if ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!is_array($input)) {
            $input = $_POST;
        }

        $name = trim((string)($input['name'] ?? ''));
        $phone = ya_cope_normalize_phone($input['phone'] ?? null);
        $address = trim((string)($input['address'] ?? ''));
        $imagesRaw = $input['image_urls'] ?? [];

        if ($name === '' || mb_strlen($name) > 150) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Désignation invalide']);
            exit;
        }
        if ($phone === null || strlen($phone) < 11) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Numéro WhatsApp invalide']);
            exit;
        }

        $urls = [];
        if (is_string($imagesRaw)) {
            $imagesRaw = array_filter(array_map('trim', explode(',', $imagesRaw)));
        }
        if (is_array($imagesRaw)) {
            foreach ($imagesRaw as $u) {
                $u = trim((string)$u);
                if ($u !== '' && count($urls) < 3) {
                    $urls[] = $u;
                }
            }
        }
        if (count($urls) < 1) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Au moins une photo est requise']);
            exit;
        }

        $imageUrls = implode(',', $urls);
        $stmt = $db->prepare(
            'INSERT INTO ya_cope_listings (name, phone, address, image_urls, `condition`)
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $name,
            $phone,
            $address !== '' ? $address : null,
            $imageUrls,
            'used',
        ]);
        $newId = (int)$db->lastInsertId();
        $fetch = $db->prepare('SELECT * FROM ya_cope_listings WHERE id = ?');
        $fetch->execute([$newId]);
        $row = $fetch->fetch(PDO::FETCH_ASSOC);
        echo json_encode(['success' => true, 'listing' => ya_cope_row($row)]);
        exit;
    }

    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
} catch (Exception $e) {
    error_log('ya_cope.php error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Erreur serveur']);
}
