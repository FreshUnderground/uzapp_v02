// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final content = File('lib/core/l10n/app_translations.dart').readAsStringSync();
  final keysByLocale = <String, Set<String>>{};

  for (final loc in ['fr', 'en', 'ln', 'sw']) {
    final start = content.indexOf("'$loc': {");
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
    final keys = RegExp(r"'([^']+)'\s*:")
        .allMatches(buf.toString())
        .map((m) => m.group(1)!)
        .toSet();
    keysByLocale[loc] = keys;
  }

  final fr = keysByLocale['fr']!;
  final frBlock = _extractBlock(content, 'fr');
  final frValues = <String, String>{};
  for (final key in fr) {
    final m = RegExp(
      "'$key':\\s*'((?:\\\\'|[^'])*)'",
      dotAll: true,
    ).firstMatch(frBlock);
    if (m != null) {
      frValues[key] = m.group(1)!.replaceAll("\\'", "'");
    } else {
      final m2 = RegExp(
        "'$key':\\s*\\n\\s*'((?:\\\\'|[^'])*)'",
        dotAll: true,
      ).firstMatch(frBlock);
      if (m2 != null) {
        frValues[key] = m2.group(1)!.replaceAll("\\'", "'");
      }
    }
  }

  for (final loc in ['en', 'ln', 'sw']) {
    final missing = fr.difference(keysByLocale[loc]!).toList()..sort();
    print('=== $loc missing (${missing.length}) ===');
    for (final k in missing) {
      print("  '$k': '${frValues[k] ?? '?'}',");
    }
    print('');
  }
}

String _extractBlock(String content, String loc) {
  final start = content.indexOf("'$loc': {");
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
  return buf.toString();
}
