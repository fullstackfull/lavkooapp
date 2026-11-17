import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/cart/domain/services/cart_service_interface.dart';
import 'package:syriapharmacy/features/compare/controllers/compare_controller.dart';
import 'package:syriapharmacy/features/compare/domain/services/compare_service_interface.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/coupon/domain/models/coupon_item_model.dart';
import 'package:syriapharmacy/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/product_details/domain/services/product_details_service_interface.dart';
import 'package:syriapharmacy/features/restock/controllers/restock_controller.dart';
import 'package:syriapharmacy/features/restock/domain/services/restock_service_interface.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/features/search_product/domain/services/search_product_service_interface.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/features/shipping/domain/services/shipping_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:syriapharmacy/features/wishlist/domain/services/wishlist_service_interface.dart';

const StorefrontChange _guestToEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: false,
);

const StorefrontChange _customerToEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: true,
);

Response<dynamic> _ok(Object? body) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: body,
    );

String get _who => StorefrontScope.current ?? 'none';

class _FakeCartService implements CartServiceInterface {
  /// When set, an answer waits for it, and is built for the storefront asked for, which is the one at the time of the request.
  Completer<void>? hold;
  int asked = 0;

  @override
  Future<dynamic> getCartList({String? couponCode}) async {
    asked++;
    final String who = _who;
    await hold?.future;

    return ApiResponseModel.withSuccess(_ok(<Object>[
      <String, Object>{
        'id': 1,
        'product_id': 1,
        'name': 'cart of $who',
        'seller_id': 1,
        'price': 10.0,
        'quantity': 1,
        'discount': 0.0,
        'tax': 0.0,
      },
    ]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWishlistService implements WishlistServiceInterface {
  Completer<void>? hold;
  int asked = 0;

  @override
  Future<dynamic> getWishList({int? offset = 1, String? search = ''}) async {
    asked++;
    final int productId = _who == 'SA' ? 7 : 8;
    await hold?.future;

    return ApiResponseModel.withSuccess(_ok(<Object>[
      <String, Object>{'id': 1, 'product_id': productId},
    ]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCompareService implements CompareServiceInterface {
  int asked = 0;

  @override
  Future<dynamic> getList() async {
    asked++;
    return ApiResponseModel.withSuccess(_ok(<String, Object>{
      'compare_lists': <Object>[
        <String, Object>{'id': 1, 'product_id': _who == 'SA' ? 7 : 8},
      ],
    }));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRestockService implements RestockServiceInterface {
  int asked = 0;

  @override
  Future<dynamic> getRestockProductList(String offset, bool getAll) async {
    asked++;
    return ApiResponseModel.withSuccess(_ok(<String, Object>{
      'data': <Object>[],
      'total_size': _who == 'SA' ? 1 : 2,
      'limit': '10',
      'offset': '1',
    }));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSearchService implements SearchProductServiceInterface {
  int authorsAsked = 0;
  int housesAsked = 0;

  @override
  Future<dynamic> getAuthorList(String? slug) async {
    authorsAsked++;
    return ApiResponseModel.withSuccess(_ok(<Object>[
      <String, Object>{'id': 1, 'name': 'author of $_who'},
    ]));
  }

  @override
  Future<dynamic> getPublishingHouse(String? slug) async {
    housesAsked++;
    return ApiResponseModel.withSuccess(_ok(<Object>[
      <String, Object>{'id': 1, 'name': 'house of $_who'},
    ]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused
    implements
        CouponServiceInterface,
        ShippingServiceInterface,
        ProductDetailsServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What the customer's own lists do when they move to another storefront: the cart and the wishlist, which the server keeps per
/// storefront, and everything else that is derived from them or that a storefront decides. The server's answers are written by hand from
/// the audit of the backend, whose storefront pull requests (#47 to #64) were not available when this was written, not recorded from a
/// real server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => StorefrontScope.publish('SA'));
  tearDown(() => StorefrontScope.publish(null));

  group('the cart', () {
    late _FakeCartService service;
    late CartController controller;

    setUp(() async {
      service = _FakeCartService();
      controller = CartController(cartServiceInterface: service);
      await controller.getCartData(const _NoContext());
    });

    test(
        'is gone at once, and the controller is loading, before anything answers',
        () async {
      expect(controller.cartList.single.name, 'cart of SA');
      controller.isSelectedList = <bool>[true];
      controller.amount = 10;

      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.cartList, isEmpty);
      expect(controller.isSelectedList, isEmpty);
      expect(controller.amount, 0.0);
      expect(controller.cartLoading, isTrue);

      await told;
    });

    test('says it is loading by the time the screens are told', () async {
      StorefrontScope.publish('AE');
      bool told = false;
      bool? loadingWhenTold;
      controller.addListener(() {
        if (told) return;
        told = true;
        loadingWhenTold = controller.cartLoading;
      });

      final Future<void> reloading =
          controller.onStorefrontChanged(_guestToEmirates);

      expect(loadingWhenTold, isTrue);
      await reloading;
    });

    test('is the new storefront\'s when it has loaded', () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.cartList.single.name, 'cart of AE');
      expect(controller.cartLoading, isFalse);
    });

    test('is asked for by a guest as well as by a customer', () async {
      for (final StorefrontChange change in <StorefrontChange>[
        _guestToEmirates,
        _customerToEmirates,
      ]) {
        service.asked = 0;
        StorefrontScope.publish('AE');
        await controller.onStorefrontChanged(change);

        expect(service.asked, 1);
      }
    });

    test('never shows an answer that was on its way when the customer moved on',
        () async {
      final Completer<void> hold = Completer<void>();
      service.hold = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      final Future<Object?> asked = controller.getCartData(const _NoContext());
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_guestToEmirates);
      await pumpEventQueue();
      hold.complete();
      await asked;
      await told;

      expect(controller.cartList.single.name, 'cart of AE');
    });

    test('and, with nothing asked for since, shows none of the old one',
        () async {
      final Completer<void> hold = Completer<void>();
      service.hold = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });
      controller.resetCartList();

      final Future<Object?> asked = controller.getCartData(const _NoContext());
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      hold.complete();
      await asked;

      expect(controller.cartList, isEmpty);
    });
  });

  group('the wishlist', () {
    late _FakeWishlistService service;
    late WishListController controller;

    setUp(() async {
      service = _FakeWishlistService();
      controller = WishListController(wishlistServiceInterface: service);
      await controller.getWishList('');
    });

    test(
        'of a customer is gone at once and loaded again for the new storefront',
        () async {
      expect(controller.addedIntoWish, <int>[7]);

      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_customerToEmirates);
      expect(controller.wishList, isNull);
      expect(controller.addedIntoWish, isEmpty);

      await told;
      expect(controller.addedIntoWish, <int>[8]);
      expect(controller.wishList?.single.productId, 8);
    });

    test(
        'of a guest is emptied and not asked for, because that would sign the guest out',
        () async {
      service.asked = 0;

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.wishList, isEmpty);
      expect(controller.addedIntoWish, isEmpty);
      expect(service.asked, 0);
    });

    test('never shows an answer that was on its way when the customer moved on',
        () async {
      final Completer<void> hold = Completer<void>();
      service.hold = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      final Future<void> asked = controller.getWishList('');
      await pumpEventQueue();
      // The old answer is the only one held: the new storefront's comes first, and the old one arrives after it.
      service.hold = null;
      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_customerToEmirates);
      await told;
      expect(controller.addedIntoWish, <int>[8]);

      hold.complete();
      await asked;

      expect(controller.addedIntoWish, <int>[8]);
      expect(controller.wishList?.single.productId, 8);
    });
  });

  group('the compared products', () {
    test('of a customer are asked for again', () async {
      final _FakeCompareService service = _FakeCompareService();
      final CompareController controller =
          CompareController(compareServiceInterface: service);
      controller.getCompareList();
      await pumpEventQueue();
      expect(controller.compIds, <int>[7]);

      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_customerToEmirates);
      expect(controller.compIds, isEmpty);
      expect(controller.compareModel, isNull);

      await told;
      await pumpEventQueue();
      expect(controller.compIds, <int>[8]);
    });

    test('of a guest are dropped and not asked for', () async {
      final _FakeCompareService service = _FakeCompareService();
      final CompareController controller =
          CompareController(compareServiceInterface: service);
      controller.getCompareList();
      await pumpEventQueue();
      service.asked = 0;

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);
      await pumpEventQueue();

      expect(controller.compIds, isEmpty);
      expect(service.asked, 0);
    });
  });

  group('the restock requests', () {
    test('of a customer are asked for again', () async {
      final _FakeRestockService service = _FakeRestockService();
      final RestockController controller =
          RestockController(restockServiceInterface: service);
      await controller.getRestockProductList(1, getAll: true);
      expect(controller.restockProductModel?.totalSize, 1);

      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_customerToEmirates);
      expect(controller.restockProductModel, isNull);

      await told;
      expect(controller.restockProductModel?.totalSize, 2);
    });

    test('of a guest are dropped and not asked for', () async {
      final _FakeRestockService service = _FakeRestockService();
      final RestockController controller =
          RestockController(restockServiceInterface: service);
      await controller.getRestockProductList(1, getAll: true);
      service.asked = 0;

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.restockProductModel, isNull);
      expect(service.asked, 0);
    });
  });

  group('the search', () {
    test('drops its results and loads the authors and publishing houses again',
        () async {
      final _FakeSearchService service = _FakeSearchService();
      final SearchProductController controller =
          SearchProductController(searchProductServiceInterface: service);
      await controller.getAuthorList(null);
      await controller.getPublishingHouseList(null);
      expect(controller.authorsList?.single.name, 'author of SA');

      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_guestToEmirates);
      expect(controller.authorsList, isNull);
      expect(controller.publishingHouseList, isNull);
      expect(controller.searchedProduct, isNull);

      await told;
      expect(controller.authorsList?.single.name, 'author of AE');
      expect(controller.publishingHouseList?.single.name, 'house of AE');
    });

    test('asks for nothing that was not showing', () async {
      final _FakeSearchService service = _FakeSearchService();
      final SearchProductController controller =
          SearchProductController(searchProductServiceInterface: service);

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(service.authorsAsked, 0);
      expect(service.housesAsked, 0);
    });
  });

  group('what is derived from the cart', () {
    test('the applied coupon and the coupon lists are dropped', () async {
      final CouponController controller =
          CouponController(couponRepo: _Unused());
      controller.couponList = <Coupons>[Coupons(id: 1)];
      controller.availableCouponList = <Coupons>[Coupons(id: 2)];
      controller.couponItemModel = CouponItemModel(coupons: <Coupons>[]);
      int notified = 0;
      controller.addListener(() => notified++);

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.couponList, isNull);
      expect(controller.availableCouponList, isNull);
      expect(controller.couponItemModel, isNull);
      expect(controller.coupon, isNull);
      expect(controller.discount, isNull);
      expect(controller.couponCode, '');
      expect(notified, 1);
    });

    test('the shipping methods offered and chosen are dropped', () async {
      final ShippingController controller =
          ShippingController(shippingServiceInterface: _Unused());
      controller.initShippingMethodIndexList(2);
      controller.isSelectedList = <bool>[true, true];
      controller.amount = 30;
      expect(controller.shippingList, hasLength(2));

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.shippingList, isNull);
      expect(controller.chosenShippingList, isEmpty);
      expect(controller.isSelectedList, isEmpty);
      expect(controller.amount, 0.0);
      expect(controller.chosenShippingMethodIndex, isEmpty);
    });

    test(
        'the product a details page was showing, and the choices on it, are dropped',
        () async {
      final ProductDetailsController controller =
          ProductDetailsController(productDetailsServiceInterface: _Unused());
      controller.setImageSliderSelectedIndex(3);
      controller.setQuantity(5);
      expect(controller.imageSliderIndex, 3);
      expect(controller.quantity, 5);

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(controller.productDetailsModel, isNull);
      expect(controller.imageSliderIndex, 0);
      expect(controller.quantity, 0);
      expect(controller.variationIndex, isNull);
    });
  });
}

/// A stand-in for the screen's context, which the cart's loader takes and never reads.
class _NoContext implements BuildContext {
  const _NoContext();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
