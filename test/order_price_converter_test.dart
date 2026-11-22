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

/// The three the platform needs to write an amount: the list, the currency the customer chose and the dollar it converts through. The controller
/// reads the last one from the list when the config arrives, which no test can make it do, so the fake answers all three.
class _SplashWithConfig extends SplashController {
  _SplashWithConfig(this._config, this._chosenCurrency)
      : super(splashServiceInterface: null);

  final ConfigModel? _config;
  final CurrencyList? _chosenCurrency;

  @override
  ConfigModel? get configModel => _config;

  @override
  CurrencyList? get myCurrency => _chosenCurrency;

  @override
  CurrencyList? get usdCurrency => _chosenCurrency == null ? null : _usDollar;
}

/// The currency the customer chose in the settings: a platform currency, which the money of an order never follows.
final CurrencyList _saudiRiyal =
    CurrencyList(id: 1, code: 'SAR', symbol: 'SR', exchangeRate: 3.75);

/// The currency the platform converts through, as the controller takes it from the list of the server.
final CurrencyList _usDollar =
    CurrencyList(id: 9, code: 'USD', symbol: '\$', exchangeRate: 1);

/// 12.5 as the platform writes it when the customer chose the riyal: the rate of the riyal in the list of the server over the rate of the
/// dollar, with the mark of the chosen currency and no decimals (12.5 x 3.75 / 1 = 46.875).
const String _twelveAndAHalfThePlatformWay = 'SR47';

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
/// currency, whatever storefront the customer is on and whatever currency they chose in the settings, and such an amount is never multiplied by
/// a rate. Storefronts are a build flag (`--dart-define=GCC_STOREFRONTS_ENABLED=true`), so the groups that write an order in its own currency
/// run only in a build that has it on, and the group that says nothing changes without it runs only in the default build.
///
/// An order of the default storefront keeps the platform's money for a customer who is on that storefront, as every price of it does. An order
/// that says nothing of what it was sold in, and one whose rate is not one, are orders whose amounts the app cannot read, and it does not guess
/// them: they are written the way the platform writes an amount, which does multiply by the rate of the currency the customer chose. The first
/// group pins that way of writing on its own, so that the amount the customer reads for such an order is an amount a test has looked at.
///
///   flutter test test/order_price_converter_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/order_price_converter_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the way the platform writes an amount', () {
    testWidgets(
        'is the amount at the rate of the currency the customer chose, over the rate of the dollar, with no decimals',
        (WidgetTester tester) async {
      final BuildContext onTheDefault = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      // The riyal is 3.75 in the list of the server and the dollar is 1: 12.5 x 3.75 / 1 = 46.875, and 1234.5 x 3.75 = 4629.375.
      expect(PriceConverter.convertPrice(onTheDefault, 12.5), 'SR47');
      expect(PriceConverter.convertPrice(onTheDefault, 1234.5), 'SR4,629');
    });

    testWidgets(
        'is what an order whose amounts the app cannot read is written as, on a storefront with its own currency',
        (WidgetTester tester) async {
      final BuildContext onKuwait = await _contextOn(tester,
          storefrontCode: 'KW', config: _config(), chosenCurrency: _saudiRiyal);

      expect(
          PriceConverter.convertOrderPrice(onKuwait, 12.5,
              market: const OrderMarket(country: 'AE')),
          'SR47');
      expect(
          PriceConverter.convertOrderPrice(onKuwait, 1234.5,
              market: const OrderMarket(country: 'AE')),
          'SR4,629');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'is a bare number until the config and the currency the customer chose have arrived',
        (WidgetTester tester) async {
      final BuildContext withoutConfig =
          await _contextOn(tester, storefrontCode: 'SA', config: null);
      final BuildContext withoutACurrency = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: null);

      expect(PriceConverter.convertPrice(withoutConfig, 12.5), '13');
      expect(PriceConverter.convertPrice(withoutACurrency, 12.5), '13');
    });
  });

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
            _twelveAndAHalfThePlatformWay,
            reason: country);
      }
    }, skip: StorefrontConfig.enabled);

    testWidgets(
        'an order of one storefront read on another is written as the app has always written an amount',
        (WidgetTester tester) async {
      for (final String customerOn in _currencyOf.keys) {
        final BuildContext context = await _contextOn(tester,
            storefrontCode: customerOn,
            config: _config(),
            chosenCurrency: _saudiRiyal);

        for (final String country in _currencyOf.keys) {
          expect(
              PriceConverter.convertOrderPrice(context, 12.5,
                  market: _orderOf(country)),
              PriceConverter.convertPrice(context, 12.5),
              reason: 'an order of $country read by a customer on $customerOn');
        }
      }
    }, skip: StorefrontConfig.enabled);

    testWidgets(
        'and it is what convertPrice writes, for a whole amount, a missing amount and an order with no record, before the config has arrived',
        (WidgetTester tester) async {
      // No config and no currency chosen: the platform writes the bare number, as it does on a device whose config has not arrived.
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
        'an order whose rate is not one is written the way the platform writes an amount, never in its currency, on every storefront',
        (WidgetTester tester) async {
      // Its amounts are not the number they are stored as in the currency it names, so they are written as the app wrote every amount before
      // storefronts: the currency the customer chose, at the rate of the list. On the storefront the order itself names too, which is the one
      // storefront where the money the app would otherwise fall back to is the currency of the order.
      for (final String customerOn in _currencyOf.keys) {
        final BuildContext context = await _contextOn(tester,
            storefrontCode: customerOn,
            config: _config(),
            chosenCurrency: _saudiRiyal);

        for (final double rate in <double>[0.307, 3.75]) {
          expect(
              PriceConverter.convertOrderPrice(context, 12.5,
                  market: _orderOf('KW', rate: rate)),
              _twelveAndAHalfThePlatformWay,
              reason: 'a rate of $rate read by a customer on $customerOn');
        }
      }

      final BuildContext onTheDefault = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      // An order that records a currency but no rate records nothing the app can read, and is written as an order that says nothing is.
      expect(
          PriceConverter.convertOrderPrice(onTheDefault, 12.5,
              market: const OrderMarket(country: 'KW', currencyCode: 'KWD')),
          _twelveAndAHalfThePlatformWay);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order of the default storefront is written for a customer on it exactly as the platform writes every amount of that storefront',
        (WidgetTester tester) async {
      final BuildContext context = await _contextOn(tester,
          storefrontCode: 'SA', config: _config(), chosenCurrency: _saudiRiyal);

      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: _orderOf('SA')),
          _twelveAndAHalfThePlatformWay);
      expect(
          PriceConverter.convertOrderPrice(context, 12.5,
              market: const OrderMarket(country: 'SA')),
          PriceConverter.convertPrice(context, 12.5));
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order of the default storefront is written in the riyals it records, and never in the money of the storefront the customer is on',
        (WidgetTester tester) async {
      for (final String customerOn in _twelveAndAHalf.keys) {
        final BuildContext context = await _contextOn(tester,
            storefrontCode: customerOn,
            config: _config(),
            chosenCurrency: _saudiRiyal);

        expect(
            PriceConverter.convertOrderPrice(context, 12.5,
                market: _orderOf('SA')),
            'SR 12.50',
            reason:
                'the riyals of a Saudi order read by a customer on $customerOn');
        expect(
            PriceConverter.convertOrderPrice(context, 12.5,
                market: const OrderMarket(country: 'SA')),
            _twelveAndAHalfThePlatformWay,
            reason: 'a Saudi order that names no currency, on $customerOn');
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order of another storefront whose currency the server could not vouch for is not written in the money of the storefront the customer is on',
        (WidgetTester tester) async {
      final BuildContext onKuwait = await _contextOn(tester,
          storefrontCode: 'KW', config: _config(), chosenCurrency: _saudiRiyal);

      // The dirhams of an order of a storefront whose currency was not active, and those of one whose rate the server did not record as one.
      expect(
          PriceConverter.convertOrderPrice(onKuwait, 12.5,
              market: const OrderMarket(country: 'AE')),
          _twelveAndAHalfThePlatformWay);
      expect(
          PriceConverter.convertOrderPrice(onKuwait, 12.5,
              market: _orderOf('AE', rate: 3.67)),
          _twelveAndAHalfThePlatformWay);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'an order of the storefront the customer is on keeps the money of that storefront when its currency is not recorded',
        (WidgetTester tester) async {
      final BuildContext onKuwait = await _contextOn(tester,
          storefrontCode: 'KW', config: _config(), chosenCurrency: _saudiRiyal);

      expect(
          PriceConverter.convertOrderPrice(onKuwait, 12.5,
              market: const OrderMarket(country: 'KW')),
          'KD 12.500');
      expect(
          PriceConverter.convertOrderPrice(onKuwait, 12.5, market: null),
          PriceConverter.convertPrice(onKuwait, 12.5));
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
          _twelveAndAHalfThePlatformWay);

      final BuildContext onKuwait = await _contextOn(tester,
          storefrontCode: 'KW', config: _config(), chosenCurrency: _saudiRiyal);
      for (final OrderMarket? market in sayingNothing) {
        expect(PriceConverter.convertOrderPrice(onKuwait, 12.5, market: market),
            PriceConverter.convertPrice(onKuwait, 12.5));
      }
    }, skip: !StorefrontConfig.enabled);
  });
}
