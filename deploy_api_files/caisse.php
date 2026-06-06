<?php
/**
 * Cash Management API (Caisse POS)
 *
 * GET  ?shop_id=1              → active session + transactions + summary
 * GET  ?shop_id=1&history=1    → closed sessions history
 * POST action=open_session     → open a new cash session
 * POST action=close_session    → close active session
 * POST action=add_transaction  → record sale/expense/withdrawal/deposit
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();

    // Ensure tables exist
    $db->exec("
        CREATE TABLE IF NOT EXISTS cash_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            shop_id INT NOT NULL,
            opened_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            closed_at DATETIME NULL,
            opening_balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
            closing_balance DECIMAL(12, 2) NULL,
            expected_balance DECIMAL(12, 2) NULL,
            opened_by VARCHAR(50) NULL,
            closed_by VARCHAR(50) NULL,
            notes TEXT NULL,
            status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_shop_status (shop_id, status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    $db->exec("
        CREATE TABLE IF NOT EXISTS cash_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            session_id INT NOT NULL,
            shop_id INT NOT NULL,
            type ENUM('sale', 'expense', 'withdrawal', 'deposit') NOT NULL,
            amount DECIMAL(12, 2) NOT NULL,
            description VARCHAR(255) NULL,
            payment_method ENUM('cash', 'mobile_money', 'card') NOT NULL DEFAULT 'cash',
            created_by VARCHAR(50) NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_session (session_id),
            INDEX idx_shop_created (shop_id, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $shopId = isset($_GET['shop_id']) ? (int)$_GET['shop_id'] : null;
        if (!$shopId) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'shop_id is required']);
            exit;
        }

        if (isset($_GET['history'])) {
            $stmt = $db->prepare("
                SELECT * FROM cash_sessions
                WHERE shop_id = ? AND status = 'closed'
                ORDER BY closed_at DESC LIMIT 30
            ");
            $stmt->execute([$shopId]);
            $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'sessions' => $sessions]);
            exit;
        }

        $stmt = $db->prepare("
            SELECT * FROM cash_sessions
            WHERE shop_id = ? AND status = 'open'
            ORDER BY opened_at DESC LIMIT 1
        ");
        $stmt->execute([$shopId]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);

        $transactions = [];
        $summary = [
            'sales' => 0,
            'expenses' => 0,
            'withdrawals' => 0,
            'deposits' => 0,
            'current_balance' => 0,
        ];

        if ($session) {
            $stmt = $db->prepare("
                SELECT * FROM cash_transactions
                WHERE session_id = ?
                ORDER BY created_at DESC
            ");
            $stmt->execute([$session['id']]);
            $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $balance = (float)$session['opening_balance'];
            foreach ($transactions as $tx) {
                $amt = (float)$tx['amount'];
                switch ($tx['type']) {
                    case 'sale':
                    case 'deposit':
                        $summary[$tx['type'] === 'sale' ? 'sales' : 'deposits'] += $amt;
                        $balance += $amt;
                        break;
                    case 'expense':
                    case 'withdrawal':
                        $summary[$tx['type'] === 'expense' ? 'expenses' : 'withdrawals'] += $amt;
                        $balance -= $amt;
                        break;
                }
            }
            $summary['current_balance'] = $balance;
        }

        echo json_encode([
            'success' => true,
            'session' => $session ?: null,
            'transactions' => $transactions,
            'summary' => $summary,
        ]);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input || empty($input['action'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'action is required']);
            exit;
        }

        $action = $input['action'];
        $shopId = isset($input['shop_id']) ? (int)$input['shop_id'] : null;
        if (!$shopId) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'shop_id is required']);
            exit;
        }

        switch ($action) {
            case 'open_session':
                $stmt = $db->prepare("SELECT id FROM cash_sessions WHERE shop_id = ? AND status = 'open'");
                $stmt->execute([$shopId]);
                if ($stmt->fetch()) {
                    http_response_code(409);
                    echo json_encode(['success' => false, 'error' => 'Une session est déjà ouverte']);
                    exit;
                }
                $openingBalance = isset($input['opening_balance']) ? (float)$input['opening_balance'] : 0;
                $openedBy = $input['opened_by'] ?? null;
                $notes = $input['notes'] ?? null;
                $stmt = $db->prepare("
                    INSERT INTO cash_sessions (shop_id, opening_balance, opened_by, notes, status)
                    VALUES (?, ?, ?, ?, 'open')
                ");
                $stmt->execute([$shopId, $openingBalance, $openedBy, $notes]);
                echo json_encode(['success' => true, 'id' => (int)$db->lastInsertId()]);
                break;

            case 'close_session':
                $sessionId = isset($input['session_id']) ? (int)$input['session_id'] : null;
                if (!$sessionId) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'session_id is required']);
                    exit;
                }
                $closingBalance = isset($input['closing_balance']) ? (float)$input['closing_balance'] : null;
                $expectedBalance = isset($input['expected_balance']) ? (float)$input['expected_balance'] : null;
                $closedBy = $input['closed_by'] ?? null;
                $notes = $input['notes'] ?? null;
                $stmt = $db->prepare("
                    UPDATE cash_sessions
                    SET status = 'closed', closed_at = NOW(),
                        closing_balance = ?, expected_balance = ?,
                        closed_by = ?, notes = COALESCE(?, notes)
                    WHERE id = ? AND shop_id = ? AND status = 'open'
                ");
                $stmt->execute([$closingBalance, $expectedBalance, $closedBy, $notes, $sessionId, $shopId]);
                if ($stmt->rowCount() === 0) {
                    http_response_code(404);
                    echo json_encode(['success' => false, 'error' => 'Session introuvable ou déjà fermée']);
                    exit;
                }
                echo json_encode(['success' => true]);
                break;

            case 'add_transaction':
                $sessionId = isset($input['session_id']) ? (int)$input['session_id'] : null;
                $type = $input['type'] ?? null;
                $amount = isset($input['amount']) ? (float)$input['amount'] : 0;
                $allowedTypes = ['sale', 'expense', 'withdrawal', 'deposit'];
                if (!$sessionId || !$type || !in_array($type, $allowedTypes) || $amount <= 0) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'error' => 'session_id, type et amount valides requis']);
                    exit;
                }
                $stmt = $db->prepare("SELECT id FROM cash_sessions WHERE id = ? AND shop_id = ? AND status = 'open'");
                $stmt->execute([$sessionId, $shopId]);
                if (!$stmt->fetch()) {
                    http_response_code(404);
                    echo json_encode(['success' => false, 'error' => 'Session ouverte introuvable']);
                    exit;
                }
                $description = $input['description'] ?? null;
                $paymentMethod = $input['payment_method'] ?? 'cash';
                $createdBy = $input['created_by'] ?? null;
                $stmt = $db->prepare("
                    INSERT INTO cash_transactions
                    (session_id, shop_id, type, amount, description, payment_method, created_by)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ");
                $stmt->execute([$sessionId, $shopId, $type, $amount, $description, $paymentMethod, $createdBy]);
                echo json_encode(['success' => true, 'id' => (int)$db->lastInsertId()]);
                break;

            default:
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Unknown action']);
        }
        exit;
    }

    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
