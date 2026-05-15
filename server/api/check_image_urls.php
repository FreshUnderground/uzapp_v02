<?php
/**
 * Diagnostic Script: Check Image URL Sources
 * 
 * This script analyzes your database to identify:
 * 1. How many images use Firebase Storage URLs
 * 2. How many images use server URLs (uzaapp.com)
 * 3. Which specific records still need migration
 * 
 * Run this script to understand the current state of your image URLs.
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Diagnostic des URLs d'images - UZA App</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 28px;
        }
        .header p {
            margin: 0;
            opacity: 0.9;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            margin: 0 0 10px 0;
            color: #333;
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .stat-card .number {
            font-size: 48px;
            font-weight: bold;
            margin: 0;
        }
        .stat-card .label {
            color: #666;
            font-size: 14px;
            margin: 5px 0 0 0;
        }
        .firebase { color: #ff6b6b; }
        .server { color: #51cf66; }
        .total { color: #339af0; }
        .section {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .section h2 {
            margin: 0 0 20px 0;
            color: #333;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #dee2e6;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .url {
            font-family: 'Courier New', monospace;
            font-size: 12px;
            word-break: break-all;
            max-width: 400px;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: bold;
        }
        .badge-firebase {
            background: #ffe3e3;
            color: #c92a2a;
        }
        .badge-server {
            background: #d3f9d8;
            color: #2b8a3e;
        }
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .alert-warning {
            background: #fff3bf;
            border-left: 4px solid #fcc419;
            color: #e67700;
        }
        .alert-success {
            background: #d3f9d8;
            border-left: 4px solid #51cf66;
            color: #2b8a3e;
        }
        .action-btn {
            display: inline-block;
            padding: 12px 24px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            margin-top: 10px;
        }
        .action-btn:hover {
            background: #5a67d8;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Diagnostic des URLs d'Images</h1>
        <p>Analyse complète des sources d'images dans votre base de données</p>
    </div>

    <?php
    try {
        $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // ===== SHOPS =====
        $shopsTotal = $pdo->query("SELECT COUNT(*) FROM shops")->fetchColumn();
        $shopsFirebase = $pdo->query("
            SELECT COUNT(*) FROM shops 
            WHERE logo_url LIKE '%firebasestorage.googleapis.com%'
               OR banner_url LIKE '%firebasestorage.googleapis.com%'
               OR video_url LIKE '%firebasestorage.googleapis.com%'
        ")->fetchColumn();
        $shopsServer = $pdo->query("
            SELECT COUNT(*) FROM shops 
            WHERE (logo_url LIKE '%uzaapp.com%'
               OR banner_url LIKE '%uzaapp.com%'
               OR video_url LIKE '%uzaapp.com%')
        ")->fetchColumn();

        // ===== PRODUCTS =====
        $productsTotal = $pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();
        $productsFirebase = $pdo->query("
            SELECT COUNT(*) FROM products 
            WHERE image_urls LIKE '%firebasestorage.googleapis.com%'
        ")->fetchColumn();
        $productsServer = $pdo->query("
            SELECT COUNT(*) FROM products 
            WHERE image_urls LIKE '%uzaapp.com%'
        ")->fetchColumn();

        // ===== STORIES =====
        $storiesTotal = $pdo->query("SELECT COUNT(*) FROM stories")->fetchColumn();
        $storiesFirebase = $pdo->query("
            SELECT COUNT(*) FROM stories 
            WHERE media_url LIKE '%firebasestorage.googleapis.com%'
        ")->fetchColumn();
        $storiesServer = $pdo->query("
            SELECT COUNT(*) FROM stories 
            WHERE media_url LIKE '%uzaapp.com%'
        ")->fetchColumn();

        // ===== STORY_MEDIA =====
        $storyMediaTotal = $pdo->query("SELECT COUNT(*) FROM story_media")->fetchColumn();
        $storyMediaFirebase = $pdo->query("
            SELECT COUNT(*) FROM story_media 
            WHERE media_url LIKE '%firebasestorage.googleapis.com%'
        ")->fetchColumn();
        $storyMediaServer = $pdo->query("
            SELECT COUNT(*) FROM story_media 
            WHERE media_url LIKE '%uzaapp.com%'
        ")->fetchColumn();

        // Calculate totals
        $totalRecords = $shopsTotal + $productsTotal + $storiesTotal + $storyMediaTotal;
        $totalFirebase = $shopsFirebase + $productsFirebase + $storiesFirebase + $storyMediaFirebase;
        $totalServer = $shopsServer + $productsServer + $storiesServer + $storyMediaServer;
        $firebasePercentage = $totalRecords > 0 ? round(($totalFirebase / $totalRecords) * 100, 1) : 0;

        // ===== DISPLAY STATS =====
        echo '<div class="stats-grid">';
        echo '<div class="stat-card">';
        echo '<h3>Total Records</h3>';
        echo '<p class="number total">' . $totalRecords . '</p>';
        echo '<p class="label">Shops + Products + Stories</p>';
        echo '</div>';

        echo '<div class="stat-card">';
        echo '<h3>Firebase URLs</h3>';
        echo '<p class="number firebase">' . $totalFirebase . '</p>';
        echo '<p class="label">' . $firebasePercentage . '% du total</p>';
        echo '</div>';

        echo '<div class="stat-card">';
        echo '<h3>Server URLs</h3>';
        echo '<p class="number server">' . $totalServer . '</p>';
        echo '<p class="label">Migrés vers uzaapp.com</p>';
        echo '</div>';
        echo '</div>';

        // Alert if Firebase URLs still exist
        if ($totalFirebase > 0) {
            echo '<div class="alert alert-warning">';
            echo '<strong>⚠️ Attention:</strong> ' . $totalFirebase . ' enregistrements utilisent encore Firebase Storage. ';
            echo 'Cela peut causer des erreurs HTTP 402 (quota dépassé) et des images non disponibles.';
            echo '<br><br>';
            echo '<strong>Solution:</strong> Exécutez le script <code>fix_firebase_urls.sql</code> pour migrer toutes les URLs vers votre serveur.';
            echo '</div>';
        } else {
            echo '<div class="alert alert-success">';
            echo '<strong>✅ Parfait!</strong> Toutes les URLs ont été migrées vers votre serveur. Aucune URL Firebase détectée.';
            echo '</div>';
        }

        // ===== DETAILED BREAKDOWN =====
        echo '<div class="section">';
        echo '<h2>📱 Shops (Boutiques)</h2>';
        echo '<p><strong>Total:</strong> ' . $shopsTotal . ' | ';
        echo '<span style="color:#ff6b6b">Firebase: ' . $shopsFirebase . '</span> | ';
        echo '<span style="color:#51cf66">Server: ' . $shopsServer . '</span></p>';
        
        if ($shopsFirebase > 0) {
            echo '<table>';
            echo '<tr><th>ID</th><th>Nom</th><th>Type</th><th>URL</th></tr>';
            $stmt = $pdo->query("
                SELECT id, name, 
                       CASE 
                           WHEN logo_url LIKE '%firebasestorage%' THEN 'logo_url'
                           WHEN banner_url LIKE '%firebasestorage%' THEN 'banner_url'
                           WHEN video_url LIKE '%firebasestorage%' THEN 'video_url'
                       END as field_name,
                       CASE 
                           WHEN logo_url LIKE '%firebasestorage%' THEN logo_url
                           WHEN banner_url LIKE '%firebasestorage%' THEN banner_url
                           WHEN video_url LIKE '%firebasestorage%' THEN video_url
                       END as url_value
                FROM shops
                WHERE logo_url LIKE '%firebasestorage%'
                   OR banner_url LIKE '%firebasestorage%'
                   OR video_url LIKE '%firebasestorage%'
                LIMIT 10
            ");
            while ($row = $stmt->fetch()) {
                echo '<tr>';
                echo '<td>' . $row['id'] . '</td>';
                echo '<td>' . htmlspecialchars($row['name']) . '</td>';
                echo '<td><span class="badge badge-firebase">' . $row['field_name'] . '</span></td>';
                echo '<td class="url">' . htmlspecialchars(substr($row['url_value'], 0, 100)) . '...</td>';
                echo '</tr>';
            }
            echo '</table>';
        }
        echo '</div>';

        echo '<div class="section">';
        echo '<h2>📦 Products (Produits)</h2>';
        echo '<p><strong>Total:</strong> ' . $productsTotal . ' | ';
        echo '<span style="color:#ff6b6b">Firebase: ' . $productsFirebase . '</span> | ';
        echo '<span style="color:#51cf66">Server: ' . $productsServer . '</span></p>';
        
        if ($productsFirebase > 0) {
            echo '<table>';
            echo '<tr><th>ID</th><th>Nom</th><th>URL (aperçu)</th></tr>';
            $stmt = $pdo->query("
                SELECT id, name, image_urls 
                FROM products 
                WHERE image_urls LIKE '%firebasestorage%'
                LIMIT 10
            ");
            while ($row = $stmt->fetch()) {
                echo '<tr>';
                echo '<td>' . $row['id'] . '</td>';
                echo '<td>' . htmlspecialchars($row['name']) . '</td>';
                echo '<td class="url">' . htmlspecialchars(substr($row['image_urls'], 0, 100)) . '...</td>';
                echo '</tr>';
            }
            echo '</table>';
        }
        echo '</div>';

        echo '<div class="section">';
        echo '<h2>📸 Stories & Arrivages</h2>';
        echo '<p><strong>Total Stories:</strong> ' . $storiesTotal . ' | ';
        echo '<span style="color:#ff6b6b">Firebase: ' . $storiesFirebase . '</span> | ';
        echo '<span style="color:#51cf66">Server: ' . $storiesServer . '</span></p>';
        
        echo '<p><strong>Total Story Media:</strong> ' . $storyMediaTotal . ' | ';
        echo '<span style="color:#ff6b6b">Firebase: ' . $storyMediaFirebase . '</span> | ';
        echo '<span style="color:#51cf66">Server: ' . $storyMediaServer . '</span></p>';
        
        if ($storiesFirebase > 0 || $storyMediaFirebase > 0) {
            echo '<table>';
            echo '<tr><th>Type</th><th>ID</th><th>Shop ID</th><th>URL (aperçu)</th></tr>';
            
            if ($storiesFirebase > 0) {
                $stmt = $pdo->query("
                    SELECT 'story' as type, id, shop_id, media_url 
                    FROM stories 
                    WHERE media_url LIKE '%firebasestorage%'
                    LIMIT 5
                ");
                while ($row = $stmt->fetch()) {
                    echo '<tr>';
                    echo '<td><span class="badge badge-firebase">Story</span></td>';
                    echo '<td>' . $row['id'] . '</td>';
                    echo '<td>' . $row['shop_id'] . '</td>';
                    echo '<td class="url">' . htmlspecialchars(substr($row['media_url'], 0, 100)) . '...</td>';
                    echo '</tr>';
                }
            }
            
            if ($storyMediaFirebase > 0) {
                $stmt = $pdo->query("
                    SELECT 'story_media' as type, id, story_id, media_url 
                    FROM story_media 
                    WHERE media_url LIKE '%firebasestorage%'
                    LIMIT 5
                ");
                while ($row = $stmt->fetch()) {
                    echo '<tr>';
                    echo '<td><span class="badge badge-firebase">Story Media</span></td>';
                    echo '<td>' . $row['id'] . '</td>';
                    echo '<td>Story: ' . $row['story_id'] . '</td>';
                    echo '<td class="url">' . htmlspecialchars(substr($row['media_url'], 0, 100)) . '...</td>';
                    echo '</tr>';
                }
            }
            echo '</table>';
        }
        echo '</div>';

        // ===== ACTION SECTION =====
        echo '<div class="section">';
        echo '<h2>🔧 Actions</h2>';
        if ($totalFirebase > 0) {
            echo '<p><strong>Étapes pour résoudre le problème:</strong></p>';
            echo '<ol>';
            echo '<li>Assurez-vous que les images migrées existent dans <code>/uploads/migrated/</code> sur votre serveur</li>';
            echo '<li>Exécutez le script SQL: <code>fix_firebase_urls.sql</code></li>';
            echo '<li>Supprimez le cache de l\'application mobile pour forcer le rechargement des nouvelles URLs</li>';
            echo '<li>Redémarrez l\'application et vérifiez que les images s\'affichent correctement</li>';
            echo '</ol>';
            echo '<a href="fix_firebase_urls.sql" class="action-btn" download>📥 Télécharger fix_firebase_urls.sql</a>';
        } else {
            echo '<p>✅ Toutes les URLs sont correctement configurées sur votre serveur!</p>';
            echo '<p>Si vous voyez encore des erreurs "Image non disponible", vérifiez:</p>';
            echo '<ul>';
            echo '<li>Les fichiers existent dans <code>/uploads/migrated/</code></li>';
            echo '<li>Les permissions de fichiers sont correctes (644 pour les fichiers, 755 pour les dossiers)</li>';
            echo '<li>Le fichier <code>.htaccess</code> est correctement configuré dans le dossier uploads</li>';
            echo '</ul>';
        }
        echo '</div>';

    } catch (PDOException $e) {
        echo '<div class="alert alert-warning">';
        echo '<strong>Erreur de connexion à la base de données:</strong> ' . htmlspecialchars($e->getMessage());
        echo '</div>';
    }
    ?>
</body>
</html>
