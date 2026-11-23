import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
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
import 'package:syriapharmacy/features/checkout/widgets/coupon_apply_widget.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:syriapharmacy/features/more/widgets/square_item_widget.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/profile/domain/services/profile_service_interface.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/features/shipping/domain/services/shipping_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/wallet/controllers/wallet_controller.dart';
import 'package:syriapharmacy/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:syriapharmacy/features/wallet/widgets/wallet_card_widget.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

import 'app_screen_harness.dart';

/// The storefronts a customer is put on here: the Emirates, whose currency is written with two decimals, and Kuwait, whose currency is
/// written with three. Both may sell, so nothing is gated and only the money is in question.
const StorefrontCountry _emirates = StorefrontCountry(
    code: 'AE', path: '/ae', currency: 'AED', sellable: true);
const StorefrontCountry _kuwait =
    StorefrontCountry(code: 'KW', path: '/kw', currency: 'KWD', sellable: true);

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
  @override
  Future<dynamic> getReferralAmount(String? amount) async =>
      answered(<String, dynamic>{'amount': 0});

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

/// The coupon the server grants, with the discount it is worth.
class _Coupons implements CouponServiceInterface {
  _Coupons(this.discount);

  final double discount;

  @override
  Future<dynamic> get(String couponCode) async =>
      answered(<String, dynamic>{'coupon_discount': discount});

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Addresses implements AddressServiceInterface {
  @override
  Future<dynamic> getList({
    bool fromRemove = false,
    bool isShipping = false,
    bool isBilling = false,
    bool all = false,
  }) async =>
      <AddressModel>[AddressModel(id: 12, address: 'A street', city: 'Dubai')];

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _Profile implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

/// The wallet's ledger as the server answers it, with the balance the card writes.
class _Wallet implements WalletServiceInterface {
  _Wallet(this.balance);

  final double balance;

  @override
  Future<dynamic> getList({
    int? offset,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,
  }) async =>
      answered(<String, dynamic>{
        'limit': 10,
        'offset': 1,
        'total_size': 0,
        'total_wallet_balance': balance,
        'wallet_transaction_list': const <dynamic>[],
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => answeredWithNothing();
}

class _SignedIn implements AuthServiceInterface {
  @override
  bool isLoggedIn() => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// One row of the cart: two of a ten-unit product, nothing discounted and no tax.
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

List<SingleChildWidget> _cartProviders() => <SingleChildWidget>[
      ChangeNotifierProvider<CartController>.value(
          value: CartController(
              cartServiceInterface:
                  _Cart(<Map<String, dynamic>>[_cartRow()]))),
      ChangeNotifierProvider<ShippingController>.value(
          value: ShippingController(shippingServiceInterface: _Shipping())),
      ChangeNotifierProvider<AuthController>.value(
          value: AuthController(authServiceInterface: _SignedIn())),
    ];

List<SingleChildWidget> _checkoutProviders(
        {CouponController? coupons, CheckoutController? checkout}) =>
    <SingleChildWidget>[
      ..._cartProviders(),
      ChangeNotifierProvider<CheckoutController>.value(
          value: checkout ??
              CheckoutController(checkoutServiceInterface: _Checkout())),
      ChangeNotifierProvider<CouponController>.value(
          value: coupons ?? CouponController(couponRepo: _Coupons(0))),
      ChangeNotifierProvider<AddressController>.value(
          value: AddressController(addressServiceInterface: _Addresses())),
      ChangeNotifierProvider<ProfileController>.value(
          value: ProfileController(profileServiceInterface: _Profile())),
    ];

Widget _checkoutScreen() => const CheckoutScreen(
    cartList: <CartModel>[],
    discount: 0.75,
    tax: 0,
    totalOrderAmount: 20,
    shippingFee: 1.25,
    quantity: 2,
    hasPhysical: true);

/// Every amount of a surface, in the words a customer reads: what the storefront's own currency gives in a build with storefronts on,
/// and what the platform's money gives in a build without them, which is what a Saudi customer reads today.
typedef _Amounts = ({Map<String, String> withStorefronts, Map<String, String> asToday});

/// J-05 criterion 3: the cart, the checkout, the wallet and the coupons write every amount through the one formatter, and this reads
/// the exact words each surface draws — the currency mark, the number and its decimals — off the real screens, built through the app's
/// own provider tree.
///
/// The surfaces here are the app's own: `CartScreen`, `CheckoutScreen`, the wallet card of the wallet screen, the "more" screen's wallet
/// tile and the checkout's coupon card. Nothing is hand-wired in their place. An amount written any other way — the number interpolated
/// beside a currency's name, `toStringAsFixed` in place of the formatter, the decimals of the wrong currency — gives a different string
/// and fails here.
///
/// Both builds are read. With storefronts on, a customer on the Emirates reads two decimals after "AED" and a customer in Kuwait three
/// after "KD", because the decimals belong to the currency (ISO 4217). With storefronts off, every amount is the platform's, at the rate
/// of the currency the customer chose in the settings and with no decimals, whatever storefront is stored — the money a Saudi customer
/// reads today, unchanged.
///
///   flutter test test/screen_money_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/screen_money_test.dart
///
/// What this does not cover: the screens were not run on a device; Saudi Arabia's own money is the platform's and is left exactly as it
/// is (J-05 criterion 1 is the owner's to decide); and the amounts of an order already placed are read by
/// order_screens_currency_test.dart, not here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Which of the two sets of words applies to the build this is running in.
  Map<String, String> expected(_Amounts amounts) =>
      StorefrontConfig.enabled ? amounts.withStorefronts : amounts.asToday;

  group('the cart screen, built', () {
    const _Amounts lineAndTotal = (
      withStorefronts: <String, String>{
        'the price of the line': 'AED 10.00',
        'the total price': 'AED 20.00',
      },
      // 10.00 and 20.00 at the rate of the riyal the customer chose, with no decimals.
      asToday: <String, String>{
        'the price of the line': 'SR38',
        'the total price': 'SR75',
      },
    );

    testWidgets('writes the price of a line and the total in one way',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_emirates],
          providers: _cartProviders());

      expected(lineAndTotal).forEach((String what, String written) {
        expect(find.text(written), findsOneWidget, reason: what);
      });
    });

    testWidgets('writes the decimals of the currency of the storefront',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'KW',
          listed: const <StorefrontCountry>[_kuwait],
          providers: _cartProviders());

      expect(find.text('KD 10.000'), findsOneWidget, reason: 'the line');
      expect(find.text('KD 20.000'), findsOneWidget, reason: 'the total');
    }, skip: !StorefrontConfig.enabled);

    // The money of a build with storefronts off is guarded twice: PriceConverter asks the build flag itself, and StorefrontChoice
    // answers Saudi Arabia for every storefront while the flag is off, whose money IS the platform's. Each guard alone is enough, so
    // taking one out is invisible on the ordinary path (mutation M13, which survived until this case was added). Here the app is given
    // a storefront controller that does answer the Emirates, so the money helper's own flag guard is the only thing left -- and it
    // keeps the platform's money, which is what a build with storefronts off must write whatever else has been wired up.
    testWidgets(
        'writes the money of the platform even when the app is on a storefront of its own',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: const CartScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_emirates],
          storefrontsEnabled: true,
          providers: _cartProviders());

      expect(find.text('SR38'), findsOneWidget, reason: 'the line');
      expect(find.text('SR75'), findsOneWidget, reason: 'the total');
      expect(find.text('AED 10.00'), findsNothing);
      expect(find.text('AED 20.00'), findsNothing);
    }, skip: StorefrontConfig.enabled);
  });

  group('the checkout screen, built', () {
    const _Amounts summary = (
      withStorefronts: <String, String>{
        'the sub total': 'AED 20.75',
        'the shipping fee': 'AED 1.25',
        'the discount': 'AED 0.75',
        'the total payable': 'AED 21.25',
      },
      asToday: <String, String>{
        'the sub total': 'SR78',
        'the shipping fee': 'SR5',
        'the discount': 'SR3',
        'the total payable': 'SR80',
      },
    );

    testWidgets('writes every amount of its order summary in one way',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: _checkoutScreen(),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_emirates],
          config: shopConfig(systemTaxIncludeStatus: 1),
          providers: _checkoutProviders());

      expected(summary).forEach((String what, String written) {
        expect(find.text(written), findsOneWidget, reason: what);
      });
    });

    testWidgets('writes the decimals of the currency of the storefront',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: _checkoutScreen(),
          customerOn: 'KW',
          listed: const <StorefrontCountry>[_kuwait],
          config: shopConfig(systemTaxIncludeStatus: 1),
          providers: _checkoutProviders());

      expect(find.text('KD 20.750'), findsOneWidget, reason: 'the sub total');
      expect(find.text('KD 21.250'), findsOneWidget,
          reason: 'the total payable');
    }, skip: !StorefrontConfig.enabled);
  });

  group('the wallet, built', () {
    const _Amounts balance = (
      withStorefronts: <String, String>{'the balance': 'AED 55.50'},
      // 55.50 at the rate of the riyal the customer chose, with no decimals.
      asToday: <String, String>{'the balance': 'SR208'},
    );

    testWidgets('the card of the wallet screen writes the balance in one way',
        (WidgetTester tester) async {
      final WalletController wallet =
          WalletController(walletServiceInterface: _Wallet(55.5));
      addTearDown(wallet.dispose);

      await ScreenHarness.open(tester,
          screen: Scaffold(
              body: WalletCardWidget(
                  tooltipController: JustTheController(),
                  focusNode: FocusNode(),
                  inputAmountController: TextEditingController())),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_emirates],
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<WalletController>.value(value: wallet),
          ]);
      await wallet.getTransactionList(1, isUpdate: false);
      await tester.pump();

      expect(find.text(words('en', 'wallet_amount')), findsOneWidget);
      expect(find.text(expected(balance)['the balance']!), findsOneWidget);
    });

    testWidgets('the tile of the more screen writes the balance in one way',
        (WidgetTester tester) async {
      await ScreenHarness.open(tester,
          screen: Scaffold(
              body: SquareButtonWidget(
                  image: Images.wallet,
                  title: words('en', 'wallet'),
                  count: 0,
                  hasCount: false,
                  isWallet: true,
                  balance: 55.5)),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_emirates]);

      expect(find.text(expected(balance)['the balance']!), findsOneWidget);
    });
  });

  group('the coupon card of the checkout, built', () {
    const _Amounts discount = (
      withStorefronts: <String, String>{'the discount': '(-AED 2.50 off)'},
      // 2.50 at the rate of the riyal the customer chose, with no decimals.
      asToday: <String, String>{'the discount': '(-SR9 off)'},
    );

    testWidgets(
        'writes the discount of the coupon the customer applied in one way',
        (WidgetTester tester) async {
      final CouponController coupons =
          CouponController(couponRepo: _Coupons(2.5));
      addTearDown(coupons.dispose);

      await ScreenHarness.open(tester,
          screen: Scaffold(
              body: CouponApplyWidget(
                  couponController: TextEditingController(), orderAmount: 20)),
          customerOn: 'AE',
          listed: const <StorefrontCountry>[_emirates],
          providers: _checkoutProviders(coupons: coupons));

      expect(find.text(words('en', 'add_coupon')), findsOneWidget);

      await coupons.applyCoupon(
          tester.element(find.byType(CouponApplyWidget)), 'SAVE', 20);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text(expected(discount)['the discount']!), findsOneWidget);
    });
  });
}
