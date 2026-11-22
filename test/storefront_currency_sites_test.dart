import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GCC-05, J-05: the currency the customer chose in the settings (`SplashController.myCurrency`) is the platform's money, not the money of a
/// storefront that trades in its own currency. A screen or a request that reads it directly would show or send the wrong currency on such a
/// storefront, so everything outside the list below asks `PriceConverter` (`currencyCodeToSend`, `currencySymbolToShow`), which answers with
/// the storefront's currency when it has one. A new reader has to be added here on purpose, with the reason.
void main() {
  const Map<String, String> readers = {
    'lib/features/splash/controllers/splash_controller.dart':
        'where the choice is kept',
    'lib/helper/price_converter.dart':
        'the helper that decides between the storefront currency and the choice',
    'lib/features/wallet/domain/repositories/wallet_repository.dart':
        'the wallet top-up: the storefront currency first, the choice as it always was otherwise',
    'lib/features/setting/screens/settings_screen.dart':
        'the settings row that shows the name of the choice (the choice is not offered on a storefront with its own currency)',
    'lib/features/loyaltyPoint/widget/loyalty_point_converter_dialogue_widget.dart':
        'the points to wallet conversion shows its rate through the exchange rate of the choice: loyalty per market is a later step (GCC-15)',
  };

  test('only the listed files read the currency chosen in the settings', () {
    final List<String> found = <String>[];

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final bool reads = entity
          .readAsLinesSync()
          .where((String line) => !line.trimLeft().startsWith('//'))
          .any((String line) => line.contains('myCurrency'));
      if (reads) {
        found.add(entity.path.replaceAll(r'\', '/'));
      }
    }

    found.sort();

    expect(found, readers.keys.toList()..sort(),
        reason:
            'a file that reads myCurrency shows or sends the platform currency; route it through PriceConverter.currencyCodeToSend or '
            'currencySymbolToShow, or add it to the list with the reason');
  });
}
