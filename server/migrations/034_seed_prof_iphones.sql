-- PROF IPHONES — recréer user + shop et rattacher les produits orphelins
-- Téléphone : +243973890511
-- Idempotent : peut être relancé sans doublon.

SET @owner_phone   := '243973890511';
SET @display_name  := 'PROF IPHONES';
-- Hash optionnel (NULL = connexion OTP / réinitialisation mot de passe)
SET @password_hash := NULL;

-- ── 1. Utilisateur ─────────────────────────────────────────────────────────
INSERT INTO users (
  phone,
  name,
  remote_id,
  password_hash,
  is_phone_verified,
  role,
  created_at,
  updated_at
)
SELECT
  @owner_phone,
  @display_name,
  @owner_phone,
  @password_hash,
  1,
  'user',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users u
  WHERE u.phone IN (@owner_phone, '0973890511', '+243973890511')
);

UPDATE users
SET
  name = @display_name,
  remote_id = COALESCE(remote_id, @owner_phone),
  updated_at = NOW()
WHERE phone IN (@owner_phone, '0973890511', '+243973890511');

SET @user_id := (
  SELECT id FROM users
  WHERE phone IN (@owner_phone, '0973890511', '+243973890511')
  ORDER BY id DESC
  LIMIT 1
);

-- ── 2. Boutique ────────────────────────────────────────────────────────────
SET @logo_url := (
  SELECT avatar_url FROM users WHERE id = @user_id LIMIT 1
);

INSERT INTO shops (
  name,
  description,
  logo_url,
  type,
  owner_id,
  phone,
  whatsapp,
  is_verified,
  updated_at
)
SELECT
  @display_name,
  'Boutique PROF IPHONES — smartphones et accessoires',
  @logo_url,
  'retail',
  @owner_phone,
  @owner_phone,
  @owner_phone,
  0,
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM shops s
  WHERE s.owner_id IN (@owner_phone, '0973890511', '+243973890511')
     OR s.name = @display_name
);

UPDATE shops
SET
  name = @display_name,
  owner_id = @owner_phone,
  phone = @owner_phone,
  whatsapp = @owner_phone,
  logo_url = COALESCE(logo_url, @logo_url),
  updated_at = NOW()
WHERE owner_id IN (@owner_phone, '0973890511', '+243973890511')
   OR name IN ('PROF IPHONE', 'PROF IPHONES', 'Prof iPhone');

SET @shop_id := (
  SELECT id FROM shops
  WHERE owner_id IN (@owner_phone, '0973890511', '+243973890511')
     OR name = @display_name
  ORDER BY id DESC
  LIMIT 1
);

-- ── 3. Rattacher les produits orphelins ────────────────────────────────────
-- (shop_id invalide ou ancien id utilisateur)
UPDATE products p
LEFT JOIN shops s ON s.id = p.shop_id
SET p.shop_id = @shop_id,
    p.updated_at = NOW()
WHERE @shop_id IS NOT NULL
  AND s.id IS NULL
  AND (
    p.shop_id = @user_id
    OR p.name LIKE '%PROF IPHONE%'
    OR p.name LIKE '%Prof iPhone%'
    OR p.name LIKE '%PROF IPHONES%'
  );

-- Rattacher aussi les mises à jour produit orphelines
UPDATE product_updates pu
INNER JOIN products p ON p.id = pu.product_id
LEFT JOIN shops s ON s.id = pu.shop_id
SET pu.shop_id = @shop_id
WHERE @shop_id IS NOT NULL
  AND s.id IS NULL
  AND p.shop_id = @shop_id;

-- ── 4. Vérification ────────────────────────────────────────────────────────
SELECT
  @user_id  AS user_id,
  @shop_id  AS shop_id,
  @display_name AS shop_name,
  @owner_phone AS phone;

SELECT
  u.id AS user_id,
  u.name AS user_name,
  u.phone,
  s.id AS shop_id,
  s.name AS shop_name,
  s.owner_id
FROM users u
LEFT JOIN shops s ON s.owner_id = u.phone
WHERE u.phone IN (@owner_phone, '0973890511', '+243973890511')
   OR u.name = @display_name;

SELECT
  p.id,
  p.name,
  p.shop_id,
  s.name AS shop_name
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE p.shop_id = @shop_id
   OR p.name LIKE '%PROF IPHONE%'
   OR p.name LIKE '%PROF IPHONES%'
ORDER BY p.id;

SELECT COUNT(*) AS orphan_products_remaining
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL;
