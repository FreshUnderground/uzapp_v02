<?php
require_once __DIR__ . '/../db.php';

// Allow API key authentication only (no user auth required for login)
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
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed. Use POST.']);
        exit;
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        throw new Exception('Invalid JSON input');
    }

    $phone = isset($input['phone']) ? $input['phone'] : null;
    $passwordHash = isset($input['password_hash']) ? $input['password_hash'] : null;

    if (!$phone) {
        throw new Exception('Phone number is required');
    }

    if (!$passwordHash) {
        throw new Exception('Password hash is required');
    }

    // Find user by phone, accepting local and international DRC formats.
    $phoneVariations = phone_variations($phone);
    $placeholders = implode(',', array_fill(0, count($phoneVariations), '?'));
    $stmt = $db->prepare("SELECT * FROM users WHERE phone IN ($placeholders) LIMIT 1");
    $stmt->execute($phoneVariations);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Aucun compte trouvé avec ce numéro'
        ]);
        exit;
    }

    // Verify password
    if ($user['password_hash'] !== $passwordHash) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'error' => 'Mot de passe incorrect'
        ]);
        exit;
    }

    // Login successful
    $user['is_phone_verified'] = (bool)$user['is_phone_verified'];
    
    echo json_encode([
        'success' => true,
        'user' => $user
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
