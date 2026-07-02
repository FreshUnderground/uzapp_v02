<?php
/**
 * Crée ou met à jour le compte admin INVESTEE (mot de passe: INVESTEE).
 */
require_once __DIR__ . '/db.php';
authenticate();

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use POST.']);
    exit;
}

const INVESTEE_PASSWORD_HASH =
    '36ec0d6033dc6c7455e83ef762f33b57499511307199e0374159a92b80441e46';

try {
    $db = DB::getInstance();

    $stmt = $db->prepare(
        "INSERT INTO users (phone, name, password_hash, is_phone_verified, role)
         VALUES ('INVESTEE', 'INVESTEE', ?, 1, 'admin')
         ON DUPLICATE KEY UPDATE
           name = VALUES(name),
           password_hash = VALUES(password_hash),
           is_phone_verified = VALUES(is_phone_verified),
           role = VALUES(role)"
    );
    $stmt->execute([INVESTEE_PASSWORD_HASH]);

    $stmt = $db->prepare("SELECT id, phone, name, role FROM users WHERE phone = 'INVESTEE' LIMIT 1");
    $stmt->execute();
    $user = $stmt->fetch();

    echo json_encode([
        'success' => true,
        'message' => 'Compte admin INVESTEE créé ou mis à jour.',
        'user' => $user,
        'login' => [
            'identifier' => 'INVESTEE',
            'password' => 'INVESTEE',
            'role' => 'admin',
        ],
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
