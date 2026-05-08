<?php
/**
 * Seed Categories Script for UzaApp
 * 
 * Idempotent: checks by name before inserting each category.
 * Supports 3-level hierarchy: Root (level=0) -> Subcategory (level=1) -> Sub-subcategory (level=2)
 * 
 * Usage: GET/POST /api/seed_categories.php
 */

require_once __DIR__ . '/../db.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = DB::getInstance();
    $inserted = 0;

    // ── Helper: find a category id by name (exact match) ──────────────
    $findId = function (string $name) use ($pdo): ?int {
        $stmt = $pdo->prepare('SELECT id FROM categories WHERE name = :name LIMIT 1');
        $stmt->execute([':name' => $name]);
        $row = $stmt->fetch();
        return $row ? (int) $row['id'] : null;
    };

    // ── Helper: insert a category if it does not exist, return its id ─
    $upsert = function (string $name, string $icon, int $level, int $sortOrder, ?int $parentId) use ($pdo, &$inserted): int {
        // Check existence
        $stmt = $pdo->prepare('SELECT id FROM categories WHERE name = :name LIMIT 1');
        $stmt->execute([':name' => $name]);
        $row = $stmt->fetch();

        if ($row) {
            return (int) $row['id'];
        }

        $stmt = $pdo->prepare(
            'INSERT INTO categories (name, icon, level, sort_order, parent_id) VALUES (:name, :icon, :level, :sort_order, :parent_id)'
        );
        $stmt->execute([
            ':name'       => $name,
            ':icon'       => $icon,
            ':level'      => $level,
            ':sort_order' => $sortOrder,
            ':parent_id'  => $parentId,
        ]);
        $inserted++;
        return (int) $pdo->lastInsertId();
    };

    // ================================================================
    // LEVEL 0 – Root categories
    // ================================================================
    $roots = [
        ['name' => 'Phones',     'icon' => 'smartphone',     'sort' => 1],
        ['name' => 'Ordi.',      'icon' => 'computer',       'sort' => 2],
        ['name' => 'Gadgets',    'icon' => 'devices_other',  'sort' => 3],
        ['name' => 'Restau.',    'icon' => 'restaurant',     'sort' => 4],
        ['name' => 'Style',      'icon' => 'shopping_bag',   'sort' => 5],
        ['name' => 'Auto',       'icon' => 'directions_car', 'sort' => 6],
    ];

    $rootIds = [];
    foreach ($roots as $r) {
        $rootIds[$r['name']] = $upsert($r['name'], $r['icon'], 0, $r['sort'], null);
    }

    // ================================================================
    // LEVEL 1 – Subcategories
    // ================================================================
    $subs = [
        'Phones' => [
            ['name' => 'Phones',      'sort' => 1],
            ['name' => 'Tablets',     'sort' => 2],
            ['name' => 'Accessoires', 'sort' => 3],
        ],
        'Ordi.' => [
            ['name' => 'Laptops',     'sort' => 1],
            ['name' => 'Desktops',    'sort' => 2],
            ['name' => 'Imprimantes', 'sort' => 3],
            ['name' => 'Composants',  'sort' => 4],
            ['name' => 'Reseaux',     'sort' => 5],
            ['name' => 'Logiciels',   'sort' => 6],
        ],
        'Gadgets' => [
            ['name' => 'Montres Connectees', 'sort' => 1],
            ['name' => 'Enceintes & Audio',  'sort' => 2],
            ['name' => 'Cameras',            'sort' => 3],
            ['name' => 'Drones',             'sort' => 4],
            ['name' => 'Gaming',             'sort' => 5],
            ['name' => 'Power Banks',        'sort' => 6],
            ['name' => 'Maison Intelligente', 'sort' => 7],
        ],
        'Auto' => [
            ['name' => 'En Vente',                'sort' => 1],
            ['name' => 'Location avec Chauffeur',  'sort' => 2],
            ['name' => 'Location sans Chauffeur',  'sort' => 3],
        ],
        'Restau.' => [
            ['name' => 'Take Away', 'sort' => 1],
            ['name' => 'Fast Food', 'sort' => 2],
            ['name' => 'Livraison', 'sort' => 3],
        ],
    ];

    $subIds = [];
    foreach ($subs as $parentName => $children) {
        $parentId = $rootIds[$parentName];
        foreach ($children as $c) {
            $subIds[$c['name']] = $upsert($c['name'], '', 1, $c['sort'], $parentId);
        }
    }

    // ================================================================
    // LEVEL 2 – Sub-subcategories
    // ================================================================
    $subsubs = [
        'Phones' => [
            'iPhone', 'Samsung', 'Tecno', 'Itel', 'Infinix',
            'Xiaomi', 'Oppo', 'Huawei', 'Nokia', 'Motorola',
            'Google Pixel', 'OnePlus', 'Realme', 'Vivo', 'Docomo',
        ],
        'Accessoires' => [
            'Coques & Etuis', 'Chargeurs', 'Ecouteurs & Casques',
            'Protections Ecran', 'Cables', 'Supports & Holders',
        ],
        'Laptops' => [
            'HP', 'Dell', 'Lenovo', 'Asus', 'Acer',
            'Apple MacBook', 'MSI', 'Toshiba',
        ],
        'Composants' => [
            'RAM', 'SSD & Disques', 'Cartes Graphiques',
            'Processeurs', 'Cartes Meres', 'Alimentations',
        ],
        'En Vente' => [
            'Voitures', 'Motos', 'Camions', 'Bus & Minibus',
        ],
    ];

    foreach ($subsubs as $parentName => $brands) {
        $parentId = $subIds[$parentName];
        foreach ($brands as $idx => $brand) {
            $upsert($brand, '', 2, $idx + 1, $parentId);
        }
    }

    // ================================================================
    // Result
    // ================================================================
    echo json_encode([
        'success'   => true,
        'inserted'  => $inserted,
        'message'   => $inserted > 0
            ? "$inserted new categories inserted."
            : 'All categories already exist. No new inserts.',
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error'   => $e->getMessage(),
    ]);
}
