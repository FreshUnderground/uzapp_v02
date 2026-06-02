import 'dart:html' as html;

bool getBrowserOnline() => html.window.navigator.onLine ?? true;

void listenBrowserConnectivity(void Function(bool online) onChanged) {
  html.window.onOnline.listen((_) => onChanged(true));
  html.window.onOffline.listen((_) => onChanged(false));
}
