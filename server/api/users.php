<?php
require_once '../db.php';
authenticate();

header('Content-Type: application/json');

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

        // Check if user exists by phone
        $stmt = $db->prepare("SELECT id FROM users WHERE phone = ?");
        $stmt->execute([$phone]);
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
                $params[] = $phone;
                $stmt = $db->prepare("UPDATE users SET " . implode(', ', $fields) . " WHERE phone = ?");
                $stmt->execute($params);
            }
            echo json_encode(['success' => true, 'phone' => $phone, 'action' => 'UPDATE']);
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
        $stmt = $db->prepare("SELECT * FROM users WHERE phone = ?");
        $stmt->execute([$phone]);
        $user = $stmt->fetch();
        echo json_encode($user ? $user : ['error' => 'User not found']);
    } else {
        // List all users (only for admin/sync purposes if needed)
        $stmt = $db->query("SELECT * FROM users LIMIT 100");
        echo json_encode($stmt->fetchAll());
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
