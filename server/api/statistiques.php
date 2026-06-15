<?php
/**
 * Admin platform dashboard — https://uzaapp.com/statistiques
 *
 * Password-protected web dashboard (session). Configure ADMIN_STATS_PASSWORD in config.php.
 * Exports (when logged in): ?format=json | ?format=csv
 * Period filter: ?preset=7d|30d|90d|365d or ?from=YYYY-MM-DD&to=YYYY-MM-DD
 */
session_start();

$dbFile = __DIR__ . '/../db.php';
if (!is_file($dbFile)) {
    $dbFile = __DIR__ . '/db.php';
}
require_once $dbFile;
require_once __DIR__ . '/platform_stats_lib.php';

if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: /statistiques');
    exit;
}

$loginError = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['password'])) {
    $expected = defined('ADMIN_STATS_PASSWORD') ? ADMIN_STATS_PASSWORD : '';
    if ($expected !== '' && hash_equals($expected, (string) $_POST['password'])) {
        $_SESSION['uza_stats_auth'] = true;
        $_SESSION['uza_stats_auth_at'] = time();
        header('Location: /statistiques');
        exit;
    }
    $loginError = 'Mot de passe incorrect.';
}

$authenticated = !empty($_SESSION['uza_stats_auth']);

if ($authenticated && isset($_SESSION['uza_stats_auth_at'])) {
    if (time() - (int) $_SESSION['uza_stats_auth_at'] > 43200) {
        session_destroy();
        $authenticated = false;
    }
}

if (!$authenticated) {
    render_login_page($loginError);
    exit;
}

$range = platform_stats_parse_range($_GET);

try {
    $db = DB::getInstance();
    $stats = platform_stats_collect($db, $range);
} catch (Exception $e) {
    http_response_code(500);
    echo '<h1>Erreur</h1><p>' . htmlspecialchars($e->getMessage()) . '</p>';
    exit;
}

$exportFormat = isset($_GET['format']) ? (string) $_GET['format'] : '';
if ($exportFormat === 'json') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['success' => true, 'data' => $stats], JSON_UNESCAPED_UNICODE);
    exit;
}
if ($exportFormat === 'csv') {
    $filename = 'uzaapp-stats-' . ($range['from'] ?? 'export') . '_' . ($range['to'] ?? '') . '.csv';
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    echo platform_stats_export_csv($stats);
    exit;
}

render_dashboard($stats);

function render_login_page(?string $error): void
{
    ?><!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>UzaApp — Statistiques</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 50%, #0f766e 100%);
      color: #e2e8f0;
    }
    .card {
      width: min(400px, 92vw); background: rgba(15, 23, 42, 0.92);
      border: 1px solid rgba(148, 163, 184, 0.2); border-radius: 16px;
      padding: 2rem; box-shadow: 0 25px 50px rgba(0,0,0,.35);
    }
    h1 { margin: 0 0 .25rem; font-size: 1.5rem; }
    .sub { color: #94a3b8; margin-bottom: 1.5rem; font-size: .9rem; }
    label { display: block; font-size: .85rem; margin-bottom: .35rem; color: #cbd5e1; }
    input[type=password] {
      width: 100%; padding: .75rem 1rem; border-radius: 10px; border: 1px solid #334155;
      background: #0f172a; color: #f8fafc; font-size: 1rem;
    }
    button {
      margin-top: 1rem; width: 100%; padding: .85rem; border: 0; border-radius: 10px;
      background: #14b8a6; color: #042f2e; font-weight: 700; font-size: 1rem; cursor: pointer;
    }
    button:hover { background: #2dd4bf; }
    .err { background: #7f1d1d; color: #fecaca; padding: .65rem .85rem; border-radius: 8px; margin-bottom: 1rem; font-size: .85rem; }
    .logo { font-size: 2rem; margin-bottom: .5rem; }
  </style>
</head>
<body>
  <form class="card" method="post">
    <div class="logo">📊</div>
    <h1>UzaApp Statistiques</h1>
    <p class="sub">Tableau de bord plateforme — accès réservé</p>
    <?php if ($error): ?><div class="err"><?= htmlspecialchars($error) ?></div><?php endif; ?>
    <label for="password">Mot de passe administrateur</label>
    <input type="password" id="password" name="password" required autofocus autocomplete="current-password">
    <button type="submit">Accéder au dashboard</button>
  </form>
</body>
</html><?php
}

function render_dashboard(array $stats): void
{
    $json = json_encode($stats, JSON_UNESCAPED_UNICODE);
    $generated = htmlspecialchars($stats['generated_at'] ?? '');
    $range = $stats['period'] ?? platform_stats_parse_range([]);
    $periodLabel = htmlspecialchars($range['label'] ?? '30 derniers jours');
    $periodFrom = htmlspecialchars($range['from'] ?? '');
    $periodTo = htmlspecialchars($range['to'] ?? '');
    $activePreset = $range['preset'] ?? '30d';
    $jsonHref = '?' . htmlspecialchars(platform_stats_build_query($range, 'json'));
    $csvHref = '?' . htmlspecialchars(platform_stats_build_query($range, 'csv'));
    ?><!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>UzaApp — Dashboard Statistiques</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
  <style>
    :root {
      --bg: #0b1220; --card: #111827; --border: #1f2937; --text: #f1f5f9;
      --muted: #94a3b8; --accent: #14b8a6; --warn: #f59e0b; --danger: #ef4444;
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: var(--bg); color: var(--text); line-height: 1.45; }
    header {
      position: sticky; top: 0; z-index: 10; display: flex; flex-wrap: wrap; gap: 1rem;
      align-items: center; justify-content: space-between; padding: 1rem 1.25rem;
      background: rgba(11, 18, 32, .95); border-bottom: 1px solid var(--border);
    }
    header h1 { margin: 0; font-size: 1.15rem; }
    header .meta { color: var(--muted); font-size: .8rem; }
    .actions { display: flex; gap: .5rem; flex-wrap: wrap; }
    .btn {
      display: inline-block; padding: .45rem .85rem; border-radius: 8px; font-size: .82rem;
      text-decoration: none; border: 1px solid var(--border); color: var(--text); background: var(--card);
    }
    .btn-primary { background: var(--accent); color: #042f2e; border-color: transparent; font-weight: 600; }
    .btn.active { background: var(--accent); color: #042f2e; border-color: transparent; font-weight: 600; }
    .period-bar {
      display: flex; flex-wrap: wrap; gap: .75rem; align-items: center; justify-content: space-between;
      padding: .75rem 1.25rem; background: rgba(17, 24, 39, .85); border-bottom: 1px solid var(--border);
    }
    .period-presets { display: flex; gap: .35rem; flex-wrap: wrap; }
    .period-custom { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; font-size: .82rem; color: var(--muted); }
    .period-custom input[type=date] {
      padding: .35rem .5rem; border-radius: 8px; border: 1px solid var(--border);
      background: var(--bg); color: var(--text); font-size: .82rem;
    }
    .note { font-size: .75rem; color: var(--muted); margin-top: .35rem; }
    main { padding: 1rem 1.25rem 2.5rem; max-width: 1400px; margin: 0 auto; }
    .grid { display: grid; gap: 1rem; }
    .kpis { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); }
    .cols-2 { grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); }
    .card {
      background: var(--card); border: 1px solid var(--border); border-radius: 14px; padding: 1rem 1.1rem;
    }
    .card h2 { margin: 0 0 .75rem; font-size: .95rem; color: var(--muted); font-weight: 600; text-transform: uppercase; letter-spacing: .04em; }
    .kpi .val { font-size: 1.75rem; font-weight: 800; line-height: 1.1; }
    .kpi .lbl { font-size: .78rem; color: var(--muted); margin-top: .2rem; }
    .kpi .delta { font-size: .72rem; color: var(--accent); margin-top: .35rem; }
    .kpi.warn .val { color: var(--warn); }
    .kpi.danger .val { color: var(--danger); }
    table { width: 100%; border-collapse: collapse; font-size: .82rem; }
    th, td { text-align: left; padding: .45rem .35rem; border-bottom: 1px solid var(--border); }
    th { color: var(--muted); font-weight: 600; }
    tr:last-child td { border-bottom: 0; }
    .badge { display: inline-block; padding: .15rem .45rem; border-radius: 999px; font-size: .7rem; background: #1e293b; }
    .badge.pending { background: #78350f; color: #fde68a; }
    .badge.active { background: #064e3b; color: #a7f3d0; }
    canvas { max-height: 260px; }
    @media (max-width: 640px) { .kpis { grid-template-columns: repeat(2, 1fr); } .kpi .val { font-size: 1.35rem; } }
  </style>
</head>
<body>
<header>
  <div>
    <h1>📊 UzaApp — Statistiques plateforme</h1>
    <div class="meta">Période : <?= $periodLabel ?> · Mis à jour : <?= $generated ?> UTC ·
      <a href="<?= $jsonHref ?>" style="color:var(--accent)">JSON</a> ·
      <a href="<?= $csvHref ?>" style="color:var(--accent)">CSV</a>
    </div>
  </div>
  <div class="actions">
    <a class="btn btn-primary" href="?<?= htmlspecialchars(platform_stats_build_query($range)) ?>">↻ Actualiser</a>
    <a class="btn" href="?logout=1">Déconnexion</a>
  </div>
</header>
<div class="period-bar">
  <div class="period-presets">
    <?php foreach (['7d' => '7 j', '30d' => '30 j', '90d' => '90 j', '365d' => '12 mois'] as $key => $label): ?>
      <a class="btn<?= $activePreset === $key ? ' active' : '' ?>" href="?preset=<?= $key ?>"><?= $label ?></a>
    <?php endforeach; ?>
  </div>
  <form class="period-custom" method="get">
    <span>Personnalisé</span>
    <input type="date" name="from" value="<?= $periodFrom ?>" required aria-label="Date début">
    <span>→</span>
    <input type="date" name="to" value="<?= $periodTo ?>" required aria-label="Date fin">
    <button type="submit" class="btn btn-primary">Appliquer</button>
  </form>
</div>
<main>
  <section class="grid kpis" id="kpi-grid"></section>
  <section class="grid cols-2" style="margin-top:1rem">
    <div class="card"><h2>Ouvertures & visites — <?= $periodLabel ?></h2><canvas id="chartVisits"></canvas></div>
    <div class="card"><h2>Visites par plateforme</h2><canvas id="chartPlatforms"></canvas></div>
  </section>
  <section class="grid cols-2" style="margin-top:1rem">
    <div class="card"><h2>Activité — <?= $periodLabel ?></h2><canvas id="chartActivity"></canvas></div>
    <div class="card"><h2>Contacts par canal (période)</h2><canvas id="chartContacts"></canvas></div>
  </section>
  <section class="grid cols-2" style="margin-top:1rem">
    <div class="card"><h2>Top boutiques — vues produits (cumul)</h2><div id="tableTopShops"></div></div>
    <div class="card"><h2>Top boutiques — contacts (période)</h2><div id="tableTopContacts"></div></div>
  </section>
  <section class="grid cols-2" style="margin-top:1rem">
    <div class="card"><h2>Top produits — vues (cumul)</h2><div id="tableTopProducts"></div></div>
    <div class="card"><h2>Boutiques par ville</h2><canvas id="chartCities"></canvas></div>
  </section>
  <section class="grid cols-2" style="margin-top:1rem">
    <div class="card"><h2>Demandes boost / bannière en attente</h2><div id="tablePending"></div></div>
    <div class="card"><h2>Commandes (période)</h2><div id="tableOrders"></div></div>
  </section>
  <section class="grid cols-2" style="margin-top:1rem">
    <div class="card"><h2>Contacts clients (période)</h2><div id="tableRecentContacts"></div></div>
    <div class="card"><h2>Boutiques actives (période)</h2><div id="tableRecentShops"></div></div>
  </section>
</main>
<script>
const STATS = <?= $json ?>;
const PERIOD = STATS.period || {};

function fmt(n) { return new Intl.NumberFormat('fr-FR').format(n ?? 0); }

function kpi(label, value, delta, cls) {
  return `<article class="card kpi ${cls || ''}"><div class="val">${fmt(value)}</div><div class="lbl">${label}</div>${delta != null && delta !== '' ? `<div class="delta">+${fmt(delta)} sur la période</div>` : ''}</article>`;
}

const o = STATS.overview;
document.getElementById('kpi-grid').innerHTML = [
  kpi('Ouvertures app', o.app_opens_total, o.app_opens_period),
  kpi('Visites web', o.web_visits_total, o.web_visits_period),
  kpi('Visiteurs uniques', o.unique_visitors_period),
  kpi('Sessions reprises', o.session_resumes_total, o.session_resumes_period),
  kpi('Vues produits', o.views_total),
  kpi('Boutiques', o.shops_total, o.shops_period),
  kpi('Produits', o.products_total, o.products_period),
  kpi('Utilisateurs', o.users_total, o.users_period),
  kpi('Partages', o.shares_total),
  kpi('Contacts', o.contacts_total, o.contacts_period),
  kpi('Clients uniques (total)', o.contacts_unique),
  kpi('Clients uniques (période)', o.contacts_unique_period),
  kpi('Abonnés boutiques', o.follows_total),
  kpi('Likes produits', o.likes_total),
  kpi('Commandes', o.orders_total, o.orders_period),
  kpi('Commandes en attente', o.orders_pending, null, o.orders_pending > 0 ? 'warn' : ''),
  kpi('Signalements', o.reports_total, o.reports_period, o.reports_total > 0 ? 'danger' : ''),
  kpi('Boost en attente', o.shops_boost_pending + o.products_boost_pending, null, 'warn'),
  kpi('Stories actives', o.stories_active),
  kpi('Arrivages actifs', o.arrivages_active),
  kpi('Boutiques vérifiées', o.shops_verified),
].join('');

function table(headers, rows) {
  if (!rows.length) return '<p style="color:#94a3b8;font-size:.85rem">Aucune donnée</p>';
  return `<table><thead><tr>${headers.map(h => `<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(r => `<tr>${r.map(c => `<td>${c}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
}

function esc(str) {
  return String(str ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

document.getElementById('tableTopShops').innerHTML = table(['Boutique','Ville','Produits','Vues'],
  (STATS.top_shops_views||[]).map(s => [esc(s.name), esc(s.city||s.commune||'—'), fmt(s.product_count), fmt(s.views)]));

document.getElementById('tableTopContacts').innerHTML = table(['Boutique','Ville','Contacts'],
  (STATS.top_shops_contacts||[]).map(s => [esc(s.name), esc(s.city||s.commune||'—'), fmt(s.contacts)]));

document.getElementById('tableTopProducts').innerHTML = table(['Produit','Boutique','Vues','Partages'],
  (STATS.top_products||[]).map(p => [esc(p.name), esc(p.shop_name), fmt(p.views), fmt(p.shares)]));

const pendingRows = [
  ...(STATS.pending_shop_promos||[]).map(s => ['Boutique', esc(s.name),
    s.boost_status==1?'<span class="badge pending">Boost</span>':'',
    s.banner_status==1?'<span class="badge pending">Bannière</span>':'',
    esc((s.updated_at||'').substring(0,16))]),
  ...(STATS.pending_product_boosts||[]).map(p => ['Produit', esc(p.name+' ('+p.shop_name+')'),
    '<span class="badge pending">Boost produit</span>','', esc((p.updated_at||'').substring(0,16))])
];
document.getElementById('tablePending').innerHTML = table(['Type','Nom','Demande','','Date'], pendingRows);

document.getElementById('tableOrders').innerHTML = table(['#','Boutique','Acheteur','Statut','Date'],
  (STATS.recent_orders||[]).map(x => [x.id, esc(x.shop_name), esc(x.buyer_phone), `<span class="badge">${esc(x.status)}</span>`, esc((x.created_at||'').substring(0,16))]));

document.getElementById('tableRecentContacts').innerHTML = table(['Canal','Client','Boutique','Date'],
  (STATS.recent_contacts||[]).map(c => [esc(c.contact_type), esc(c.user_phone), esc(c.shop_name), esc((c.created_at||'').substring(0,16))]));

document.getElementById('tableRecentShops').innerHTML = table(['Boutique','Ville','Boost','Date'],
  (STATS.recent_shops||[]).map(s => [esc(s.name), esc(s.city||s.commune||'—'),
    s.boost_status==2?'<span class="badge active">Actif</span>':(s.boost_status==1?'<span class="badge pending">Attente</span>':'—'),
    esc((s.updated_at||'').substring(0,16))]));

function fillSeriesDays(series) {
  const map = {}; (series||[]).forEach(r => { map[r.day] = parseInt(r.count, 10); });
  const labels = [], values = [];
  const from = PERIOD.from || new Date(Date.now() - 29 * 864e5).toISOString().slice(0, 10);
  const to = PERIOD.to || new Date().toISOString().slice(0, 10);
  const cursor = new Date(from + 'T12:00:00');
  const end = new Date(to + 'T12:00:00');
  while (cursor <= end) {
    const key = cursor.toISOString().slice(0, 10);
    labels.push(key.slice(5));
    values.push(map[key] || 0);
    cursor.setDate(cursor.getDate() + 1);
  }
  return { labels, values };
}

const actLabels = fillSeriesDays(STATS.series?.products).labels;

new Chart(document.getElementById('chartVisits'), {
  type: 'line',
  data: {
    labels: actLabels,
    datasets: [
      { label: 'Ouvertures app', data: fillSeriesDays(STATS.series?.app_opens).values, borderColor: '#22d3ee', tension: .3 },
      { label: 'Visites web', data: fillSeriesDays(STATS.series?.web_visits).values, borderColor: '#a78bfa', tension: .3 },
      { label: 'Total visites', data: fillSeriesDays(STATS.series?.platform_visits).values, borderColor: '#14b8a6', tension: .3 },
    ]
  },
  options: {
    responsive: true,
    plugins: { legend: { labels: { color: '#94a3b8' } } },
    scales: {
      x: { ticks: { color: '#64748b', maxTicksLimit: 10 }, grid: { color: '#1f2937' } },
      y: { ticks: { color: '#64748b' }, grid: { color: '#1f2937' }, beginAtZero: true }
    }
  }
});

const platforms = STATS.visits_by_platform || [];
new Chart(document.getElementById('chartPlatforms'), {
  type: 'doughnut',
  data: {
    labels: platforms.map(p => p.platform || 'inconnu'),
    datasets: [{ data: platforms.map(p => p.count), backgroundColor: ['#22d3ee', '#6366f1', '#f59e0b', '#ec4899', '#14b8a6'] }]
  },
  options: { plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8' } } } }
});

new Chart(document.getElementById('chartActivity'), {
  type: 'line',
  data: {
    labels: actLabels,
    datasets: [
      { label: 'Produits', data: fillSeriesDays(STATS.series?.products).values, borderColor: '#14b8a6', tension: .3 },
      { label: 'Boutiques', data: fillSeriesDays(STATS.series?.shops).values, borderColor: '#6366f1', tension: .3 },
      { label: 'Contacts', data: fillSeriesDays(STATS.series?.contacts).values, borderColor: '#f59e0b', tension: .3 },
      { label: 'Commandes', data: fillSeriesDays(STATS.series?.orders).values, borderColor: '#ec4899', tension: .3 },
    ]
  },
  options: {
    responsive: true,
    plugins: { legend: { labels: { color: '#94a3b8' } } },
    scales: {
      x: { ticks: { color: '#64748b', maxTicksLimit: 10 }, grid: { color: '#1f2937' } },
      y: { ticks: { color: '#64748b' }, grid: { color: '#1f2937' }, beginAtZero: true }
    }
  }
});

const contactTypes = STATS.contacts_by_type || [];
new Chart(document.getElementById('chartContacts'), {
  type: 'doughnut',
  data: {
    labels: contactTypes.map(c => c.contact_type || 'autre'),
    datasets: [{ data: contactTypes.map(c => c.count), backgroundColor: ['#14b8a6','#6366f1','#f59e0b','#ec4899'] }]
  },
  options: { plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8' } } } }
});

const cities = STATS.cities || [];
new Chart(document.getElementById('chartCities'), {
  type: 'bar',
  data: { labels: cities.map(c => c.location), datasets: [{ label: 'Boutiques', data: cities.map(c => c.shop_count), backgroundColor: '#6366f1' }] },
  options: {
    indexAxis: 'y', plugins: { legend: { display: false } },
    scales: { x: { ticks: { color: '#64748b' }, grid: { color: '#1f2937' } }, y: { ticks: { color: '#94a3b8' }, grid: { display: false } } }
  }
});
</script>
</body>
</html><?php
}
