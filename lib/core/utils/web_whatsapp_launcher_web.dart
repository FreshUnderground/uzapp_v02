// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Opens WhatsApp (app or web) from Flutter web / installed PWA.
///
/// Uses a transient anchor click — more reliable than [window.open] in
/// standalone display mode, where blob downloads often open in-browser.
Future<bool> openWhatsAppShare({
  String? phone,
  required String message,
}) async {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return false;

  final digits = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
  final encoded = Uri.encodeComponent(trimmed);
  final href = digits.isNotEmpty
      ? 'https://wa.me/$digits?text=$encoded'
      : 'https://wa.me/?text=$encoded';

  final anchor = html.AnchorElement(href: href)
    ..target = '_blank'
    ..rel = 'noopener noreferrer external';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

bool get isStandalonePwa {
  return html.window.matchMedia('(display-mode: standalone)').matches ||
      html.window.matchMedia('(display-mode: fullscreen)').matches ||
      (html.window.navigator as dynamic).standalone == true;
}
