// ignore_for_file: avoid_print
import 'dart:io';

/// Replaces hardcoded UI strings with tr(context, 'key') in lib/ui and lib/core/services.
void main() {
  final replacements = <String, String>{
    "'Réessayer'": "tr(context, 'retry')",
    "'Synchronisation en cours...'": "tr(context, 'sync_in_progress')",
    "'Code renvoyé'": "tr(context, 'code_resent')",
    "'Fermer'": "tr(context, 'close')",
    "'Confirmer'": "tr(context, 'confirm')",
    "'Paiement reçu'": "tr(context, 'payment_received')",
    "'Livrée'": "tr(context, 'delivered')",
    "'Commandes reçues'": "tr(context, 'orders_received')",
    "'Préparation du catalogue…'": "tr(context, 'catalog_preparing')",
    "'Passer'": "tr(context, 'skip')",
    "'Boutique introuvable'": "tr(context, 'shop_not_found')",
    "'Numéro WhatsApp non disponible'": "tr(context, 'whatsapp_unavailable')",
    "'Le nom de la boutique est requis'": "tr(context, 'shop_name_required')",
    "'Échec de l\\'upload du logo'": "tr(context, 'logo_upload_failed')",
    "'Profil mis à jour'": "tr(context, 'profile_updated')",
    "'Supprimer ?'": "tr(context, 'delete_confirm_title')",
    "'Supprimé avec succès'": "tr(context, 'deleted_success')",
    "'Signaler ce produit'": "tr(context, 'report_product')",
    "'Raison du signalement'": "tr(context, 'report_reason')",
    "'Signalement envoyé. Merci pour votre aide.'": "tr(context, 'report_sent')",
    "'Erreur lors de l\\'envoi du signalement.'": "tr(context, 'report_error')",
    "'Annuler'": "tr(context, 'cancel')",
    "'Envoyer'": "tr(context, 'send')",
    "'Connectez-vous pour signaler un produit'": "tr(context, 'report_login_required')",
    "'Produit ajouté à votre sélection'": "tr(context, 'product_added_selection')",
    "'Donner mon avis'": "tr(context, 'give_review')",
    "'Merci pour votre avis !'": "tr(context, 'thanks_review')",
    "'Publier mon avis'": "tr(context, 'publish_review')",
    "'Signaler'": "tr(context, 'report_action')",
    "'Lien copié !'": "tr(context, 'link_copied')",
    "'Message copié'": "tr(context, 'message_copied')",
    "'Copier'": "tr(context, 'copy')",
    "'Appel direct'": "tr(context, 'direct_call')",
    "'Envoyer un SMS'": "tr(context, 'send_sms')",
    "'Paiement Mobile Money'": "tr(context, 'mobile_money_payment')",
    "'OK'": "tr(context, 'ok')",
    "'Payer maintenant'": "tr(context, 'pay_now')",
    "'Continuer via WhatsApp'": "tr(context, 'continue_whatsapp')",
    "'Alerte stock enregistrée'": "tr(context, 'stock_alert_saved')",
    "'Alerte prix'": "tr(context, 'price_alert')",
    "'Alerte retour stock'": "tr(context, 'restock_alert')",
    "'Une seule boutique à la fois pour le paiement.'": "tr(context, 'one_shop_payment')",
    "'Numéro vendeur indisponible.'": "tr(context, 'seller_phone_unavailable')",
    "'Numéro de contact invalide.'": "tr(context, 'invalid_contact_number')",
    "'Numero de telephone non disponible'": "tr(context, 'phone_unavailable')",
    "'Modifier ma Boutique'": "tr(context, 'edit_shop')",
    "'Enregistrer les modifications'": "tr(context, 'save_changes')",
    "'Logo'": "tr(context, 'logo')",
    "'Enregistrement...'": "tr(context, 'saving')",
    "'Livraison disponible'": "tr(context, 'delivery_available')",
    "'Avec chauffeur'": "tr(context, 'with_driver')",
    "'Publication rapide'": "tr(context, 'quick_publish')",
    "'Publier'": "tr(context, 'publish')",
    "'Appuyez pour ajouter une photo'": "tr(context, 'tap_add_photo')",
    "'Nom du produit requis'": "tr(context, 'product_name_required')",
    "'Ajoutez au moins une photo'": "tr(context, 'add_photo_required')",
    "'Produit publié !'": "tr(context, 'product_published')",
    "'Statistiques'": "tr(context, 'statistics')",
    "'Autoriser la localisation'": "tr(context, 'allow_location')",
    "'RECHERCHE'": "tr(context, 'search_title')",
    "'Reinitialiser'": "tr(context, 'reset_filters')",
    "'Réinitialiser'": "tr(context, 'reset_filters')",
    "'Appliquer'": "tr(context, 'apply')",
    "'Tout effacer'": "tr(context, 'clear_all')",
    "'Aucune catégorie'": "tr(context, 'no_categories')",
    "'Diagnostic Catégories'": "tr(context, 'category_diagnostic')",
    "'Aucune catégorie racine'": "tr(context, 'no_root_categories')",
    "'Aucun produit'": "tr(context, 'no_products')",
    "'Mettre à jour le stock'": "tr(context, 'update_stock')",
    "'Demande envoyée !'": "tr(context, 'request_sent')",
    "'Sélectionnez un produit'": "tr(context, 'select_product')",
    "'Mettre à jour le produit'": "tr(context, 'update_product')",
    "'Publier la mise à jour'": "tr(context, 'publish_update')",
    "'Aucun produit à mettre à jour'": "tr(context, 'no_product_to_update')",
    "'Statut WhatsApp'": "tr(context, 'whatsapp_status')",
    "'Gérer mes produits'": "tr(context, 'manage_my_products')",
    "'Changer'": "tr(context, 'change')",
    "'Partage Facebook impossible.'": "tr(context, 'share_facebook_failed')",
    "'Partage impossible. Réessayez.'": "tr(context, 'share_failed_retry')",
    "'Images partagées ou téléchargées selon votre navigateur.'": "tr(context, 'share_images_hint')",
    "'Création vidéo TikTok impossible.'": "tr(context, 'tiktok_video_failed')",
    "'Ouvrir la caisse'": "tr(context, 'open_cash_register')",
    "'Fermer la caisse'": "tr(context, 'close_cash_register')",
    "'Caisse ouverte'": "tr(context, 'cash_register_opened')",
    "'Caisse fermée'": "tr(context, 'cash_register_closed')",
    "'Gestion Caisse'": "tr(context, 'cash_management')",
    "'Aucune boutique disponible'": "tr(context, 'no_shop_available')",
    "'Session ouverte'": "tr(context, 'session_open')",
    "'Aucune transaction'": "tr(context, 'no_transactions')",
    "'Transactions'": "tr(context, 'transactions')",
    "'Cash'": "tr(context, 'cash')",
    "'Carte'": "tr(context, 'card')",
    "'Ouvrir'": "tr(context, 'open')",
    "'Enregistrer'": "tr(context, 'register')",
    "'Aide & Support'": "tr(context, 'help_support')",
    "'Démarrer la discussion'": "tr(context, 'start_discussion')",
    "'Veuillez sélectionner un média'": "tr(context, 'select_media')",
    "'La connexion est lente. Réessayer?'": "tr(context, 'slow_connection_retry')",
    "'Vidéo'": "tr(context, 'video')",
    "'Sécurité & Confidentialité'": "tr(context, 'security_privacy')",
    "'Compris'": "tr(context, 'understood')",
    "'Localiser la boutique'": "tr(context, 'locate_shop')",
    "'Plus tard'": "tr(context, 'later')",
    "'Capturer'": "tr(context, 'capture')",
    "'Position capturée'": "tr(context, 'position_captured')",
    "'Erreur de connexion'": "tr(context, 'connection_error')",
    "'Effacer'": "tr(context, 'clear')",
    "'WhatsApp, SMS, réseaux sociaux…'": "tr(context, 'share_whatsapp_sms')",
    "'Sélectionnez une catégorie'": "tr(context, 'choose_category')",
    "'Choisir ou créer une catégorie'": "tr(context, 'choose_or_create_category')",
    "'Nouvelle catégorie…'": "tr(context, 'new_category')",
    "'Sélectionnez une sous-catégorie'": "tr(context, 'choose_subcategory')",
    "'Le prix sera affiché comme \"Sur demande\"'": "tr(context, 'price_on_request_hint')",
    "'Veuillez choisir ou saisir une catégorie'": "tr(context, 'choose_category_required')",
    "'Boutique créée avec succès'": "tr(context, 'shop_created_success')",
    "'Numéro vérifié avec succès'": "tr(context, 'phone_verified_success')",
    "'Impossible de capturer la localisation. Réessayez.'": "tr(context, 'location_capture_failed')",
    "'Erreur de localisation.'": "tr(context, 'location_error')",
    "'Produit supprimé avec succès'": "tr(context, 'product_deleted_success')",
    "'Galerie'": "tr(context, 'gallery')",
    "'Appareil photo'": "tr(context, 'camera')",
    "'Produits'": "tr(context, 'products')",
    "'Arrivages'": "tr(context, 'arrivages')",
    "'Supprimer'": "tr(context, 'delete')",
    "'Mode Léger'": "tr(context, 'lite_mode')",
    "'Masquer les images pour économiser les données'": "tr(context, 'lite_mode_subtitle')",
    "'Boutique locale'": "tr(context, 'local_shop')",
    "'Mobile Money'": "tr(context, 'mobile_money')",
  };

  final dirs = ['lib/ui', 'lib/core/services'];
  var total = 0;
  for (final dir in dirs) {
    for (final file in Directory(dir).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      var content = file.readAsStringSync();
      final original = content;

      if (content.contains("tr(context,") && !content.contains("import '../../core/l10n/tr.dart'") && !content.contains("import '../../../core/l10n/tr.dart'") && !content.contains("import '../core/l10n/tr.dart'") && !content.contains("import 'package:uzaapp/core/l10n/tr.dart'")) {
        // compute relative import depth
        final path = file.path.replaceAll('\\', '/');
        if (path.contains('/ui/') || path.contains('/services/')) {
          final depth = path.split('/').length - 2; // lib/...
          final prefix = List.filled(depth - 1, '..').join('/');
          if (!content.contains('l10n/tr.dart')) {
            final importLine = "import '${prefix.isEmpty ? '' : '$prefix/'}core/l10n/tr.dart';\n";
            final idx = content.indexOf("import 'package:flutter");
            if (idx >= 0) {
              final lineEnd = content.indexOf('\n', idx);
              content = content.substring(0, lineEnd + 1) + importLine + content.substring(lineEnd + 1);
            }
          }
        }
      }

      for (final e in replacements.entries) {
        content = content.replaceAll("Text(${e.key})", 'Text(${e.value})');
        content = content.replaceAll("Text(${e.key},", 'Text(${e.value},');
        content = content.replaceAll("title: Text(${e.key})", 'title: Text(${e.value})');
        content = content.replaceAll("title: const Text(${e.key})", 'title: Text(${e.value})');
        content = content.replaceAll("child: const Text(${e.key})", 'child: Text(${e.value})');
        content = content.replaceAll("child: Text(${e.key})", 'child: Text(${e.value})');
        content = content.replaceAll("label: const Text(${e.key})", 'label: Text(${e.value})');
        content = content.replaceAll("label: Text(${e.key})", 'label: Text(${e.value})');
        content = content.replaceAll("content: const Text(${e.key})", 'content: Text(${e.value})');
        content = content.replaceAll("content: Text(${e.key})", 'content: Text(${e.value})');
        content = content.replaceAll("subtitle: const Text(${e.key})", 'subtitle: Text(${e.value})');
        content = content.replaceAll("hint: const Text(${e.key})", 'hint: Text(${e.value})');
      }

      // Remove const before Text(tr(...)) where invalid
      content = content.replaceAll('const Text(tr(', 'Text(tr(');
      content = content.replaceAll('const SnackBar(content: Text(tr(', 'SnackBar(content: Text(tr(');

      if (content != original) {
        file.writeAsStringSync(content);
        total++;
        print('Updated ${file.path}');
      }
    }
  }
  print('Done. $total files updated.');
}
