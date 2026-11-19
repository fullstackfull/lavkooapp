import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/home/widgets/aster_theme/order_again_list_view_widget.dart';
import 'package:syriapharmacy/features/order/controllers/order_controller.dart';
import 'package:syriapharmacy/features/order/domain/models/order_model.dart';
import 'package:syriapharmacy/features/order/domain/services/order_service_interface.dart';
import 'package:syriapharmacy/features/order/widgets/order_widget.dart';
import 'package:syriapharmacy/features/order_details/controllers/order_details_controller.dart';
import 'package:syriapharmacy/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:syriapharmacy/features/order_details/widgets/order_amount_calculation.dart';
import 'package:syriapharmacy/features/order_details/widgets/order_details_widget.dart';
import 'package:syriapharmacy/features/reorder/controllers/re_order_controller.dart';
import 'package:syriapharmacy/features/reorder/domain/services/re_order_service_interface.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

Map<String, dynamic> _languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

class _FileLocalization extends AppLocalization {
  _FileLocalization(super.locale)
      : _values = _languageFile(locale.languageCode);

  final Map<String, dynamic> _values;

  @override
  String? translate(String? key) => _values[key] as String?;
}

class _FileLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _FileLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalization> load(Locale locale) =>
      SynchronousFuture<AppLocalization>(_FileLocalization(locale));

  @override
  bool shouldReload(_FileLocalizationsDelegate old) => false;
}

class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

class _SplashWithConfig extends SplashController {
  _SplashWithConfig(this._config) : super(splashServiceInterface: null);

  final ConfigModel _config;

  @override
  ConfigModel? get configModel => _config;
}

/// The two answers the details screen asks the server for: the lines of an order and the order itself, as the controller reads them.
class _OrderAnswers implements OrderDetailsServiceInterface {
  _OrderAnswers({required this.lines, required this.order});

  final List<Map<String, dynamic>> lines;
  final Map<String, dynamic> order;

  Future<ApiResponseModel<Response<dynamic>>> _answered(Object? data) async =>
      ApiResponseModel<Response<dynamic>>.withSuccess(Response<dynamic>(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
          data: data));

  @override
  Future<dynamic> getOrderDetails(String orderID) => _answered(lines);

  @override
  Future<dynamic> getOrderFromOrderId(String orderID) => _answered(order);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _NoOrderServer implements OrderServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _NoReOrderServer implements ReOrderServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// The server's currency list. The Qatari riyal and the Bahraini dinar are left out, so that the code stands in for their mark.
ConfigModel _config() => ConfigModel(
      currencySymbolPosition: 'left',
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

const Map<String, String> _nameInEnglish = <String, String>{
  'SA': 'Saudi Arabia',
  'AE': 'United Arab Emirates',
  'KW': 'Kuwait',
  'QA': 'Qatar',
  'BH': 'Bahrain',
  'OM': 'Oman',
};

/// 12.5 as each storefront with its own currency writes it, by hand.
const Map<String, String> _twelveAndAHalf = <String, String>{
  'AE': 'AED 12.50',
  'KW': 'KD 12.500',
  'QA': 'QAR 12.50',
  'BH': 'BHD 12.500',
  'OM': 'OMR 12.500',
};

Map<String, dynamic> _snapshot(String country) => <String, dynamic>{
      'storefront_country': country,
      'currency_code': _currencyOf[country],
      'currency_rate': '1.00000000',
    };

/// An order as the server answers it, with the amounts of the tests below: 12.5 of products, 1.25 of shipping, 0.75 of coupon.
Map<String, dynamic> _order(
        {Map<String, dynamic> snapshot = const {},
        Map<String, dynamic> more = const {}}) =>
    <String, dynamic>{
      'id': 4217,
      'seller_is': 'admin',
      'order_status': 'pending',
      'payment_status': 'unpaid',
      'created_at': '2026-11-12T10:32:00.000000Z',
      'order_amount': 12.5,
      'discount_amount': 0.75,
      'shipping_cost': 1.25,
      'extra_discount': 0,
      'order_type': 'default_type',
      'order_details_count': 3,
      ...snapshot,
      ...more,
    };

Map<String, dynamic> _line({
  Map<String, dynamic> snapshot = const {},
  Map<String, dynamic>? editHistory,
}) =>
    <String, dynamic>{
      'id': 9001,
      'order_id': 4217,
      'qty': 2,
      'price': 6.25,
      'tax': 0,
      'discount': 0.5,
      'order': <String, dynamic>{
        'is_shipping_free': false,
        'order_status': 'pending',
        ...snapshot,
      },
      'product_details': <String, dynamic>{
        'id': 31,
        'name': 'Vitamin C',
        'slug': 'vitamin-c',
        'product_type': 'physical',
        'thumbnail_full_url': <String, dynamic>{
          'key': 'p.png',
          'path': 'p.png',
          'status': 404,
        },
      },
      if (editHistory != null) 'latest_edit_history': editHistory,
    };

Future<OrderDetailsController> _controllerOf({
  required Map<String, dynamic> order,
  Map<String, dynamic>? line,
}) async {
  final OrderDetailsController controller = OrderDetailsController(
      orderDetailsServiceInterface: _OrderAnswers(
          lines: <Map<String, dynamic>>[line ?? _line()], order: order));
  await controller.getOrderDetails('4217');
  await controller.getOrderFromOrderId('4217');

  return controller;
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  String customerOn = 'SA',
  Locale locale = const Locale('en'),
  List<SingleChildWidget> providers = const <SingleChildWidget>[],
}) async {
  SharedPreferences.setMockInitialValues(
      <String, Object>{AppConstants.storefrontCountry: customerOn});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final StorefrontController storefronts = StorefrontController(
    storefrontServiceInterface: _NoServer(),
    storefrontChoice: StorefrontChoice(preferences, enabled: true),
  );
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<StorefrontController>.value(value: storefronts),
        ChangeNotifierProvider<SplashController>.value(
            value: _SplashWithConfig(_config())),
        ...providers,
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _FileLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// J-13 criterion 1, the screens: the list item of an order, the billing summary and the lines of its details, and the "order again" card
/// write the amounts of an order in the currency the order was sold in, and show the country it was sold in, in a build with storefronts on;
/// and write everything as they always did, with no country, in a build without them or for an order that says nothing. The orders are the
/// answers of the server written by hand (see order_market_test.dart), read through the models and the controller of the screens, so what
/// is on the screen is what the server's keys became.
///
/// What this does not cover: the screens were not run on a device, so how a country line sits in the card is not looked at (it is one line of
/// the style of the date above it), and the amounts of an order the screens write by another route are listed, with why, by
/// order_amounts_inventory_test.dart.
///
///   flutter test test/order_screens_currency_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/order_screens_currency_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the list item of an order', () {
    Widget itemOf(Map<String, dynamic> order) =>
        OrderWidget(orderModel: Orders.fromJson(order));

    testWidgets(
        'writes its amount in the currency of the order and says the country it was sold in, for each storefront with its own currency',
        (WidgetTester tester) async {
      for (final String customerOn in _currencyOf.keys) {
        for (final MapEntry<String, String> storefront
            in _twelveAndAHalf.entries) {
          await _pump(tester,
              customerOn: customerOn,
              child: itemOf(_order(snapshot: _snapshot(storefront.key))));

          expect(find.text(storefront.value), findsOneWidget,
              reason:
                  'the amount of an order of ${storefront.key} on the screen of a customer on $customerOn');
          expect(find.text(_nameInEnglish[storefront.key]!), findsOneWidget,
              reason: storefront.key);
        }
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets('says the country in Arabic when the app is in Arabic',
        (WidgetTester tester) async {
      await _pump(tester,
          locale: const Locale('ar'),
          child: itemOf(_order(snapshot: _snapshot('KW'))));

      expect(find.text('KD 12.500'), findsOneWidget);
      expect(find.text('الكويت'), findsOneWidget);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'says the country of an order of the default storefront and writes its amount as before',
        (WidgetTester tester) async {
      await _pump(tester, child: itemOf(_order(snapshot: _snapshot('SA'))));

      expect(find.text('Saudi Arabia'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'says no country and writes its amount as before for an order that says nothing of what it was sold in',
        (WidgetTester tester) async {
      await _pump(tester, child: itemOf(_order()));

      expect(find.text('13'), findsOneWidget);
      for (final String name in _nameInEnglish.values) {
        expect(find.text(name), findsNothing, reason: name);
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'says no country and writes its amount as the app always has with storefronts off, whatever the order says',
        (WidgetTester tester) async {
      for (final String country in _currencyOf.keys) {
        await _pump(tester,
            customerOn: country,
            child: itemOf(_order(snapshot: _snapshot(country))));

        expect(find.text('13'), findsOneWidget, reason: country);
        expect(find.text('Order #4217'), findsOneWidget, reason: country);
        for (final String name in _nameInEnglish.values) {
          expect(find.text(name), findsNothing, reason: '$name on $country');
        }
      }
    }, skip: StorefrontConfig.enabled);

    testWidgets(
        'writes the amount of a POS order, which it works out from its lines, in the currency of the order',
        (WidgetTester tester) async {
      final Map<String, dynamic> pos = _order(snapshot: _snapshot('KW'), more: {
        'order_type': 'POS',
        'extra_discount': 0.5,
        'extra_discount_type': 'amount',
        'total_tax_amount': 0.625,
        'details': <Map<String, dynamic>>[
          <String, dynamic>{'qty': 2, 'price': 6.25, 'tax': 0, 'discount': 0.5},
        ],
      });

      await _pump(tester, child: itemOf(pos));

      // 2 x 6.25 + 0.625 of tax - 0.5 of discount + 1.25 of shipping - 0.75 of coupon - 0.5 of extra discount
      expect(find.text('KD 12.625'), findsOneWidget);
    }, skip: !StorefrontConfig.enabled);
  });

  group('the billing summary of an order', () {
    Future<void> pumpSummary(
      WidgetTester tester, {
      required OrderDetailsController controller,
      double eeDiscount = 0,
      double shipping = 1.25,
      double tax = 0.625,
    }) =>
        _pump(tester,
            child: OrderAmountCalculation(
              itemTotalAmount: 12.5,
              discount: 0.5,
              eeDiscount: eeDiscount,
              tax: tax,
              shippingCost: shipping,
              referAndEarnDiscount: 0,
              orderProvider: controller,
            ));

    testWidgets(
        'writes every amount in the currency of the order, with its decimals, and says the country first',
        (WidgetTester tester) async {
      final OrderDetailsController controller =
          await _controllerOf(order: _order(snapshot: _snapshot('KW')));

      await pumpSummary(tester, controller: controller);

      expect(find.text('Country'), findsOneWidget);
      expect(find.text('Kuwait'), findsOneWidget);
      expect(find.text('KD 12.500'), findsOneWidget, reason: 'sub total');
      expect(find.text('KD 1.250'), findsOneWidget, reason: 'shipping fee');
      expect(find.text('KD 0.500'), findsOneWidget, reason: 'discount');
      expect(find.text('KD 0.750'), findsOneWidget, reason: 'coupon');
      expect(find.text('KD 0.625'), findsOneWidget, reason: 'tax');
      expect(find.text('KD 13.125'), findsOneWidget, reason: 'total payable');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes the amounts of an order of each storefront with its own currency in that currency, on the screen of a customer on another',
        (WidgetTester tester) async {
      for (final String country in _twelveAndAHalf.keys) {
        final OrderDetailsController controller =
            await _controllerOf(order: _order(snapshot: _snapshot(country)));

        await _pump(tester,
            customerOn: country == 'KW' ? 'OM' : 'KW',
            child: OrderAmountCalculation(
              itemTotalAmount: 12.5,
              discount: 0,
              eeDiscount: 0,
              tax: 0,
              shippingCost: 0,
              referAndEarnDiscount: 0,
              orderProvider: controller,
            ));

        expect(find.text(_twelveAndAHalf[country]!), findsWidgets,
            reason: 'the sub total of an order of $country');
        expect(find.text(_nameInEnglish[country]!), findsOneWidget,
            reason: country);
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes what is due on an edited order, and what is to be returned, in the currency of the order',
        (WidgetTester tester) async {
      final OrderDetailsController due = await _controllerOf(
        order: _order(snapshot: _snapshot('KW')),
        line: _line(snapshot: _snapshot('KW'), editHistory: <String, dynamic>{
          'id': 1,
          'order_id': 4217,
          'order_due_amount': 2.5,
          'order_due_payment_status': 'unpaid',
          'order_return_amount': 0,
        }),
      );
      await pumpSummary(tester, controller: due);

      expect(find.text('KD 2.500'), findsOneWidget, reason: 'due');
      expect(find.text('KD 10.625'), findsOneWidget, reason: 'paid');

      final OrderDetailsController returned = await _controllerOf(
        order: _order(snapshot: _snapshot('KW')),
        line: _line(snapshot: _snapshot('KW'), editHistory: <String, dynamic>{
          'id': 2,
          'order_id': 4217,
          'order_due_amount': 0,
          'order_return_amount': 1.5,
          'order_return_payment_status': 'pending',
        }),
      );
      await pumpSummary(tester, controller: returned);

      expect(find.text('KD 14.625'), findsOneWidget, reason: 'paid');
      expect(find.text('KD 1.500'), findsOneWidget, reason: 'to return');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes what a POS customer paid, and the change, in the currency of the order, and no shipping fee',
        (WidgetTester tester) async {
      final OrderDetailsController controller = await _controllerOf(
          order: _order(snapshot: _snapshot('KW'), more: {
        'order_type': 'POS',
        'extra_discount': 0.5,
        'extra_discount_type': 'amount',
        'paid_amount': 20,
      }));

      await pumpSummary(
        tester,
        controller: controller,
        eeDiscount: 0.5,
        shipping: 0,
        tax: 0,
      );

      expect(find.text('KD 20.000'), findsOneWidget, reason: 'paid amount');
      expect(find.text('KD 0.500'), findsNWidgets(2),
          reason: 'discount and extra discount');
      // 12.5 - 0.5 of extra discount - 0.75 of coupon - 0.5 of discount = 10.75 payable, so 9.25 of change
      expect(find.text('KD 10.750'), findsOneWidget, reason: 'total payable');
      expect(find.text('KD 9.250'), findsOneWidget, reason: 'change');
      expect(find.text('Shipping fee'), findsNothing);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes an order of the default storefront as before, with its country, and an order that says nothing as before, with none',
        (WidgetTester tester) async {
      final OrderDetailsController saudi =
          await _controllerOf(order: _order(snapshot: _snapshot('SA')));
      await pumpSummary(tester, controller: saudi);

      expect(find.text('Saudi Arabia'), findsOneWidget);
      expect(find.text('13'), findsNWidgets(2), reason: 'sub total and total');

      final OrderDetailsController before =
          await _controllerOf(order: _order());
      await pumpSummary(tester, controller: before);

      expect(find.text('Country'), findsNothing);
      expect(find.text('13'), findsNWidgets(2), reason: 'sub total and total');
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes every amount as the app always has and says no country with storefronts off, whatever the order says',
        (WidgetTester tester) async {
      for (final String country in _currencyOf.keys) {
        final OrderDetailsController controller =
            await _controllerOf(order: _order(snapshot: _snapshot(country)));

        await pumpSummary(tester, controller: controller);

        expect(find.text('Country'), findsNothing, reason: country);
        expect(find.text('13'), findsNWidgets(2),
            reason: 'sub total and total on $country');
        for (final String name in _nameInEnglish.values) {
          expect(find.text(name), findsNothing, reason: '$name on $country');
        }
      }
    }, skip: StorefrontConfig.enabled);
  });

  group('a line of the details of an order', () {
    Future<Widget> lineOf(Map<String, dynamic> snapshot) async {
      final OrderDetailsController controller = await _controllerOf(
          order: _order(snapshot: snapshot), line: _line(snapshot: snapshot));

      return OrderDetailsWidget(
        orderDetailsModel: controller.orderDetails!.first,
        callback: () {},
        orderType: 'default_type',
        paymentStatus: 'unpaid',
        orderId: '4217',
        index: 0,
      );
    }

    Future<void> pumpLine(
        WidgetTester tester, Map<String, dynamic> snapshot) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await _pump(tester,
          child: await lineOf(snapshot),
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<LocalizationController>.value(
                value: LocalizationController(
                    sharedPreferences: preferences, dioClient: null)),
            ChangeNotifierProvider<OrderController>.value(
                value:
                    OrderController(orderServiceInterface: _NoOrderServer())),
          ]);
    }

    testWidgets(
        'writes its price in the currency of the order, for each storefront with its own currency',
        (WidgetTester tester) async {
      for (final MapEntry<String, String> storefront in <String, String>{
        'AE': 'AED 6.25',
        'KW': 'KD 6.250',
        'QA': 'QAR 6.25',
        'BH': 'BHD 6.250',
        'OM': 'OMR 6.250',
      }.entries) {
        await pumpLine(tester, _snapshot(storefront.key));

        expect(find.text(storefront.value), findsOneWidget,
            reason: storefront.key);
      }
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes its price as before for an order that says nothing of what it was sold in',
        (WidgetTester tester) async {
      await pumpLine(tester, <String, dynamic>{});

      expect(find.text('6'), findsOneWidget);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes its price as the app always has with storefronts off, whatever the order says',
        (WidgetTester tester) async {
      await pumpLine(tester, _snapshot('KW'));

      expect(find.text('6'), findsOneWidget);
    }, skip: StorefrontConfig.enabled);
  });

  group('the order again card', () {
    Future<void> pumpCard(
        WidgetTester tester, Map<String, dynamic> order) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await _pump(tester,
          child: OrderAgainCard(orders: Orders.fromJson(order)),
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<ReOrderController>.value(
                value: ReOrderController(
                    reOrderServiceInterface: _NoReOrderServer())),
            ChangeNotifierProvider<ThemeController>.value(
                value: ThemeController(sharedPreferences: preferences)),
          ]);
    }

    testWidgets('writes the total of an order in the currency of the order',
        (WidgetTester tester) async {
      await pumpCard(tester, _order(snapshot: _snapshot('KW')));

      expect(find.textContaining('KD 12.500'), findsOneWidget);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes the total of an order that says nothing of what it was sold in as before',
        (WidgetTester tester) async {
      await pumpCard(tester, _order());

      expect(find.textContaining(': 13'), findsOneWidget);
    }, skip: !StorefrontConfig.enabled);

    testWidgets(
        'writes the total of an order as the app always has with storefronts off, whatever the order says',
        (WidgetTester tester) async {
      await pumpCard(tester, _order(snapshot: _snapshot('KW')));

      expect(find.textContaining(': 13'), findsOneWidget);
    }, skip: StorefrontConfig.enabled);
  });
}
