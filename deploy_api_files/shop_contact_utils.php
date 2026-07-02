<?php
/**
 * Shop landing / WhatsApp helpers (mirrors ContactService shop messages).
 */
require_once __DIR__ . '/product_contact_utils.php';

function uzaapp_absolute_url(?string $url): ?string
{
    if ($url === null || trim($url) === '') {
        return null;
    }
    $url = trim($url);
    if (strpos($url, 'http') === 0) {
        return $url;
    }
    return 'https://uzaapp.com/' . ltrim($url, '/');
}

function shop_preview_logo_url(array $shop): ?string
{
    return uzaapp_absolute_url($shop['logo_url'] ?? null)
        ?? uzaapp_absolute_url($shop['banner_url'] ?? null);
}

function shop_og_image(array $shop): string
{
    return shop_preview_logo_url($shop) ?? 'https://uzaapp.com/assets/logo.png';
}

function shop_location_text(array $shop): ?string
{
    $commune = trim((string)($shop['commune'] ?? ''));
    $city = trim((string)($shop['city'] ?? ''));
    $parts = array_filter([$commune, $city]);
    if (!empty($parts)) {
        return implode(', ', $parts);
    }
    $address = trim((string)($shop['address'] ?? ''));
    return $address !== '' ? $address : null;
}

function shop_og_description(array $shop): string
{
    $name = trim((string)($shop['name'] ?? 'Boutique'));
    $location = shop_location_text($shop);
    $desc = trim(strip_tags((string)($shop['description'] ?? '')));
    if (mb_strlen($desc) > 120) {
        $desc = mb_substr($desc, 0, 120) . '...';
    }

    $parts = array_filter([$name, $desc !== '' ? $desc : null, $location]);
    return implode(' · ', $parts) . ' — Uzaapp - ' . uzaapp_marketplace_tagline();
}

function shop_whatsapp_message(array $shop, string $pageUrl): string
{
    $name = trim((string)($shop['name'] ?? 'Boutique'));
    $location = shop_location_text($shop);
    $locationLine = $location !== null ? '• ' . $location . "\n" : '';
    $verifiedLine = !empty($shop['is_verified']) ? "• Boutique vérifiée UzaApp\n" : '';

    $logoLine = '';
    $logoUrl = shop_preview_logo_url($shop);
    if ($logoUrl !== null) {
        $logoLine = "\n" . $logoUrl . "\n";
    }

    return 'Bonjour, je vous contacte depuis UzaApp.' . "\n"
        . 'Je suis intéressé(e) par votre boutique :' . "\n\n"
        . '*' . mb_strtoupper($name) . '*' . "\n"
        . $locationLine
        . $verifiedLine
        . $logoLine
        . "\n"
        . '>> Voir la boutique :' . "\n"
        . $pageUrl . "\n\n"
        . 'Auriez-vous des articles disponibles pour moi ?' . "\n\n"
        . '---' . "\n"
        . 'Des milliers de produits disponibles près de chez vous !' . "\n"
        . 'Téléchargez UzaApp — Le marché en ligne N°1 en RDC' . "\n\n"
        . '#UzaApp #Boutique #Shopping #RDC';
}
