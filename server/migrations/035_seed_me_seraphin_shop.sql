-- Boutique Me Seraphin (user id=23, phone=243857608784)
-- L'utilisateur existe déjà dans `users` — ce script crée la boutique manquante.
-- Idempotent : peut être relancé sans doublon.

SET @owner_phone := '243857608784';
SET @shop_name   := 'Me Seraphin';
SET @user_id     := 23;

SET @logo_url := (
  SELECT avatar_url
  FROM users
  WHERE id = @user_id
     OR phone IN (@owner_phone, '0857608784', '+243857608784')
  ORDER BY id DESC
  LIMIT 1
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
  @shop_name,
  NULL,
  @logo_url,
  'retail',
  @owner_phone,
  @owner_phone,
  @owner_phone,
  0,
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM shops s
  WHERE s.owner_id IN (@owner_phone, '0857608784', '+243857608784')
     OR s.name IN ('Me Seraphin', 'Me seraphin')
     OR (s.name = @shop_name AND s.phone IN (@owner_phone, '0857608784'))
);

UPDATE shops
SET
  name = @shop_name,
  owner_id = @owner_phone,
  phone = @owner_phone,
  whatsapp = @owner_phone,
  logo_url = COALESCE(logo_url, @logo_url),
  updated_at = NOW()
WHERE owner_id IN (@owner_phone, '0857608784', '+243857608784')
   OR name IN ('Me Seraphin', 'Me seraphin');

SET @shop_id := (
  SELECT id FROM shops
  WHERE owner_id IN (@owner_phone, '0857608784', '+243857608784')
     OR name = @shop_name
  ORDER BY id DESC
  LIMIT 1
);

-- Rattacher les produits orphelins (shop_id = ancien user.id 23 ou nom Seraphin)
UPDATE products p
LEFT JOIN shops s ON s.id = p.shop_id
SET p.shop_id = @shop_id,
    p.updated_at = NOW()
WHERE @shop_id IS NOT NULL
  AND s.id IS NULL
  AND (
    p.shop_id = @user_id
    OR p.name LIKE '%Seraphin%'
  );

UPDATE product_updates pu
INNER JOIN products p ON p.id = pu.product_id
LEFT JOIN shops s ON s.id = pu.shop_id
SET pu.shop_id = @shop_id
WHERE @shop_id IS NOT NULL
  AND s.id IS NULL
  AND p.shop_id = @shop_id;

-- Vérification
SELECT
  @user_id  AS user_id,
  @shop_id  AS shop_id,
  @shop_name AS shop_name,
  @owner_phone AS phone;

SELECT
  u.id AS user_id,
  u.name AS user_name,
  u.phone,
  u.avatar_url,
  s.id AS shop_id,
  s.name AS shop_name,
  s.owner_id,
  s.logo_url
FROM users u
LEFT JOIN shops s ON s.owner_id = u.phone
WHERE u.id = @user_id
   OR u.phone IN (@owner_phone, '0857608784')
   OR u.name = 'Me Seraphin';

SELECT
  p.id,
  p.name,
  p.shop_id,
  s.name AS shop_name
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE p.shop_id = @shop_id
ORDER BY p.id;

SELECT COUNT(*) AS orphan_products_remaining
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL;
