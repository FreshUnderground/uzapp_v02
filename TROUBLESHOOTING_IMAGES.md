# Guide de Dépannage: Images non disponibles dans les Arrivages et Stories

## 🔍 Problème
Les images des arrivages et stories affichent parfois "Image non disponible" alors qu'elles existaient et s'affichaient correctement avant.

## 📋 Causes Possibles

### 1. **Firebase Storage Quota Exceeded (HTTP 402)** ⚠️
Votre Firebase Storage (plan Spark gratuit) a atteint ses limites:
- 5 GB de stockage maximum
- 15 GB/mois de téléchargement

**Symptôme:** Les images Firebase ne chargent plus et retournent une erreur 402.

### 2. **URLs Firebase Encore dans la Base de Données**
Même après migration, certaines URLs pointent toujours vers Firebase Storage au lieu de votre serveur.

### 3. **Cache d'Images Obsolète**
L'application met en cache les images. Si une image a échoué au premier chargement, le cache conserve l'erreur.

### 4. **Fichiers Manquants sur le Serveur**
Les images migrées n'existent pas dans `/uploads/migrated/` sur votre serveur.

---

## ✅ Solutions

### ÉTAPE 1: Diagnostiquer le Problème

1. **Exécutez le script de diagnostic:**
   ```
   https://uzaapp.com/api/check_image_urls.php
   ```
   
   Ce script vous montrera:
   - Combien d'images utilisent encore Firebase Storage
   - Combien d'images utilisent votre serveur
   - Quels enregistrements spécifiques ont besoin d'être migrés

2. **Vérifiez les logs de l'application:**
   - Ouvrez l'application en mode debug
   - Cherchez les messages contenant:
     - `⚠️ FIREBASE STORAGE QUOTA EXCEEDED`
     - `⚠️ IMAGE NOT FOUND (404)`
     - `Image load failed`

---

### ÉTAPE 2: Migrer les URLs Firebase vers votre Serveur

#### Option A: Migration Automatique (Recommandée)

1. **Connectez-vous à phpMyAdmin** ou à votre interface MySQL

2. **Exécutez le script SQL:**
   ```sql
   -- Le fichier est à la racine du projet:
   -- fix_firebase_urls.sql
   ```

3. **Vérifiez le résultat:**
   - Le script affiche le nombre d'URLs restantes avec Firebase
   - Ce nombre devrait être 0 après exécution

#### Option B: Migration Manuelle (si Option A échoue)

Si les images ont des noms de fichiers différents, utilisez ce script PHP:

```bash
# Déployez le script migrate_images.php sur votre serveur
# Puis accédez à: https://uzaapp.com/api/migrate_images.php
```

---

### ÉTAPE 3: Vérifier les Fichiers sur le Serveur

1. **Connectez-vous à votre serveur** (FTP/SSH)

2. **Vérifiez que le dossier existe:**
   ```bash
   ls -la /path/to/uzaapp/uploads/migrated/
   ```

3. **Vérifiez les permissions:**
   ```bash
   # Dossier: 755
   chmod 755 uploads/migrated/
   
   # Fichiers: 644
   chmod 644 uploads/migrated/*
   ```

4. **Testez une URL directement:**
   ```
   https://uzaapp.com/uploads/migrated/[nom-du-fichier].jpg
   ```
   L'image devrait s'afficher dans votre navigateur.

---

### ÉTAPE 4: Nettoyer le Cache de l'Application

#### Sur Mobile (Android/iOS):

1. **Android:**
   ```
   Paramètres → Applications → UZA App → Stockage → Vider le cache
   ```

2. **iOS:**
   ```
   Supprimez et réinstallez l'application
   ```

3. **Depuis l'application:**
   - Ajoutez un bouton "Vider le cache" dans les paramètres (optionnel)
   - Ou forcez une resync complète

#### Sur Web:

1. **Chrome/Edge:**
   ```
   Ctrl + Shift + Delete → Images et fichiers en cache → Effacer
   ```

2. **Force refresh:**
   ```
   Ctrl + F5
   ```

---

### ÉTAPE 5: Tester et Vérifier

1. **Redémarrez l'application**

2. **Naviguez vers:**
   - Screen des arrivages
   - Screen des stories
   - Discover feed

3. **Vérifiez que:**
   - ✅ Toutes les images chargent correctement
   - ❌ Plus de message "Image non disponible"
   - ❌ Plus d'erreurs 402 dans les logs

4. **Exécutez à nouveau le diagnostic:**
   ```
   https://uzaapp.com/api/check_image_urls.php
   ```
   - Le nombre d'URLs Firebase devrait être 0

---

## 🔧 Améliorations Implémentées

### 1. Meilleure Détection d'Erreurs

L'application détecte maintenant différents types d'erreurs:
- **402**: Quota Firebase dépassé → "Quota dépassé"
- **404**: Image supprimée → "Image supprimée"
- **5xx**: Erreur serveur → "Erreur serveur"
- **Autre**: Erreur générique → "Image non disponible"

### 2. Logs de Debugging Améliorés

Chaque erreur d'image est maintenant loguée avec:
```
Image load failed: url=..., error=..., retry=0
⚠️ FIREBASE STORAGE QUOTA EXCEEDED for ...
💡 Run fix_firebase_urls.sql to migrate Firebase URLs to server
```

### 3. Retry Automatique

L'application essaie automatiquement de recharger les images 3 fois avant d'afficher l'erreur.

---

## 📊 Prévention Future

### 1. Monitorer l'Utilisation de Firebase

**Vérifiez régulièrement:**
```
Firebase Console → Storage → Usage & billing
```

**Si vous approchez des limites:**
- Migrez vers Firebase Blaze (pay-as-you-go)
- Ou migrez toutes les images vers votre serveur

### 2. Utiliser Votre Serveur pour les Nouvelles Images

**Assurez-vous que:**
- Les nouvelles stories utilisent `https://uzaapp.com/uploads/`
- Les nouveaux produits utilisent `https://uzaapp.com/uploads/`
- Plus aucune nouvelle image n'est uploadée sur Firebase

### 3. Backup Régulier

**Sauvegardez régulièrement:**
```bash
# Backup de la base de données
mysqldump -u [user] -p [database] > backup_$(date +%Y%m%d).sql

# Backup des images
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz uploads/
```

---

## 🆘 Dépannage Avancé

### Problème: Les images montrent toujours "Image non disponible" après migration

**Solution:**
1. Vérifiez que les fichiers existent:
   ```bash
   ls -la /path/to/uploads/migrated/
   ```

2. Testez l'accès direct:
   ```
   https://uzaapp.com/uploads/migrated/test.jpg
   ```

3. Vérifiez le fichier `.htaccess` dans `uploads/`:
   ```apache
   Options -Indexes
   <FilesMatch "\.(jpg|jpeg|png|gif|webp|mp4)$">
       Header set Access-Control-Allow-Origin "*"
   </FilesMatch>
   ```

### Problème: Erreur de syntaxe SQL avec REGEXP_REPLACE

**Solution:**
Si votre MySQL est < 8.0, remplacez:
```sql
SET image_urls = REGEXP_REPLACE(image_urls, '\\?alt=media&token=[^,&]+', '')
```

Par:
```sql
SET image_urls = SUBSTRING_INDEX(image_urls, '?', 1)
```

### Problème: Certaines images Firebase fonctionnent encore

**Explication:**
Firebase ne coupe pas immédiatement l'accès quand le quota est atteint. Certaines images peuvent encore fonctionner sporadiquement.

**Solution:**
Migrez TOUTES les URLs même si certaines fonctionnent encore, pour éviter des problèmes futurs.

---

## 📞 Support

Si le problème persiste après avoir suivi toutes ces étapes:

1. **Collectez ces informations:**
   - Capture d'écran du diagnostic (`check_image_urls.php`)
   - Logs de l'application (messages avec `ImageUtils`)
   - Exemples d'URLs qui ne fonctionnent pas

2. **Vérifiez:**
   - [ ] Script SQL exécuté avec succès
   - [ ] Fichiers existent dans `/uploads/migrated/`
   - [ ] Permissions correctes (644/755)
   - [ ] Cache de l'application vidé
   - [ ] Application redémarrée

3. **Contactez le support technique** avec les informations collectées

---

## 📝 Checklist de Résolution

- [ ] Étape 1: Diagnostic exécuté (`check_image_urls.php`)
- [ ] Étape 2: Script SQL migré (`fix_firebase_urls.sql`)
- [ ] Étape 3: Fichiers vérifiés sur le serveur
- [ ] Étape 4: Cache de l'application vidé
- [ ] Étape 5: Images testées et fonctionnelles
- [ ] Prévention: Monitoring Firebase configuré
- [ ] Prévention: Backup régulier planifié

---

**Dernière mise à jour:** Mai 2026  
**Version de l'app:** 2.0+  
**Améliorations incluses:** Meilleure détection d'erreurs, logs améliorés, retry automatique
