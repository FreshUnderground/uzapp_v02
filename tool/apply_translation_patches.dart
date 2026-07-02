// ignore_for_file: avoid_print
import 'dart:io';
import 'translation_patches.dart';

void main() {
  final file = File('lib/core/l10n/app_translations.dart');
  var content = file.readAsStringSync();

  content = _patchLocale(content, 'en', enMissing);
  content = _patchLocale(content, 'ln', lnMissing);
  content = _patchLocale(content, 'sw', swMissing);

  file.writeAsStringSync(content);
  print('Patched app_translations.dart');
}

String _patchLocale(
  String content,
  String locale,
  Map<String, String> missing,
) {
  final marker = "'$locale': {";
  final start = content.indexOf(marker);
  if (start < 0) throw StateError('Locale $locale not found');

  // Insert before closing brace of locale block
  var depth = 0;
  var i = content.indexOf('{', start);
  var end = -1;
  for (; i < content.length; i++) {
    final c = content[i];
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) throw StateError('End of $locale block not found');

  final block = content.substring(start, end);
  final toAdd = StringBuffer();
  for (final e in missing.entries) {
    if (!block.contains("'${e.key}':")) {
      final v = e.value.replaceAll("'", "\\'");
      toAdd.writeln("      '${e.key}': '$v',");
    }
  }

  if (toAdd.isEmpty) return content;

  final insert = '\n${toAdd.toString().trimRight()}\n';
  return content.substring(0, end) + insert + content.substring(end);
}
