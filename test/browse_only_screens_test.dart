import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/features/address/domain/services/address_service_interface.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/auth/domain/services/auth_service_interface.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/cart/domain/services/cart_service_interface.dart';
import 'package:syriapharmacy/features/cart/screens/cart_screen.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:syriapharmacy/features/checkout/screens/checkout_screen.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/profile/domain/services/profile_service_interface.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/features/shipping/domain/services/shipping_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_browse_only_notice.dart';

import 'app_screen_harness.dart';

/// The two storefronts these tests put a customer on: the Emirates, which the server lists but has not approved for sales, and the
/// Emirates once it has.
const StorefrontCountry _browseOnlyEmirates = StorefrontCountry(
    code: 'AE', path: '/ae', currency: 'AED', sellable: false);
const StorefrontCountry _sellingEmirates = StorefrontCountry(
    code: 'AE', path: '/ae', currency: 'AED', sellable: true);

/// Saudi Arabia as the server would mark it if it stopped selling. The flag-off group lists it so that the dormancy it proves does not
/// rest on the default storefront's own `sellable` default: with storefronts off the customer is Saudi whatever they chose, and the
/// stored answer about Saudi Arabia must not be read either. Without it, taking the dormancy guard out of `StorefrontChoice.canSell`
/// changed nothing in that group (mutation M7, which survived until this was added).
const StorefrontCountry _stoppedSaudiArabia = StorefrontCountry(
    code: 'SA', path: '/sa', currency: 'SAR', sellable: false);

class _Cart implements CartServiceInterface {
  _Cart(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  Future<dynamic> getCartList({String? couponCode}) async => answered(rows);

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Shipping implements ShippingServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Checkout implements CheckoutServiceInterface {
  final List<Symbol> requests = <Symbol>[];

  @override
  Future<dynamic> getReferralAmount(String? amount) async =>
      answered(<String, dynamic>{'amount': 0});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    requests.add(invocation.memberName);

    return answeredWithNothing();
  }
}

class _Coupons implements CouponServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

/// One saved address, as the controller hands the screen its list.
class _Addresses implements AddressServiceInterface {
  @override
  Future<dynamic> getList({
    bool fromRemove = false,
    bool isShipping = false,
    bool isBilling = false,
    bool all = false,
  }) async =>
      <AddressModel>[
        AddressModel(
            id: 12,
            contactPersonName: 'A customer',
            addressType: 'home',
            address: 'A street',
            city: 'Dubai',
            country: 'AE',
            phone: '0500000000'),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Profile implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _SignedIn implements AuthServiceInterface {
  @override
  bool isLoggedIn() => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// One row of the cart, as the server answers it: two of a ten-riyal product, nothing discounted.
Map<String, dynamic> _cartRow() => <String, dynamic>{
      'id': 1,
      'product_id': 31,
      'name': 'Vitamin C',
      'seller': 'admin',
      'thumbnail': 'p.png',
      'seller_id': 1,
      'seller_is': 'admin',
      'image': 'p.png',
      'price': 10.0,
      'discounted_price': null,
      'quantity': 2,
      'max_quantity': 10,
      'variant': '',
      'discount': 0.0,
      'discount_type': 'amount',
      'tax': 0.0,
      'tax_model': 'exclude',
      'tax_type': 'percent',
      'cart_group_id': 'admin-1',
      'shop_info': 'Shop',
      'shipping_cost': 0,
      'product_type': 'physical',
      'slug': 'vitamin-c',
      'minimum_order_amount_info': 0,
      'is_product_available': 1,
      'is_checked': 1,
      'applied_tax': 0.0,
      'applied_tax_type': 'percent',
      'shipping_cost_tax': 0.0,
      'product': <String, dynamic>{
        'id': 31,
        'name': 'Vitamin C',
        'slug': 'vitamin-c',
        'minimum_order_qty': 1,
        'total_current_stock': 10,
      },
    };

CartController _cartWithOneRow() => CartController(
    cartServiceInterface: _Cart(<Map<String, dynamic>>[_cartRow()]));

List<SingleChildWidget> _cartProviders(CartController cart) =>
    <SingleChildWidget>[
      ChangeNotifierProvider<CartController>.value(value: cart),
      ChangeNotifierProvider<ShippingController>.value(
          value: ShippingController(shippingServiceInterface: _Shipping())),
      ChangeNotifierProvider<AuthController>.value(
          value: AuthController(authServiceInterface: _SignedIn())),
    ];

List<SingleChildWidget> _checkoutProviders(CheckoutController checkout) =>
    <SingleChildWidget>[
      ..._cartProviders(_cartWithOneRow()),
      ChangeNotifierProvider<CheckoutController>.value(value: checkout),
      ChangeNotifierProvider<CouponController>.value(
          value: CouponController(couponRepo: _Coupons())),
      ChangeNotifierProvider<AddressController>.value(
          value: AddressController(addressServiceInterface: _Addresses())),
      ChangeNotifierProvider<ProfileController>.value(
          value: ProfileController(profileServiceInterface: _Profile())),
    ];

/// The colour the cart paints its Checkout button in: the shop's own colour while a sale may start, the disabled colour while it
/// may not. It is read off the box the real screen built, not off the source.
Color _cartCheckoutButtonColour(WidgetTester tester) {
  final Finder label = find.text(words('en', 'checkout'));
  final Finder box =
      find.ancestor(of: label.last, matching: find.byType(Container)).first;

  return ((tester.widget<Container>(box).decoration) as BoxDecoration).color!;
}

/// The customer has chosen their saved address and ticked the terms, which is everything the checkout asks of them before its Proceed
/// button is its own to offer. It is done after the screen is built, because the screen's own `initState` resets the tick.
Future<void> _customerIsReadyToOrder(
    WidgetTester tester, CheckoutController checkout) async {
  checkout.setAddressIndex(0);
  checkout.toggleTermsCheck();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// I2-10 criterion 5 and I2-13 criterion 1, the screens: the cart and the checkout a customer actually sees on a storefront the server
/// has not approved for sales. Both screens are built here — the app's own `CartScreen` and `CheckoutScreen`, through the app's provider
/// tree and its global navigator key — and what they draw is read out of the tree: the words of the notice, the colour the cart paints
/// its Checkout button, whether the checkout's Proceed button can be pressed at all, and what happens when a customer presses them.
///
/// The gate the screens read is `StorefrontController.saleGate`, which asks `StorefrontChoice`; the choice takes whether storefronts
/// are on as a parameter, so the screens can be read in both builds. The group that leaves that parameter out is the dormancy proof:
/// in a build with storefronts off, a customer stored on a storefront the server lists as not sellable sees the cart and the checkout
/// exactly as a Saudi customer sees them today.
///
///   flutter test test/browse_only_screens_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/browse_only_screens_test.dart
///
/// What this does not cover: the screens were not run on a device, and only one width and one text size are looked at (the notice's own
/// widget is looked at narrow and large by storefront_browse_only_notice_test.dart). Nothing here says what the server does with a
/// request that reaches it anyway; that is the backend's own gate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final String notice = words('en', 'storefront_browse_only_notice');
  final String noticeInArabic =
      words('ar', 'storefront_browse_only_notice');

  group('the cart screen, built, on a storefront that may not sell', () {
    testWidgets('shows the notice in the words of the language file',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_browseOnlyEmirates],
          storefrontsEnabled: true,
          providers: _cartProviders(_cartWithOneRow()));

      expect(find.byType(StorefrontBrowseOnlyNotice), findsOneWidget);
      expect(find.text(notice), findsOneWidget);
    });

    testWidgets('shows the notice in Arabic when the app is in Arabic',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_browseOnlyEmirates],
          storefrontsEnabled: true,
          locale: const Locale('ar'),
          providers: _cartProviders(_cartWithOneRow()));

      expect(find.text(noticeInArabic), findsOneWidget);
      expect(noticeInArabic, isNot(notice));
    });

    testWidgets('paints its Checkout button in the disabled colour',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_browseOnlyEmirates],
          storefrontsEnabled: true,
          providers: _cartProviders(_cartWithOneRow()));

      final ThemeData theme =
          Theme.of(tester.element(find.byType(CartScreen)));

      expect(_cartCheckoutButtonColour(tester), theme.disabledColor);
      expect(_cartCheckoutButtonColour(tester), isNot(theme.primaryColor));
    });

    testWidgets(
        'answers a press of Checkout with the notice and goes no further',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_browseOnlyEmirates],
          storefrontsEnabled: true,
          providers: _cartProviders(_cartWithOneRow()));

      // Every message the framework reports from the press is collected, so the press is shown to have done one thing and nothing
      // else: the checkout screen is reached through the router, which this app is built without here, so an attempt to open it
      // would be reported as well.
      final List<String> reported = <String>[];
      final void Function(FlutterErrorDetails)? previously =
          FlutterError.onError;
      FlutterError.onError =
          (FlutterErrorDetails details) => reported.add(details.toString());
      addTearDown(() => FlutterError.onError = previously);

      await tester.tap(find.text(words('en', 'checkout')).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The notice twice: the card at the top of the cart, and the message the press put up.
      expect(find.text(notice), findsNWidgets(2));
      expect(find.byType(CheckoutScreen), findsNothing);

      // Every message the press reports is the cart's own bottom bar being 0.2 of a pixel short of its contents while a message is up,
      // which it is for every warning the cart shows and which this branch did not introduce (see the lane's report). Anything else the
      // press reported — an attempt to route to the checkout above all — lands here and fails.
      for (final String message in reported) {
        expect(message, contains('overflowed'), reason: message);
        expect(message, contains('cart_screen.dart'), reason: message);
      }
    });
  });

  group('the cart screen, built, on a storefront that may sell', () {
    testWidgets('shows no notice and paints Checkout in the shop\'s colour',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_sellingEmirates],
          storefrontsEnabled: true,
          providers: _cartProviders(_cartWithOneRow()));

      final ThemeData theme =
          Theme.of(tester.element(find.byType(CartScreen)));

      expect(find.byType(StorefrontBrowseOnlyNotice), findsNothing);
      expect(find.text(notice), findsNothing);
      expect(_cartCheckoutButtonColour(tester), theme.primaryColor);
    });
  });

  group('the checkout screen, built, on a storefront that may not sell', () {
    testWidgets('shows the notice and its Proceed button cannot be pressed',
        (WidgetTester tester) async {
      final CheckoutController checkout =
          CheckoutController(checkoutServiceInterface: _Checkout());

      await ScreenHarness.open(tester,
          screen: const CheckoutScreen(
              cartList: <CartModel>[],
              discount: 0,
              tax: 0,
              totalOrderAmount: 20,
              shippingFee: 0,
              quantity: 2,
              hasPhysical: true),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_browseOnlyEmirates],
          storefrontsEnabled: true,
          providers: _checkoutProviders(checkout));
      await _customerIsReadyToOrder(tester, checkout);

      expect(find.byType(StorefrontBrowseOnlyNotice), findsOneWidget);
      expect(find.text(notice), findsOneWidget);
      expect(checkout.isAcceptTerms, isTrue);
      expect(checkout.addressIndex, 0);
      expect(
          tester
              .widget<CustomButton>(find.widgetWithText(
                  CustomButton, words('en', 'proceed')))
              .onTap,
          isNull);
    });

    testWidgets('shows the notice in Arabic when the app is in Arabic',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CheckoutScreen(
              cartList: <CartModel>[],
              discount: 0,
              tax: 0,
              totalOrderAmount: 20,
              shippingFee: 0,
              quantity: 2,
              hasPhysical: true),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_browseOnlyEmirates],
          storefrontsEnabled: true,
          locale: const Locale('ar'),
          providers: _checkoutProviders(
              CheckoutController(checkoutServiceInterface: _Checkout())));

      expect(find.text(noticeInArabic), findsOneWidget);
    });
  });

  group('the checkout screen, built, on a storefront that may sell', () {
    testWidgets(
        'shows no notice and its Proceed button can be pressed once the terms are accepted',
        (WidgetTester tester) async {
      final CheckoutController checkout =
          CheckoutController(checkoutServiceInterface: _Checkout());

      await ScreenHarness.open(tester,
          screen: const CheckoutScreen(
              cartList: <CartModel>[],
              discount: 0,
              tax: 0,
              totalOrderAmount: 20,
              shippingFee: 0,
              quantity: 2,
              hasPhysical: true),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_sellingEmirates],
          storefrontsEnabled: true,
          providers: _checkoutProviders(checkout));
      await _customerIsReadyToOrder(tester, checkout);

      expect(find.byType(StorefrontBrowseOnlyNotice), findsNothing);
      expect(find.text(notice), findsNothing);
      expect(
          tester
              .widget<CustomButton>(find.widgetWithText(
                  CustomButton, words('en', 'proceed')))
              .onTap,
          isNotNull);
    });
  });

  group('the checkout screen a customer presses Proceed on', () {
    for (final String language in <String>['en', 'ar']) {
      testWidgets(
          'shows in $language the refusal the controller handed its callback, and sends no order',
          (WidgetTester tester) async {
        final _Checkout service = _Checkout();
        final CheckoutController checkout =
            CheckoutController(checkoutServiceInterface: service);

        final ScreenHarness harness = await ScreenHarness.open(tester,
            screen: const CheckoutScreen(
                cartList: <CartModel>[],
                discount: 0,
                tax: 0,
                totalOrderAmount: 20,
                shippingFee: 0,
                quantity: 2,
                hasPhysical: true),
            customerOn: 'AE',
            listed: const <StorefrontCountry>[_sellingEmirates],
            storefrontsEnabled: true,
            locale: Locale(language),
            providers: _checkoutProviders(checkout));
        await _customerIsReadyToOrder(tester, checkout);
        checkout.setOfflineChecked('cod');
        await tester.pump();

        // The screen was built while the Emirates could sell, so its button is live. The server's newer answer arrives before the
        // customer presses it: the controller reads that answer, not the one the button was drawn from.
        await StoredStorefronts(harness.preferences)
            .save(const <StorefrontCountry>[_browseOnlyEmirates]);
        final Finder button = find.widgetWithText(
            CustomButton, words(language, 'proceed'));

        expect(tester.widget<CustomButton>(button).onTap, isNotNull);

        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // The notice is the one the controller read out of the language files for the language the app is in, and the screen put it up.
        expect(find.text(words(language, 'storefront_browse_only_notice')),
            findsOneWidget);
        expect(service.requests, isNot(contains(#cashOnDeliveryPlaceOrder)));
        expect(checkout.isLoading, isFalse);
      }, skip: !StorefrontConfig.enabled);
    }
  });

  group('the screens of a build with storefronts off', () {
    testWidgets(
        'the cart shows no notice and Checkout is live, whatever the server said about the storefront the customer is on',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[
            _stoppedSaudiArabia,
            _browseOnlyEmirates
          ],
          providers: _cartProviders(_cartWithOneRow()));

      final ThemeData theme =
          Theme.of(tester.element(find.byType(CartScreen)));

      expect(find.byType(StorefrontBrowseOnlyNotice), findsNothing);
      expect(find.text(notice), findsNothing);
      expect(_cartCheckoutButtonColour(tester), theme.primaryColor);
    });

    testWidgets(
        'the checkout shows no notice and its Proceed button is live, whatever the server said',
        (WidgetTester tester) async {
      final CheckoutController checkout =
          CheckoutController(checkoutServiceInterface: _Checkout());

      await ScreenHarness.open(tester,
          screen: const CheckoutScreen(
              cartList: <CartModel>[],
              discount: 0,
              tax: 0,
              totalOrderAmount: 20,
              shippingFee: 0,
              quantity: 2,
              hasPhysical: true),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[
            _stoppedSaudiArabia,
            _browseOnlyEmirates
          ],
          providers: _checkoutProviders(checkout));
      await _customerIsReadyToOrder(tester, checkout);

      expect(find.byType(StorefrontBrowseOnlyNotice), findsNothing);
      expect(find.text(notice), findsNothing);
      expect(
          tester
              .widget<CustomButton>(find.widgetWithText(
                  CustomButton, words('en', 'proceed')))
              .onTap,
          isNotNull);
    });
  }, skip: StorefrontConfig.enabled);
}
