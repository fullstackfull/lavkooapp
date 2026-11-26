import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';

/// J-14: an address takes its country from the customer and from the storefront they are on, and never from a country written into the source.
///
/// What this pins, and why it is worth a test of its own. `add_new_address_screen.dart` carried `String zip = '', country = 'IN';` from the template
/// the application was built from, and the tracker recorded "removing the template default country IN" as work left on this card. Measured, it was a
/// DEAD field: the address the screen saves reads `_countryCodeController.text` and `_zipCodeController.text`, and nothing read either local. So
/// taking it out changed no behaviour -- but a country code of the template sitting in the address screen is exactly the sort of thing somebody
/// later wires up, and the six markets of this platform do not include it.
///
/// The scan is over the whole address feature rather than the one line that held it, because the next such default will not be on that line. A
/// country code that genuinely belongs here is one of the markets, and those are named by [StorefrontCountry.all] -- so the allowed set is READ from
/// that class instead of typed out, and a seventh market added there is allowed here the same day. Comment lines are stripped first: a comment
/// explaining a code is not code naming one.
void main() {
  /// The address feature's own files: the catalogue client, the form, and
  /// every widget the form draws.
  const String feature = 'lib/features/address';

  /// A two-letter upper-case string literal: the shape of an ISO 3166 country
  /// code, which is how a hard-coded country appears in Dart.
  final RegExp countryShapedLiteral = RegExp(r"'([A-Z]{2})'");

  /// The country codes the address feature may name: the markets this platform
  /// serves, read from the class that lists them.
  final Set<String> markets = StorefrontCountry.all
      .map((StorefrontCountry market) => market.code)
      .toSet();

  test('the address feature names no country that is not a market', () {
    final Map<String, List<String>> found = <String, List<String>>{};

    for (final FileSystemEntity entity
        in Directory(feature).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final Iterable<String> lines = entity
          .readAsLinesSync()
          .where((String line) => !line.trimLeft().startsWith('//'));

      for (final String line in lines) {
        for (final RegExpMatch match in countryShapedLiteral.allMatches(line)) {
          final String named = match.group(1)!;

          if (!markets.contains(named)) {
            found
                .putIfAbsent(
                    entity.path.replaceAll(r'\', '/'), () => <String>[])
                .add(named);
          }
        }
      }
    }

    expect(found, isEmpty,
        reason: 'a country code written into the address feature is a default '
            'no customer and no storefront chose. The template left "IN" in '
            'the address form for exactly this long. Put the country behind '
            'the storefront the customer is on, or name the market in '
            'StorefrontCountry if it is one.');
  });

  test('the markets the scan allows are the markets the app serves', () {
    expect(markets, containsAll(<String>['SA', 'AE', 'KW', 'QA', 'BH', 'OM']));
    expect(markets.contains('IN'), isFalse,
        reason: 'the template country is not a market of this platform, so '
            'the scan above must refuse it');

    for (final String market in markets) {
      expect(countryShapedLiteral.hasMatch("'$market'"), isTrue,
          reason: 'every market code is of the shape the scan looks for, or a '
              'hard-coded market would slip past it');
    }
  });
}
