DEPLOIEMENT URGENT - Corriger /product/8 et #/shop/1
====================================================

1) RACINE du site (/htdocs/uzaapp.com/)
   - Remplacer .htaccess par: web/.htaccess
   - Remplacer product_page.php par: web/product_page.php
   - Ajouter shop_page.php depuis: web/shop_page.php
   - Rebuild Flutter web (flutter build web) puis uploader index.html + build/web/*

2) SUPPRIMER sur le serveur (s'ils existent) :
   - /product/ (dossier physique - cause erreur 500)
   - /shop/ (dossier physique)
   - Ancien product_page.php casse (remplacer par le delegate)

3) API (/htdocs/uzaapp.com/api/)
   - Uploader tout deploy_api_files/

4) TESTS apres upload :
   - https://uzaapp.com/product/8        → page detail (desktop)
   - https://uzaapp.com/#/shop/1         → boutique 1 (pas accueil)
   - https://uzaapp.com/api/product_page.php?id=8 → 200 OK
