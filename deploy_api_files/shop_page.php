<?php
/**
 * Shop landing page with dynamic Open Graph meta tags.
 * Serves as the WhatsApp link preview target for shared shops.
 * No authentication required — this is a public page.
 */
$dbFile = __DIR__ . '/db.php';
if (!is_file($dbFile)) {
    $dbFile = __DIR__ . '/../db.php';
}
require_once $dbFile;
require_once __DIR__ . '/phone_utils.php';
require_once __DIR__ . '/shop_contact_utils.php';

$shopId = $_GET['id'] ?? '';
if (!$shopId) {
    header('Location: https://uzaapp.com');
    exit;
}

$shop = null;
$dbError = null;

try {
    $db = DB::getInstance();
    $stmt = $db->prepare('SELECT * FROM shops WHERE id = ?');
    $stmt->execute([$shopId]);
    $shop = $stmt->fetch(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $dbError = $e->getMessage();
    error_log('shop_page.php error: ' . $dbError);
}

// JSON API for Flutter deep links (no auth required)
if (isset($_GET['format']) && $_GET['format'] === 'json') {
    header('Content-Type: application/json');
    if (!$shop) {
        http_response_code(404);
        echo json_encode(['success' => false, 'shop' => null]);
        exit;
    }
    echo json_encode(['success' => true, 'shop' => $shop]);
    exit;
}

// Mobile smart opener: try native app, fallback to Flutter web
if (isset($_GET['bridge']) && $_GET['bridge'] === '1') {
    if (!$shop) {
        http_response_code(404);
        header('Location: https://uzaapp.com');
        exit;
    }
    require_once __DIR__ . '/smart_open_bridge.php';
    renderSmartOpenBridge('shop', $shopId, $shop['name'] ?? null);
    exit;
}

if (!$shop) {
    http_response_code(404);
}

$shopName        = $shop ? ($shop['name'] ?? null) : null;
$shopDescription = $shop ? ($shop['description'] ?? null) : null;
$shopVerified    = $shop ? !empty($shop['is_verified']) : false;

$tagline = uzaapp_marketplace_tagline();
$title = $shopName
    ? htmlspecialchars($shopName . ' - Uzaapp')
    : 'Boutique non trouvée - Uzaapp';
$description = $shop
    ? htmlspecialchars(shop_og_description($shop))
    : 'Cette boutique n\'est plus disponible sur Uzaapp - ' . $tagline;

$image = $shop ? shop_og_image($shop) : 'https://uzaapp.com/assets/logo.png';
$displayImage = $shop ? shop_preview_logo_url($shop) : null;
$locationText = $shop ? shop_location_text($shop) : null;
$pageUrl = 'https://uzaapp.com/shop/' . urlencode($shopId);

$whatsAppPhone = null;
$whatsAppUrl = null;
if ($shop) {
    $whatsAppPhone = shop_whatsapp_number(
        $shop['whatsapp'] ?? null,
        $shop['phone'] ?? null
    );
    if ($whatsAppPhone !== null) {
        $whatsAppUrl = product_whatsapp_url(
            $whatsAppPhone,
            shop_whatsapp_message($shop, $pageUrl)
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

  <meta property="og:title" content="<?= $title ?>">
  <meta property="og:description" content="<?= $description ?>">
  <meta property="og:image" content="<?= htmlspecialchars($image) ?>">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="<?= htmlspecialchars($pageUrl) ?>">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Uzaapp">

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
    .shop-info {
      margin-top: 20px;
      padding: 16px;
      background: #f9f9f9;
      border-radius: 12px;
      text-align: left;
    }
    .shop-info img.logo-img {
      width: 96px;
      height: 96px;
      border-radius: 50%;
      object-fit: cover;
      display: block;
      margin: 0 auto 12px;
      border: 3px solid #fff;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .shop-info .name {
      font-weight: 700;
      font-size: 18px;
      color: #222;
      text-align: center;
    }
    .shop-info .location {
      text-align: center;
      color: #666;
      font-size: 14px;
      margin-top: 6px;
    }
    .shop-info .desc {
      margin-top: 12px;
      color: #555;
      font-size: 14px;
      line-height: 1.5;
    }
    .verified {
      display: inline-block;
      background: #e3f2fd;
      color: #1565c0;
      padding: 2px 10px;
      border-radius: 12px;
      font-size: 12px;
      margin-top: 8px;
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

    <?php if ($shop): ?>
    <div class="shop-info">
      <?php if ($displayImage): ?>
        <img src="<?= htmlspecialchars($displayImage) ?>" alt="<?= htmlspecialchars($shopName ?? 'Boutique') ?>" class="logo-img">
      <?php endif; ?>
      <div class="name"><?= htmlspecialchars($shopName ?? 'Boutique') ?></div>
      <?php if ($locationText): ?>
        <div class="location"><?= htmlspecialchars($locationText) ?></div>
      <?php endif; ?>
      <?php if ($shopVerified): ?>
        <div style="text-align:center;"><span class="verified">✓ Boutique vérifiée</span></div>
      <?php endif; ?>
      <?php if (!empty($shopDescription)): ?>
        <div class="desc"><?= htmlspecialchars(mb_substr(strip_tags($shopDescription), 0, 200)) ?></div>
      <?php endif; ?>
    </div>
    <div class="actions">
      <?php if ($whatsAppUrl): ?>
        <a href="<?= htmlspecialchars($whatsAppUrl) ?>" class="btn btn-whatsapp" rel="noopener noreferrer">
          Contacter sur WhatsApp
        </a>
      <?php endif; ?>
      <a href="uzaapp://shop/<?= htmlspecialchars($shopId) ?>" class="btn btn-outline" id="openApp">
        Ouvrir dans l'app
      </a>
    </div>
    <?php else: ?>
    <div class="shop-info" style="text-align:center; padding: 40px 20px;">
      <div style="font-size:64px; margin-bottom:16px; color:#FE3E00;">404</div>
      <div class="name" style="font-size:20px; color:#333; margin-bottom:8px;">Oups! Boutique introuvable</div>
      <p style="color:#666; font-size:15px; margin-bottom:24px;">Cette boutique n'existe plus ou a &eacute;t&eacute; supprim&eacute;e.</p>
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
