# TestFlight — UzaApp iOS

## Prérequis

- Compte Apple Developer actif
- Xcode 15+ sur macOS
- Certificat de distribution + profil de provisioning App Store

## Build

```bash
flutter build ipa --release
```

Ou via Xcode : ouvrir `ios/Runner.xcworkspace`, sélectionner **Any iOS Device**, **Product > Archive**.

## Universal Links

1. Remplacer `TEAMID` dans `web/.well-known/apple-app-site-association`
2. Héberger le fichier à `https://uzaapp.com/.well-known/apple-app-site-association`
3. Vérifier `Runner.entitlements` (associated domains)

## Tests recommandés avant soumission

- Connexion OTP / mot de passe
- Création boutique + produit + sync offline
- Scanner code-barres
- Deep link `https://uzaapp.com/product/1`
- Géolocalisation « produits proches »

## Notes App Review

Les achats se font hors application via WhatsApp ; préciser dans les notes de review.
