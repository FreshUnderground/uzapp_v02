/// Texte marketing court pour inviter d'autres commerçants à rejoindre UzaApp.
class AppShareMessages {
  AppShareMessages._();

  static const String downloadUrl = 'https://uzaapp.com';

  /// Message rapide pour groupes WhatsApp actifs (commerçants).
  static String merchantInvite() =>
      '📢 *Commerçants RDC* — votre boutique en ligne, *gratuite* sur UzaApp !\n\n'
      '🛍️ Vitrine digitale + WhatsApp direct\n'
      '📍 Clients proches vous trouvent sur la carte\n'
      '🔔 Alertes à chaque nouvel arrivage\n'
      '📲 Visuels statut WhatsApp générés automatiquement\n\n'
      '➡️ Téléchargez : $downloadUrl\n'
      '➡️ Profil → *Créer ma boutique* → c\'est parti !\n\n'
      '#UzaApp #VendezLocal 🇨🇩';

  static String merchantInviteSubject() =>
      'UzaApp — Créez votre boutique gratuitement';
}
