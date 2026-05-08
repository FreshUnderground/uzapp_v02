# 🔧 GUIDE DE DÉPANNAGE - SYNCHRONISATION

## Problème: Rien ne se同步 en ligne (produits, stories, arrivages, images)

---

## 📋 ÉTAPE 1: Tester la Connectivité du Serveur

### 1.1 Test Upload & Sync
Accédez à cette URL dans votre navigateur:
```
https://uzaapp.com/api/test_upload_sync.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
```

**Ce que vous devez voir:**
- ✅ `auth_test.key_matches`: "Yes"
- ✅ `db_connection`: "OK"
- ✅ `upload_directory.exists`: "Yes"
- ✅ `upload_directory.writable`: "Yes"
- ✅ Tous les `subdirectories` doivent être "Yes" pour exists et writable
- ✅ `database_tables` doivent tous montrer "OK"

**Si un test échoue:**
- ❌ `auth_test` échoue → Problème de clé API
- ❌ `db_connection` échoue → Problème de connexion base de données
- ❌ `upload_directory` échoue → Problème de permissions serveur
- ❌ `database_tables` échoue → Tables manquantes dans la base de données

---

## 📋 ÉTAPE 2: Vérifier les Logs de l'Application

### 2.1 Lancer l'App en Mode Debug
```bash
flutter run
```

### 2.2 Chercher ces Messages dans la Console

**Messages de PUSH (envoi vers serveur):**
```
==============================================================
PUSH: Starting push of X items
PUSH: Queue items: products/CREATE, stories/CREATE
==============================================================
PUSH [1/2] products/CREATE id=1
PUSH DATA (full): {"id":1,"shop_id":1,"name":"Test Product",...}
PUSH → products/CREATE (keys: [id, shop_id, name, ...])
PUSH → sync.php  uri=https://uzaapp.com/api/sync.php?api_key=...
PUSH ← products/CREATE  status=200  body={"success":true,"id":123,...}
PUSH ✓ products/CREATE server confirmed (id=123, action=CREATE)
PUSH ✓ products/CREATE id=1 removed from queue
```

**Messages de PULL (réception du serveur):**
```
PULL: Fetching categories, products, shops, stories
API: Fetching products from https://uzaapp.com/api/products.php?api_key=...
API: Products response status: 200
API: Fetched 45 products
```

**Messages d'ERREUR à surveiller:**
```
❌ PUSH ✗ products/CREATE HTTP 400: {"error":"Shop name is required"}
❌ PUSH ✗ products/CREATE logical failure: shop_id is required
❌ PUSH ✗ products/CREATE TIMEOUT (attempt 1/3)
❌ PULL ERROR (products): TimeoutException
❌ API ERROR (uploadFile): Connection refused
```

---

## 📋 ÉTAPE 3: Utiliser l'Écran de Debug Sync

### 3.1 Ajouter l'Écran de Debug Temporairement

Dans votre fichier de navigation principal (ex: `main.dart` ou `home_screen.dart`), ajoutez:

```dart
import 'package:uzaapp/ui/screens/sync_debug_screen.dart';

// Ajoutez un bouton ou menu pour accéder au debug
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
);
```

### 3.2 Utiliser les Boutons de Debug

1. **"Manual Sync"** → Force une synchronisation manuelle
2. **"Force Push All"** → Réessaie tous les éléments en queue
3. **"Full Reset & Sync"** → Réinitialise tout et resynchronise
4. **"View Queue Details"** → Montre ce qui est dans la queue

---

## 📋 ÉTAPE 4: Diagnostic des Problèmes Courants

### ❌ PROBLÈME 1: Les images ne s'uploadent pas

**Symptômes:**
- Message "Échec de l'upload du média"
- Console montre: `API ERROR (uploadFile): ...`

**Solutions:**
1. Vérifier que le dossier `/uploads/` existe sur le serveur
2. Vérifier les permissions: `chmod -R 755 /path/to/uzaapp/server/uploads/`
3. Tester l'upload manuellement avec le script de test
4. Vérifier `upload_max_filesize` dans php.ini (doit être ≥ 50M)

### ❌ PROBLÈME 2: Les produits ne se synchronisent pas

**Symptômes:**
- Produits créés localement mais pas sur le serveur
- Queue contient des items `products/CREATE`

**Solutions:**
1. Vérifier que `shop_id` est présent dans les données du produit
2. Vérifier que la boutique existe sur le serveur
3. Regarder les logs PUSH pour voir l'erreur exacte
4. Utiliser "Force Push All" pour réessayer

### ❌ PROBLÈME 3: Les stories/arrivages ne montent pas

**Symptômes:**
- Stories visibles localement mais pas en ligne
- Items `stories/CREATE` bloqués dans la queue

**Solutions:**
1. Vérifier que `shop_id` est correct (doit être le remote_id, pas local ID)
2. Vérifier que `media_url` est présent (l'image doit être uploadée d'abord)
3. Regarder les logs pour voir si l'upload a réussi

### ❌ PROBLÈME 4: Photo de profil/cover ne s'uploadent pas

**Symptômes:**
- Sélection de l'image mais rien ne change
- Pas d'erreur visible

**Solutions:**
1. Vérifier les logs pour `upload.php` responses
2. Vérifier que les dossiers `boutiques/profil` et `boutiques/cover` existent
3. Tester avec le script `test_upload_sync.php`

---

## 📋 ÉTAPE 5: Réparation Complète

### 5.1 Si Rien ne Fonctionne

**Dans l'application:**
1. Ouvrir l'écran de debug sync
2. Cliquer sur "Full Reset & Sync"
3. Attendre la fin de la synchronisation
4. Vérifier les logs console

**Sur le serveur (si vous avez accès SSH):**
```bash
# Aller dans le dossier du serveur
cd /path/to/uzaapp/server

# Vérifier les permissions
chmod -R 755 uploads/
chown -R www-data:www-data uploads/

# Vérifier les logs PHP
tail -f /var/log/php-fpm/error.log

# Vérifier les logs Nginx/Apache
tail -f /var/log/nginx/error.log
# ou
tail -f /var/log/apache2/error.log
```

### 5.2 Recréer les Dossiers d'Upload (si manquants)

```bash
cd /path/to/uzaapp/server
mkdir -p uploads/stories
mkdir -p uploads/produits
mkdir -p uploads/boutiques/profil
mkdir -p uploads/boutiques/cover
mkdir -p uploads/general

chmod -R 755 uploads/
```

---

## 📋 ÉTAPE 6: Vérification Finale

### 6.1 Test Complet

1. **Créer un produit test:**
   - Nom: "TEST PRODUCT"
   - Ajouter une image
   - Sauvegarder
   - Vérifier les logs PUSH

2. **Créer une story test:**
   - Sélectionner une image
   - Publier
   - Vérifier les logs PUSH

3. **Vérifier sur le serveur:**
   ```
   https://uzaapp.com/api/products.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
   https://uzaapp.com/api/stories.php?api_key=uza_sk_305f0f1ab9c86b0259c876595f74fdf4
   ```

### 6.2 Vérifier dans la Base de Données

```sql
-- Produits récents
SELECT id, name, shop_id, created_at FROM products 
ORDER BY created_at DESC LIMIT 10;

-- Stories récentes
SELECT id, shop_id, media_url, created_at FROM stories 
ORDER BY created_at DESC LIMIT 10;

-- Vérifier les uploads
-- (via FTP ou fichier manager)
-- Dossier: /path/to/uzaapp/server/uploads/
```

---

## 🆘 Besoin d'Aide?

### Informations à Fournir:

1. **Logs de la console Flutter** (copier-coller les messages PUSH/PULL)
2. **Résultat du test upload**: `https://uzaapp.com/api/test_upload_sync.php`
3. **Queue status**: Via l'écran de debug → "View Queue Details"
4. **Erreurs spécifiques**: Messages d'erreur exacts

### Commands Utiles:

```bash
# Voir les logs Flutter en temps réel
flutter run | grep -E "PUSH|PULL|ERROR|API"

# Tester la connectivité API
curl -X GET "https://uzaapp.com/api/ping.php"

# Tester l'upload
curl -X POST "https://uzaapp.com/api/upload.php" \
  -H "X-API-Key: uza_sk_305f0f1ab9c86b0259c876595f74fdf4" \
  -F "file=@test.jpg" \
  -F "folder=test"
```

---

## ✅ Checklist de Vérification

- [ ] Script de test fonctionne (`test_upload_sync.php`)
- [ ] Dossiers uploads existent et sont accessibles en écriture
- [ ] Base de données connectée et tables existantes
- [ ] Clé API correcte dans l'app Flutter
- [ ] Logs PUSH montrent des succès (✓) pas des erreurs (✗)
- [ ] Logs PULL récupèrent des données du serveur
- [ ] Queue sync se vide après force push
- [ ] Produits/stories visibles sur le serveur via API

---

**Dernière mise à jour:** 2026-05-08
**Version:** 1.0
