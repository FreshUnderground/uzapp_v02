<?php
/**
 * DRC phone normalization for wa.me links (mirrors lib/core/utils/phone_utils.dart).
 */

function phone_digits_only(?string $phone): string
{
    if ($phone === null || trim($phone) === '') {
        return '';
    }
    return preg_replace('/\D/', '', $phone) ?? '';
}

function phone_normalize_drc(?string $phone): string
{
    $cc = '243';
    $digits = phone_digits_only($phone);
    if ($digits === '') {
        return '';
    }

    while (strpos($digits, $cc . $cc) === 0 && strlen($digits) > 12) {
        $digits = substr($digits, strlen($cc));
    }

    if (strpos($digits, $cc . '0') === 0 && strlen($digits) > 12) {
        $withoutTrunk = $cc . substr($digits, strlen($cc) + 1);
        if (strlen($withoutTrunk) >= 12) {
            $digits = strlen($withoutTrunk) > 12
                ? substr($withoutTrunk, 0, 12)
                : $withoutTrunk;
        }
    }

    if (strpos($digits, $cc) === 0 && strlen($digits) >= 11) {
        return strlen($digits) > 12 ? substr($digits, 0, 12) : $digits;
    }

    if (strpos($digits, '00' . $cc) === 0 && strlen($digits) >= 13) {
        $digits = substr($digits, 2);
        return strlen($digits) > 12 ? substr($digits, 0, 12) : $digits;
    }

    if (strlen($digits) > 0 && $digits[0] === '0' && strlen($digits) >= 10) {
        return $cc . substr($digits, 1);
    }

    if (strlen($digits) === 9) {
        return $cc . $digits;
    }

    return $digits;
}

function phone_is_valid_drc(?string $phone): bool
{
    $normalized = phone_normalize_drc($phone);
    return strpos($normalized, '243') === 0 && strlen($normalized) === 12;
}

/** Common formats for matching owner_id across local & server (mirrors PhoneUtils.lookupKeys). */
function phone_lookup_keys(?string $phone): array
{
    if ($phone === null || trim($phone) === '') {
        return [];
    }
    $trimmed = trim($phone);
    $normalized = phone_normalize_drc($phone);
    $keys = array_unique(array_filter([
        $trimmed,
        $normalized,
        $normalized !== '' ? '+' . $normalized : '',
    ]));
    if ($normalized !== '' && strpos($normalized, '243') === 0 && strlen($normalized) >= 12) {
        $local = substr($normalized, 3);
        $keys[] = $local;
        $keys[] = '0' . $local;
    }
    return array_values(array_unique(array_filter($keys)));
}

function shop_whatsapp_number(?string $whatsapp, ?string $phone): ?string
{
    foreach ([$whatsapp, $phone] as $raw) {
        if ($raw === null || trim($raw) === '') {
            continue;
        }
        $normalized = phone_normalize_drc($raw);
        if (phone_is_valid_drc($normalized)) {
            return $normalized;
        }
    }
    return null;
}
