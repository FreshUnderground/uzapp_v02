// ignore_for_file: avoid_print
import 'dart:io';
import 'ui_strings_patch.dart';
import 'secondary_strings_patch.dart';

void main() {
  final file = File('lib/core/l10n/app_translations.dart');
  var content = file.readAsStringSync();

  for (final entry in [
    ('fr', {...uiStringsFr, ...secondaryFr}),
    ('en', {...uiStringsEn, ...secondaryEn}),
    ('ln', {...uiStringsLn, ...secondaryLn}),
    ('sw', {...uiStringsSw, ...secondarySw}),
  ]) {
    content = _patchLocale(content, entry.$1, entry.$2);
  }

  file.writeAsStringSync(content);
  print('UI strings patched.');
}

String _patchLocale(
  String content,
  String locale,
  Map<String, String> strings,
) {
  final marker = "'$locale': {";
  final start = content.indexOf(marker);
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

  final block = content.substring(start, end);
  final toAdd = StringBuffer();
  for (final e in strings.entries) {
    if (!block.contains("'${e.key}':")) {
      final v = e.value.replaceAll("'", "\\'");
      toAdd.writeln("      '${e.key}': '$v',");
    }
  }
  if (toAdd.isEmpty) return content;
  return content.substring(0, end) + '\n${toAdd.toString().trimRight()}\n' + content.substring(end);
}
