import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SEC-E16-01: the app verifies the server's certificate, and nothing in it accepts one that fails.
///
/// What was there until this test existed: `lib/main.dart` declared `class MyHttpOverrides extends HttpOverrides` whose
/// `badCertificateCallback` returned `true` -- for every certificate, every host and every port -- and installed it as
/// `HttpOverrides.global` before anything else ran. That is not a relaxed check; it is no check. Anyone able to answer for the server on
/// the network -- a cafe's access point, a hostile resolver, a router in the middle -- could present a certificate they made themselves
/// and the app would accept it, read and rewrite everything it carried, and show the shopper no sign at all. Sessions, tokens, addresses
/// and the whole payment conversation travel that way, so this one line undid every control the server has, however well the server was
/// written.
///
/// It was not a workaround for anything. It entered with the repository's own initial commit, which is where this kind of line usually
/// comes from -- silencing a certificate error on a development machine and then shipping -- and the SELLER app, which talks to the same
/// backend, carries no override and works. A valid certificate is already being served.
///
/// This is a SCAN rather than a behavioural test on purpose: the fault is an absence, and the realistic regression is the line coming
/// back in a file nobody is watching, not an override that answers wrongly. `HttpOverrides.global` is process-wide, so one such line
/// anywhere in `lib` is enough to disable verification everywhere -- which is why the whole tree is read and not only `main.dart`.
///
/// COMMENTS ARE STRIPPED BEFORE SCANNING. `lib/main.dart` now carries a comment that names `badCertificateCallback` to say why no
/// override is installed, and a scan that read its own explanation would fail on the very prose that prevents the fault. Stripping
/// comments is also why the spellings below can stay simple.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: _withoutComments(entity.readAsStringSync()),
  };

  test(
    'the sources are read, so an empty scan cannot pass for a clean one',
    () {
      expect(
        sources.length,
        greaterThan(100),
        reason: 'lib holds hundreds of Dart files; a near-empty map means the scan read nothing',
      );
      expect(
        sources.containsKey('lib/main.dart'),
        isTrue,
        reason: 'main.dart is where the override was installed',
      );
    },
  );

  test('no file accepts a certificate that failed verification', () {
    final List<String> offenders = <String>[
      for (final MapEntry<String, String> source in sources.entries)
        if (source.value.contains('badCertificateCallback')) source.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'badCertificateCallback decides whether a REJECTED certificate is used anyway. A handler that can answer true for a host '
          'the shopper never chose accepts a certificate anyone can make, so these files hand the session to whoever is in the middle: '
          '${offenders.join(', ')}',
    );
  });

  test('no file installs a global HttpOverrides, which would decide for every connection the app makes', () {
    final List<String> offenders = <String>[
      for (final MapEntry<String, String> source in sources.entries)
        if (source.value.contains('HttpOverrides.global') ||
            source.value.contains('extends HttpOverrides'))
          source.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'HttpOverrides.global replaces the client every HTTPS connection in the process is built from, so one of these reaches '
          'code that never asked for it -- including a payment screen in another feature: ${offenders.join(', ')}',
    );
  });

  test('no file builds a SecurityContext that trusts everything', () {
    final List<String> offenders = <String>[
      for (final MapEntry<String, String> source in sources.entries)
        if (source.value.contains('SecurityContext(withTrustedRoots: false)'))
          source.key,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'a context built without trusted roots verifies against nothing unless the file then adds its own authority, which none of '
          'these does: ${offenders.join(', ')}',
    );
  });
}

/// The source with its comments removed, so the scan reads code and not prose.
///
/// Whole-line comments and doc comments go, and so do block comments. A TRAILING comment on a line of code is left alone, because cutting
/// at `//` would also cut a `https://` inside a string literal -- and a violation hidden after a trailing comment on a code line is not a
/// thing that happens, while URLs in strings are everywhere.
String _withoutComments(String source) {
  final String withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );

  return withoutBlocks
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}
