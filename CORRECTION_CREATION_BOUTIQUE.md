# Problème de Création de Boutique : Utilisateur Créé mais Boutique Pas en Ligne

## 🔍 Description du Problème

Quand vous créez une boutique dans l'application :
- ✅ L'utilisateur est créé dans la table `users`
- ✅ La boutique est créée dans la base de données locale SQLite
- ❌ La boutique n'est PAS créée dans la table distante `shops` (MySQL)

## 📊 Comment Fonctionne la Création de Boutique

Le processus de création suit ces étapes :

```
1. Registration Utilisateur (table users) ✅
   ↓
2. Création Boutique Locale (SQLite) ✅
   ↓
3. Mise en File de Sync (table sync_queue) ✅
   ↓
4. Push vers Serveur Distant (sync.php ou shops.php) ❌ ÉCHEC ICI
   ↓
5. La boutique apparaît en ligne dans la table shops
```

## 🐛 Causes Possibles

### 1. **Champ `type` Manquant ou Incorrect**
Le serveur nécessite un champ `type` (soit 'retail' soit 'wholesale').

**Vérifier:** Ligne 635 dans `create_shop_screen.dart`
```dart
'type': _selectedType.name,  // Doit être envoyé
```

### 2. **File de Sync Non Traitée**
La boutique est mise en file mais jamais poussée vers le serveur.

**Debug:** Vérifiez les logs de l'app pour :
```
PUSH: Starting push of X items
PUSH ✓ shops/CREATE id=XXX removed from queue
```

### 3. **Erreur de Validation Serveur**
L'API PHP rejette les données de la boutique.

**Erreurs courantes:**
- Champs requis manquants (name, type, owner_id)
- Noms de colonnes invalides dans le payload
- Violations de contraintes de base de données

### 4. **Problème d'Authentification/Clé API**
La requête de sync n'est pas correctement authentifiée.

## 🛠️ Solutions

### Solution 1: Exécuter le Script de Diagnostic

Accédez à cette URL dans votre navigateur :
```
https://uzaapp.com/api/test_shop_creation_diagnostic.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
```

Cela montrera :
- ✅ Statut de connexion base de données
- ✅ Structures des tables (shops, users)
- ✅ Utilisateurs et boutiques récents
- ✅ Test de création de boutique
- ✅ Problèmes courants

### Solution 2: Vérifier les Logs de l'Application

Quand vous créez une boutique, cherchez ces messages :

```
SHOP SYNC QUEUED: Shop ID=XXX, Owner ID=XXX
SHOP SYNC DATA: {"id":XXX,"name":"...","type":"retail",...}
PUSH: Starting push of X items
PUSH [1/X] shops/CREATE id=XXX
PUSH DATA (full): {...}
```

**Si vous voyez des erreurs :**
- `PUSH ✗ FAILED RESPONSE` - Le serveur a rejeté les données
- `PUSH ⏱ TIMEOUT` - Le serveur n'a pas répondu à temps
- `PUSH ✗ ERROR` - Erreur réseau ou autre

### Solution 3: Création Manuelle de Boutique via SQL

Si la sync échoue, vous pouvez créer manuellement la boutique :

1. Obtenez l'ID utilisateur de la table `users`
2. Utilisez ce SQL :
```sql
INSERT INTO shops (
    name, description, type, owner_id, phone, 
    address, city, commune, is_verified, created_at, updated_at
) VALUES (
    'Nom de Votre Boutique',
    'Description de la Boutique',
    'retail',
    ID_UTILISATEUR_ICI,
    'NUMEROtelephone',
    'Ville, Commune',
    'Ville',
    'Commune',
    1,
    NOW(),
    NOW()
);
```

### Solution 4: Forcer la Sync depuis l'App

1. Ouvrez l'application
2. Allez dans Paramètres ou écran Debug
3. Cherchez le bouton "Force Push All" ou "Manual Sync"
4. Cliquez pour retenter toutes les opérations de sync en attente

### Solution 5: Vérifier les Logs d'Erreur du Serveur

Sur votre serveur, vérifiez les logs PHP :
```bash
# Emplacements courants :
/var/log/php-fpm/error.log
/var/log/apache2/error.log
/var/log/nginx/error.log
```

Cherchez des erreurs liées à :
- `shops.php`
- `sync.php`
- Erreurs PDO
- Erreurs de validation

## 📋 Étapes de Vérification

Après avoir appliqué les correctifs, vérifiez :

1. **Vérifier la table shops distante :**
```sql
SELECT id, name, owner_id, phone, created_at 
FROM shops 
ORDER BY created_at DESC 
LIMIT 10;
```

2. **Vérifier la relation boutique-propriétaire :**
```sql
SELECT s.id, s.name, s.owner_id, u.phone, u.name as owner_name
FROM shops s
JOIN users u ON s.owner_id = u.id
ORDER BY s.created_at DESC;
```

3. **Chercher les boutiques orphelines :**
```sql
SELECT s.id, s.name, s.owner_id
FROM shops s
LEFT JOIN users u ON s.owner_id = u.id
WHERE u.id IS NULL;
```

## 🔧 Modifications de Code Effectuées

### 1. Logs de Debug Améliorés
**Fichier :** `lib/ui/screens/create_shop_screen.dart`

Ajout de logs détaillés quand la boutique est mise en file :
```dart
debugPrint('SHOP SYNC QUEUED: Shop ID=$shopId, Owner ID=$userId');
debugPrint('SHOP SYNC DATA: ${jsonEncode({...})}');
```

### 2. Champs de Localisation Ajoutés
**Fichier :** `lib/ui/screens/create_shop_screen.dart`

Include maintenant latitude et longitude dans le payload de sync :
```dart
'latitude': _latitude,
'longitude': _longitude,
```

### 3. Script de Diagnostic
**Fichier :** `server/api/test_shop_creation_diagnostic.php`

Outil de diagnostic complet pour tester :
- Structure de la base de données
- Flux de création de boutique
- Problèmes courants

### 4. Écran de Debug de Sync
**Fichier :** `lib/ui/screens/shop_sync_debug_screen.dart`

Écran Flutter pour :
- Voir les boutiques locales
- Voir la file de sync
- Forcer le push
- Vider la file

## 🎯 Checklist de Correction Rapide

- [ ] Exécuter le script de diagnostic et vérifier les résultats
- [ ] Vérifier les logs de l'app lors de la création de boutique
- [ ] Vérifier que le champ `type` est envoyé ('retail' ou 'wholesale')
- [ ] Vérifier les logs d'erreur PHP du serveur
- [ ] Vérifier que la clé API est correcte
- [ ] Tester avec insertion SQL manuelle
- [ ] Forcer la sync depuis l'app
- [ ] Vérifier la connectivité réseau

## 📊 Requêtes SQL Utiles

### Trouver les utilisateurs sans boutique :
```sql
SELECT u.id, u.phone, u.name, u.created_at,
       s.id as shop_id, s.name as shop_name
FROM users u
LEFT JOIN shops s ON u.id = s.owner_id
WHERE s.id IS NULL
ORDER BY u.created_at DESC
LIMIT 20;
```

### Créer une boutique manquante :
```sql
INSERT INTO shops (
    name, description, type, owner_id, phone, 
    address, city, commune, is_verified, created_at, updated_at
) VALUES (
    'Ma Boutique',
    'Description',
    'retail',
    123,  -- Remplacer par l'ID utilisateur réel
    '+243XXXXXXXXX',
    'Butembo, Vulengera',
    'Butembo',
    'Vulengera',
    1,
    NOW(),
    NOW()
);
```

### Voir toutes les boutiques avec leurs propriétaires :
```sql
SELECT 
    s.id AS shop_id,
    s.name AS shop_name,
    s.type,
    s.owner_id,
    u.phone AS owner_phone,
    u.name AS owner_name,
    s.created_at AS shop_created
FROM shops s
INNER JOIN users u ON s.owner_id = u.id
ORDER BY s.created_at DESC;
```

## 📞 Prochaines Étapes

Si le problème persiste après avoir essayé toutes les solutions :

1. **Partagez les résultats du diagnostic** du script de test
2. **Partagez les logs de l'app** de la tentative de création de boutique
3. **Partagez les logs d'erreur du serveur** de la même période
4. **Vérifiez la base de données** pour les utilisateurs récents sans boutiques

## 🔗 Fichiers Connexes

- `lib/ui/screens/create_shop_screen.dart` - UI de création de boutique
- `lib/data/services/sync_service.dart` - Gestion de la file de sync
- `lib/core/services/api_service.dart` - Communication API
- `server/api/sync.php` - Endpoint de sync serveur
- `server/api/shops.php` - Endpoint shops serveur
- `server/api/test_shop_creation_diagnostic.php` - Outil de diagnostic
- `lib/ui/screens/shop_sync_debug_screen.dart` - Écran de debug
- `fix_missing_shops.sql` - Script SQL pour corriger les boutiques manquantes
- `SHOP_CREATION_FIX.md` - Guide complet en anglais

## 📝 Résumé

**Le problème :** Les boutiques sont créées localement mais ne sont pas synchronisées avec le serveur distant.

**La cause la plus probable :** Échec silencieux lors de la poussée de sync vers le serveur (sync.php ou shops.php).

**La solution :** 
1. Exécuter le diagnostic pour identifier le problème exact
2. Vérifier les logs pour voir les erreurs
3. Créer manuellement les boutiques manquantes si nécessaire
4. Améliorer les logs pour le debug futur

**Fichiers créés pour aider :**
- ✅ Script de diagnostic PHP
- ✅ Écran de debug Flutter
- ✅ Script SQL pour identifier/corriger
- ✅ Documentation complète (FR et EN)
