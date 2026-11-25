import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-05, GCC-05: an analytics event names the money its number is in.
///
/// Four of the app's seven Meta tracking calls wrote `currency: 'SYP'`, so every add to cart, every product view and the basket of every
/// one of the six markets was attributed in Syrian pounds -- a dinar basket of 12.500 reported as 12.500 SYP is not a rounding error, it
/// is a different amount of money. The three that did ask took `Get.context!`, so an event fired after the screen had gone crashed on the
/// bang. Both now go through `PriceConverter.analyticsCurrencyCode`, which answers the storefront's own currency, the currency chosen in
/// the settings, or the last resort, in that order.
///
///   flutter test test/analytics_currency_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/analytics_currency_test.dart
class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

class _SplashWithConfig extends SplashController {
  _SplashWithConfig(this._config, this._chosenCurrency)
      : super(splashServiceInterface: null);

  final ConfigModel? _config;
  final CurrencyList? _chosenCurrency;

  @override
  ConfigModel? get configModel => _config;

  @override
  CurrencyList? get myCurrency => _chosenCurrency;
}

final CurrencyList _saudiRiyal =
    CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75);

ConfigModel _config() => ConfigModel(
      currencySymbolPosition: 'left',
      currencyList: [
        CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75),
        CurrencyList(id: 2, code: 'KWD', symbol: 'KD', exchangeRate: 0.307),
      ],
    );

late WidgetTester _tester;

Future<BuildContext> _contextOn({
  required String storefrontCode,
  ConfigModel? config,
  CurrencyList? chosenCurrency,
}) async {
  SharedPreferences.setMockInitialValues(
      {AppConstants.storefrontCountry: storefrontCode});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final StorefrontController storefronts = StorefrontController(
    storefrontServiceInterface: _NoServer(),
    storefrontChoice: StorefrontChoice(preferences, enabled: true),
  );

  late BuildContext captured;
  await _tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorefrontController>.value(value: storefronts),
        ChangeNotifierProvider<SplashController>.value(
            value: _SplashWithConfig(config, chosenCurrency)),
      ],
      child: Builder(builder: (BuildContext context) {
        captured = context;
        return const SizedBox();
      }),
    ),
  );

  return captured;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('whatever the build', () {
    testWidgets('an event is attributed in the currency the customer chose when that is all the app knows',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: StorefrontCountry.defaultCountry.code,
          config: _config(),
          chosenCurrency: _saudiRiyal);

      expect(PriceConverter.analyticsCurrencyCode(context), 'SAR');
    });

    testWidgets('and never in an empty string or a null, which an event cannot carry',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: StorefrontCountry.defaultCountry.code, config: null);

      expect(PriceConverter.analyticsCurrencyCode(context), isNotEmpty);
      expect(PriceConverter.analyticsCurrencyCode(null), isNotEmpty);
    });
  });

  group('with storefronts off (the default build)', () {
    testWidgets('the stored storefront is not read, so the currency chosen in the settings stands',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: 'KW',
          config: _config(),
          chosenCurrency: _saudiRiyal);

      expect(PriceConverter.analyticsCurrencyCode(context), 'SAR');
    }, skip: StorefrontConfig.enabled);

    testWidgets('and before the config arrives the code the app has always sent is sent',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context =
          await _contextOn(storefrontCode: 'KW', config: null);

      expect(PriceConverter.analyticsCurrencyCode(context), 'SYP');
      expect(PriceConverter.analyticsCurrencyCode(null), 'SYP');
    }, skip: StorefrontConfig.enabled);
  });

  group('with storefronts on (a build made with --dart-define=GCC_STOREFRONTS_ENABLED=true)', () {
    testWidgets('a Kuwaiti basket is attributed in dinars, not in the currency chosen in the settings',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: 'KW',
          config: _config(),
          chosenCurrency: _saudiRiyal);

      expect(PriceConverter.analyticsCurrencyCode(context), 'KWD');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('each of the other markets is attributed in its own currency',
        (WidgetTester tester) async {
      _tester = tester;

      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        if (storefront.code == StorefrontCountry.defaultCountry.code) {
          continue;
        }

        final BuildContext context = await _contextOn(
            storefrontCode: storefront.code,
            config: _config(),
            chosenCurrency: _saudiRiyal);

        expect(PriceConverter.analyticsCurrencyCode(context),
            storefront.currency,
            reason:
                'the ${storefront.code} storefront trades in ${storefront.currency}');
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets('the default storefront keeps the currency chosen in the settings',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: StorefrontCountry.defaultCountry.code,
          config: _config(),
          chosenCurrency: _saudiRiyal);

      expect(PriceConverter.analyticsCurrencyCode(context), 'SAR');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('and with nothing known at all the money of the market the app opens on is named',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: StorefrontCountry.defaultCountry.code, config: null);

      expect(PriceConverter.analyticsCurrencyCode(context),
          StorefrontCountry.defaultCountry.currency);
      expect(PriceConverter.analyticsCurrencyCode(null),
          StorefrontCountry.defaultCountry.currency);
    }, skip: !StorefrontConfig.enabled);
  });

  /// The scan below is what stops the next tracking call from being written with a literal, which is how all four of these were written in
  /// the first place. It reads the source and does not depend on the build flag, so it runs once in each build and says the same thing.
  group('no file writes a currency code into an event', () {
    /// The files that may name a currency code in a `currency:` argument, with the reason. Everything else asks
    /// `PriceConverter.analyticsCurrencyCode`.
    const Map<String, String> allowed = {
      'lib/features/storefront/domain/models/storefront_country.dart':
          'the table of the six markets and the money each trades in: this is where a currency code belongs',
      'lib/features/storefront/domain/models/storefront_money_block.dart':
          'the reader of the money block the SERVER sends, which carries the code it was given and never works one out: '
          'the scan is about a currency a file decided for itself, and this file decides nothing',
      'lib/features/checkout/domain/models/myfatoorah_payment_status.dart':
          'the gateway reports the currency it took the payment in; the empty string is "it said none"',
      'lib/services/meta_tracking_service.dart':
          'the tracking service passes on the code its caller gave it',
    };

    test('every currency named in an argument is the one the storefront is in', () {
      final RegExp argument = RegExp(r'\bcurrency:\s*(.+?),?\s*$');
      final List<String> offenders = <String>[];

      for (final FileSystemEntity entity
          in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final String path = entity.path.replaceAll(r'\', '/');
        if (allowed.containsKey(path)) {
          continue;
        }

        for (final String line in entity.readAsLinesSync()) {
          final String trimmed = line.trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
            continue;
          }

          final RegExpMatch? match = argument.firstMatch(trimmed);
          final String? value = match?.group(1);
          if (value == null ||
              value.startsWith('PriceConverter.analyticsCurrencyCode')) {
            continue;
          }

          offenders.add('$path: $trimmed');
        }
      }

      expect(offenders, isEmpty,
          reason:
              'an event or a request that names a currency it worked out for itself can name the wrong one; ask '
              'PriceConverter.analyticsCurrencyCode, or add the file to the allowed list with the reason');
    });

    test('and the allowed list names no file that has gone', () {
      for (final String path in allowed.keys) {
        expect(File(path).existsSync(), isTrue,
            reason:
                '$path is on the allowed list of files that may name a currency code, and is not there any more');
      }
    });
  });
}
