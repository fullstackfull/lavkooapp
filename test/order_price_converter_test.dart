import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/order_market.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

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

/// The currency the customer chose in the settings: a platform currency, which the money of an order never follows.
final CurrencyList _saudiRiyal =
    CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75);

/// The server's currency list. The Qatari riyal and the Bahraini dinar are left out, so that the code stands in for their mark.
ConfigModel _config({String position = 'left'}) => ConfigModel(
      currencySymbolPosition: position,
      currencyList: [
        CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75),
        CurrencyList(id: 2, code: 'KWD', symbol: 'KD', exchangeRate: 0.307),
        CurrencyList(id: 3, code: 'AED', symbol: 'AED', exchangeRate: 3.67),
        CurrencyList(id: 4, code: 'OMR', symbol: 'OMR', exchangeRate: 0.385),
      ],
    );

const Map<String, String> _currencyOf = <String, String>{
  'SA': 'SAR',
  'AE': 'AED',
  'KW': 'KWD',
  'QA': 'QAR',
  'BH': 'BHD',
  'OM': 'OMR',
};

/// 12.5, written by hand as each storefront with its own currency writes it: the decimals of its currency (three for the dinar and the
/// rial), its mark or its code, and the amount as it is stored.
const Map<String, String> _twelveAndAHalf = <String, String>{
  'AE': 'AED 12.50',
  'KW': 'KD 12.500',
  'QA': 'QAR 12.50',
  'BH': 'BHD 12.500',
  'OM': 'OMR 12.500',
};

OrderMarket _orderOf(String country, {double rate = 1}) => OrderMarket(
    country: country, currencyCode: _currencyOf[country], currencyRate: rate);

Future<BuildContext> _contextOn(
  WidgetTester tester, {
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
  await tester.pumpWidget(
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

/// J-13 criterion 1, the money half: an amount of an order is written in the currency the order was sold in, with the decimals of that
/// currency, whatever storefront the customer is on and whatever currency they chose in the settings, and an amount is never multiplied by a
/// rate. Storefronts are a build flag (`--dart-define=GCC_STOREFRONTS_ENABLED=true`), so the groups that write an order in its own currency
/// run only in a build that has it on, and the group that says nothing changes without it runs only in the default build.
///
/// An order of the default storefront keeps the platform's money, as every price of that storefront does; an order that says nothing of what
/// it was sold in, and one whose rate is not one, are orders whose currency the app cannot tell, and it does not guess it. All three are
/// written by `convertPrice`, as every order always was, which on a storefront with its own currency is the money of that storefront: the
/// tests pin that they are written exactly as `convertPrice` writes them, not that this is the right money for them.
///
///   flutter test test/order_price_converter_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/order_price_converter_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('with storefronts off (the default build), whatever the order says',
      () {
    testWidgets(
        'an order of every storefront is written as the app has always written an amount',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'KW', config: _config(), chosenCurrency: _saudiRiyal);

      for (final String country in _currencyOf.keys) {
        expect(
            PriceConverter.convertOrderPrice(context, 12.5,
                market: _orderOf(country)),
            '13',
            reason: country);
      }
    }, skip: StorefrontConfig.enabled);

    testWidgets(
        'and it is what convertPrice writes, for a whole amount, a missing amount and an order with no record',
        (WidgetTester tester) async {
      final BuildContext context =
          await _contextOn(tester, storefrontCode: 'KW', config: null);

      expect(
          PriceConverter.convertOrderPrice(context, 100,
              market: _orderOf('KW')),
          PriceConverter.convertPrice(context, 100));
      expect(
          PriceConverter.convertOrderPrice(context, null,
              market: _orderOf('KW')),
          '0');
      expect(
          PriceConverter.convertOrderPrice(context, 12.5, market: null), '13');
    }, skip: StorefrontConfig.enabled);
  });

  group(
      'with storefronts on (a build made with --dart-define=GCC_STOREFRONTS_ENABLED=true)',
      () {
    testWidgets(
        'an order of each storefront with its own currency is written in that currency, whatever storefront the customer is on',
        (WidgetTester tester) async {
      for (final String customerOn in _currencyOf.keys) {
        final BuildContext context = await _contextOn(tester,
            storefrontCode: customerOn,
            config: _config(),
            chosenCurrency: _saudiRiyal);

        for (final MapEntry<String, String> order in _twelveAndAHalf.entries) {
          expect(
              PriceConverter.convertOrderPrice(context, 12.5,
                  market: _orderOf(order.key)),
              order.value,
              reason:
                  'an order of ${order.key} read by a customer on $customerOn');
        }
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'the dinar and the rial have three decimals and the others two, with a thousands separator',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      final Map<String, String> written = <String, String>{
        for (final String country in _twelveAndAHalf.keys)
          country: PriceConverter.convertOrderPrice(context, 1234.5,
              market: _orderOf(country)),
      };

      expect(written, <String, String>{
        'AE': 'AED 1,234.50',
        'KW': 'KD 1,234.500',
        'QA': 'QAR 1,234.50',
        'BH': 'BHD 1,234.500',
        'OM': 'OMR 1,234.500',
      });
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'a missing amount is written as zero with its currency, and a negative one keeps its sign',
        (WidgetTester tester) async {
      final BuildContext context =
          await _contextOn(tester, storefrontCode: 'SA', config: _config());

      expect(
          PriceConverter.convertOrderPrice(context, null,
              market: _orderOf('KW')),
          'KD 0.000');
      expect(
          PriceConverter.convertOrderPrice(context, -2.5,
              market: _orderOf('AE')),
          'AED -2.50');
    }, skip: !StorefrontConfig.enabled);

    testWidgets('the mark of the currency is on the side the config says',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(position: 'right'));

      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: _orderOf('AE')),
          '12.50 AED');
      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: _orderOf('KW')),
          '12.500 KD');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'the code stands in for a mark the server did not send, and before the config has arrived',
        (WidgetTester tester) async {
      final BuildContext withoutConfig =
          await _contextOn(tester, storefrontCode: 'SA', config: null);

      expect(
          PriceConverter.convertOrderPrice(withoutConfig, 12.5,
              market: _orderOf('KW')),
          'KWD 12.500');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an amount is never multiplied by the rate of the currency list, nor by the rate of the order',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      // The list has the dinar at 0.307 and the riyal at 3.75: neither is applied to the stored amount.
      expect(
          PriceConverter.convertOrderPrice(context, 100,
              market: _orderOf('KW')),
          'KD 100.000');
      expect(
          PriceConverter.convertOrderPrice(context, 100,
              market: _orderOf('AE')),
          'AED 100.00');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order whose rate is not one is written as before, never in its currency and never multiplied',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      for (final double rate in <double>[0.307, 3.75]) {
        expect(
            PriceConverter.convertOrderPrice(context, 12.5,
                market: _orderOf('KW', rate: rate)),
            '13',
            reason: 'a rate of $rate');
      }
      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: const OrderMarket(country: 'KW', currencyCode: 'KWD')),
          '13');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order of the default storefront is written as before, in the way of the platform and not in riyals with two decimals',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: _orderOf('SA')),
          '13');
      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: const OrderMarket(country: 'SA')),
          '13');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order that says nothing of what it was sold in is written exactly as convertPrice writes it',
        (WidgetTester tester) async {
      const List<OrderMarket?> sayingNothing = <OrderMarket?>[
        null,
        OrderMarket(),
        OrderMarket(currencyCode: 'KWD', currencyRate: 1),
        OrderMarket(country: 'KW'),
      ];

      final BuildContext onTheDefault = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);
      for (final OrderMarket? market in sayingNothing) {
        expect(
            PriceConverter.convertOrderPrice(onTheDefault, 12.5,
                market: market),
            PriceConverter.convertPrice(onTheDefault, 12.5));
      }
      expect(PriceConverter.convertOrderPrice(onTheDefault, 12.5, market: null),
          '13');

      final BuildContext onKuwait = await _contextOn(tester,
          storefrontCode: 'KW', config: _config(), chosenCurrency: _saudiRiyal);
      for (final OrderMarket? market in sayingNothing) {
        expect(PriceConverter.convertOrderPrice(onKuwait, 12.5, market: market),
            PriceConverter.convertPrice(onKuwait, 12.5));
      }
    }, skip: !StorefrontConfig.enabled);
  });
}
