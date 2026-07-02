<?php
/**
 * Product landing page with dynamic Open Graph meta tags.
 * Serves as the WhatsApp link preview target for shared products.
 * No authentication required — this is a public page.
 */
$dbFile = __DIR__ . '/db.php';
if (!is_file($dbFile)) {
    $dbFile = __DIR__ . '/../db.php';
}
require_once $dbFile;
require_once __DIR__ . '/phone_utils.php';
require_once __DIR__ . '/product_contact_utils.php';

$productId = $_GET['id'] ?? '';
if (!$productId) {
    header('Location: https://uzaapp.com');
    exit;
}

$product = null;
$shop = null;
$dbError = null;

try {
    $db = DB::getInstance();
    $stmt = $db->prepare('SELECT * FROM products WHERE id = ?');
    $stmt->execute([$productId]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($product && !empty($product['shop_id'])) {
        $shopStmt = $db->prepare('SELECT id, name, whatsapp, phone FROM shops WHERE id = ?');
        $shopStmt->execute([$product['shop_id']]);
        $shop = $shopStmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }
} catch (Exception $e) {
    $dbError = $e->getMessage();
    error_log('product_page.php error: ' . $dbError);
}

// JSON API for Flutter deep links (no auth required)
if (isset($_GET['format']) && $_GET['format'] === 'json') {
    header('Content-Type: application/json');
    if (!$product) {
        http_response_code(404);
        echo json_encode(['success' => false, 'product' => null]);
        exit;
    }
    echo json_encode(['success' => true, 'product' => $product]);
    exit;
}

// Mobile smart opener: try native app, fallback to Flutter web
if (isset($_GET['bridge']) && $_GET['bridge'] === '1') {
    if (!$product) {
        http_response_code(404);
        header('Location: https://uzaapp.com');
        exit;
    }
    require_once __DIR__ . '/smart_open_bridge.php';
    renderSmartOpenBridge('product', $productId, $product['name'] ?? null);
    exit;
}

// Return 404 if product not found or DB error occurred
if (!$product) {
    http_response_code(404);
}

// Safely extract product fields with null coalescing
$productName      = $product ? ($product['name'] ?? null) : null;
$productPrice     = $product ? ($product['price'] ?? null) : null;
$productImages    = $product ? ($product['image_urls'] ?? null) : null;
$productCondition = $product ? ($product['condition'] ?? null) : null;

// Build OG values with safe fallbacks
$tagline = uzaapp_marketplace_tagline();
$title = $productName ? htmlspecialchars($productName . ' - Uzaapp') : 'Produit non trouvé - Uzaapp';
$description = $productName
    ? htmlspecialchars(product_og_description($product))
    : 'Ce produit n\'est plus disponible sur Uzaapp - ' . $tagline;
$previewPrice = $product ? product_preview_price_label($product) : null;

$image = 'https://uzaapp.com/assets/logo.png';
if ($productImages) {
    $images = explode(',', $productImages);
    $firstImage = isset($images[0]) ? trim($images[0]) : '';
    if (!empty($firstImage)) {
        // Ensure absolute URL
        if (strpos($firstImage, 'http') !== 0) {
            $firstImage = 'https://uzaapp.com/' . ltrim($firstImage, '/');
        }
        $image = $firstImage;
    }
}

$conditionLabel = '';
if (!empty($productCondition) && $productCondition !== 'new') {
    $labels = [
        'like_new' => 'Comme neuf',
        'good'     => 'Bon état',
        'fair'     => 'État correct',
        'poor'     => 'Usé',
    ];
    $conditionLabel = $labels[$productCondition] ?? $productCondition;
}

$pageUrl = 'https://uzaapp.com/product/' . urlencode($productId);

$whatsAppPhone = null;
$whatsAppUrl = null;
if ($product && $shop) {
    $whatsAppPhone = shop_whatsapp_number(
        $shop['whatsapp'] ?? null,
        $shop['phone'] ?? null
    );
    if ($whatsAppPhone !== null) {
        $whatsAppUrl = product_whatsapp_url(
            $whatsAppPhone,
            product_whatsapp_message($product, $shop, $pageUrl)
        );
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= $title ?></title>

  <!-- Open Graph for WhatsApp / social previews -->
  <meta property="og:title" content="<?= $title ?>">
  <meta property="og:description" content="<?= $description ?>">
  <meta property="og:image" content="<?= htmlspecialchars($image) ?>">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="<?= htmlspecialchars($pageUrl) ?>">
  <meta property="og:type" content="product">
  <meta property="og:site_name" content="Uzaapp">

  <!-- Twitter Card fallback -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="<?= $title ?>">
  <meta name="twitter:description" content="<?= $description ?>">
  <meta name="twitter:image" content="<?= htmlspecialchars($image) ?>">

  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f5f5;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 32px;
      max-width: 400px;
      width: 90%;
      text-align: center;
      box-shadow: 0 4px 24px rgba(0,0,0,0.08);
    }
    .logo { width: 64px; height: 64px; margin-bottom: 16px; }
    h1 { color: #FE3E00; font-size: 24px; margin-bottom: 8px; }
    p { color: #666; margin-bottom: 24px; line-height: 1.5; }
    .btn {
      display: inline-block;
      background: #FE3E00;
      color: white;
      text-decoration: none;
      padding: 14px 32px;
      border-radius: 12px;
      font-weight: 600;
      font-size: 16px;
      transition: background 0.2s;
    }
    .btn:hover { background: #e03500; }
    .btn-whatsapp {
      background: #25D366;
      width: 100%;
      margin-top: 16px;
    }
    .btn-whatsapp:hover { background: #1da851; }
    .btn-outline {
      background: transparent;
      color: #FE3E00;
      border: 2px solid #FE3E00;
      width: 100%;
      margin-top: 10px;
    }
    .btn-outline:hover { background: #fff5f2; }
    .actions { margin-top: 20px; display: flex; flex-direction: column; gap: 0; }
    .product-info {
      margin-top: 20px;
      padding: 16px;
      background: #f9f9f9;
      border-radius: 12px;
      text-align: left;
    }
    .product-info img { width: 100%; border-radius: 8px; margin-bottom: 12px; }
    .product-info .name { font-weight: 700; font-size: 18px; color: #222; }
    .product-info .price { font-size: 20px; color: #FE3E00; font-weight: 700; margin-top: 4px; }
    .product-info .condition {
      display: inline-block;
      background: #e8f5e9;
      color: #2e7d32;
      padding: 2px 10px;
      border-radius: 12px;
      font-size: 12px;
      margin-top: 6px;
    }
    .store-links { margin-top: 24px; }
    .store-links a { color: #019C94; text-decoration: underline; margin: 0 8px; }
  </style>
</head>
<body>
  <div class="container">
    <img src="/assets/logo.png" alt="Uzaapp" class="logo" onerror="this.style.display='none'">
    <h1>Uzaapp</h1>
    <p><?= htmlspecialchars($tagline) ?></p>

    <?php if ($product): ?>
    <div class="product-info">
      <?php if (!empty($productImages)): ?>
        <?php
          $rawFirst = trim(explode(',', $productImages)[0]);
          $firstImage = $rawFirst;
          if (!empty($rawFirst) && strpos($rawFirst, 'http') !== 0) {
              $firstImage = 'https://uzaapp.com/' . ltrim($rawFirst, '/');
          }
        ?>
        <img src="<?= htmlspecialchars($firstImage) ?>" alt="<?= htmlspecialchars($productName ?? 'Produit') ?>">
      <?php endif; ?>
      <div class="name"><?= htmlspecialchars($productName ?? 'Produit') ?></div>
      <?php if ($previewPrice !== null): ?>
        <div class="price"><?= htmlspecialchars($previewPrice) ?></div>
      <?php endif; ?>
      <?php if ($conditionLabel): ?>
        <div class="condition"><?= htmlspecialchars($conditionLabel) ?></div>
      <?php endif; ?>
    </div>
    <div class="actions">
      <?php if ($whatsAppUrl): ?>
        <a href="<?= htmlspecialchars($whatsAppUrl) ?>" class="btn btn-whatsapp" rel="noopener noreferrer">
          Contacter sur WhatsApp
        </a>
      <?php endif; ?>
      <a href="uzaapp://product/<?= htmlspecialchars($productId) ?>" class="btn btn-outline" id="openApp">
        Ouvrir dans l'app
      </a>
    </div>
    <?php else: ?>
    <div class="product-info" style="text-align:center; padding: 40px 20px;">
      <div style="font-size:64px; margin-bottom:16px; color:#FE3E00;">404</div>
      <div class="name" style="font-size:20px; color:#333; margin-bottom:8px;">Oups! Produit introuvable</div>
      <p style="color:#666; font-size:15px; margin-bottom:24px;">Ce produit a probablement &eacute;t&eacute; vendu ou supprim&eacute; de la plateforme.</p>
      <a href="https://uzaapp.com" class="btn" style="background:#f0f0f0; color:#333;">Retour &agrave; l'accueil</a>
    </div>
    <?php endif; ?>

    <div class="store-links">
      <p style="margin-top:16px; font-size:14px;">Pas encore l'app?</p>
      <a href="https://play.google.com/store/apps/details?id=com.uzaapp" target="_blank">Play Store</a>
    </div>
  </div>

</body>
</html>
