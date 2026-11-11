import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/widgets/banners_widget.dart';
import 'package:syriapharmacy/features/banner/widgets/footer_banner_slider_widget.dart';
import 'package:syriapharmacy/features/banner/widgets/single_banner_widget.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:syriapharmacy/features/brand/widgets/brand_list_widget.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/widgets/category_list_widget.dart';
import 'package:syriapharmacy/features/clearance_sale/widgets/clearance_sale_list_widget.dart';
import 'package:syriapharmacy/features/deal/controllers/featured_deal_controller.dart';
import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/deal/widgets/featured_deal_list_widget.dart';
import 'package:syriapharmacy/features/deal/widgets/flash_deals_list_widget.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/screens/dynamic_home_view.dart';
import 'package:syriapharmacy/features/home/shimmers/flash_deal_shimmer.dart';
import 'package:syriapharmacy/features/home/widgets/aster_theme/find_what_you_need_shimmer.dart';
import 'package:syriapharmacy/features/home/widgets/featured_product_widget.dart';
import 'package:syriapharmacy/features/home/widgets/product_list_widget.dart';
import 'package:syriapharmacy/features/home/widgets/product_type_popup_menu_widget.dart';
import 'package:syriapharmacy/features/notification/controllers/notification_controller.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/widgets/home_category_product_widget.dart';
import 'package:syriapharmacy/features/product/widgets/latest_product_list_widget.dart';
import 'package:syriapharmacy/features/product/widgets/recommended_product_widget.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/features/home/widgets/top_seller_widget.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/chat/controllers/chat_controller.dart';
import 'package:syriapharmacy/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:syriapharmacy/helper/shop_helper.dart';

import '../../../data/datasource/remote/dio/dio_client.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  static Future<void> loadData(bool reload) async {
    // The themed home syncs on the same triggers as everything else here; costs one version
    // request when nothing changed, and nothing at all decides to render before it answers.
    final dynamicThemeController =
        Provider.of<DynamicThemeController>(Get.context!, listen: false);
    dynamicThemeController.sync(force: reload);

    // With a published theme the legacy home widgets are not in the tree, so the fetches that
    // exist only to feed them are pure network waste on every refresh. Read synchronously: at a
    // cold start this is still false (the sync above has not answered yet), so the legacy data
    // loads once as before and the fallback home is never empty; the saving applies to every
    // pull-to-refresh and resume after that. Anything another tab can read keeps loading always.
    final bool themedHome = dynamicThemeController.hasPublishedTheme;

    final flashDealController =
    Provider.of<FlashDealController>(Get.context!, listen: false);
    final shopController =
    Provider.of<ShopController>(Get.context!, listen: false);
    final categoryController =
    Provider.of<CategoryController>(Get.context!, listen: false);
    final bannerController =
    Provider.of<BannerController>(Get.context!, listen: false);
    final addressController =
    Provider.of<AddressController>(Get.context!, listen: false);
    final productController =
    Provider.of<ProductController>(Get.context!, listen: false);
    final brandController =
    Provider.of<BrandController>(Get.context!, listen: false);
    final featuredDealController =
    Provider.of<FeaturedDealController>(Get.context!, listen: false);
    final notificationController =
    Provider.of<NotificationController>(Get.context!, listen: false);
    final cartController =
    Provider.of<CartController>(Get.context!, listen: false);
    final profileController =
    Provider.of<ProfileController>(Get.context!, listen: false);
    final splashController =
    Provider.of<SplashController>(Get.context!, listen: false);

    if (flashDealController.flashDealList.isEmpty || reload) {
      // await flashDealController.getFlashDealList(reload, false);
    }

    splashController.initConfig(Get.context!, null, null);


    categoryController.getCategoryList(reload);

    bannerController.getBannerList();

    addressController.getAddressList();

    cartController.getCartData(Get.context!);

    brandController.getBrandList(offset: 1, isUpdate: reload);

    featuredDealController.getFeaturedDealList();

    if (!themedHome) {
      if (categoryController.categoryList.isNotEmpty) {
        for (var category in categoryController.categoryList.take(5)) {
          categoryController.getCategoryPageHeaderData(category.id!);
        }
      }

      shopController.getAllSellerList(offset: 1, isUpdate: reload);
      shopController.getTopSellerList(offset: 1, isUpdate: reload);

      productController.getHomeCategoryProductList(reload);

      productController.getLatestProductList(1, isUpdate: reload);
      productController.getSelectedProductModel(1, isUpdate: reload);

      productController.getFeaturedProductModel(1, isUpdate: reload);

      productController.getRecommendedProduct();

      productController.getClearanceAllProductList(1, isUpdate: reload);
    }

    if (notificationController.notificationModel == null ||
        (notificationController.notificationModel != null &&
            notificationController.notificationModel!.notification!.isEmpty) ||
        reload) {
      notificationController.getNotificationList(1);
    }

    if (Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn() &&
        profileController.userInfoModel == null) {
      await profileController.getUserInfo(Get.context!);
    }
  }
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  void passData(int index, String title) {
    index = index;
    title = title;
  }

  bool singleVendor = false;
  @override
  void initState() {
    super.initState();

    singleVendor = Provider.of<SplashController>(context, listen: false)
        .configModel
        ?.businessMode ==
        "single";
  }

  @override
  Widget build(BuildContext context) {
    // One switch decides the whole page body: with a published theme the home CONTENT -
    // banner, categories, rails - comes exclusively from the Theme Builder, and the only
    // thing the old code still draws is the app's own header. Without one, the page is
    // exactly the app's original home. Never both: two banner sliders is a bug.
    final bool useThemedHome =
        context.watch<DynamicThemeController>().hasPublishedTheme;

    final ConfigModel? configModel =
        Provider.of<SplashController>(context, listen: true).configModel;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
            showModalBottomSheet(
              context: context,
              builder: (context) => const NotLoggedInBottomSheetWidget(),
            );
          } else {
            final configModel = Provider.of<SplashController>(context, listen: false).configModel;
            final bool isVacationActive = ShopHelper.isVacationActive(
              context,
              startDate: configModel?.inhouseVacationAdd?.vacationStartDate,
              endDate: configModel?.inhouseVacationAdd?.vacationEndDate,
              vacationDurationType: configModel?.inhouseVacationAdd?.vacationDurationType,
              vacationStatus: configModel?.inhouseVacationAdd?.status == 1,
              isInHouseSeller: true,
            );

            Provider.of<ChatController>(context, listen: false).setUserTypeIndex(context, 1);
            RouterHelper.getChatScreenRoute(
              action: RouteAction.push,
              id: 0,
              name: configModel?.inHouseShop?.name ?? '',
              userType: 1,
              image: configModel?.inHouseShop?.imageFullUrl?.path ?? '',
              isShopOnVacation: isVacationActive,
              isShopTemporaryClosed: configModel?.inhouseTemporaryClose?.status ?? false,
            );
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        // elevation: 4,
        shape: const CircleBorder(),
        child: Lottie.asset(
          'assets/lottie/chat.json',
          width: 45,
          height: 45,
          repeat: true,
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  DioClient.clearMemoryCache();  // ← امسح Memory فقط
                  await HomePage.loadData(true);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // SliverAppBar(
                    //   floating: true,
                    //   snap: true,
                    //   elevation: 0,
                    //   centerTitle: true,
                    //   automaticallyImplyLeading: false,
                    //   backgroundColor: Colors.transparent,
                    //   titleSpacing: 0,
                    //   leadingWidth: 70,
                    //   leading: Center(
                    //     child: Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 16),
                    //       child: _HeaderActionButton(
                    //         icon: Icons.menu_rounded,
                    //         onTap: () => ZoomDrawer.of(context)?.toggle(),
                    //       ),
                    //     ),
                    //   ),
                    //   actions: [
                    //     _HeaderActionButton(
                    //       icon: Icons.search_rounded,
                    //       onTap: () =>
                    //           RouterHelper.getSearchRoute(action: RouteAction.push),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     _HeaderActionButton(
                    //       icon: Icons.notifications_none_outlined,
                    //       onTap: () => RouterHelper.getNotificationRoute(
                    //           action: RouteAction.push),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     _HeaderActionButton(
                    //       icon: Icons.shopping_cart_outlined,
                    //       onTap: () => RouterHelper.getCartScreenRoute(
                    //           action: RouteAction.push),
                    //       showBadge: true,
                    //     ),
                    //     const SizedBox(width: 25),
                    //   ],
                    // ),
                    //
                    // SliverToBoxAdapter(
                    //   child: BannersWidget().animateSectionEntrance(index: 2),
                    // ),
                    // SliverToBoxAdapter(
                    //   child: CategoryListWidget(isHomePage: true)
                    //       .animateSectionEntrance(index: 3),
                    // ),
                    SliverToBoxAdapter(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (!useThemedHome)
                            BannersWidget().animateSectionEntrance(index: 2),

                          // الهيدر فوق البنر - يبقى دائما. مع ثيم منشور البنر تحته يختفي،
                          // فيأخذ الهيدر خلفية التدرج المعتمد (بنفسجي ← أزرق 140°) ويجلس
                          // البحث داخله كبطاقة بيضاء، كما في التصميم المعتمد Direction B.
                          Container(
                            decoration: useThemedHome
                                ? const BoxDecoration(
                                    gradient: BrandGradients.primary,
                                    borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(18)),
                                  )
                                : null,
                            child: SafeArea(
                            top: useThemedHome,
                            bottom: false,
                            child: Padding(
                              padding: useThemedHome
                                  ? const EdgeInsets.fromLTRB(16, 12, 16, 16)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 60),
                              child: Column(children: [
                                if (useThemedHome) ...[
                                  // صف الهوية المعتمد: شعار + اسم المتجر +
                                  // «التوصيل إلى» فوق البحث، وبجانبه المفضلة
                                  // والسلة بعدّادها والإشعارات والقائمة.
                                  Row(children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.35)),
                                      ),
                                      // The mark the launch sequence lands on:
                                      // the butterfly alone, legible at 30px,
                                      // where the full lockup was unreadable.
                                      child: SvgPicture.asset(
                                          'assets/launch/butterfly_mono_white.svg',
                                          fit: BoxFit.contain),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Provider.of<SplashController>(
                                                        context,
                                                        listen: false)
                                                    .configModel
                                                    ?.companyName ??
                                                AppConstants.appName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: tajawalHeavy.copyWith(
                                                fontSize: 13.5,
                                                color: Colors.white),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                RouterHelper
                                                    .getAddressListScreen(
                                                        action:
                                                            RouteAction.push),
                                            child: Consumer<AddressController>(
                                                builder: (context, address,
                                                    child) {
                                              final String? city = (address
                                                              .addressList
                                                              ?.isNotEmpty ??
                                                          false)
                                                  ? address
                                                      .addressList![address
                                                                  .selectAddressIndex <
                                                              address
                                                                  .addressList!
                                                                  .length
                                                          ? address
                                                              .selectAddressIndex
                                                          : 0]
                                                      .city
                                                  : null;
                                              return Text(
                                                city != null
                                                    ? '${getTranslated('delivery_to', context)}: $city ▾'
                                                    : '${getTranslated('select_delivery_address', context)} ▾',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textRegular.copyWith(
                                                    fontSize: 9.5,
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.85)),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _HeaderActionButton(
                                      icon: Icons.favorite_border_rounded,
                                      onGradient: true,
                                      onTap: () => RouterHelper.getWishListRoute(
                                          action: RouteAction.push),
                                    ),
                                    const SizedBox(width: 4),
                                    _HeaderActionButton(
                                      icon: Icons.shopping_cart_outlined,
                                      onGradient: true,
                                      showBadge: true,
                                      onTap: () =>
                                          RouterHelper.getCartScreenRoute(
                                              action: RouteAction.push),
                                    ),
                                    // Notifications live in the account hub with
                                    // the orders and the addresses. A fifth icon
                                    // here squeezed the brand name to an ellipsis
                                    // on a 360dp handset, and the name is what
                                    // the approved header is built around.
                                    const SizedBox(width: 4),
                                    // The account hub: orders, profile, addresses,
                                    // coupons, the policies, support — and the
                                    // language and currency inside it. The tab
                                    // that held all of it went when the bar was
                                    // cut to the approved four, and the screen
                                    // was left in the codebase reachable by
                                    // nothing at all.
                                    _HeaderActionButton(
                                      icon: Icons.person_outline_rounded,
                                      onGradient: true,
                                      onTap: () => RouterHelper.getMoreRoute(
                                          action: RouteAction.push),
                                    ),
                                    const SizedBox(width: 4),
                                    _HeaderActionButton(
                                      icon: Icons.menu_rounded,
                                      onGradient: true,
                                      onTap: () =>
                                          ZoomDrawer.of(context)?.toggle(),
                                    ),
                                  ]),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    // حقل البحث — بطاقة بيضاء بعرض كامل
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => RouterHelper.getSearchRoute(action: RouteAction.push),
                                      borderRadius: BorderRadius.circular(12),
                                      // بطاقة البحث البيضاء المعتمدة: حقل أبيض مصمت
                                      // بأيقونة بنفسجية فوق تدرج الهيدر.
                                      child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: BrandColors.ink.withValues(alpha: 0.18),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.search_rounded,
                                              size: 18,
                                              color: BrandColors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              getTranslated('search_products_hint', context) ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: BrandColors.mutedText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                    if (!useThemedHome) ...[
                                      const SizedBox(width: 4),
                                      _HeaderActionButton(
                                        icon:
                                            Icons.notifications_none_outlined,
                                        onTap: () =>
                                            RouterHelper.getNotificationRoute(
                                                action: RouteAction.push),
                                      ),
                                      const SizedBox(width: 4),
                                      _HeaderActionButton(
                                        icon: Icons.menu_rounded,
                                        onTap: () =>
                                            ZoomDrawer.of(context)?.toggle(),
                                      ),
                                    ],
                                  ],
                                ),
                              ]),
                            ),
                          ),
                          ),

                          // الكاتيغوري معلق تحت البنر
                          // الكاتيغوري معلق تحت البنر مع خلفية زجاجية (blur)
                          if (!useThemedHome)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -80,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                              child: Container(
                                decoration: BoxDecoration(
                                  // شفافية بالكامل تقريباً مع لمسة بسيطة جداً
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black.withValues(alpha: 0.02)
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                                child: CategoryListWidget(isHomePage: true)
                                    .animateSectionEntrance(index: 3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // const SliverToBoxAdapter(child: SizedBox(height: 90)),

                    // The Theme Builder controls the home CONTENT only: when a theme is
                    // published, the composed sections replace everything from here down, while
                    // the header, search, drawer and navigation above stay exactly the app's own.
                    ...(useThemedHome
                        ? const <Widget>[
                            SliverToBoxAdapter(child: DynamicHomeSections()),
                            SliverToBoxAdapter(child: SizedBox(height: 120)),
                          ]
                        : <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Consumer<FlashDealController>(
                              builder: (context, megaDeal, child) {
                                return megaDeal.flashDeal == null
                                    ? const FlashDealShimmer()
                                    : (megaDeal.flashDealList.isNotEmpty &&
                                            (megaDeal.duration ??
                                                    Duration.zero) >
                                                Duration.zero)
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                      Dimensions.paddingSizeDefault),
                                  // The approved composition: one blue→magenta
                                  // field carrying the bar, the countdown and
                                  // the white deal cards together.
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: BrandGradients.flash,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.only(
                                        bottom: Dimensions.paddingSizeSmall),
                                    child: Column(children: [
                                      FlashDealBar(
                                        title: getTranslated(
                                            'flash_deal', context)!
                                            .toUpperCase(),
                                        embedded: true,
                                        eventDuration:
                                        megaDeal.flashDeal != null
                                            ? megaDeal.duration
                                            : null,
                                        onTap: () {
                                          RouterHelper
                                              .getFlashDealScreenViewRoute();
                                        },
                                      ),
                                      const FlashDealsListWidget(),
                                    ]),
                                  ),
                                )
                                    : const SizedBox.shrink();
                              }),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        ],
                      ).animateSectionEntrance(index: 4),
                    ),
                    SliverToBoxAdapter(
                      child: Consumer<FeaturedDealController>(
                          builder: (context, featuredDealProvider, child) {
                            return featuredDealProvider.featuredDealProductList != null
                                ? featuredDealProvider
                                .featuredDealProductList!.isNotEmpty
                                ? Column(
                              children: [
                                Column(children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical:
                                        Dimensions.paddingSizeDefault),
                                    child: TitleRowWidget(
                                      title:
                                      '${getTranslated('featured_deals', context)}',
                                      onTap: () {
                                        RouterHelper
                                            .getFeaturedDealScreenViewRoute();
                                      },
                                    ),
                                  ),
                                  const FeaturedDealsListWidget(),
                                ]),
                                const SizedBox(
                                    height: Dimensions.paddingSizeDefault),
                              ],
                            )
                                : const SizedBox.shrink()
                                : const FindWhatYouNeedShimmer();
                          }).animateSectionEntrance(index: 5),
                    ),
                    SliverToBoxAdapter(
                      child: const ClearanceListWidget()
                          .animateSectionEntrance(index: 6),
                    ),
                    SliverToBoxAdapter(
                        child: SizedBox(height: Dimensions.paddingSizeDefault)),
                    SliverToBoxAdapter(
                      child: const FeaturedProductWidget()
                          .animateSectionEntrance(index: 8),
                    ),
                    SliverToBoxAdapter(
                        child: SizedBox(height: Dimensions.paddingSizeDefault)),
                    if (!singleVendor)
                      SliverToBoxAdapter(
                        child: Container(
                          padding:
                          EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                          child: Column(
                            children: [
                              Consumer<ShopController>(
                                  builder: (context, topSellerProvider, child) {
                                    return (topSellerProvider.topSellerModel != null &&
                                        (topSellerProvider
                                            .topSellerModel!.sellers !=
                                            null &&
                                            topSellerProvider.topSellerModel!
                                                .sellers!.isNotEmpty))
                                        ? TitleRowWidget(
                                        title: getTranslated('top_seller', context),
                                        onTap: () =>
                                            RouterHelper.getAllTopSellerRoute(
                                                action: RouteAction.push,
                                                title: 'top_seller'))
                                        : const SizedBox();
                                  }),
                              singleVendor
                                  ? const SizedBox(height: 0)
                                  : const SizedBox(
                                  height: Dimensions.paddingSizeSmall),
                              singleVendor
                                  ? const SizedBox()
                                  : Consumer<ShopController>(
                                  builder: (context, topSellerProvider, child) {
                                    return (topSellerProvider.topSellerModel !=
                                        null &&
                                        (topSellerProvider.topSellerModel!
                                            .sellers !=
                                            null &&
                                            topSellerProvider.topSellerModel!
                                                .sellers!.isNotEmpty))
                                        ? Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: Dimensions
                                                .paddingSizeDefault),
                                        child: SizedBox(
                                            height: ResponsiveHelper.isTab(
                                                context)
                                                ? 170
                                                : 150,
                                            child: const TopSellerWidget()))
                                        : const SizedBox();
                                  })
                            ],
                          ),
                        ).animateSectionEntrance(index: 9),
                      ),
                    if (!singleVendor)
                      SliverToBoxAdapter(
                          child: SizedBox(height: Dimensions.paddingSizeDefault)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: RecommendedProductWidget()
                            .animateSectionEntrance(index: 10),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Consumer<BannerController>(
                          builder: (context, footerBannerProvider, child) {
                            return footerBannerProvider.footerBannerList != null &&
                                footerBannerProvider.footerBannerList!.isNotEmpty
                                ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault),
                                child: SingleBannersWidget(
                                    bannerModel:
                                    footerBannerProvider.footerBannerList?[0]))
                                : const SizedBox();
                          }).animateSectionEntrance(index: 7),
                    ),
                    SliverToBoxAdapter(
                        child: SizedBox(height: Dimensions.paddingSizeDefault)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: LatestProductListWidget()
                            .animateSectionEntrance(index: 11),
                      ),
                    ),

                    const HomeCategoryProductWidget(isHomePage: true),

                    SliverToBoxAdapter(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((Provider.of<BannerController>(context,
                                listen: false)
                                .footerBannerList
                                ?.length ??
                                0) >
                                1)
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                            const FooterBannerSliderWidget(),
                          ]).animateSectionEntrance(index: 13),
                    ),
                    if (configModel!.brandSetting == "1")
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const BrandListWidget(isHomePage: true),
                            const SizedBox(height: Dimensions.paddingSizeDefault),
                          ],
                        ).animateSectionEntrance(index: 12),
                      ),
                    SliverPersistentHeader(
                        pinned: true,
                        delegate: SliverDelegate(
                          height: 50,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                child: const ProductPopupFilterWidget()),
                          ),
                        )),
                    HomeProductListWidget(scrollController: _scrollController),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ]),
                  ],
                ),
              )).animateScreenEntrance(),
        ],
      ),
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  SliverDelegate({required this.child, this.height = 50});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}

class SliverSearchDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  SliverSearchDelegate({required this.child, this.height = 70});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverSearchDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  /// True when the button sits on the approved gradient header: translucent
  /// white chip with a white icon, per the design's header actions.
  final bool onGradient;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onGradient
              ? Colors.white.withValues(alpha: 0.18)
              : isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onGradient
                ? Colors.white.withValues(alpha: 0.35)
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: onGradient
                  ? Colors.white
                  : Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withValues(alpha: 0.8),
            ),
            if (showBadge)
              // The approved cart badge: a magenta count riding the icon.
              PositionedDirectional(
                top: 3,
                end: 3,
                child: Consumer<CartController>(
                  builder: (context, cart, child) {
                    return cart.cartList.isNotEmpty
                        ? Container(
                            constraints: const BoxConstraints(
                                minWidth: 14, minHeight: 14),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: BrandColors.magenta,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(999)),
                            ),
                            child: Text(
                              cart.cartList.length > 9
                                  ? '9+'
                                  : '${cart.cartList.length}',
                              style: robotoBold.copyWith(
                                  fontSize: 7, color: Colors.white),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
