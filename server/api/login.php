<?php
require_once __DIR__ . '/../db.php';

// Allow API key authentication only (no user auth required for login)
authenticate();

header('Content-Type: application/json');

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

    // Find user by phone
    $stmt = $db->prepare("SELECT * FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
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
