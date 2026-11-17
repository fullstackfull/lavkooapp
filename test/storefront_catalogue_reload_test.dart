import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/domain/services/banner_service_interface.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:syriapharmacy/features/brand/domain/repositories/brand_repository.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/domain/services/category_service_interface.dart';
import 'package:syriapharmacy/features/deal/controllers/featured_deal_controller.dart';
import 'package:syriapharmacy/features/deal/domain/services/featured_deal_service_interface.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/domain/services/product_service_interface.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/product/enums/product_type.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/shop/domain/models/seller_model.dart';
import 'package:syriapharmacy/features/shop/domain/services/shop_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';

const StorefrontChange _toEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: false,
);

Response<dynamic> _ok(Object? body) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: body,
    );

/// Whoever the app's requests are for when the answer is built: what a server with storefronts does.
String get _who => StorefrontScope.current ?? 'none';

/// The data sync layer's answer: nothing local, and a client answer built when it is asked, for the storefront asked for. A test that
/// wants an answer held back gives [hold].
ApiResponseModel<T> _answer<T>(DataSourceEnum source, Object? Function() body) {
  if (source == DataSourceEnum.local) {
    return ApiResponseModel<T>.withError('no local data');
  }

  return ApiResponseModel<T>.withSuccess(_ok(body()) as T);
}

Map<String, Object> _productPage(String name) => <String, Object>{
      'total_size': 1,
      'limit': 10,
      'offset': 1,
      'products': <Object>[
        <String, Object>{'id': 1, 'name': name},
      ],
    };

class _FakeCategoryService implements CategoryServiceInterface {
  Completer<void>? hold;
  Completer<void>? holdHeader;
  int asked = 0;

  @override
  Future<ApiResponseModel<T>> getList<T>(
      {required DataSourceEnum source}) async {
    if (source == DataSourceEnum.client) asked++;
    final String who = _who;
    if (source == DataSourceEnum.client) await hold?.future;

    return _answer<T>(
        source,
        () => <Object>[
              <String, Object>{'id': 1, 'name': 'categories of $who'},
            ]);
  }

  @override
  Future<dynamic> getSellerWiseCategoryList(String slug) async =>
      ApiResponseModel.withError('x');

  @override
  Future<ApiResponseModel> getCategoryPageHeader(int categoryId) async {
    final String who = _who;
    await holdHeader?.future;

    return ApiResponseModel.withSuccess(_ok(<String, Object>{
      'sub_categories': <Object>[
        <String, Object>{'id': 2, 'name': 'sub category of $who'},
      ],
    }));
  }
}

class _FakeBannerService implements BannerServiceInterface {
  @override
  Future<ApiResponseModel<T>> getList<T>(
      {required DataSourceEnum source}) async {
    final String who = _who;
    return _answer<T>(
        source,
        () => <Object>[
              <String, Object>{
                'id': 1,
                'banner_type': 'Main Banner',
                'photo': who
              },
              <String, Object>{
                'id': 2,
                'banner_type': 'Promo Banner Left',
                'photo': who,
              },
            ]);
  }
}

class _FakeBrandRepository implements BrandRepository {
  /// While set, the second page waits for it.
  Completer<void>? holdSecondPage;

  @override
  Future<ApiResponseModel<T>> getBrandList<T>(
      {int offset = 1, required DataSourceEnum source}) async {
    final String who = _who;
    if (offset == 2) await holdSecondPage?.future;
    return _answer<T>(
        source,
        () => <String, Object>{
              'total_size': 1,
              'limit': 24,
              'offset': offset,
              'brands': <Object>[
                <String, Object>{'id': 1, 'name': 'brand of $who'},
              ],
            });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFeaturedDealService implements FeaturedDealServiceInterface {
  @override
  Future<ApiResponseModel<T>> getFeaturedDeal<T>(
      {required DataSourceEnum source}) async {
    final String who = _who;
    return _answer<T>(
        source,
        () => <Object>[
              <String, Object>{'id': 1, 'name': 'deal of $who'},
            ]);
  }
}

class _FakeProductService implements ProductServiceInterface {
  final List<String> asked = <String>[];

  /// While set, the second page waits for it.
  Completer<void>? holdSecondPage;

  ApiResponseModel<T> _page<T>(String what, DataSourceEnum source) {
    final String who = _who;
    if (source == DataSourceEnum.client) asked.add(what);
    return _answer<T>(source, () => _productPage('$what of $who'));
  }

  @override
  Future<ApiResponseModel<T>> getProductModelByType<T>(
      {required int offset,
      required ProductType productType,
      required DataSourceEnum source}) async {
    final ApiResponseModel<T> answer = _page<T>(productType.name, source);
    if (offset == 2) await holdSecondPage?.future;

    return answer;
  }

  @override
  Future<ApiResponseModel<T>> getRecommendedProduct<T>(
      {required DataSourceEnum source}) async {
    final String who = _who;
    if (source == DataSourceEnum.client) asked.add('recommended');
    return _answer<T>(
        source, () => <String, Object>{'id': 1, 'name': 'deal of $who'});
  }

  @override
  Future<ApiResponseModel<T>> getHomeCategoryProductList<T>(
      {required DataSourceEnum source}) async {
    final String who = _who;
    if (source == DataSourceEnum.client) asked.add('homeCategories');
    return _answer<T>(
        source,
        () => <Object>[
              <String, Object>{
                'id': 1,
                'name': 'category of $who',
                'products': []
              },
            ]);
  }

  @override
  Future<ApiResponseModel<T>> getClearanceAllProductList<T>(
      {required int offset, required DataSourceEnum source}) async {
    final ApiResponseModel<T> answer = _page<T>('clearance', source);
    if (offset == 2) await holdSecondPage?.future;

    return answer;
  }

  @override
  Future<ApiResponseModel<T>> getMostDemandedProduct<T>(
          {required DataSourceEnum source}) async =>
      ApiResponseModel<T>.withError('not used');

  @override
  Future<ApiResponseModel<T>> getFindWhatYouNeed<T>(
          {required DataSourceEnum source}) async =>
      ApiResponseModel<T>.withError('not used');

  @override
  Future<ApiResponseModel<T>> getMostSearchingProductList<T>(
      {required int offset, required DataSourceEnum source}) async {
    final ApiResponseModel<T> answer = _page<T>('mostSearching', source);
    if (offset == 2) await holdSecondPage?.future;

    return answer;
  }

  @override
  Future<dynamic> getFilteredProductList(
          BuildContext context, String offset, ProductType productType) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> getBrandOrCategoryProductList(
          {required bool isBrand,
          required int id,
          String searchProduct = '',
          required int offset}) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> getRelatedProductList(String id) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> getLatestProductList(String offset) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> getJustForYouProductList(
          {required int offset, int? limit}) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> getClearanceSearchProducts(
          String query,
          String? categoryIds,
          String? brandIds,
          String? authorIds,
          String? publishingIds,
          String? sort,
          String? priceMin,
          String? priceMax,
          int offset,
          String? productType,
          String? offerType) async =>
      ApiResponseModel.withError('not used');
}

class _FakeShopService implements ShopServiceInterface {
  final List<String> asked = <String>[];

  /// While set, the second page waits for it.
  Completer<void>? holdSecondPage;

  @override
  Future<ApiResponseModel<T>> getSellerList<T>(
      {required String type,
      required int offset,
      required int limit,
      required DataSourceEnum source}) async {
    final String who = _who;
    if (source == DataSourceEnum.client) asked.add(type);
    if (offset == 2) await holdSecondPage?.future;
    return _answer<T>(
        source,
        () => <String, Object>{
              'total_size': 1,
              'limit': limit,
              'offset': offset,
              'sellers': <Object>[
                <String, Object>{
                  'id': 1,
                  'f_name': '$type seller of $who',
                  'pos_status': 0,
                  'minimum_order_amount': 0,
                  'free_delivery_status': 0,
                  'free_delivery_over_amount': 0,
                },
              ],
            });
  }

  @override
  Future<ApiResponseModel<T>> getMoreStore<T>(
      {required DataSourceEnum source}) async {
    final String who = _who;
    if (source == DataSourceEnum.client) asked.add('moreStore');
    return _answer<T>(
        source,
        () => <Object>[
              <String, Object>{'id': 1, 'name': 'store of $who'},
            ]);
  }

  @override
  Future<dynamic> getClearanceShopProductList(
          String type, String offset, String sellerId) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> get(String id) async =>
      ApiResponseModel.withError('not used');

  @override
  Future<dynamic> getClearanceSearchProduct(
          String sellerId, String offset, String productId,
          {String search = '',
          String? categoryIds,
          String? brandIds,
          String? authorIds,
          String? publishingIds,
          String? productType,
          String? offerType}) async =>
      ApiResponseModel.withError('not used');
}

/// The lists of the home and what a screen of the catalogue holds, in the controllers: what each does when the customer moves to another
/// storefront. Each controller is given the answers of a server that answers for the storefront it is asked for, so what is shown can be
/// told by what it says.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => StorefrontScope.publish('SA'));
  tearDown(() => StorefrontScope.publish(null));

  /// Moves the app to the Emirates the way the chooser does: the requests ask for it first, then the controller is told.
  Future<void> moveTo(StorefrontChangeListener controller,
      {bool wait = true}) async {
    StorefrontScope.publish('AE');
    final Future<void> told = controller.onStorefrontChanged(_toEmirates);
    if (wait) await told;
    await pumpEventQueue();
  }

  group('categories', () {
    late _FakeCategoryService service;
    late CategoryController controller;

    setUp(() async {
      service = _FakeCategoryService();
      controller = CategoryController(categoryServiceInterface: service);
      await controller.getCategoryList(true);
    });

    test('drop at once, before anything is asked for', () async {
      expect(controller.categoryList.single.name, 'categories of SA');

      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_toEmirates);

      expect(controller.categoryList, isEmpty);
      expect(controller.filteredCategoryList, isEmpty);
      expect(controller.categorySelectedIndex, isNull);

      await told;
    });

    test('and are loaded again for the storefront the customer is on',
        () async {
      await moveTo(controller);

      expect(controller.categoryList.single.name, 'categories of AE');
      expect(service.asked, 2);
    });

    test('an answer for the storefront the customer left is not shown',
        () async {
      final Completer<void> hold = Completer<void>();
      final _FakeCategoryService slow = _FakeCategoryService()..hold = hold;
      final CategoryController other =
          CategoryController(categoryServiceInterface: slow);
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      final Future<void> loading = other.getCategoryList(true);
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      hold.complete();
      await loading;

      expect(other.categoryList, isEmpty);
    });
  });

  group('the header of a category', () {
    test('is dropped with the rest, and one that was on its way is not kept',
        () async {
      final _FakeCategoryService service = _FakeCategoryService();
      final CategoryController controller =
          CategoryController(categoryServiceInterface: service);
      await controller.getCategoryPageHeaderData(1);
      expect(controller.hasHeaderFor(1), isTrue);
      expect(controller.getSubCategoriesForCategory(1)?.single.name,
          'sub category of SA');

      await moveTo(controller);
      expect(controller.hasHeaderFor(1), isFalse);

      final Completer<void> hold = Completer<void>();
      service.holdHeader = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });
      final Future<void> loading = controller.getCategoryPageHeaderData(1);
      await pumpEventQueue();
      StorefrontScope.publish('KW');
      hold.complete();
      await loading;

      expect(controller.hasHeaderFor(1), isFalse);
    });
  });

  group('banners', () {
    test('drop at once, every slot of them, and are loaded again', () async {
      final BannerController controller =
          BannerController(bannerServiceInterface: _FakeBannerService());
      controller.getBannerList();
      await pumpEventQueue();
      expect(controller.mainBannerList?.single.photo, 'SA');
      expect(controller.promoBannerLeft?.photo, 'SA');

      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_toEmirates);
      expect(controller.mainBannerList, isNull);
      expect(controller.promoBannerLeft, isNull);

      await told;
      await pumpEventQueue();
      expect(controller.mainBannerList?.single.photo, 'AE');
      expect(controller.promoBannerLeft?.photo, 'AE');
    });
  });

  group('brands', () {
    test('drop at once and are loaded again', () async {
      final BrandController controller =
          BrandController(brandRepo: _FakeBrandRepository());
      await controller.getBrandList(offset: 1);
      expect(controller.brandList.single.name, 'brand of SA');

      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_toEmirates);
      expect(controller.brandModel, isNull);
      expect(controller.brandList, isEmpty);
      expect(controller.brandListSorted, isNull);

      await told;
      expect(controller.brandList.single.name, 'brand of AE');
    });
  });

  group('the featured deal', () {
    test('drops at once and is loaded again', () async {
      final FeaturedDealController controller = FeaturedDealController(
          featuredDealServiceInterface: _FakeFeaturedDealService());
      await controller.getFeaturedDealList();
      await pumpEventQueue();
      expect(controller.featuredDealProductList?.single.name, 'deal of SA');

      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_toEmirates);
      expect(controller.featuredDealProductList, isNull);

      await told;
      await pumpEventQueue();
      expect(controller.featuredDealProductList?.single.name, 'deal of AE');
    });
  });

  group('the lists of products', () {
    late _FakeProductService service;
    late ProductController controller;

    setUp(() async {
      service = _FakeProductService();
      controller = ProductController(productServiceInterface: service);
    });

    test('drop at once, every one of them, before anything is asked for',
        () async {
      await controller.getLatestProductList(1);
      await controller.getFeaturedProductModel(1);
      await controller.getJustForYouProduct(1);
      await controller.getHomeCategoryProductList(true);
      await controller.getRecommendedProduct();
      await pumpEventQueue();
      expect(controller.latestProductModel?.products?.single.name,
          'latestProduct of SA');
      service.asked.clear();

      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_toEmirates);

      expect(controller.latestProductModel, isNull);
      expect(controller.featuredProductModel, isNull);
      expect(controller.justForYouProductModel, isNull);
      expect(controller.homeCategoryProductList, isEmpty);
      expect(controller.recommendedProduct, isNull);
      expect(controller.brandOrCategoryProductList, isNull);
      expect(controller.relatedProductList, isNull);
      expect(service.asked, isEmpty);

      await told;
    });

    test('and the ones that were showing are loaded again, and no others',
        () async {
      await controller.getLatestProductList(1);
      await controller.getHomeCategoryProductList(true);
      await pumpEventQueue();
      service.asked.clear();

      await moveTo(controller);

      expect(service.asked,
          unorderedEquals(<String>['latestProduct', 'homeCategories']));
      expect(controller.latestProductModel?.products?.single.name,
          'latestProduct of AE');
      expect(controller.homeCategoryProductList.single.name, 'category of AE');
      expect(controller.featuredProductModel, isNull);
    });

    test('nothing is asked for when nothing was showing', () async {
      await moveTo(controller);

      expect(service.asked, isEmpty);
    });
  });

  group('the shops', () {
    test('drop at once, and the ones the home showed are loaded again',
        () async {
      final _FakeShopService service = _FakeShopService();
      final ShopController controller =
          ShopController(shopServiceInterface: service);
      await controller.getTopSellerList(offset: 1);
      await pumpEventQueue();
      expect(
          controller.topSellerModel?.sellers?.single.fName, 'top seller of SA');
      service.asked.clear();

      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_toEmirates);
      expect(controller.topSellerModel, isNull);
      expect(controller.allSellerModel, isNull);
      expect(controller.moreStoreList, isEmpty);
      expect(controller.clearanceProductModel, isNull);
      expect(controller.sellerInfoModel, isNull);

      await told;
      await pumpEventQueue();
      expect(service.asked, <String>['top']);
      expect(
          controller.topSellerModel?.sellers?.single.fName, 'top seller of AE');
    });
  });

  group('a page that was on its way when the customer moved on', () {
    test('is not added to the brands of the storefront they are on', () async {
      final _FakeBrandRepository repository = _FakeBrandRepository();
      final BrandController controller = BrandController(brandRepo: repository);
      await controller.getBrandList(offset: 1);
      final Completer<void> hold = Completer<void>();
      repository.holdSecondPage = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      final Future<void> paging = controller.getBrandList(offset: 2);
      await pumpEventQueue();
      await moveTo(controller);
      hold.complete();
      await paging;

      expect(controller.brandList.map((b) => b.name), <String>['brand of AE']);
    });

    for (final ({
      String name,
      Future<void> Function(ProductController) first,
      Future<void> Function(ProductController) second,
      List<Product>? Function(ProductController) shown,
      String label,
    }) loader in <({
      String name,
      Future<void> Function(ProductController) first,
      Future<void> Function(ProductController) second,
      List<Product>? Function(ProductController) shown,
      String label,
    })>[
      (
        name: 'latest',
        first: (c) => c.getLatestProductList(1),
        second: (c) => c.getLatestProductList(2),
        shown: (c) => c.latestProductModel?.products,
        label: 'latestProduct',
      ),
      (
        name: 'selected',
        first: (c) => c.getSelectedProductModel(1),
        second: (c) => c.getSelectedProductModel(2),
        shown: (c) => c.selectedProductModel?.products,
        label: 'discountedProduct',
      ),
      (
        name: 'featured',
        first: (c) => c.getFeaturedProductModel(1),
        second: (c) => c.getFeaturedProductModel(2),
        shown: (c) => c.featuredProductModel?.products,
        label: 'featuredProduct',
      ),
      (
        name: 'just for you',
        first: (c) => c.getJustForYouProduct(1),
        second: (c) => c.getJustForYouProduct(2),
        shown: (c) => c.justForYouProductModel?.products,
        label: 'justForYou',
      ),
      (
        name: 'every product of a type',
        first: (c) => c.getAllProductModelByType(
            offset: 1, type: ProductType.latestProduct),
        second: (c) => c.getAllProductModelByType(
            offset: 2, type: ProductType.latestProduct),
        shown: (c) => c.allProductModel?.products,
        label: 'latestProduct',
      ),
      (
        name: 'most searched',
        first: (c) => c.getMostSearchingProduct(1),
        second: (c) => c.getMostSearchingProduct(2),
        shown: (c) => c.mostSearchingProduct?.products,
        label: 'mostSearching',
      ),
      (
        name: 'clearance',
        first: (c) => c.getClearanceAllProductList(1),
        second: (c) => c.getClearanceAllProductList(2),
        shown: (c) => c.clearanceProductModel?.products,
        label: 'clearance',
      ),
    ]) {
      test(
          'is not added to the ${loader.name} products of the storefront they are on',
          () async {
        final _FakeProductService service = _FakeProductService();
        final ProductController controller =
            ProductController(productServiceInterface: service);
        await loader.first(controller);
        await pumpEventQueue();
        expect(loader.shown(controller), isNotNull, reason: 'page one loaded');
        final Completer<void> hold = Completer<void>();
        service.holdSecondPage = hold;
        addTearDown(() {
          if (!hold.isCompleted) hold.complete();
        });

        final Future<void> paging = loader.second(controller);
        await pumpEventQueue();
        await moveTo(controller);
        hold.complete();
        await paging;
        await pumpEventQueue();

        // A list that belongs to one screen is dropped and not loaded again, and the most searched list is, in the code as it is, always
        // replaced by an empty one after its first page.
        final Map<String, List<String?>?> expectedByLoader =
            <String, List<String?>?>{
          'every product of a type': null,
          'most searched': <String?>[],
        };
        expect(
          loader.shown(controller)?.map((p) => p.name).toList(),
          expectedByLoader.containsKey(loader.name)
              ? expectedByLoader[loader.name]
              : <String?>['${loader.label} of AE'],
        );
      });
    }

    test(
        'is not added to the list of every product of a type that a screen opened for the storefront they are on',
        () async {
      final _FakeProductService service = _FakeProductService();
      final ProductController controller =
          ProductController(productServiceInterface: service);
      await controller.getAllProductModelByType(
          offset: 1, type: ProductType.latestProduct);
      await pumpEventQueue();
      final Completer<void> hold = Completer<void>();
      service.holdSecondPage = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      final Future<void> paging = controller.getAllProductModelByType(
          offset: 2, type: ProductType.latestProduct);
      await pumpEventQueue();
      await moveTo(controller);
      // The change drops the list and loads nothing in its place: it belongs to a screen. This one is opened on the new storefront before
      // the page of the old one comes in.
      await controller.getAllProductModelByType(
          offset: 1, type: ProductType.latestProduct);
      await pumpEventQueue();
      hold.complete();
      await paging;
      await pumpEventQueue();

      expect(controller.allProductModel?.products?.map((p) => p.name),
          <String?>['latestProduct of AE']);
    });

    for (final ({
      String name,
      Future<void> Function(ShopController) first,
      Future<void> Function(ShopController) second,
      List<Seller>? Function(ShopController) shown,
      String label,
    }) loader in <({
      String name,
      Future<void> Function(ShopController) first,
      Future<void> Function(ShopController) second,
      List<Seller>? Function(ShopController) shown,
      String label,
    })>[
      (
        name: 'top',
        first: (c) => c.getTopSellerList(offset: 1),
        second: (c) => c.getTopSellerList(offset: 2),
        shown: (c) => c.topSellerModel?.sellers,
        label: 'top',
      ),
      (
        name: 'filtered',
        first: (c) => c.getFilteredSellerList(type: 'new', offset: 1),
        second: (c) => c.getFilteredSellerList(type: 'new', offset: 2),
        shown: (c) => c.filteredSellerModel?.sellers,
        label: 'top',
      ),
      (
        name: 'all',
        first: (c) => c.getAllSellerList(offset: 1),
        second: (c) => c.getAllSellerList(offset: 2),
        shown: (c) => c.allSellerModel?.sellers,
        label: 'all',
      ),
    ]) {
      test(
          'is not added to the ${loader.name} shops of the storefront they are on',
          () async {
        final _FakeShopService service = _FakeShopService();
        final ShopController controller =
            ShopController(shopServiceInterface: service);
        await loader.first(controller);
        await pumpEventQueue();
        expect(loader.shown(controller), isNotNull, reason: 'page one loaded');
        final Completer<void> hold = Completer<void>();
        service.holdSecondPage = hold;
        addTearDown(() {
          if (!hold.isCompleted) hold.complete();
        });

        final Future<void> paging = loader.second(controller);
        await pumpEventQueue();
        await moveTo(controller);
        hold.complete();
        await paging;
        await pumpEventQueue();

        expect(loader.shown(controller)?.map((s) => s.fName),
            <String?>['${loader.label} seller of AE']);
      });
    }
  });
}
