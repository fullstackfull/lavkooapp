import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// getTranslated falls back to the RAW KEY when a translation is missing, so a
/// key absent from a language file ships as literal `view_all` text in that
/// language. This scan keeps every statically-written key backed by both
/// shipped languages.
void main() {
  final Map<String, Set<String>> usedKeys = _collectUsedKeys();

  for (final language in ['en', 'ar']) {
    test('every getTranslated key exists in $language.json', () {
      final Map<String, dynamic> values = json.decode(
          File('assets/language/$language.json').readAsStringSync())
        as Map<String, dynamic>;

      final List<String> missing = usedKeys.keys
          .where((key) => !values.containsKey(key))
          .toList()
        ..sort();

      expect(
        missing,
        isEmpty,
        reason: missing
            .map((key) => '$key (used in ${usedKeys[key]!.first})')
            .join('\n'),
      );
    });
  }
}

Map<String, Set<String>> _collectUsedKeys() {
  final RegExp call = RegExp(r'''getTranslated\(\s*(['"])((?:\\.|(?!\1).)*)\1''');
  final Map<String, Set<String>> keys = {};

  final Iterable<File> sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  for (final file in sources) {
    // The formatter splits calls across lines, so the key often sits on the line AFTER
    // `getTranslated(` — scan the file as one string, with comment lines dropped first.
    final String source = file
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    for (final match in call.allMatches(source)) {
      final String key = match.group(2)!.replaceAll(r"\'", "'");
      // Interpolated keys are resolved at runtime; only literals can be checked.
      if (key.contains(r'$') || key.contains('{')) continue;
      keys.putIfAbsent(key, () => {}).add(file.path);
    }
  }
  return keys;
}
