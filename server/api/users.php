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

try {
    $db = DB::getInstance();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            throw new Exception('Invalid JSON input');
        }

        $phone = isset($input['phone']) ? $input['phone'] : null;
        $remoteId = isset($input['remote_id']) ? $input['remote_id'] : null;

        if (!$phone) {
            throw new Exception('Phone number is required');
        }

        // Check if user exists by phone, accepting local and international DRC formats.
        $phoneVariations = phone_variations($phone);
        $placeholders = implode(',', array_fill(0, count($phoneVariations), '?'));
        $stmt = $db->prepare("SELECT id, phone FROM users WHERE phone IN ($placeholders) LIMIT 1");
        $stmt->execute($phoneVariations);
        $existing = $stmt->fetch();

        if ($existing) {
            // UPDATE existing user (one number = one account)
            $fields = [];
            $params = [];
            foreach ($input as $key => $value) {
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
            // CREATE new user
            $keys = array_keys($input);
            $values = array_values($input);
            $placeholders = array_fill(0, count($keys), '?');
            
            $stmt = $db->prepare("INSERT INTO users (" . implode(', ', $keys) . ") VALUES (" . implode(', ', $placeholders) . ")");
            $stmt->execute($values);
            
            echo json_encode(['success' => true, 'id' => $db->lastInsertId(), 'action' => 'CREATE']);
        }
        exit;
    }

    // GET Logic (Fetch by phone)
    $phone = isset($_GET['phone']) ? $_GET['phone'] : null;
    if ($phone) {
        $phoneVariations = phone_variations($phone);
        $placeholders = implode(',', array_fill(0, count($phoneVariations), '?'));
        $stmt = $db->prepare("SELECT * FROM users WHERE phone IN ($placeholders) LIMIT 1");
        $stmt->execute($phoneVariations);
        $user = $stmt->fetch();
        if (!$user) {
            $stmt = $db->prepare("SELECT * FROM users WHERE UPPER(name) = UPPER(?) LIMIT 1");
            $stmt->execute([trim((string) $phone)]);
            $user = $stmt->fetch();
        }
        if ($user) {
            $user['is_phone_verified'] = (bool)$user['is_phone_verified'];
        }
        echo json_encode($user ? $user : ['error' => 'User not found']);
    } else {
        // List all users (only for admin/sync purposes if needed)
        $stmt = $db->query("SELECT * FROM users LIMIT 100");
        $users = $stmt->fetchAll();
        foreach ($users as &$user) {
            $user['is_phone_verified'] = (bool)$user['is_phone_verified'];
        }
        echo json_encode($users);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
