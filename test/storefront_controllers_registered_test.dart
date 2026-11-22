import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/domain/services/banner_service_interface.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:syriapharmacy/features/brand/domain/repositories/brand_repository.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/cart/domain/services/cart_service_interface.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/domain/services/category_service_interface.dart';
import 'package:syriapharmacy/features/compare/controllers/compare_controller.dart';
import 'package:syriapharmacy/features/compare/domain/services/compare_service_interface.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:syriapharmacy/features/deal/controllers/featured_deal_controller.dart';
import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/deal/domain/services/featured_deal_service_interface.dart';
import 'package:syriapharmacy/features/deal/domain/services/flash_deal_service_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';
import 'package:syriapharmacy/features/loyaltyPoint/controllers/loyalty_point_controller.dart';
import 'package:syriapharmacy/features/loyaltyPoint/domain/services/loyalty_point_service_interface.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/features/product/domain/services/product_service_interface.dart';
import 'package:syriapharmacy/features/product/domain/services/seller_product_service_interface.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/product_details/domain/services/product_details_service_interface.dart';
import 'package:syriapharmacy/features/restock/controllers/restock_controller.dart';
import 'package:syriapharmacy/features/restock/domain/services/restock_service_interface.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/features/search_product/domain/services/search_product_service_interface.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/features/shipping/domain/services/shipping_service_interface.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/shop/domain/services/shop_service_interface.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/services/splash_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/wallet/controllers/wallet_controller.dart';
import 'package:syriapharmacy/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:syriapharmacy/features/wishlist/domain/services/wishlist_service_interface.dart';

class _BannerService extends Fake implements BannerServiceInterface {}

class _BrandRepository extends Fake implements BrandRepository {}

class _CartService extends Fake implements CartServiceInterface {}

class _CategoryService extends Fake implements CategoryServiceInterface {}

class _CompareService extends Fake implements CompareServiceInterface {}

class _CouponService extends Fake implements CouponServiceInterface {}

class _FeaturedDealService extends Fake
    implements FeaturedDealServiceInterface {}

class _FlashDealService extends Fake implements FlashDealServiceInterface {}

class _ThemeService extends Fake implements DynamicThemeServiceInterface {}

class _ProductService extends Fake implements ProductServiceInterface {}

class _SellerProductService extends Fake
    implements SellerProductServiceInterface {}

class _ProductDetailsService extends Fake
    implements ProductDetailsServiceInterface {}

class _RestockService extends Fake implements RestockServiceInterface {}

class _SearchService extends Fake implements SearchProductServiceInterface {}

class _ShippingService extends Fake implements ShippingServiceInterface {}

class _ShopService extends Fake implements ShopServiceInterface {}

class _SplashService extends Fake implements SplashServiceInterface {}

class _LoyaltyPointService extends Fake
    implements LoyaltyPointServiceInterface {}

class _WalletService extends Fake implements WalletServiceInterface {}

class _WishlistService extends Fake implements WishlistServiceInterface {}

/// Every controller that holds what a storefront decides is built by the container with the notifier, joins it when it is built and
/// leaves it when it is disposed. The inventory test pins which controllers those are; this one pins that each of them really does it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, ChangeNotifier Function(StorefrontChangeNotifier)> builds =
      <String, ChangeNotifier Function(StorefrontChangeNotifier)>{
    'BannerController': (StorefrontChangeNotifier notifier) => BannerController(
        bannerServiceInterface: _BannerService(),
        storefrontChangeNotifier: notifier),
    'BrandController': (StorefrontChangeNotifier notifier) => BrandController(
        brandRepo: _BrandRepository(), storefrontChangeNotifier: notifier),
    'CartController': (StorefrontChangeNotifier notifier) => CartController(
        cartServiceInterface: _CartService(),
        storefrontChangeNotifier: notifier),
    'CategoryController': (StorefrontChangeNotifier notifier) =>
        CategoryController(
            categoryServiceInterface: _CategoryService(),
            storefrontChangeNotifier: notifier),
    'CompareController': (StorefrontChangeNotifier notifier) =>
        CompareController(
            compareServiceInterface: _CompareService(),
            storefrontChangeNotifier: notifier),
    'CouponController': (StorefrontChangeNotifier notifier) => CouponController(
        couponRepo: _CouponService(), storefrontChangeNotifier: notifier),
    'FeaturedDealController': (StorefrontChangeNotifier notifier) =>
        FeaturedDealController(
            featuredDealServiceInterface: _FeaturedDealService(),
            storefrontChangeNotifier: notifier),
    'FlashDealController': (StorefrontChangeNotifier notifier) =>
        FlashDealController(
            flashDealServiceInterface: _FlashDealService(),
            storefrontChangeNotifier: notifier),
    'DynamicThemeController': (StorefrontChangeNotifier notifier) =>
        DynamicThemeController(
            dynamicThemeServiceInterface: _ThemeService(),
            storefrontChangeNotifier: notifier),
    'ProductController': (StorefrontChangeNotifier notifier) =>
        ProductController(
            productServiceInterface: _ProductService(),
            storefrontChangeNotifier: notifier),
    'SellerProductController': (StorefrontChangeNotifier notifier) =>
        SellerProductController(
            sellerProductServiceInterface: _SellerProductService(),
            storefrontChangeNotifier: notifier),
    'ProductDetailsController': (StorefrontChangeNotifier notifier) =>
        ProductDetailsController(
            productDetailsServiceInterface: _ProductDetailsService(),
            storefrontChangeNotifier: notifier),
    'RestockController': (StorefrontChangeNotifier notifier) =>
        RestockController(
            restockServiceInterface: _RestockService(),
            storefrontChangeNotifier: notifier),
    'SearchProductController': (StorefrontChangeNotifier notifier) =>
        SearchProductController(
            searchProductServiceInterface: _SearchService(),
            storefrontChangeNotifier: notifier),
    'ShippingController': (StorefrontChangeNotifier notifier) =>
        ShippingController(
            shippingServiceInterface: _ShippingService(),
            storefrontChangeNotifier: notifier),
    'ShopController': (StorefrontChangeNotifier notifier) => ShopController(
        shopServiceInterface: _ShopService(),
        storefrontChangeNotifier: notifier),
    'SplashController': (StorefrontChangeNotifier notifier) => SplashController(
        splashServiceInterface: _SplashService(),
        storefrontChangeNotifier: notifier),
    'LoyaltyPointController': (StorefrontChangeNotifier notifier) =>
        LoyaltyPointController(
            loyaltyPointServiceInterface: _LoyaltyPointService(),
            storefrontChangeNotifier: notifier),
    'WalletController': (StorefrontChangeNotifier notifier) => WalletController(
        walletServiceInterface: _WalletService(),
        storefrontChangeNotifier: notifier),
    'WishListController': (StorefrontChangeNotifier notifier) =>
        WishListController(
            wishlistServiceInterface: _WishlistService(),
            storefrontChangeNotifier: notifier),
  };

  StorefrontChangeNotifier notifier() => StorefrontChangeNotifier(
        clearHttpCache: (String code) {},
        clearLocalCache: (String code) async {},
        isSignedIn: () => false,
        enabled: true,
      );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  for (final MapEntry<String,
          ChangeNotifier Function(StorefrontChangeNotifier)> build
      in builds.entries) {
    test('${build.key} joins the notifier when built and leaves when disposed',
        () async {
      final StorefrontChangeNotifier subject = notifier();

      final ChangeNotifier controller = build.value(subject);
      // A controller may finish something it started when it was built (the splash controller reads a preference): not after it is gone.
      await pumpEventQueue();
      expect(controller, isA<StorefrontChangeListener>());
      expect(subject.listenerCount, 1);

      controller.dispose();
      expect(subject.listenerCount, 0);
    });
  }

  test('every one of them is the one the inventory says is told', () {
    expect(builds, hasLength(20));
  });

  test(
      'the config of the shop is left alone when the app has no screen to read it with',
      () async {
    final SplashController controller =
        SplashController(splashServiceInterface: _SplashService());

    await controller.onStorefrontChanged(const StorefrontChange(
      previous: StorefrontCountry.saudiArabia,
      current: StorefrontCountry.kuwait,
      signedIn: false,
    ));

    expect(controller.configModel, isNull);
  });
}
