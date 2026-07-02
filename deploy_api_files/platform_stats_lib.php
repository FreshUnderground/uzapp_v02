<?php
/**
 * Aggregated platform statistics for the admin dashboard.
 */

function platform_stats_shop_share_types_sql(): string
{
    return "'share','catalog_share','qr_share','story_share','whatsapp_status','facebook_status','tiktok_status'";
}

function platform_stats_shop_engagement_totals(PDO $db): array
{
    if (!platform_stats_table_exists($db, 'shop_analytics')) {
        return ['shop_views' => 0, 'shop_shares' => 0];
    }

    $shareTypes = platform_stats_shop_share_types_sql();
    return [
        'shop_views' => platform_stats_scalar(
            $db,
            "SELECT COUNT(*) FROM shop_analytics WHERE interaction_type = 'view'"
        ),
        'shop_shares' => platform_stats_scalar(
            $db,
            "SELECT COUNT(*) FROM shop_analytics WHERE interaction_type IN ($shareTypes)"
        ),
    ];
}

function platform_stats_shop_engagement_in_range(PDO $db, string $from, string $to): array
{
    if (!platform_stats_table_exists($db, 'shop_analytics')) {
        return ['shop_views' => 0, 'shop_shares' => 0];
    }

    $shareTypes = platform_stats_shop_share_types_sql();
    return [
        'shop_views' => platform_stats_scalar(
            $db,
            "SELECT COUNT(*) FROM shop_analytics
             WHERE interaction_type = 'view'
             AND DATE(created_at) >= ? AND DATE(created_at) <= ?",
            [$from, $to]
        ),
        'shop_shares' => platform_stats_scalar(
            $db,
            "SELECT COUNT(*) FROM shop_analytics
             WHERE interaction_type IN ($shareTypes)
             AND DATE(created_at) >= ? AND DATE(created_at) <= ?",
            [$from, $to]
        ),
    ];
}

function platform_stats_table_exists(PDO $db, string $table): bool
{
    static $cache = [];
    if (isset($cache[$table])) {
        return $cache[$table];
    }
    try {
        $stmt = $db->prepare(
            'SELECT COUNT(*) FROM information_schema.tables
             WHERE table_schema = DATABASE() AND table_name = ?'
        );
        $stmt->execute([$table]);
        $cache[$table] = ((int) $stmt->fetchColumn()) > 0;
    } catch (Exception $e) {
        $cache[$table] = false;
    }
    return $cache[$table];
}

function platform_stats_scalar(PDO $db, string $sql, array $params = []): int
{
    try {
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        return (int) $stmt->fetchColumn();
    } catch (Exception $e) {
        return 0;
    }
}

function platform_stats_fetch_all(PDO $db, string $sql, array $params = []): array
{
    try {
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Exception $e) {
        return [];
    }
}

function platform_stats_parse_range(array $query): array
{
    $presets = [
        '7d' => ['days' => 7, 'label' => '7 derniers jours'],
        '30d' => ['days' => 30, 'label' => '30 derniers jours'],
        '90d' => ['days' => 90, 'label' => '90 derniers jours'],
        '365d' => ['days' => 365, 'label' => '12 derniers mois'],
    ];

    $from = isset($query['from']) ? trim((string) $query['from']) : '';
    $to = isset($query['to']) ? trim((string) $query['to']) : '';
    $datePattern = '/^\d{4}-\d{2}-\d{2}$/';

    if ($from !== '' && $to !== '' && preg_match($datePattern, $from) && preg_match($datePattern, $to)) {
        $fromDt = DateTimeImmutable::createFromFormat('Y-m-d', $from);
        $toDt = DateTimeImmutable::createFromFormat('Y-m-d', $to);
        if ($fromDt && $toDt && $fromDt <= $toDt) {
            $days = (int) $fromDt->diff($toDt)->days + 1;
            return [
                'preset' => 'custom',
                'from' => $from,
                'to' => $to,
                'days' => min($days, 366),
                'label' => $from . ' → ' . $to,
            ];
        }
    }

    $preset = isset($query['preset']) ? (string) $query['preset'] : '30d';
    if (!isset($presets[$preset])) {
        $preset = '30d';
    }

    $days = $presets[$preset]['days'];
    $toDate = new DateTimeImmutable('today');
    $fromDate = $toDate->modify('-' . ($days - 1) . ' days');

    return [
        'preset' => $preset,
        'from' => $fromDate->format('Y-m-d'),
        'to' => $toDate->format('Y-m-d'),
        'days' => $days,
        'label' => $presets[$preset]['label'],
    ];
}

function platform_stats_build_query(array $range, ?string $format = null): string
{
    $params = [];
    if ($range['preset'] === 'custom') {
        $params['from'] = $range['from'];
        $params['to'] = $range['to'];
    } else {
        $params['preset'] = $range['preset'];
    }
    if ($format !== null && $format !== '') {
        $params['format'] = $format;
    }
    return http_build_query($params);
}

function platform_stats_count_in_range(
    PDO $db,
    string $table,
    string $dateCol,
    string $from,
    string $to,
    string $extraWhere = ''
): int {
    if (!platform_stats_table_exists($db, $table)) {
        return 0;
    }
    $where = "DATE($dateCol) >= ? AND DATE($dateCol) <= ?";
    if ($extraWhere !== '') {
        $where .= ' AND (' . $extraWhere . ')';
    }
    return platform_stats_scalar(
        $db,
        "SELECT COUNT(*) FROM `$table` WHERE $where",
        [$from, $to]
    );
}

function platform_stats_daily_series(
    PDO $db,
    string $table,
    string $dateCol,
    string $from,
    string $to,
    string $extraWhere = ''
): array {
    if (!platform_stats_table_exists($db, $table)) {
        return [];
    }
    $where = "DATE($dateCol) >= ? AND DATE($dateCol) <= ?";
    if ($extraWhere !== '') {
        $where .= ' AND (' . $extraWhere . ')';
    }
    return platform_stats_fetch_all(
        $db,
        "SELECT DATE($dateCol) AS day, COUNT(*) AS count
         FROM `$table`
         WHERE $where
         GROUP BY DATE($dateCol)
         ORDER BY day ASC",
        [$from, $to]
    );
}

function platform_stats_visits_series(PDO $db, string $eventType, string $from, string $to): array
{
    return platform_stats_daily_series(
        $db,
        'platform_visits',
        'created_at',
        $from,
        $to,
        "event_type = " . $db->quote($eventType)
    );
}

function platform_stats_collect(PDO $db, ?array $range = null): array
{
    $range = $range ?? platform_stats_parse_range([]);
    $from = $range['from'];
    $to = $range['to'];

    $hasOrders = platform_stats_table_exists($db, 'orders');
    $hasReports = platform_stats_table_exists($db, 'product_reports');
    $hasContacts = platform_stats_table_exists($db, 'user_contacts');
    $hasLikes = platform_stats_table_exists($db, 'product_likes');
    $hasFollows = platform_stats_table_exists($db, 'shop_follows');
    $hasFcm = platform_stats_table_exists($db, 'fcm_tokens');
    $hasPlatformVisits = platform_stats_table_exists($db, 'platform_visits');
    $hasShopAnalytics = platform_stats_table_exists($db, 'shop_analytics');
    $shopEngagementTotals = platform_stats_shop_engagement_totals($db);
    $shopEngagementPeriod = platform_stats_shop_engagement_in_range($db, $from, $to);

    $productViewsTotal = platform_stats_scalar(
        $db,
        'SELECT COALESCE(SUM(views_count), 0) FROM products'
    );
    $productSharesTotal = platform_stats_scalar(
        $db,
        'SELECT COALESCE(SUM(shares_count), 0) FROM products'
    );

    $overview = [
        'shops_total' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM shops'),
        'shops_verified' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM shops WHERE is_verified = 1'),
        'shops_boost_active' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM shops WHERE boost_status = 2'),
        'shops_banner_active' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM shops WHERE banner_status = 2'),
        'shops_boost_pending' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM shops WHERE boost_status = 1'),
        'shops_banner_pending' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM shops WHERE banner_status = 1'),
        'products_total' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM products'),
        'products_promo' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM products WHERE is_promotion = 1'),
        'products_sold' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM products WHERE is_sold = 1'),
        'products_boost_active' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM products WHERE boost_status = 2'),
        'products_boost_pending' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM products WHERE boost_status = 1'),
        'users_total' => platform_stats_scalar($db, 'SELECT COUNT(*) FROM users'),
        'users_admins' => platform_stats_scalar($db, "SELECT COUNT(*) FROM users WHERE role = 'admin'"),
        'stories_active' => platform_stats_scalar(
            $db,
            'SELECT COUNT(*) FROM stories WHERE expires_at > NOW() AND is_arrivage = 0'
        ),
        'arrivages_active' => platform_stats_scalar(
            $db,
            'SELECT COUNT(*) FROM stories WHERE expires_at > NOW() AND is_arrivage = 1'
        ),
        'views_total' => $productViewsTotal,
        'product_views_total' => $productViewsTotal,
        'shares_total' => $productSharesTotal,
        'product_shares_total' => $productSharesTotal,
        'shop_views_total' => $shopEngagementTotals['shop_views'],
        'shop_shares_total' => $shopEngagementTotals['shop_shares'],
        'engagement_views_total' => $productViewsTotal + $shopEngagementTotals['shop_views'],
        'engagement_shares_total' => $productSharesTotal + $shopEngagementTotals['shop_shares'],
        'reports_total' => $hasReports
            ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM product_reports')
            : platform_stats_scalar($db, 'SELECT COALESCE(SUM(report_count), 0) FROM products'),
        'likes_total' => $hasLikes
            ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM product_likes')
            : 0,
        'follows_total' => $hasFollows
            ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM shop_follows')
            : 0,
        'contacts_total' => $hasContacts
            ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM user_contacts')
            : 0,
        'contacts_unique' => $hasContacts
            ? platform_stats_scalar($db, 'SELECT COUNT(DISTINCT user_phone) FROM user_contacts')
            : 0,
        'orders_total' => $hasOrders ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM orders') : 0,
        'orders_pending' => $hasOrders
            ? platform_stats_scalar(
                $db,
                "SELECT COUNT(*) FROM orders WHERE status IN ('requested', 'pending_payment')"
            )
            : 0,
        'fcm_tokens' => $hasFcm ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM fcm_tokens') : 0,
        'app_opens_total' => $hasPlatformVisits
            ? platform_stats_scalar($db, "SELECT COUNT(*) FROM platform_visits WHERE event_type = 'app_open'")
            : 0,
        'web_visits_total' => $hasPlatformVisits
            ? platform_stats_scalar($db, "SELECT COUNT(*) FROM platform_visits WHERE event_type = 'web_visit'")
            : 0,
        'session_resumes_total' => $hasPlatformVisits
            ? platform_stats_scalar($db, "SELECT COUNT(*) FROM platform_visits WHERE event_type = 'session_resume'")
            : 0,
        'platform_visits_total' => $hasPlatformVisits
            ? platform_stats_scalar($db, 'SELECT COUNT(*) FROM platform_visits')
            : 0,
    ];

    $overview['shops_period'] = platform_stats_count_in_range($db, 'shops', 'updated_at', $from, $to);
    $overview['products_period'] = platform_stats_count_in_range($db, 'products', 'updated_at', $from, $to);
    $overview['users_period'] = platform_stats_count_in_range($db, 'users', 'created_at', $from, $to);
    $overview['contacts_period'] = $hasContacts
        ? platform_stats_count_in_range($db, 'user_contacts', 'created_at', $from, $to)
        : 0;
    $overview['contacts_unique_period'] = $hasContacts
        ? platform_stats_scalar(
            $db,
            'SELECT COUNT(DISTINCT user_phone) FROM user_contacts
             WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?',
            [$from, $to]
        )
        : 0;
    $overview['orders_period'] = $hasOrders
        ? platform_stats_count_in_range($db, 'orders', 'created_at', $from, $to)
        : 0;
    $overview['app_opens_period'] = $hasPlatformVisits
        ? platform_stats_count_in_range($db, 'platform_visits', 'created_at', $from, $to, "event_type = 'app_open'")
        : 0;
    $overview['web_visits_period'] = $hasPlatformVisits
        ? platform_stats_count_in_range($db, 'platform_visits', 'created_at', $from, $to, "event_type = 'web_visit'")
        : 0;
    $overview['platform_visits_period'] = $hasPlatformVisits
        ? platform_stats_count_in_range($db, 'platform_visits', 'created_at', $from, $to)
        : 0;
    $overview['session_resumes_period'] = $hasPlatformVisits
        ? platform_stats_count_in_range($db, 'platform_visits', 'created_at', $from, $to, "event_type = 'session_resume'")
        : 0;
    $overview['unique_visitors_period'] = $hasPlatformVisits
        ? platform_stats_scalar(
            $db,
            "SELECT COUNT(DISTINCT visitor_id) FROM platform_visits
             WHERE visitor_id IS NOT NULL AND visitor_id != ''
             AND DATE(created_at) >= ? AND DATE(created_at) <= ?",
            [$from, $to]
        )
        : 0;
    $overview['reports_period'] = $hasReports
        ? platform_stats_count_in_range($db, 'product_reports', 'created_at', $from, $to)
        : 0;
    $overview['shop_views_period'] = $shopEngagementPeriod['shop_views'];
    $overview['shop_shares_period'] = $shopEngagementPeriod['shop_shares'];
    $overview['engagement_views_period'] = ($overview['shop_views_period'] ?? 0);
    $overview['engagement_shares_period'] = ($overview['shop_shares_period'] ?? 0);

    $shopInteractionsByType = $hasShopAnalytics
        ? platform_stats_fetch_all(
            $db,
            'SELECT interaction_type, COUNT(*) AS count FROM shop_analytics
             WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?
             GROUP BY interaction_type ORDER BY count DESC',
            [$from, $to]
        )
        : [];

    $shareTypes = platform_stats_shop_share_types_sql();
    $shopAnalyticsJoin = $hasShopAnalytics
        ? "LEFT JOIN (
            SELECT shop_id,
              SUM(CASE WHEN interaction_type = 'view' THEN 1 ELSE 0 END) AS shop_views,
              SUM(CASE WHEN interaction_type IN ($shareTypes) THEN 1 ELSE 0 END) AS shop_shares
            FROM shop_analytics
            GROUP BY shop_id
          ) sa ON sa.shop_id = s.id"
        : 'LEFT JOIN (SELECT NULL AS shop_id, 0 AS shop_views, 0 AS shop_shares) sa ON 1=0';

    $topShopsByViews = platform_stats_fetch_all(
        $db,
        "SELECT s.id, s.name, s.city, s.commune,
                COUNT(p.id) AS product_count,
                COALESCE(SUM(p.views_count), 0) AS product_views,
                COALESCE(sa.shop_views, 0) AS shop_views,
                COALESCE(SUM(p.views_count), 0) + COALESCE(sa.shop_views, 0) AS views,
                COALESCE(SUM(p.shares_count), 0) + COALESCE(sa.shop_shares, 0) AS shares
         FROM shops s
         LEFT JOIN products p ON p.shop_id = s.id
         $shopAnalyticsJoin
         GROUP BY s.id, s.name, s.city, s.commune, sa.shop_views, sa.shop_shares
         ORDER BY views DESC
         LIMIT 10"
    );

    $visitsByPlatform = $hasPlatformVisits
        ? platform_stats_fetch_all(
            $db,
            'SELECT platform, COUNT(*) AS count FROM platform_visits
             WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?
             GROUP BY platform ORDER BY count DESC',
            [$from, $to]
        )
        : [];

    $contactsByType = $hasContacts
        ? platform_stats_fetch_all(
            $db,
            'SELECT contact_type, COUNT(*) AS count FROM user_contacts
             WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?
             GROUP BY contact_type ORDER BY count DESC',
            [$from, $to]
        )
        : [];

    $topShopsByContacts = $hasContacts
        ? platform_stats_fetch_all(
            $db,
            'SELECT s.id, s.name, s.city, s.commune, COUNT(uc.id) AS contacts
             FROM shops s
             JOIN user_contacts uc ON uc.shop_id = s.id
             WHERE DATE(uc.created_at) >= ? AND DATE(uc.created_at) <= ?
             GROUP BY s.id, s.name, s.city, s.commune
             ORDER BY contacts DESC
             LIMIT 10',
            [$from, $to]
        )
        : [];

    $topProducts = platform_stats_fetch_all(
        $db,
        'SELECT p.id, p.name, p.views_count AS views, p.shares_count AS shares,
                p.price, s.name AS shop_name
         FROM products p
         JOIN shops s ON s.id = p.shop_id
         ORDER BY p.views_count DESC
         LIMIT 15'
    );

    $citiesBreakdown = platform_stats_fetch_all(
        $db,
        "SELECT COALESCE(NULLIF(TRIM(city), ''), NULLIF(TRIM(commune), ''), 'Non renseigné') AS location,
                COUNT(*) AS shop_count
         FROM shops
         GROUP BY location
         ORDER BY shop_count DESC
         LIMIT 12"
    );

    $recentShops = platform_stats_fetch_all(
        $db,
        'SELECT id, name, city, commune, boost_status, banner_status, is_verified, updated_at
         FROM shops
         WHERE DATE(updated_at) >= ? AND DATE(updated_at) <= ?
         ORDER BY updated_at DESC
         LIMIT 10',
        [$from, $to]
    );

    $recentContacts = $hasContacts
        ? platform_stats_fetch_all(
            $db,
            'SELECT uc.id, uc.contact_type, uc.user_phone, uc.created_at,
                    s.name AS shop_name, p.name AS product_name
             FROM user_contacts uc
             JOIN shops s ON s.id = uc.shop_id
             LEFT JOIN products p ON p.id = uc.product_id
             WHERE DATE(uc.created_at) >= ? AND DATE(uc.created_at) <= ?
             ORDER BY uc.created_at DESC
             LIMIT 15',
            [$from, $to]
        )
        : [];

    $pendingBoosts = platform_stats_fetch_all(
        $db,
        "SELECT id, name, boost_status, banner_status, updated_at
         FROM shops
         WHERE boost_status = 1 OR banner_status = 1
         ORDER BY updated_at DESC
         LIMIT 20"
    );

    $pendingProductBoosts = platform_stats_fetch_all(
        $db,
        "SELECT p.id, p.name, p.boost_status, s.name AS shop_name, p.updated_at
         FROM products p
         JOIN shops s ON s.id = p.shop_id
         WHERE p.boost_status = 1
         ORDER BY p.updated_at DESC
         LIMIT 20"
    );

    $ordersByStatus = $hasOrders
        ? platform_stats_fetch_all(
            $db,
            'SELECT status, COUNT(*) AS count FROM orders
             WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?
             GROUP BY status ORDER BY count DESC',
            [$from, $to]
        )
        : [];

    $recentOrders = $hasOrders
        ? platform_stats_fetch_all(
            $db,
            'SELECT o.id, o.buyer_phone, o.status, o.created_at, s.name AS shop_name
             FROM orders o
             JOIN shops s ON s.id = o.shop_id
             WHERE DATE(o.created_at) >= ? AND DATE(o.created_at) <= ?
             ORDER BY o.created_at DESC
             LIMIT 12',
            [$from, $to]
        )
        : [];

    return [
        'generated_at' => gmdate('c'),
        'period' => $range,
        'overview' => $overview,
        'contacts_by_type' => $contactsByType,
        'shop_interactions_by_type' => $shopInteractionsByType,
        'top_shops_views' => $topShopsByViews,
        'top_shops_contacts' => $topShopsByContacts,
        'top_products' => $topProducts,
        'cities' => $citiesBreakdown,
        'recent_shops' => $recentShops,
        'recent_contacts' => $recentContacts,
        'pending_shop_promos' => $pendingBoosts,
        'pending_product_boosts' => $pendingProductBoosts,
        'orders_by_status' => $ordersByStatus,
        'recent_orders' => $recentOrders,
        'visits_by_platform' => $visitsByPlatform,
        'series' => [
            'shops' => platform_stats_daily_series($db, 'shops', 'updated_at', $from, $to),
            'products' => platform_stats_daily_series($db, 'products', 'updated_at', $from, $to),
            'users' => platform_stats_daily_series($db, 'users', 'created_at', $from, $to),
            'contacts' => $hasContacts
                ? platform_stats_daily_series($db, 'user_contacts', 'created_at', $from, $to)
                : [],
            'orders' => $hasOrders
                ? platform_stats_daily_series($db, 'orders', 'created_at', $from, $to)
                : [],
            'app_opens' => $hasPlatformVisits
                ? platform_stats_visits_series($db, 'app_open', $from, $to)
                : [],
            'web_visits' => $hasPlatformVisits
                ? platform_stats_visits_series($db, 'web_visit', $from, $to)
                : [],
            'platform_visits' => $hasPlatformVisits
                ? platform_stats_daily_series($db, 'platform_visits', 'created_at', $from, $to)
                : [],
            'shop_views' => $hasShopAnalytics
                ? platform_stats_daily_series(
                    $db,
                    'shop_analytics',
                    'created_at',
                    $from,
                    $to,
                    "interaction_type = 'view'"
                )
                : [],
            'shop_shares' => $hasShopAnalytics
                ? platform_stats_daily_series(
                    $db,
                    'shop_analytics',
                    'created_at',
                    $from,
                    $to,
                    'interaction_type IN (' . platform_stats_shop_share_types_sql() . ')'
                )
                : [],
        ],
    ];
}

function platform_stats_csv_cell($value): string
{
    $text = (string) ($value ?? '');
    if (strpbrk($text, ",\"\n\r") !== false) {
        return '"' . str_replace('"', '""', $text) . '"';
    }
    return $text;
}

function platform_stats_csv_row(array $cells): string
{
    return implode(',', array_map('platform_stats_csv_cell', $cells)) . "\r\n";
}

function platform_stats_export_csv(array $stats): string
{
    $out = "\xEF\xBB\xBF";
    $period = $stats['period'] ?? [];
    $out .= platform_stats_csv_row(['UzaApp — Statistiques plateforme']);
    $out .= platform_stats_csv_row(['Généré le', $stats['generated_at'] ?? '']);
    $out .= platform_stats_csv_row(['Période', $period['label'] ?? '', $period['from'] ?? '', $period['to'] ?? '']);
    $out .= "\r\n";

    $out .= platform_stats_csv_row(['# KPIs']);
    $out .= platform_stats_csv_row(['Indicateur', 'Total', 'Sur la période']);
    foreach ($stats['overview'] ?? [] as $key => $value) {
        if (substr($key, -7) === '_period') {
            continue;
        }
        $periodKey = $key . '_period';
        $periodValue = $stats['overview'][$periodKey] ?? '';
        $out .= platform_stats_csv_row([$key, $value, $periodValue]);
    }
    $out .= "\r\n";

    $out .= platform_stats_csv_row(['# Activité quotidienne']);
    $seriesKeys = ['products', 'shops', 'users', 'contacts', 'orders', 'app_opens', 'web_visits', 'platform_visits', 'shop_views', 'shop_shares'];
    $series = $stats['series'] ?? [];
    $days = [];
    foreach ($seriesKeys as $key) {
        foreach ($series[$key] ?? [] as $row) {
            $days[$row['day']] = true;
        }
    }
    ksort($days);
    $header = array_merge(['jour'], $seriesKeys);
    $out .= platform_stats_csv_row($header);
    foreach (array_keys($days) as $day) {
        $row = [$day];
        foreach ($seriesKeys as $key) {
            $count = 0;
            foreach ($series[$key] ?? [] as $entry) {
                if (($entry['day'] ?? '') === $day) {
                    $count = (int) ($entry['count'] ?? 0);
                    break;
                }
            }
            $row[] = $count;
        }
        $out .= platform_stats_csv_row($row);
    }
    $out .= "\r\n";

    $sections = [
        'contacts_by_type' => ['Contacts par canal', ['Canal', 'Nombre']],
        'shop_interactions_by_type' => ['Engagement boutique (période)', ['Type', 'Nombre']],
        'visits_by_platform' => ['Visites par plateforme', ['Plateforme', 'Nombre']],
        'orders_by_status' => ['Commandes par statut', ['Statut', 'Nombre']],
        'top_shops_views' => ['Top boutiques — vues (cumul)', ['Boutique', 'Ville', 'Produits', 'Vues produits', 'Vues boutique', 'Vues totales', 'Partages']],
        'top_shops_contacts' => ['Top boutiques — contacts (période)', ['Boutique', 'Ville', 'Contacts']],
        'top_products' => ['Top produits — vues (cumul)', ['Produit', 'Boutique', 'Vues', 'Partages', 'Prix']],
        'recent_orders' => ['Commandes (période)', ['ID', 'Boutique', 'Acheteur', 'Statut', 'Date']],
        'recent_contacts' => ['Contacts (période)', ['Canal', 'Client', 'Boutique', 'Date']],
        'recent_shops' => ['Boutiques actives (période)', ['Boutique', 'Ville', 'Boost', 'Date']],
    ];

    foreach ($sections as $key => [$title, $headers]) {
        $rows = $stats[$key] ?? [];
        $out .= platform_stats_csv_row(['# ' . $title]);
        $out .= platform_stats_csv_row($headers);
        if ($key === 'top_shops_views') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([
                    $r['name'] ?? '',
                    $r['city'] ?? $r['commune'] ?? '',
                    $r['product_count'] ?? 0,
                    $r['views'] ?? 0,
                    $r['shares'] ?? 0,
                ]);
            }
        } elseif ($key === 'top_shops_contacts') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([$r['name'] ?? '', $r['city'] ?? $r['commune'] ?? '', $r['contacts'] ?? 0]);
            }
        } elseif ($key === 'top_products') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([
                    $r['name'] ?? '',
                    $r['shop_name'] ?? '',
                    $r['views'] ?? 0,
                    $r['shares'] ?? 0,
                    $r['price'] ?? '',
                ]);
            }
        } elseif ($key === 'recent_orders') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([
                    $r['id'] ?? '',
                    $r['shop_name'] ?? '',
                    $r['buyer_phone'] ?? '',
                    $r['status'] ?? '',
                    $r['created_at'] ?? '',
                ]);
            }
        } elseif ($key === 'recent_contacts') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([
                    $r['contact_type'] ?? '',
                    $r['user_phone'] ?? '',
                    $r['shop_name'] ?? '',
                    $r['created_at'] ?? '',
                ]);
            }
        } elseif ($key === 'recent_shops') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([
                    $r['name'] ?? '',
                    $r['city'] ?? $r['commune'] ?? '',
                    $r['boost_status'] ?? '',
                    $r['updated_at'] ?? '',
                ]);
            }
        } elseif ($key === 'shop_interactions_by_type') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([$r['interaction_type'] ?? '', $r['count'] ?? 0]);
            }
        } elseif ($key === 'contacts_by_type') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([$r['contact_type'] ?? '', $r['count'] ?? 0]);
            }
        } elseif ($key === 'visits_by_platform') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([$r['platform'] ?? '', $r['count'] ?? 0]);
            }
        } elseif ($key === 'orders_by_status') {
            foreach ($rows as $r) {
                $out .= platform_stats_csv_row([$r['status'] ?? '', $r['count'] ?? 0]);
            }
        }
        $out .= "\r\n";
    }

    return $out;
}
