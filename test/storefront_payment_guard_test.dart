import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/features/wallet/controllers/wallet_controller.dart';
import 'package:syriapharmacy/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/main.dart' show navigatorKey;
import 'package:syriapharmacy/utill/app_constants.dart';

Map<String, dynamic> _languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

/// The app's translations, read straight from the language files and handed over at once, so what a controller says is in the real words.
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

/// Records every request a controller makes, by the name of the service method, and answers each with a failure that is not an order, so a
/// request that is made is told apart from one that is not. Nothing is faked but the answer: the controllers are the app's own.
class _Requests {
  final List<Symbol> made = <Symbol>[];

  Future<dynamic> failed(Invocation invocation) {
    made.add(invocation.memberName);

    return Future<dynamic>.value(
        ApiResponseModel<dynamic>.withError('no answer', unanswered: true));
  }
}

class _RecordingCheckoutService extends _Requests
    implements CheckoutServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => failed(invocation);
}

class _RecordingWalletService extends _Requests
    implements WalletServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => failed(invocation);
}

class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

class _SplashWithoutCurrency extends SplashController {
  _SplashWithoutCurrency() : super(splashServiceInterface: null);
}

/// The Emirates, once the server has opened them for sales.
const StorefrontCountry _openedEmirates = StorefrontCountry(
  code: 'AE',
  path: '/ae',
  currency: 'AED',
  sellable: true,
);

class _Harness {
  _Harness._({
    required this.checkoutService,
    required this.walletService,
    required this.checkout,
    required this.wallet,
  });

  factory _Harness() {
    final _RecordingCheckoutService checkoutService =
        _RecordingCheckoutService();
    final _RecordingWalletService walletService = _RecordingWalletService();

    return _Harness._(
      checkoutService: checkoutService,
      walletService: walletService,
      checkout: CheckoutController(checkoutServiceInterface: checkoutService),
      wallet: WalletController(walletServiceInterface: walletService),
    );
  }

  final _RecordingCheckoutService checkoutService;
  final _RecordingWalletService walletService;
  final CheckoutController checkout;
  final WalletController wallet;

  /// What the controller gave the screen's callback when an order was asked for: whether it was placed, the message, the order ids, whether
  /// the customer is new.
  final List<List<Object?>> orderAnswers = <List<Object?>>[];

  List<Symbol> get requests => <Symbol>[
        ...checkoutService.made,
        ...walletService.made,
      ];

  Future<void> placeOrder({bool isOffline = false, bool byWallet = false}) =>
      checkout.placeOrder(
        callback:
            (bool placed, String message, String orderIds, bool newUser) =>
                orderAnswers.add(<Object?>[placed, message, orderIds, newUser]),
        addressID: '12',
        isfOffline: isOffline,
        wallet: byWallet,
      );
}

/// The storefront the customer chose, and the list the server last answered with.
typedef _Storefront = ({String? chosen, List<StorefrontCountry>? listed});

/// One way a customer starts an order, a payment or a top-up, and the request it makes when nothing stops it.
typedef _Path = ({
  String name,
  Symbol request,
  Future<void> Function(_Harness harness) start,
});

final List<_Path> _orderPaths = <_Path>[
  (
    name: 'cash on delivery',
    request: #cashOnDeliveryPlaceOrder,
    start: (_Harness harness) => harness.placeOrder(),
  ),
  (
    name: 'offline payment',
    request: #offlinePaymentPlaceOrder,
    start: (_Harness harness) => harness.placeOrder(isOffline: true),
  ),
  (
    name: 'wallet payment',
    request: #walletPaymentPlaceOrder,
    start: (_Harness harness) => harness.placeOrder(byWallet: true),
  ),
];

final List<_Path> _paymentPaths = <_Path>[
  (
    name: 'digital payment',
    request: #digitalPaymentPlaceOrder,
    start: (_Harness harness) => harness.checkout.digitalPaymentPlaceOrder(
        customerId: '7', addressId: '12', paymentMethod: 'gateway'),
  ),
  (
    name: 'wallet top-up',
    request: #addFundToWallet,
    start: (_Harness harness) =>
        harness.wallet.addFundToWallet('100', 'gateway'),
  ),
];

/// The customer is on [chosen], which the server has [listed] as it has, and the app is a MaterialApp with the global navigator key, which is
/// what the controllers find their context by.
Future<_Harness> _open(WidgetTester tester,
    {String? chosen, List<StorefrontCountry>? listed}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (chosen != null) AppConstants.storefrontCountry: chosen,
  });
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  if (listed != null) {
    await StoredStorefronts(preferences).save(listed);
  }

  final _Harness harness = _Harness();
  addTearDown(harness.checkout.dispose);
  addTearDown(harness.wallet.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorefrontController>.value(
          value: StorefrontController(
            storefrontServiceInterface: _NoServer(),
            storefrontChoice: StorefrontChoice(preferences, enabled: true),
          ),
        ),
        ChangeNotifierProvider<SplashController>.value(
            value: _SplashWithoutCurrency()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _FileLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const Scaffold(),
      ),
    ),
  );

  return harness;
}

/// J-09 criterion 1: no payment and no top-up request leaves the app on a storefront that may not sell. The guards are in the controllers that
/// start one, so these tests start each of them by hand, on a storefront that is browse-only, and look at what the service was asked: nothing,
/// and the controller answers as its guard says, with the notice. The same controllers on a storefront that may sell make their request, so
/// it is the guard that stopped it and nothing else. I2-13 criterion 1 is the same guard and the same notice.
///
/// A storefront is browse-only only in a build with storefronts on (the flag is a compile-time constant), so the groups that need the guard
/// run in that build and the group that says what a build without it does runs in the other:
///
///   flutter test test/storefront_payment_guard_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/storefront_payment_guard_test.dart
///
/// The paths started here are the cash on delivery, the offline and the wallet orders (`CheckoutController.placeOrder`), the digital payment
/// (`CheckoutController.digitalPaymentPlaceOrder`) and the wallet top-up (`WalletController.addFundToWallet`). The payment of what is still due
/// on an order the customer already has (`OrderDetailsController.duePayment*`) has no such guard, and is not started here.
///
/// I2-10 criterion 5 says the cart and the checkout screens show the notice and switch Proceed off. The screens are not built here (they
/// need the providers of the whole app), so the last group is structural only: it pins the lines of the two screens that read the gate while
/// listening, show the notice and switch the button off, as the dashboard's maintenance screen is pinned.
void main() {
  final String notice =
      _languageFile('en')['storefront_browse_only_notice'] as String;

  test('the notice is words, not the key', () {
    expect(notice, isNot('storefront_browse_only_notice'));
    expect(notice.length, greaterThan(20));
  });

  group('on a storefront that is browse-only', () {
    testWidgets(
        'a digital payment is not started, and the controller answers with the notice',
        (WidgetTester tester) async {
      final _Harness harness = await _open(tester, chosen: 'AE');

      final ApiResponseModel answer = await harness.checkout
          .digitalPaymentPlaceOrder(
              customerId: '7', addressId: '12', paymentMethod: 'gateway');
      await tester.pump();

      expect(harness.requests, isEmpty);
      expect(answer.error, notice);
      expect(answer.response, isNull);
      expect(answer.isSuccess, isFalse);
      expect(harness.checkout.isLoading, isFalse);
      expect(find.text(notice), findsOneWidget);
    });

    for (final _Path path in _orderPaths) {
      testWidgets(
          'an order by ${path.name} is not placed, and the screen is told the notice',
          (WidgetTester tester) async {
        final _Harness harness = await _open(tester, chosen: 'AE');

        await path.start(harness);

        expect(harness.requests, isEmpty);
        expect(harness.orderAnswers, <List<Object?>>[
          <Object?>[false, notice, '', false],
        ]);
        expect(harness.checkout.isLoading, isFalse);
      });
    }

    testWidgets(
        'a top-up of the wallet is not started, and the customer is shown the notice',
        (WidgetTester tester) async {
      final _Harness harness = await _open(tester, chosen: 'AE');

      await harness.wallet.addFundToWallet('100', 'gateway');
      await tester.pump();

      expect(harness.requests, isEmpty);
      expect(harness.wallet.isConvert, isFalse);
      expect(find.text(notice), findsOneWidget);
    });

    testWidgets(
        'Saudi Arabia is browse-only too while the server lists it as not sellable',
        (WidgetTester tester) async {
      final _Harness harness =
          await _open(tester, chosen: 'SA', listed: <StorefrontCountry>[
        const StorefrontCountry(
            code: 'SA', path: '/sa', currency: 'SAR', sellable: false),
      ]);

      await harness.checkout.digitalPaymentPlaceOrder(
          customerId: '7', addressId: '12', paymentMethod: 'gateway');
      await harness.wallet.addFundToWallet('100', 'gateway');

      expect(harness.requests, isEmpty);
    });
  }, skip: !StorefrontConfig.enabled);

  group('on a storefront that may sell', () {
    final Map<String, _Storefront> storefronts = <String, _Storefront>{
      'the default one': (chosen: null, listed: null),
      'the Emirates, once the server has opened them': (
        chosen: 'AE',
        listed: <StorefrontCountry>[
          StorefrontCountry.saudiArabia,
          _openedEmirates,
        ],
      ),
    };

    for (final MapEntry<String, _Storefront> storefront
        in storefronts.entries) {
      for (final _Path path in <_Path>[..._orderPaths, ..._paymentPaths]) {
        testWidgets('${path.name} makes its request on ${storefront.key}',
            (WidgetTester tester) async {
          final _Harness harness = await _open(tester,
              chosen: storefront.value.chosen, listed: storefront.value.listed);

          await path.start(harness);
          await tester.pump();

          expect(harness.requests, <Symbol>[path.request]);
          expect(find.text(notice), findsNothing);
          for (final List<Object?> answer in harness.orderAnswers) {
            expect(answer[1], isNot(notice));
          }
        });
      }
    }
  });

  group('with storefronts off', () {
    for (final _Path path in <_Path>[..._orderPaths, ..._paymentPaths]) {
      testWidgets(
          '${path.name} makes its request, whatever storefront is stored, as it always has',
          (WidgetTester tester) async {
        final _Harness harness = await _open(tester, chosen: 'AE');

        await path.start(harness);

        expect(harness.requests, <Symbol>[path.request]);
      });
    }
  }, skip: StorefrontConfig.enabled);

  group(
      'the cart and the checkout screens, structural only: their source, not the screens built',
      () {
    final String cart =
        File('lib/features/cart/screens/cart_screen.dart').readAsStringSync();
    final String checkout =
        File('lib/features/checkout/screens/checkout_screen.dart')
            .readAsStringSync();

    test(
        'both read the gate from the storefront controller while listening, so they change when a newer answer arrives',
        () {
      final RegExp readsTheGate = RegExp(
          r'final\s+CheckoutSaleGate\s+saleGate\s*=\s*Provider\.of<StorefrontController>\(context\)\s*\.saleGate;');

      expect(readsTheGate.hasMatch(cart), isTrue, reason: 'the cart');
      expect(readsTheGate.hasMatch(checkout), isTrue, reason: 'the checkout');
    });

    test(
        'the cart shows the notice while the storefront may not sell, and its Proceed does nothing but say so then',
        () {
      expect(
          RegExp(r'if\s*\(\s*saleGate\.showsBrowseOnlyNotice\b[^)]*\)\s*const\s+StorefrontBrowseOnlyNotice\(')
              .hasMatch(cart),
          isTrue,
          reason: 'the notice');
      expect(
          RegExp(r"onTap:\s*\(\)\s*async\s*\{\s*if\s*\(\s*saleGate\.showsBrowseOnlyNotice\s*\)\s*\{[^}]*'storefront_browse_only_notice'[^}]*\breturn\s*;\s*\}")
              .hasMatch(cart),
          isTrue,
          reason: 'the first thing Proceed does is to say so and stop');
    });

    test(
        'the checkout shows the notice while the storefront may not sell, and its button to place the order is off then',
        () {
      expect(
          RegExp(r'if\s*\(\s*saleGate\.showsBrowseOnlyNotice\s*\)\s*\.\.\.\[\s*const\s+StorefrontBrowseOnlyNotice\(\)')
              .hasMatch(checkout),
          isTrue,
          reason: 'the notice');
      expect(
          RegExp(r'onTap:\s*!saleGate\.permits\(\s*otherwiseEnabled:[^?]*\)\s*\?\s*null\s*:')
              .hasMatch(checkout),
          isTrue,
          reason: 'the button');
    });
  });
}
