// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final content = File('lib/core/l10n/app_translations.dart').readAsStringSync();
  final locales = ['fr', 'en', 'ln', 'sw'];
  final keysByLocale = <String, Set<String>>{};

  for (final loc in locales) {
    final start = content.indexOf("'$loc': {");
    if (start < 0) continue;
    var depth = 0;
    var i = content.indexOf('{', start);
    final buf = StringBuffer();
    for (; i < content.length; i++) {
      final c = content[i];
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) {
          buf.write(c);
          break;
        }
      }
      buf.write(c);
    }
    final block = buf.toString();
    final keys = RegExp(r"'([^']+)'\s*:").allMatches(block).map((m) => m.group(1)!).toSet();
    keysByLocale[loc] = keys;
  }

  final fr = keysByLocale['fr'] ?? {};
  for (final loc in locales) {
    if (loc == 'fr') {
      print('fr: ${fr.length} keys');
      continue;
    }
    final keys = keysByLocale[loc] ?? {};
    final missing = fr.difference(keys);
    final extra = keys.difference(fr);
    print('$loc: ${keys.length} keys, missing ${missing.length}, extra ${extra.length}');
    if (missing.isNotEmpty && missing.length <= 30) {
      print('  missing: ${missing.join(', ')}');
    } else if (missing.isNotEmpty) {
      print('  missing (first 30): ${missing.take(30).join(', ')}');
    }
  }
}
