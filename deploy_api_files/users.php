<?php
require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

function phone_variations($phone) {
    $cleaned = preg_replace('/\s+/', '', trim($phone));
    $digits = preg_replace('/\D+/', '', $cleaned);
    $variations = array_filter([$cleaned, $digits]);

    if (strpos($digits, '243') === 0 && strlen($digits) >= 12) {
        $local = substr($digits, 3);
        $variations[] = $local;
        $variations[] = '0' . $local;
        $variations[] = $digits;
        $variations[] = '+' . $digits;
    } elseif (strpos($digits, '0') === 0 && strlen($digits) >= 10) {
        $local = substr($digits, 1);
        $variations[] = $local;
        $variations[] = '0' . $local;
        $variations[] = '243' . $local;
        $variations[] = '+243' . $local;
    } elseif (strlen($digits) === 9) {
        $variations[] = $digits;
        $variations[] = '0' . $digits;
        $variations[] = '243' . $digits;
        $variations[] = '+243' . $digits;
    }

    return array_values(array_unique(array_filter($variations)));
}

$ALLOWED_USER_COLUMNS = [
    'phone', 'name', 'email', 'firebase_uid', 'avatar_url',
    'is_phone_verified', 'password_hash', 'created_at', 'updated_at',
];

function strip_user_secrets(array $user): array {
    unset($user['password_hash']);
    return $user;
}

try {
    $db = DB::getInstance();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            throw new Exception('Invalid JSON input');
        }

        $phone = isset($input['phone']) ? $input['phone'] : null;

        if (!$phone) {
            throw new Exception('Phone number is required');
        }

        // Never allow role escalation via public users endpoint.
        unset($input['role'], $input['id']);

        $filtered = array_intersect_key($input, array_flip($ALLOWED_USER_COLUMNS));
        if (empty($filtered['phone'])) {
            $filtered['phone'] = $phone;
        }

        $phoneVariations = phone_variations($phone);
        $placeholders = implode(',', array_fill(0, count($phoneVariations), '?'));
        $stmt = $db->prepare("SELECT id, phone FROM users WHERE phone IN ($placeholders) LIMIT 1");
        $stmt->execute($phoneVariations);
        $existing = $stmt->fetch();

        if ($existing) {
            $fields = [];
            $params = [];
            foreach ($filtered as $key => $value) {
                if ($key !== 'id' && $key !== 'phone') {
                    $fields[] = "`$key` = ?";
                    $params[] = $value;
                }
            }
            if (!empty($fields)) {
                $params[] = $existing['id'];
                $stmt = $db->prepare("UPDATE users SET " . implode(', ', $fields) . " WHERE id = ?");
                $stmt->execute($params);
            }
            echo json_encode(['success' => true, 'phone' => $existing['phone'], 'action' => 'UPDATE']);
        } else {
            $keys = array_keys($filtered);
            $values = array_values($filtered);
            $placeholders = array_fill(0, count($keys), '?');
            $stmt = $db->prepare("INSERT INTO users (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
            $stmt->execute($values);
            echo json_encode(['success' => true, 'id' => $db->lastInsertId(), 'action' => 'CREATE']);
        }
        exit;
    }

    // GET — by phone only (no bulk list)
    $phone = isset($_GET['phone']) ? $_GET['phone'] : null;
    if (!$phone) {
        http_response_code(400);
        echo json_encode(['error' => 'phone parameter required']);
        exit;
    }

    $phoneVariations = phone_variations($phone);
    $placeholders = implode(',', array_fill(0, count($phoneVariations), '?'));
    $stmt = $db->prepare(
        "SELECT id, phone, name, email, role, firebase_uid, avatar_url, is_phone_verified, created_at, updated_at
         FROM users WHERE phone IN ($placeholders) LIMIT 1"
    );
    $stmt->execute($phoneVariations);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        $stmt = $db->prepare(
            "SELECT id, phone, name, email, role, firebase_uid, avatar_url, is_phone_verified, created_at, updated_at
             FROM users WHERE UPPER(name) = UPPER(?) LIMIT 1"
        );
        $stmt->execute([trim((string) $phone)]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
    }
    if ($user) {
        $user['is_phone_verified'] = (bool)$user['is_phone_verified'];
        $user = strip_user_secrets($user);
        echo json_encode($user);
    } else {
        echo json_encode(['error' => 'User not found']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
