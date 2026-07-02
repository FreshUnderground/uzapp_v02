-- Produits sans boutique valide (ex. PROF IPHONE +243973890511 supprimé de users sans shop)
-- Étape 1 : DIAGNOSTIC (exécuter d'abord)
SELECT
  p.id,
  p.name,
  p.shop_id,
  p.updated_at
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL
ORDER BY p.id;

-- Produits orphelins liés au numéro PROF IPHONE (shop_id = ancien user.id possible)
SELECT
  p.id,
  p.name,
  p.shop_id
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL
  AND (
    p.shop_id IN (
      SELECT id FROM users
      WHERE phone IN ('243973890511', '+243973890511', '0973890511', '973890511')
    )
    OR p.name LIKE '%PROF IPHONE%'
    OR p.name LIKE '%Prof iPhone%'
  );

-- Étape 2 : NETTOYAGE (décommenter après vérification du diagnostic)
/*
-- Likes
DELETE pl FROM product_likes pl
INNER JOIN products p ON p.id = pl.product_id
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL;

-- Mises à jour produit
DELETE pu FROM product_updates pu
INNER JOIN products p ON p.id = pu.product_id
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL;

-- Stories des shop_id fantômes
DELETE sm FROM story_media sm
INNER JOIN stories st ON st.id = sm.story_id
LEFT JOIN shops s ON s.id = st.shop_id
WHERE s.id IS NULL;

DELETE st FROM stories st
LEFT JOIN shops s ON s.id = st.shop_id
WHERE s.id IS NULL;

-- Produits orphelins
DELETE p FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL;

-- Vérification finale
SELECT COUNT(*) AS orphan_products_remaining
FROM products p
LEFT JOIN shops s ON s.id = p.shop_id
WHERE s.id IS NULL;
*/
