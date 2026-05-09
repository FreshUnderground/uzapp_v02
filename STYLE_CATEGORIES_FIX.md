# Correction des Sous-Catégories Style

## Problème
Les sous-catégories de **Style** n'apparaissaient pas car elles n'existaient pas dans la base de données.

## Ce qui a été corrigé

### 1. Ajout des sous-catégories Style dans seed_categories.php

**Niveau 1 - Sous-catégories de Style :**
- Homme
- Femme
- Enfant
- Chaussures
- Accessoires Mode

**Niveau 2 - Sous-sous-catégories :**

**Homme :**
- Chemises, Pantalons, T-Shirts, Vestes
- Costumes, Jeans, Shorts, Polos

**Femme :**
- Robes, Jupes, Blouses, Pantalons
- Racs, Tuniques, Jeans, Vestes

**Chaussures :**
- Sneakers, Chaussures Homme, Chaussures Femme
- Sandales, Bottes, Escarpins, Mocassins

**Accessoires Mode :**
- Sacs & Bagages, Montres, Bijoux
- Lunettes, Ceintures, Chapeaux & Casquettes

### 2. Scripts créés

- `server/api/seed_categories.php` - **MODIFIÉ** : Ajouté les sous-catégories Style
- `server/api/force_sync_categories.php` - **NOUVEAU** : Force la synchronisation complète
- `server/check_and_fix_categories.sql` - **NOUVEAU** : Diagnostic et correction SQL

## Comment déployer

### Étape 1 : Déployer les fichiers PHP sur le serveur

Téléversez ces fichiers vers votre serveur :
```
server/api/seed_categories.php
server/api/force_sync_categories.php
```

### Étape 2 : Exécuter le script de seeding

**Option A - Via navigateur :**
```
https://uzaapp.com/api/seed_categories.php
```

**Option B - Via curl :**
```bash
curl https://uzaapp.com/api/seed_categories.php
```

**Résultat attendu :**
```json
{
  "success": true,
  "inserted": 36,
  "message": "36 new categories inserted."
}
```
*(Le nombre peut varier selon ce qui existe déjà)*

### Étape 3 : Vérifier dans la base de données

Exécutez cette requête SQL pour vérifier :
```sql
SELECT 
    id, name, parent_id, level, sort_order
FROM categories
WHERE name IN ('Style', 'Homme', 'Femme', 'Enfant', 'Chaussures', 'Accessoires Mode')
ORDER BY level, sort_order;
```

Vous devriez voir :
```
| id | name              | parent_id | level | sort_order |
|----|-------------------|-----------|-------|------------|
| .. | Style             | NULL      | 0     | 5          |
| .. | Homme             | [Style]   | 1     | 1          |
| .. | Femme             | [Style]   | 1     | 2          |
| .. | Enfant            | [Style]   | 1     | 3          |
| .. | Chaussures        | [Style]   | 1     | 4          |
| .. | Accessoires Mode  | [Style]   | 1     | 5          |
```

### Étape 4 : Synchroniser l'app Flutter

Dans l'app, quand vous ouvrez l'écran de création de produit :
1. Le code appelle automatiquement `syncService.ensureCategoriesSynced()`
2. Les nouvelles catégories sont téléchargées
3. Quand vous cliquez sur **Style**, vous verrez :
   - Homme
   - Femme
   - Enfant
   - Chaussures
   - Accessoires Mode

### Étape 5 : Tester

1. Ouvrez l'app
2. Allez à la création d'un produit
3. Sélectionnez **Style** comme catégorie principale
4. ✅ Les sous-catégories devraient apparaître
5. Sélectionnez une sous-catégorie (ex: Homme)
6. ✅ Le formulaire Style devrait apparaître avec les champs spécifiques

## Hiérarchie complète Style

```
Style (level 0 - Root)
├── Homme (level 1)
│   ├── Chemises (level 2)
│   ├── Pantalons
│   ├── T-Shirts
│   ├── Vestes
│   ├── Costumes
│   ├── Jeans
│   ├── Shorts
│   └── Polos
│
├── Femme (level 1)
│   ├── Robes (level 2)
│   ├── Jupes
│   ├── Blouses
│   ├── Pantalons
│   ├── Racs
│   ├── Tuniques
│   ├── Jeans
│   └── Vestes
│
├── Enfant (level 1)
│
├── Chaussures (level 1)
│   ├── Sneakers (level 2)
│   ├── Chaussures Homme
│   ├── Chaussures Femme
│   ├── Sandales
│   ├── Bottes
│   ├── Escarpins
│   └── Mocassins
│
└── Accessoires Mode (level 1)
    ├── Sacs & Bagages (level 2)
    ├── Montres
    ├── Bijoux
    ├── Lunettes
    ├── Ceintures
    └── Chapeaux & Casquettes
```

## Formulaire Style

Quand vous créez un produit dans une sous-catégorie Style, le formulaire affichera :

- **Genre** : Dropdown (Homme/Femme/Enfant/Unisexe)
- **Taille** : Text field (XS, S, M, L, XL, XXL, ou numérique)
- **Marque** : Text field
- **Coloris** : Text field
- **Matière** : Text field (Coton, Cuir, Polyester, etc.)
- **Type de vêtement** : Text field (Chemise, Pantalon, Robe, Chaussures, etc.)
- **Collection/Saison** : Dropdown (Été/Hiver/Printemps/Automne/Toute saison)

## Problèmes potentiels

### Les sous-catégories n'apparaissent toujours pas ?

**Solution 1 - Forcer la synchronisation :**
```bash
curl https://uzaapp.com/api/force_sync_categories.php
```

**Solution 2 - Vérifier la base de données :**
```bash
mysql -u votre_user -p inves2504808_11wdvwt < server/check_and_fix_categories.sql
```

**Solution 3 - Nettoyer et reseeder :**
```sql
-- Supprimer toutes les catégories (ATTENTION !)
DELETE FROM categories;

-- Puis réexécuter seed_categories.php
```

### Le formulaire Style n'apparaît pas ?

Vérifiez que la sous-catégorie sélectionnée a bien `parent_id` pointant vers Style. Le formulaire apparaît seulement si :
- La catégorie racine est "Style"
- OU la sous-catégorie contient "style", "habillement", "fashion", "vetement", "homme", "femme", "enfant", "chaussure" dans son nom

## Prochaines étapes optionnelles

Vous pouvez ajouter plus de sous-catégories selon vos besoins :
- **Sport** (vêtements sportifs)
- **Lingerie**
- **Uniformes**
- **Traditionnel** (tenues traditionnelles africaines)

Pour ajouter, modifiez `seed_categories.php` et réexécutez le script.
