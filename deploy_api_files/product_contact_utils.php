<?php
/**
 * WhatsApp contact message for product landing pages (mirrors ContactService).
 */

function uzaapp_marketplace_tagline(): string
{
    return 'La marketplace des téléphones, ordinateurs et gadgets en RDC';
}

function product_has_visible_price(array $product): bool
{
    if (!empty($product['hide_price'])) {
        return false;
    }
    $price = $product['price'] ?? null;
    return $price !== null && (float)$price > 0;
}

function product_preview_price_label(array $product): string
{
    if (!product_has_visible_price($product)) {
        return 'Prix à discuter';
    }
    $amount = (float)$product['price'];
    if (fmod($amount, 1.0) === 0.0) {
        return number_format($amount, 0, '.', '') . ' $';
    }
    return number_format($amount, 2, '.', '') . ' $';
}

function product_og_description(array $product): string
{
    $name = trim((string)($product['name'] ?? 'Produit'));
    if (!product_has_visible_price($product)) {
        return $name . ' — Prix à discuter sur Uzaapp - ' . uzaapp_marketplace_tagline();
    }
    $amount = product_preview_price_label($product);
    return $name . ' à ' . $amount . ' sur Uzaapp - ' . uzaapp_marketplace_tagline();
}

function product_whatsapp_message(array $product, ?array $shop, string $pageUrl): string
{
    $name = trim((string)($product['name'] ?? 'Produit'));
    $description = trim((string)($product['description'] ?? ''));
    $category = trim((string)($product['category'] ?? ''));
    $promo = trim((string)($product['promotion_message'] ?? ''));
    $condition = (string)($product['condition'] ?? 'new');

    $conditionLine = $condition === 'new'
        ? '• État : Neuf'
        : '• État : Occasion';

    $priceLine = product_has_visible_price($product)
        ? '• Prix : ' . product_preview_price_label($product)
        : 'Prix à discuter';

    $descLine = '';
    if ($description !== '') {
        $short = mb_strlen($description) > 120
            ? mb_substr($description, 0, 120) . '...'
            : $description;
        $descLine = '• ' . $short . "\n";
    }

    $categoryLine = $category !== '' ? '• Catégorie : ' . $category . "\n" : '';
    $promoLine = $promo !== '' ? '> ' . $promo . "\n" : '';
    $shopLine = ($shop !== null && !empty($shop['name']))
        ? '• Boutique : ' . trim((string)$shop['name']) . "\n"
        : '';

    $imageLine = '';
    if (!empty($product['image_urls'])) {
        $rawImage = trim(explode(',', (string)$product['image_urls'])[0]);
        if ($rawImage !== '') {
            if (strpos($rawImage, 'http') !== 0) {
                $rawImage = 'https://uzaapp.com/' . ltrim($rawImage, '/');
            }
            $imageLine = "\n" . $rawImage . "\n";
        }
    }

    return 'Bonjour, je vous contacte depuis UzaApp.' . "\n"
        . 'Je suis très intéressé(e) par votre article :' . "\n\n"
        . '*' . mb_strtoupper($name) . '*' . "\n"
        . $descLine
        . $categoryLine
        . $promoLine
        . $conditionLine . "\n"
        . $priceLine . "\n"
        . $shopLine
        . $imageLine
        . "\n"
        . '>> Voir le produit :' . "\n"
        . $pageUrl . "\n\n"
        . 'Cet article est-il toujours disponible ?' . "\n\n"
        . '---' . "\n"
        . 'Des milliers de produits disponibles près de chez vous !' . "\n"
        . 'Téléchargez UzaApp — Le marché en ligne N°1 en RDC' . "\n\n"
        . '#UzaApp #Shopping #RDC #Kinshasa';
}

function product_whatsapp_url(string $phone, string $message): string
{
    return 'https://wa.me/' . $phone . '?text=' . rawurlencode($message);
}
