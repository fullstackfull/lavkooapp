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

/// GCC-05, J-05: the price helpers write a non-default storefront's prices in its own currency, and write everything else exactly as the
/// app always has. Storefronts are a build flag (`--dart-define=GCC_STOREFRONTS_ENABLED=true`), so the tests of a storefront with its own
/// currency only run in a build that has it on; the pins of the old output run in the default build.
///
///   flutter test test/price_converter_storefront_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/price_converter_storefront_test.dart
class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

class _SplashWithConfig extends SplashController {
  _SplashWithConfig(this._config) : super(splashServiceInterface: null);

  final ConfigModel? _config;

  @override
  ConfigModel? get configModel => _config;
}

ConfigModel _configWith({String position = 'left'}) => ConfigModel(
      currencySymbolPosition: position,
      currencyList: [
        CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75),
        CurrencyList(id: 2, code: 'KWD', symbol: 'KD', exchangeRate: 0.307),
        CurrencyList(id: 3, code: 'AED', symbol: 'AED', exchangeRate: 3.67),
        CurrencyList(id: 4, code: 'OMR', symbol: 'OMR', exchangeRate: 0.385),
      ],
    );

Future<BuildContext> _contextOn({
  required String storefrontCode,
  ConfigModel? config,
}) async {
  SharedPreferences.setMockInitialValues(
      {AppConstants.storefrontCountry: storefrontCode});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final StorefrontController storefronts = StorefrontController(
    storefrontServiceInterface: _NoServer(),
    storefrontChoice: StorefrontChoice(preferences, enabled: true),
  );

  late BuildContext captured;
  await _pump(storefronts, config, (BuildContext context) => captured = context);

  return captured;
}

late WidgetTester _tester;

Future<void> _pump(StorefrontController storefronts, ConfigModel? config,
    void Function(BuildContext) capture) async {
  await _tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorefrontController>.value(value: storefronts),
        ChangeNotifierProvider<SplashController>.value(
            value: _SplashWithConfig(config)),
      ],
      child: Builder(builder: (BuildContext context) {
        capture(context);
        return const SizedBox();
      }),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('with storefronts off (the default build), whatever the stored choice', () {
    testWidgets('a price is written as the app has always written it',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context =
          await _contextOn(storefrontCode: 'KW', config: null);

      expect(PriceConverter.convertPrice(context, 12.5), '13');
      expect(PriceConverter.convertPrice(context, null), '0');
      expect(
          PriceConverter.convertPrice(context, 100,
              discount: 10, discountType: 'amount'),
          '90');
      expect(
          PriceConverter.convertPrice(context, 200,
              discount: 10, discountType: 'percent'),
          '180');
      expect(PriceConverter.convertPriceWithoutSymbol(context, 12.5), '12.5');
      expect(PriceConverter.getUnitCurrency(context, 12.5), '12.5');
    }, skip: StorefrontConfig.enabled);
  });

  group('with storefronts on (a build made with --dart-define=GCC_STOREFRONTS_ENABLED=true)', () {
    testWidgets('a Kuwaiti price has three decimals, its own symbol and no conversion',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context =
          await _contextOn(storefrontCode: 'KW', config: _configWith());

      expect(PriceConverter.convertPrice(context, 12.5), 'KD 12.500');
      expect(PriceConverter.convertPrice(context, 1234.5), 'KD 1,234.500');
      expect(
          PriceConverter.convertPrice(context, 12.5,
              discount: 10, discountType: 'amount'),
          'KD 2.500');
      expect(
          PriceConverter.convertPrice(context, 200,
              discount: 10, discountType: 'percent'),
          'KD 180.000');
      expect(PriceConverter.convertPriceWithoutSymbol(context, 12.5), '12.500');
      expect(PriceConverter.getUnitCurrency(context, 12.5), 'KD 12.500');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('an Emirati price has two decimals, and the mark can be on the right',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: 'AE', config: _configWith(position: 'right'));

      expect(PriceConverter.convertPrice(context, 12.5), '12.50 AED');
      expect(PriceConverter.convertPriceWithoutSymbol(context, 12.5), '12.50');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('the code stands in for a symbol the server did not send',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context = await _contextOn(
          storefrontCode: 'BH', config: _configWith());

      expect(PriceConverter.convertPrice(context, 12.5), 'BHD 12.500');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('a config that has not arrived yet still gives the currency code',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context =
          await _contextOn(storefrontCode: 'OM', config: null);

      expect(PriceConverter.convertPrice(context, 12.5), 'OMR 12.500');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('the default storefront keeps the way the app writes its prices',
        (WidgetTester tester) async {
      _tester = tester;
      final BuildContext context =
          await _contextOn(storefrontCode: 'SA', config: null);

      expect(PriceConverter.convertPrice(context, 12.5), '13');
      expect(PriceConverter.convertPriceWithoutSymbol(context, 12.5), '12.5');
      expect(PriceConverter.getUnitCurrency(context, 12.5), '12.5');
    }, skip: !StorefrontConfig.enabled);
  });
}
