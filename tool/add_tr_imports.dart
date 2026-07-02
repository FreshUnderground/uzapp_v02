// ignore_for_file: avoid_print
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final libDir = Directory('lib');
  var count = 0;
  for (final file in libDir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    var content = file.readAsStringSync();
    if (!content.contains('tr(context,') && !content.contains('trLanguageName(') && !content.contains('trThemeMode(')) {
      continue;
    }
    if (content.contains('l10n/tr.dart')) continue;

    final rel = p.relative(file.path, from: 'lib').replaceAll('\\', '/');
    final depth = rel.split('/').length - 1;
    final prefix = List.generate(depth, (_) => '..').join('/');
    final importLine = "import '$prefix/l10n/tr.dart';\n";

    final flutterIdx = content.indexOf("import 'package:flutter");
    if (flutterIdx < 0) continue;
    final lineEnd = content.indexOf('\n', flutterIdx);
    content = content.substring(0, lineEnd + 1) + importLine + content.substring(lineEnd + 1);
    file.writeAsStringSync(content);
    count++;
    print('Import added: $rel');
  }
  print('Done: $count files');
}
