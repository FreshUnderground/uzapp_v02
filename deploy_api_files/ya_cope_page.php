<?php
/**
 * Ya Cope listing landing page with Open Graph meta tags.
 * Public page — no authentication required.
 */
$dbFile = __DIR__ . '/db.php';
if (!is_file($dbFile)) {
    $dbFile = __DIR__ . '/../db.php';
}
require_once $dbFile;
require_once __DIR__ . '/phone_utils.php';
require_once __DIR__ . '/product_contact_utils.php';
require_once __DIR__ . '/ya_cope_utils.php';
require_once __DIR__ . '/smart_open_bridge.php';

$listingId = $_GET['id'] ?? '';
if (!$listingId) {
    header('Location: https://uzaapp.com');
    exit;
}

$listing = null;

try {
    $db = DB::getInstance();
    ya_cope_purge_expired($db);
    $activeWhere = ya_cope_active_where();
    $stmt = $db->prepare(
        "SELECT * FROM ya_cope_listings WHERE id = ? AND {$activeWhere} LIMIT 1"
    );
    $stmt->execute([$listingId]);
    $listing = $stmt->fetch(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    error_log('ya_cope_page.php error: ' . $e->getMessage());
}

if (isset($_GET['format']) && $_GET['format'] === 'json') {
    header('Content-Type: application/json');
    if (!$listing) {
        http_response_code(404);
        echo json_encode(['success' => false, 'listing' => null]);
        exit;
    }
    echo json_encode(['success' => true, 'listing' => $listing]);
    exit;
}

if (!$listing) {
    http_response_code(404);
}

$listingName = $listing ? ($listing['name'] ?? null) : null;
$listingImages = $listing ? ($listing['image_urls'] ?? null) : null;
$listingPhone = $listing ? ($listing['phone'] ?? null) : null;
$listingAddress = $listing ? ($listing['address'] ?? null) : null;

$tagline = uzaapp_marketplace_tagline();
$title = $listingName
    ? htmlspecialchars($listingName . ' - Ya Cope · Uzaapp')
    : 'Annonce introuvable - Uzaapp';
$description = $listingName
    ? htmlspecialchars(
        $listingName . ' — Occasion · Prix à discuter sur Ya Cope - ' . $tagline
    )
    : 'Cette annonce n\'est plus disponible sur Uzaapp - ' . $tagline;

$image = 'https://uzaapp.com/assets/logo.png';
if ($listingImages) {
    $images = explode(',', $listingImages);
    $firstImage = isset($images[0]) ? trim($images[0]) : '';
    if ($firstImage !== '') {
        if (strpos($firstImage, 'http') !== 0) {
            $firstImage = 'https://uzaapp.com/' . ltrim($firstImage, '/');
        }
        $image = $firstImage;
    }
}

$pageUrl = 'https://uzaapp.com/ya-cope/' . urlencode($listingId);

$whatsAppUrl = null;
if ($listing && $listingPhone) {
    $waPhone = shop_whatsapp_number($listingPhone, null);
    if ($waPhone !== null) {
        $msg = 'Bonjour, je vous contacte depuis UzaApp (Ya Cope).' . "\n"
            . 'Je suis intéressé(e) par : ' . ($listingName ?? 'Annonce') . "\n\n"
            . '>> Voir l\'annonce :' . "\n" . $pageUrl . "\n\n"
            . 'Est-ce que l\'article est toujours disponible ?';
        $whatsAppUrl = product_whatsapp_url($waPhone, $msg);
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
  <meta property="og:type" content="product">
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
    h1 { color: #019C94; font-size: 24px; margin-bottom: 8px; }
    .badge {
      display: inline-block;
      background: #fff3e0;
      color: #ff9800;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 12px;
    }
    p { color: #666; margin-bottom: 24px; line-height: 1.5; }
    .btn {
      display: inline-block;
      background: #019C94;
      color: white;
      text-decoration: none;
      padding: 14px 32px;
      border-radius: 12px;
      font-weight: 600;
      font-size: 16px;
    }
    .btn-whatsapp { background: #25D366; width: 100%; margin-top: 16px; }
    .btn-outline {
      background: transparent;
      color: #019C94;
      border: 2px solid #019C94;
      width: 100%;
      margin-top: 10px;
    }
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
    .product-info .price { font-size: 18px; color: #019C94; font-weight: 700; margin-top: 4px; }
    .product-info .address { font-size: 13px; color: #888; margin-top: 8px; }
    .store-links { margin-top: 24px; }
    .store-links a { color: #019C94; text-decoration: underline; margin: 0 8px; }
  </style>
</head>
<body>
  <div class="container">
    <img src="/assets/logo.png" alt="Uzaapp" class="logo" onerror="this.style.display='none'">
    <h1>Ya Cope</h1>
    <span class="badge">Occasion · sans boutique</span>
    <p><?= htmlspecialchars($tagline) ?></p>

    <?php if ($listing): ?>
    <div class="product-info">
      <?php if (!empty($listingImages)): ?>
        <?php
          $rawFirst = trim(explode(',', $listingImages)[0]);
          $firstImage = $rawFirst;
          if ($rawFirst !== '' && strpos($rawFirst, 'http') !== 0) {
              $firstImage = 'https://uzaapp.com/' . ltrim($rawFirst, '/');
          }
        ?>
        <img src="<?= htmlspecialchars($firstImage) ?>" alt="<?= htmlspecialchars($listingName ?? 'Annonce') ?>">
      <?php endif; ?>
      <div class="name"><?= htmlspecialchars($listingName ?? 'Annonce') ?></div>
      <div class="price">Prix à discuter</div>
      <?php if (!empty($listingAddress)): ?>
        <div class="address"><?= htmlspecialchars($listingAddress) ?></div>
      <?php endif; ?>
    </div>
    <div class="actions">
      <?php if ($whatsAppUrl): ?>
        <a href="<?= htmlspecialchars($whatsAppUrl) ?>" class="btn btn-whatsapp" rel="noopener noreferrer">
          Contacter sur WhatsApp
        </a>
      <?php endif; ?>
      <a href="<?= htmlspecialchars(landingWebUrl('ya-cope', $listingId), ENT_QUOTES, 'UTF-8') ?>" class="btn" id="openApp">
        Accéder à Uzaapp
      </a>
    </div>
    <?php else: ?>
    <div class="product-info" style="text-align:center; padding: 40px 20px;">
      <div style="font-size:64px; margin-bottom:16px; color:#019C94;">404</div>
      <div class="name" style="font-size:20px; color:#333; margin-bottom:8px;">Annonce introuvable</div>
      <p style="color:#666; font-size:15px; margin-bottom:24px;">Cette annonce a probablement été vendue ou retirée.</p>
      <a href="https://uzaapp.com" class="btn">Retour à l'accueil</a>
    </div>
    <?php endif; ?>

    <div class="store-links">
      <p style="margin-top:16px; font-size:14px;">Pas encore l'app?</p>
      <a href="<?= htmlspecialchars(landingPlayStoreUrl(), ENT_QUOTES, 'UTF-8') ?>" target="_blank" rel="noopener noreferrer">Play Store</a>
    </div>
  </div>

  <?php if ($listing): renderLandingOpenScript('ya-cope', $listingId); endif; ?>
</body>
</html>
