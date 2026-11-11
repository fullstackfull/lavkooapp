import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/services/analytics_reporter.dart';
import 'package:syriapharmacy/features/banner/domain/models/banner_model.dart';
import 'package:syriapharmacy/features/banner/domain/services/banner_service_interface.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/helper/data_sync_helper.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/helper/route_healper.dart';

class BannerController extends ChangeNotifier {
  final BannerServiceInterface? bannerServiceInterface;
  BannerController({required this.bannerServiceInterface});

  /// One destination vocabulary for the whole app: a banner from the dashboard and a banner placed
  /// by the theme builder are the same tap.
  static const ThemeActionResolver _actions = ThemeActionResolver();

  List<BannerModel>? _mainBannerList;
  List<BannerModel>? _footerBannerList;
  BannerModel? mainSectionBanner;
  BannerModel? sideBarBanner;
  Product? _product;
  int? _currentIndex;
  int? _footerBannerIndex;
  List<BannerModel>? get mainBannerList => _mainBannerList;
  List<BannerModel>? get footerBannerList => _footerBannerList;

  Product? get product => _product;
  int? get currentIndex => _currentIndex;
  int? get footerBannerIndex => _footerBannerIndex;

  BannerModel? promoBannerMiddleTop;
  BannerModel? promoBannerRight;
  BannerModel? promoBannerMiddleBottom;
  BannerModel? promoBannerLeft;
  BannerModel? promoBannerBottom;
  BannerModel? sideBarBannerBottom;
  BannerModel? topSideBarBannerBottom;

  Future<void> getBannerList() async {
    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () =>
          bannerServiceInterface!.getList(source: DataSourceEnum.local),
      fetchFromClient: () =>
          bannerServiceInterface!.getList(source: DataSourceEnum.client),
      onResponse: (data, _) {
        _mainBannerList = [];
        _footerBannerList = [];

        data.forEach((bannerModel) {
          if (bannerModel['banner_type'] == 'Main Banner') {
            _mainBannerList!.add(BannerModel.fromJson(bannerModel));
          } else if (bannerModel['banner_type'] == 'Promo Banner Middle Top') {
            promoBannerMiddleTop = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] == 'Promo Banner Right') {
            promoBannerRight = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] ==
              'Promo Banner Middle Bottom') {
            promoBannerMiddleBottom = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] == 'Promo Banner Bottom') {
            promoBannerBottom = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] == 'Promo Banner Left') {
            promoBannerLeft = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] == 'Sidebar Banner') {
            sideBarBanner = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] == 'Top Side Banner') {
            topSideBarBannerBottom = BannerModel.fromJson(bannerModel);
          } else if (bannerModel['banner_type'] == 'Footer Banner') {
            _footerBannerList?.add(BannerModel.fromJson(bannerModel));
          } else if (bannerModel['banner_type'] == 'Main Section Banner') {
            mainSectionBanner = BannerModel.fromJson(bannerModel);
          }
        });

        _currentIndex = 0;
        _footerBannerIndex = 0;

        notifyListeners();
      },
    );
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void onChangeFooterBannerIndex(int index) {
    _footerBannerIndex = index;
    notifyListeners();
  }

  /// Open what a banner points at.
  ///
  /// The shop resolves every banner's link into a typed action — the same one the theme sections
  /// carry — so this is one line for every banner in the app. What it replaces was the reason a
  /// banner pointing at a category or a shop often did nothing at all: the old code looked the id
  /// up in whichever list happened to be cached, and a list that had not loaded yet turned the tap
  /// into a silent no-op.
  ///
  /// [_openFromResource] is the fallback for a shop too old to send an action.
  void openBanner(BuildContext context, BannerModel? banner) {
    if (banner == null) return;

    // Counted before the navigation, not after: the tap is the thing being measured, and whatever
    // happens next — a screen, a browser, nothing at all — must not change whether it was counted.
    AnalyticsReporter.bannerClicked(banner.id);

    final action = banner.action;

    if (action != null && _actions.isNavigable(action)) {
      _actions.go(context, action);
      return;
    }

    _openFromResource(context, banner);
  }

  /// The pre-action contract: a resource type and an id, or a bare url.
  ///
  /// Every branch navigates on the id alone. The destination screens fetch what they need, so
  /// needing a cached list here was never a requirement — only a bug.
  void _openFromResource(BuildContext context, BannerModel banner) {
    final id = banner.resourceId;

    switch (banner.resourceType) {
      case 'product':
        final product = banner.product;
        if (product == null && id == null) return;
        RouterHelper.getProductDetailsRoute(
          action: RouteAction.push,
          productId: product?.id ?? id,
          slug: product?.slug,
        );

      case 'category' when id != null:
        RouterHelper.getBrandCategoryRoute(
          action: RouteAction.push,
          isBrand: false,
          id: id,
          name: _nameOf(context, id, isBrand: false),
        );

      case 'brand' when id != null:
        RouterHelper.getBrandCategoryRoute(
          action: RouteAction.push,
          isBrand: true,
          id: id,
          name: _nameOf(context, id, isBrand: true),
        );

      case 'shop' when id != null:
        _openShop(context, id);

      default:
        // Anything else is the merchant's own link: the gateway asks the shop what it means and
        // opens the screen behind it, or the browser when it is not one of ours.
        final url = banner.url;
        if (url != null && url.isNotEmpty) {
          RouterHelper.getDeepLinkRoute(action: RouteAction.push, link: url);
        }
    }
  }

  /// A cached display name for the screen's title bar, when one happens to be loaded. Absent is
  /// fine — the destination screen shows what it fetched.
  String? _nameOf(BuildContext context, int id, {required bool isBrand}) {
    if (isBrand) {
      final brands = Provider.of<BrandController>(context, listen: false).brandList;
      final index = brands.indexWhere((brand) => brand.id == id);
      return index == -1 ? null : brands[index].name;
    }

    final categories =
        Provider.of<CategoryController>(context, listen: false).categoryList;
    final index = categories.indexWhere((category) => category.id == id);
    return index == -1 ? null : categories[index].name;
  }

  void _openShop(BuildContext context, int id) {
    final sellers =
        Provider.of<ShopController>(context, listen: false).allSellerModel?.sellers;
    final index = sellers?.indexWhere((seller) => seller.id == id) ?? -1;
    final shop = index == -1 ? null : sellers?[index].shop;

    RouterHelper.getTopSellerRoute(
      action: RouteAction.push,
      slug: shop?.slug ?? '',
      sellerId: id,
      temporaryClose: shop?.temporaryClose,
      vacationStatus: shop?.vacationStatus,
      vacationEndDate: shop?.vacationEndDate,
      vacationStartDate: shop?.vacationStartDate,
      vacationDurationType: shop?.vacationDurationType,
      name: shop?.name,
      banner: shop?.bannerFullUrl?.path,
      image: shop?.imageFullUrl?.path,
    );
  }
}
