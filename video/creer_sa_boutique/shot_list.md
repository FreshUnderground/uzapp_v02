# Shot list — Capture d'écran UzaApp

**Format :** 9:16 (1080×1920) pour réseaux sociaux · **Durée brute cible :** 2–3 min (sera accélérée au montage)

**Préparation avant tournage**

- Utiliser un compte **sans boutique** pour montrer le parcours complet, ou un compte test dédié
- Remplir des données réalistes (ex. boutique « Mode Kinshasa », ville Kinshasa, commune Gombe)
- Désactiver notifications pendant l'enregistrement
- Activer « Ne pas déranger » sur le téléphone

---

## Plan A — Séquences B-roll (à filmer en premier)

| # | Durée | Écran / action | Voix off associée |
|---|-------|----------------|-------------------|
| A1 | 3 s | Commerçant réel ou stock : personne sur téléphone dans une boutique | Accroche |
| A2 | 4 s | **Fiche publique boutique** (`ShopProfileScreen`) — logo, nom, produits, bouton WhatsApp | « vitrine digitale » |
| A3 | 4 s | **Près de moi** (`NearbyShopsScreen`) — carte avec épingles boutiques | « carte Près de moi » |
| A4 | 4 s | **Statut WhatsApp** (`WhatsappStatusScreen`) — visuels générés, templates | « visuels statut WhatsApp » |
| A5 | 3 s | **Partage** (`ShopShareSheet`) — QR code + lien | CTA final |

---

## Plan B — Wizard création (7 étapes)

**Point d'entrée :** Profil → bouton **« Créer ma boutique »** (`ProfileScreen`)

| # | Étape | Écran | Champs à montrer | Bouton visible |
|---|-------|-------|------------------|----------------|
| B0 | Entrée | Profil sans boutique | Bannière « Vendez vos produits sur UzaApp » | **Créer ma boutique** |
| B1 | 1/7 Informations | `CreateShopScreen` | Nom *, Type (Détail/Gros) *, Ville *, Commune * | **Suivant** |
| B2 | 2/7 Contact | idem | Numéro de téléphone *, WhatsApp (optionnel) | **Suivant** |
| B3 | 3/7 Vérification | idem | Champ OTP 6 chiffres OU | **Passer (non vérifié)** |
| B4 | 4/7 Détails | idem | Logo, description, Facebook, Instagram, TikTok, YouTube | **Suivant** |
| B5 | 5/7 Mot de passe | idem | Mot de passe *, Confirmer * | **Suivant** |
| B6 | 6/7 Aperçu | idem | Prévisualisation fiche « Voici comment ta boutique apparaîtra » | **Suivant** |
| B7 | 7/7 Localisation | idem | **Capturer ma position** ou **Passer cette étape** | **Publier ma boutique** |
| B8 | Succès | Dialogue + snackbar | « Enregistrement... » puis **« Boutique créée avec succès »** | — |
| B9 | Résultat | `ShopProfileScreen` | Fiche boutique fraîchement créée | — |

**Par plan :** 2–3 secondes par étape B1–B7, pause 1 s sur le bouton avant tap.

---

## Plan C — Post-création (CTA)

| # | Durée | Action |
|---|-------|--------|
| C1 | 3 s | Profil vendeur → **Partager ma boutique** |
| C2 | 4 s | `ShopShareSheet` : onglet lien + QR |
| C3 | 3 s | `SellerQuickActions` : grille Produit · Statut WA · Partager · Catalogue |
| C4 | 2 s | Logo UzaApp + texte « Télécharge UzaApp » (écran téléchargement ou outro graphique) |

---

## Nommage des fichiers bruts

```
video/creer_sa_boutique/raw/
  A1_accroche.mp4
  A2_vitrine.mp4
  A3_pres_de_moi.mp4
  A4_statut_wa.mp4
  A5_partage.mp4
  B0_profil_entree.mp4
  B1_etape1_infos.mp4
  B2_etape2_contact.mp4
  ...
  B9_boutique_creee.mp4
  C1_cta_partage.mp4
```

---

## Outils recommandés

- **Android :** enregistrement intégré ou AZ Screen Recorder
- **iOS :** enregistrement d'écran natif
- **Émulateur :** `adb shell screenrecord` (moins naturel, à éviter si possible)
