<?php
/**
 * Product Reports API
 *
 * POST /api/reports.php
 *   - Creates a new product report
 *   - Body: { product_id, reason, details? }
 *   - Requires X-API-Key header
 *
 * GET /api/reports.php?product_id=123
 *   - Returns report count for a product (admin use)
 *   - Requires X-API-Key header
 */

require_once __DIR__ . '/../db.php';
authenticate();

header('Content-Type: application/json');

try {
    $db = DB::getInstance();

    // Ensure the product_reports table exists
    $db->exec("
        CREATE TABLE IF NOT EXISTS product_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            product_id INT NOT NULL,
            reason VARCHAR(255) NOT NULL,
            details TEXT,
            reporter_phone VARCHAR(20),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_product_id (product_id),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);

        if (!$input) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON input']);
            exit;
        }

        // Validate required fields
        if (empty($input['product_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'product_id is required']);
            exit;
        }

        if (empty($input['reason'])) {
            http_response_code(400);
            echo json_encode(['error' => 'reason is required']);
            exit;
        }

        // Validate reason against allowed values
        $allowedReasons = [
            'Faux produit',
            'Prix incorrect',
            'Photo trompeuse',
            'Arnaque possible',
            'Autre',
        ];

        if (!in_array($input['reason'], $allowedReasons)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid reason. Allowed: ' . implode(', ', $allowedReasons)]);
            exit;
        }

        $productId = (int)$input['product_id'];
        $reason = $input['reason'];
        $details = isset($input['details']) ? $input['details'] : null;
        $reporterPhone = isset($input['reporter_phone']) ? $input['reporter_phone'] : null;

        if (!$reporterPhone) {
            http_response_code(400);
            echo json_encode(['error' => 'reporter_phone is required']);
            exit;
        }

        // Check that the product exists
        $stmt = $db->prepare("SELECT id FROM products WHERE id = ?");
        $stmt->execute([$productId]);
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            exit;
        }

        // Rate-limit: max 3 reports per product per phone per day
        if ($reporterPhone) {
            $stmt = $db->prepare(
                "SELECT COUNT(*) as cnt FROM product_reports 
                 WHERE product_id = ? AND reporter_phone = ? AND created_at > DATE_SUB(NOW(), INTERVAL 1 DAY)"
            );
            $stmt->execute([$productId, $reporterPhone]);
            $count = (int)$stmt->fetch()['cnt'];
            if ($count >= 3) {
                http_response_code(429);
                echo json_encode(['error' => 'Too many reports for this product today']);
                exit;
            }
        }

        // Insert the report
        $stmt = $db->prepare(
            "INSERT INTO product_reports (product_id, reason, details, reporter_phone) VALUES (?, ?, ?, ?)"
        );
        $stmt->execute([$productId, $reason, $details, $reporterPhone]);

        // Update report_count on the products table (if column exists)
        try {
            $db->exec(
                "ALTER TABLE products ADD COLUMN report_count INT NOT NULL DEFAULT 0"
            );
        } catch (Exception $e) {
            // Column already exists – ignore
        }

        $db->prepare(
            "UPDATE products SET report_count = report_count + 1 WHERE id = ?"
        )->execute([$productId]);

        $reportId = (int)$db->lastInsertId();

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'report_id' => $reportId,
            'product_id' => $productId,
        ]);
        exit;
    }

    // GET: list recent reports (admin) or count for a product
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        if (isset($_GET['list']) && (string) $_GET['list'] === '1') {
            authenticate_admin();

            $limit = isset($_GET['limit']) ? min((int) $_GET['limit'], 100) : 50;
            $stmt = $db->prepare(
                "SELECT pr.id, pr.product_id, pr.reason, pr.details, pr.reporter_phone,
                        pr.created_at, p.name AS product_name, s.name AS shop_name, s.id AS shop_id
                 FROM product_reports pr
                 JOIN products p ON p.id = pr.product_id
                 JOIN shops s ON s.id = p.shop_id
                 ORDER BY pr.created_at DESC
                 LIMIT ?"
            );
            $stmt->bindValue(1, $limit, PDO::PARAM_INT);
            $stmt->execute();
            $reports = $stmt->fetchAll();

            echo json_encode([
                'success' => true,
                'reports' => $reports,
                'count' => count($reports),
            ]);
            exit;
        }

        $productId = isset($_GET['product_id']) ? (int)$_GET['product_id'] : null;

        if (!$productId) {
            http_response_code(400);
            echo json_encode(['error' => 'product_id query parameter is required']);
            exit;
        }

        $stmt = $db->prepare(
            "SELECT COUNT(*) as report_count FROM product_reports WHERE product_id = ?"
        );
        $stmt->execute([$productId]);
        $row = $stmt->fetch();

        // Get breakdown by reason
        $stmt = $db->prepare(
            "SELECT reason, COUNT(*) as count FROM product_reports WHERE product_id = ? GROUP BY reason ORDER BY count DESC"
        );
        $stmt->execute([$productId]);
        $breakdown = $stmt->fetchAll();

        echo json_encode([
            'product_id' => $productId,
            'report_count' => (int)$row['report_count'],
            'breakdown' => $breakdown,
        ]);
        exit;
    }

    // Unsupported method
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
