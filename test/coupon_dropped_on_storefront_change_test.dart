import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/cart/domain/services/cart_service_interface.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:syriapharmacy/features/checkout/widgets/coupon_apply_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/coupon_bottom_sheet_widget.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

import 'app_screen_harness.dart';

const StorefrontCountry _emirates = StorefrontCountry(
    code: 'AE', path: '/ae', currency: 'AED', sellable: true);
const StorefrontCountry _kuwait =
    StorefrontCountry(code: 'KW', path: '/kw', currency: 'KWD', sellable: true);

/// The coupon the server grants on the storefront the customer is on, and the coupons it lists for them.
class _Coupons implements CouponServiceInterface {
  static const double discount = 2.5;

  int listed = 0;

  @override
  Future<dynamic> get(String couponCode) async =>
      answered(<String, dynamic>{'coupon_discount': discount});

  @override
  Future<dynamic> getAvailableCouponList() async {
    listed++;

    return answered(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 7,
        'title': 'Ten off',
        'code': 'SAVE',
        'discount': 10,
        'discount_type': 'percentage',
        'min_purchase': 5,
        'coupon_type': 'default_type',
        'coupon_bearer': 'inhouse',
        'limit': 1,
        'expire_date': '2027-01-31',
        'plain_expire_date': '2027-01-31',
        'order_count': 0,
      },
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Cart implements CartServiceInterface {
  @override
  Future<dynamic> getCartList({String? couponCode}) async =>
      answered(const <dynamic>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Checkout implements CheckoutServiceInterface {
  @override
  Future<dynamic> getReferralAmount(String? amount) async =>
      answered(<String, dynamic>{'amount': 0});

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

/// The app's own notifier, built as `di_container` builds it but with the caches it clears recorded rather than cleared, and with
/// whether storefronts are on given as a parameter so both builds can be read.
class _Changes extends StorefrontChangeNotifier {
  _Changes({required super.enabled})
      : super(
          clearHttpCache: _nothingToClear,
          clearLocalCache: _nothingToDelete,
          isSignedIn: _signedIn,
        );

  static void _nothingToClear(String storefrontCode) {}

  static Future<void> _nothingToDelete(String storefrontCode) async {}

  static bool _signedIn() => true;
}

/// B-16 criterion 5: a customer who has a coupon applied loses it, and the coupon lists with it, when they move to another storefront —
/// read off the coupon surface the checkout actually shows, not off the controller's fields.
///
/// The surface is the app's own `CouponApplyWidget`, the card the checkout puts above its payment methods, and the app's own
/// `CouponBottomSheetWidget`, the sheet that card opens. The coupon is applied the way a customer applies one, through
/// `CouponController.applyCoupon` over a server that grants it; the move is made by the app's own `StorefrontChangeNotifier`, which the
/// controller joined in its constructor exactly as `di_container` has it join.
///
/// The notifier takes whether storefronts are on as a parameter, so both builds are read here. With storefronts off nothing moves a
/// customer between storefronts and the notifier does nothing, so the coupon stays applied: that is the dormancy of this behaviour, and
/// the group that proves it runs in both builds too.
///
///   flutter test test/coupon_dropped_on_storefront_change_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/coupon_dropped_on_storefront_change_test.dart
///
/// What this does not cover: the surfaces were not run on a device, and nothing here says what the server does with a coupon code of
/// another storefront — the app simply no longer holds it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The coupon card and the sheet it opens, with a coupon controller that has joined [changes].
  Future<CouponController> openTheCouponSurface(
    WidgetTester tester, {
    required StorefrontChangeNotifier changes,
    required _Coupons coupons,
  }) async {
    final CouponController controller = CouponController(
        couponRepo: coupons, storefrontChangeNotifier: changes);
    addTearDown(controller.dispose);

    await ScreenHarness.open(tester,
        screen: Scaffold(
            body: Column(children: <Widget>[
          CouponApplyWidget(
              couponController: TextEditingController(), orderAmount: 20),
          const Expanded(child: CouponBottomSheetWidget(orderAmount: 20)),
        ])),
        customerOn: 'AE',
        listed: const <StorefrontCountry>[_emirates, _kuwait],
        storefrontsEnabled: true,
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<CouponController>.value(value: controller),
          ChangeNotifierProvider<CartController>.value(
              value: CartController(cartServiceInterface: _Cart())),
          ChangeNotifierProvider<CheckoutController>.value(
              value:
                  CheckoutController(checkoutServiceInterface: _Checkout())),
        ]);

    return controller;
  }

  Future<void> applyTheCoupon(
      WidgetTester tester, CouponController controller) async {
    await controller.getAvailableCouponList();
    await controller.applyCoupon(
        tester.element(find.byType(CouponApplyWidget)), 'SAVE', 20);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('a customer with a coupon applied who moves to another storefront',
      () {
    testWidgets('no longer sees the coupon, nor its discount, on the card',
        (WidgetTester tester) async {
      final _Coupons coupons = _Coupons();
      final StorefrontChangeNotifier changes = _Changes(enabled: true);
      final CouponController controller = await openTheCouponSurface(tester,
          changes: changes, coupons: coupons);

      await applyTheCoupon(tester, controller);

      expect(find.text(words('en', 'coupon_applied')), findsOneWidget);
      expect(find.text('SAVE'), findsWidgets);

      await changes.storefrontChanged(
          previous: _emirates, current: _kuwait);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(words('en', 'coupon_applied')), findsNothing);
      expect(find.text(words('en', 'add_coupon')), findsOneWidget);
      expect(controller.couponCode, isEmpty);
      expect(controller.discount, isNull);
    });

    testWidgets('no longer sees the coupons the other storefront listed',
        (WidgetTester tester) async {
      final _Coupons coupons = _Coupons();
      final StorefrontChangeNotifier changes = _Changes(enabled: true);
      final CouponController controller = await openTheCouponSurface(tester,
          changes: changes, coupons: coupons);

      await applyTheCoupon(tester, controller);

      // The entry of the listed coupon on the sheet: what it takes to use it, written through the one formatter.
      final String leastToSpend = StorefrontConfig.enabled
          ? '${words('en', 'available_from')} AED 5.00'
          : '${words('en', 'available_from')} SR19';

      expect(find.text(words('en', 'available_promo')), findsOneWidget);
      expect(find.text(leastToSpend), findsOneWidget);
      expect(coupons.listed, 1);

      await changes.storefrontChanged(
          previous: _emirates, current: _kuwait);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(leastToSpend), findsNothing);
      expect(find.text(words('en', 'available_promo')), findsOneWidget,
          reason: 'the sheet is still open; it is the list that is gone');
      expect(controller.availableCouponList, isNull);
      expect(controller.couponList, isNull);
      expect(controller.couponItemModel, isNull);

      // The list is asked for again when the coupon sheet is next opened, for the storefront the customer is on now.
      await controller.getAvailableCouponList();
      await tester.pump();

      expect(coupons.listed, 2);
      expect(find.text(leastToSpend), findsOneWidget);
    });

    testWidgets('keeps the coupon when the storefront has not changed',
        (WidgetTester tester) async {
      final StorefrontChangeNotifier changes = _Changes(enabled: true);
      final CouponController controller = await openTheCouponSurface(tester,
          changes: changes, coupons: _Coupons());

      await applyTheCoupon(tester, controller);
      await changes.storefrontChanged(
          previous: _emirates, current: _emirates);
      await tester.pump();

      expect(find.text(words('en', 'coupon_applied')), findsOneWidget);
    });
  });

  group('the coupon of a build with storefronts off', () {
    testWidgets('stays applied, because nothing moves a customer anywhere',
        (WidgetTester tester) async {
      final StorefrontChangeNotifier changes =
          _Changes(enabled: StorefrontConfig.enabled);
      final CouponController controller = await openTheCouponSurface(tester,
          changes: changes, coupons: _Coupons());

      await applyTheCoupon(tester, controller);
      await changes.storefrontChanged(previous: _emirates, current: _kuwait);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(words('en', 'coupon_applied')), findsOneWidget);
      expect(controller.couponCode, 'SAVE');
    });
  }, skip: StorefrontConfig.enabled);
}
