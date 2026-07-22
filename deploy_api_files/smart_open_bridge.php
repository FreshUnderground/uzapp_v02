<?php
/**
 * Smart app opener: tries native app, falls back to Flutter web.
 */
function landingPlayStoreUrl(): string
{
    return 'https://play.google.com/store/apps/details?id=com.investeegroup.uzaapp';
}

function landingWebUrl(string $type, string $id): string
{
    return 'https://uzaapp.com/' . $type . '/' . rawurlencode($id) . '?web=1';
}

function landingAppUrl(string $type, string $id): string
{
    return 'uzaapp://' . $type . '/' . rawurlencode($id);
}

function renderLandingOpenScript(string $type, string $id): void
{
    $safeId = preg_replace('/[^0-9A-Za-z_-]/', '', $id);
    if ($safeId === '') {
        return;
    }
    if (!in_array($type, ['product', 'shop', 'ya-cope'], true)) {
        $type = 'product';
    }

    $webUrl = landingWebUrl($type, $safeId);
    $appUrl = landingAppUrl($type, $safeId);
    $package = 'com.investeegroup.uzaapp';
    ?>
<script>
(function () {
  var btn = document.getElementById('openApp');
  if (!btn) return;

  var webUrl = <?= json_encode($webUrl) ?>;
  var appUrl = <?= json_encode($appUrl) ?>;
  var packageName = <?= json_encode($package) ?>;
  var linkType = <?= json_encode($type) ?>;
  var linkId = <?= json_encode($safeId) ?>;

  btn.addEventListener('click', function (e) {
    var ua = navigator.userAgent || '';
    if (!/Android|iPhone|iPad|iPod/i.test(ua)) {
      return;
    }

    e.preventDefault();
    var opened = false;
    var timer = null;

    function cancelFallback() {
      opened = true;
      if (timer) clearTimeout(timer);
    }

    timer = setTimeout(function () {
      if (!opened) window.location.href = webUrl;
    }, 2200);

    document.addEventListener('visibilitychange', function () {
      if (document.hidden) cancelFallback();
    }, { once: true });
    window.addEventListener('pagehide', cancelFallback, { once: true });
    window.addEventListener('blur', cancelFallback, { once: true });

    if (/Android/i.test(ua)) {
      window.location.href =
        'intent://' + linkType + '/' + encodeURIComponent(linkId) +
        '#Intent;scheme=uzaapp;package=' + packageName +
        ';S.browser_fallback_url=' + encodeURIComponent(webUrl) + ';end';
    } else {
      window.location.href = appUrl;
    }
  });
})();
</script>
    <?php
}

function renderSmartOpenBridge(string $type, string $id, ?string $label = null): void
{
    if (!in_array($type, ['product', 'shop', 'ya-cope'], true)) {
        $type = 'product';
    }
    $safeId = preg_replace('/[^0-9A-Za-z_-]/', '', $id);
    if ($safeId === '') {
        header('Location: https://uzaapp.com');
        exit;
    }

    $webUrl = 'https://uzaapp.com/' . $type . '/' . rawurlencode($safeId) . '?web=1';
    $appUrl = 'uzaapp://' . $type . '/' . rawurlencode($safeId);
    $package = 'com.investeegroup.uzaapp';
    $title = $label ? htmlspecialchars($label, ENT_QUOTES, 'UTF-8') : 'Uzaapp';
    ?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= $title ?> - Uzaapp</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f5f5;
      color: #333;
      text-align: center;
      padding: 24px;
    }
    .box {
      background: #fff;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 360px;
      box-shadow: 0 4px 24px rgba(0,0,0,0.08);
    }
    h1 { color: #FE3E00; font-size: 22px; margin: 0 0 8px; }
    p { color: #666; line-height: 1.5; margin: 0 0 20px; }
    a {
      display: inline-block;
      color: #019C94;
      font-weight: 600;
      text-decoration: none;
    }
    .spinner {
      width: 36px;
      height: 36px;
      border: 3px solid #eee;
      border-top-color: #FE3E00;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      margin: 0 auto 16px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="box">
    <div class="spinner"></div>
    <h1>Uzaapp</h1>
    <p>Ouverture<?= $label ? ' de <strong>' . $title . '</strong>' : '' ?>…</p>
    <a href="<?= htmlspecialchars($webUrl, ENT_QUOTES, 'UTF-8') ?>" id="webFallback">
      Continuer dans le navigateur
    </a>
  </div>
  <script>
  (function () {
    var webUrl = <?= json_encode($webUrl) ?>;
    var appUrl = <?= json_encode($appUrl) ?>;
    var packageName = <?= json_encode($package) ?>;
    var opened = false;

    function cancelFallback() {
      opened = true;
      if (fallbackTimer) clearTimeout(fallbackTimer);
    }

    document.addEventListener('visibilitychange', function () {
      if (document.hidden) cancelFallback();
    });
    window.addEventListener('pagehide', cancelFallback);
    window.addEventListener('blur', cancelFallback);

    var fallbackTimer = setTimeout(function () {
      if (!opened) window.location.replace(webUrl);
    }, 2200);

    var ua = navigator.userAgent || '';
    if (/Android/i.test(ua)) {
      var intent =
        'intent://<?= $type ?>/<?= rawurlencode($safeId) ?>' +
        '#Intent;scheme=uzaapp;package=' + packageName +
        ';S.browser_fallback_url=' + encodeURIComponent(webUrl) + ';end';
      window.location.href = intent;
    } else if (/iPhone|iPad|iPod/i.test(ua)) {
      window.location.href = appUrl;
    } else {
      cancelFallback();
      window.location.replace(webUrl);
    }
  })();
  </script>
</body>
</html>
    <?php
}
