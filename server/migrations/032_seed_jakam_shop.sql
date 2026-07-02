-- Boutique Jakam (utilisateur id=25, phone=243960897252)
-- À exécuter dans phpMyAdmin si users contient Jakam mais pas shops.
-- Idempotent : ne crée rien si une boutique existe déjà pour ce owner_id.

SET @owner_phone := '243960897252';
SET @shop_name   := 'Jakam';

-- Reprend le logo du profil utilisateur si disponible
SET @logo_url := (
  SELECT avatar_url
  FROM users
  WHERE phone = @owner_phone
     OR phone IN ('0960897252', '243960897252')
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
  created_at,
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
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1
  FROM shops s
  WHERE s.owner_id IN (@owner_phone, '0960897252', '243960897252')
     OR (s.name = @shop_name AND s.phone IN (@owner_phone, '0960897252', '243960897252'))
);

-- Vérification
SELECT
  u.id   AS user_id,
  u.name AS user_name,
  u.phone,
  s.id   AS shop_id,
  s.name AS shop_name,
  s.owner_id,
  s.logo_url
FROM users u
LEFT JOIN shops s
  ON s.owner_id IN (u.phone, '243960897252', '0960897252')
WHERE u.phone IN (@owner_phone, '0960897252', '243960897252')
   OR u.name = 'Jakam';
