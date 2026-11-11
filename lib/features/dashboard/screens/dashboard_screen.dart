import 'package:flutter/material.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:syriapharmacy/features/dashboard/screens/menu_screen.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/cart/screens/cart_screen.dart';
import 'package:syriapharmacy/features/chat/controllers/chat_controller.dart';
import 'package:syriapharmacy/features/dashboard/models/navigation_model.dart';

import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/restock/controllers/restock_controller.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:syriapharmacy/helper/network_info.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/features/dashboard/widgets/app_exit_card_widget.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/features/home/screens/aster_theme_home_screen.dart';
import 'package:syriapharmacy/features/home/screens/fashion_theme_home_screen.dart';
import 'package:syriapharmacy/features/category/screens/category_screen.dart';
import 'package:syriapharmacy/features/home/screens/home_screens.dart';
import 'package:syriapharmacy/features/wishlist/screens/wishlist_screen.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/features/health/health_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';

class DashBoardScreen extends StatefulWidget {
  final int? pageIndex;
  const DashBoardScreen({super.key, required this.pageIndex});
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  int _pageIndex = 0;
  late List<NavigationModel> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  final PageStorageBucket bucket = PageStorageBucket();
  final ZoomDrawerController _drawerController = ZoomDrawerController();
  final GlobalKey<CartIconKey> _cartNavKey = GlobalKey<CartIconKey>();

  bool singleVendor = false;

  @override
  void initState() {
    super.initState();

    Provider.of<FlashDealController>(context, listen: false)
        .getFlashDealList(true, true);
    Provider.of<SplashController>(context, listen: false)
        .getBusinessPagesList('default');
    Provider.of<SplashController>(context, listen: false)
        .getBusinessPagesList('pages');
    if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<CartController>(context, listen: false).mergeGuestCart();
      Provider.of<WishListController>(context, listen: false).getWishList('');
      Provider.of<ChatController>(context, listen: false)
          .getChatList(1, reload: false, userType: 0);
      Provider.of<ChatController>(context, listen: false)
          .getChatList(1, reload: false, userType: 1);
      Provider.of<RestockController>(context, listen: false)
          .getRestockProductList(1, getAll: true);
    }

    final SplashController splashController =
        Provider.of<SplashController>(context, listen: false);
    singleVendor = splashController.configModel?.businessMode == "single";
    Provider.of<SearchProductController>(context, listen: false)
        .getAuthorList(null);
    Provider.of<SearchProductController>(context, listen: false)
        .getPublishingHouseList(null);

    if (widget.pageIndex != null) {
      _pageIndex = widget.pageIndex!;
    }

    // if (splashController.configModel?.activeTheme == "default") {
    //   HomePage.loadData(false);
    // } else if (splashController.configModel?.activeTheme == "theme_aster") {
    //   AsterThemeHomeScreen.loadData(false);
    // } else {
    //   FashionThemeHomePage.loadData(false);
    // }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (splashController.configModel?.activeTheme == "default") {
        HomePage.loadData(false);
      } else if (splashController.configModel?.activeTheme == "theme_aster") {
        AsterThemeHomeScreen.loadData(false);
      } else {
        FashionThemeHomePage.loadData(false);
      }
    });
    // The approved tab set: الرئيسية / الأقسام / [بحث مركزي] / المفضلة / السلة.
    // Inbox, offers and more moved to the drawer menu, which pushes their routes.
    _screens = [
      NavigationModel(
        name: 'home',
        icon: Images.homeImage,
        screen: (splashController.configModel?.activeTheme == "default")
            ? const HomePage()
            : (splashController.configModel?.activeTheme == "theme_aster")
                ? const AsterThemeHomeScreen()
                : const HomePage(),
      ),
      NavigationModel(
          name: 'categories',
          icon: Images.category,
          screen: const CategoryScreen()),
      NavigationModel(
          name: 'wishList',
          icon: Images.wishImage,
          screen: const WishListScreen(fromDashboard: true)),
      NavigationModel(
          name: 'cart',
          icon: Images.cartArrowDownImage,
          screen: const CartScreen(showBackButton: false, fromDashboard: true),
          showCartIcon: true),
    ];

    NetworkInfo.checkConnectivity(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;

    return ThemeSwitchingArea(
      child: ZoomDrawer(
        controller: _drawerController,
        menuScreen: MenuScreen(
          selectedIndex: _pageIndex,
          onItemSelected: (index) {
            _setPage(index);
            _drawerController.toggle!();
          },
        ),
        mainScreen: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (_pageIndex != 0) {
              _setPage(0);
              return;
            } else {
              await Future.delayed(const Duration(milliseconds: 150));
              if (context.mounted) {
                if (_pageIndex == 0) {
                  showModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: Get.context!,
                    builder: (_) => const AppExitCard(),
                  );
                }
              }
            }
            return;
          },
          child: AddToCartAnimation(
            cartKey: _cartNavKey,
            height: 30,
            width: 30,
            opacity: 0.85,
            dragAnimation: const DragToCartAnimationOptions(
              rotation: true,
            ),
            jumpAnimation: const JumpAnimationOptions(),
            createAddToCartAnimation: (addToCartAnimationMethod) {
              AppConstants.runAddToCartAnimation = addToCartAnimationMethod;
            },
            child: Scaffold(
              key: _scaffoldKey,
              extendBody: false,
              body: IndexedStack(
                index: _pageIndex,
                children: _screens
                    .map((s) => PageStorage(bucket: bucket, child: s.screen))
                    .toList(),
              ),
              bottomNavigationBar: _IosGlassNavBar(
                currentIndex: _pageIndex,
                onTap: _setPage,
                screens: _screens,
                cartKey: _cartNavKey,
              ),
            ),
          ),
        ),
        borderRadius: 24.0,
        // Disable showShadow because ZoomDrawer implements shadows by duplicating the entire
        // mainScreen widget tree under different Transform parents, which violates the uniqueness 
        // constraint of the GlobalKey (_cartNavKey) used by AddToCartIcon inside the mainScreen.
        showShadow: false,
        angle: isLtr ? -10.0 : 10.0,
        drawerShadowsBackgroundColor: (isDark
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).primaryColor)
            .withOpacity(0.3),
        slideWidth: MediaQuery.of(context).size.width * 0.75,
        menuBackgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).primaryColor,
        mainScreenScale: 0.15,
        isRtl: !isLtr,
      ),
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageIndex = pageIndex;
    });
  }
}

// ─── iOS Glass Navigation Bar ─────────────────────────────────────────────────

class _IosGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationModel> screens;
  final GlobalKey<CartIconKey> cartKey;

  const _IosGlassNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.screens,
    required this.cartKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // The approved bar: a flat surface with an ink hairline on top and the
    // raised gradient search circle at its centre.
    final List<Widget> items = [
      for (int i = 0; i < screens.length; i++)
        _NavItem(
          screen: screens[i],
          isSelected: currentIndex == i,
          isDark: isDark,
          primaryColor: Theme.of(context).primaryColor,
          onTap: () => onTap(i),
          cartKey: cartKey,
        ),
    ];
    items.insert(2, const SizedBox(width: 54));

    const double raise = 22;
    final double barHeight = 62 + (bottomPad > 0 ? bottomPad : 8);

    // The raised circle lives INSIDE the bar's own box: a child painted outside
    // its parent's bounds still renders, but never receives a tap — half the
    // search button would be dead. So the bar reserves the overhang instead.
    return SizedBox(
      height: barHeight + raise,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: Container(
          height: barHeight,
          padding: EdgeInsets.only(
              top: 6, bottom: bottomPad > 0 ? bottomPad : 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: const Border(
                top: BorderSide(color: BrandColors.hairline, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items,
          ),
        ),
        ),
        Positioned(
          top: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => RouterHelper.getSearchRoute(action: RouteAction.push),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: BrandGradients.primary,
                border: Border.all(
                    color: Theme.of(context).cardColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.search_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavigationModel screen;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final GlobalKey<CartIconKey> cartKey;

  const _NavItem({
    required this.screen,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.cartKey,
  });

  String _label(BuildContext ctx) {
    switch (screen.name) {
      case 'home':
        return getTranslated('home', ctx) ?? 'Home';
      case 'categories':
        return getTranslated('categories', ctx) ?? 'Categories';
      case 'wishList':
        return getTranslated('wishList', ctx) ?? 'Wishlist';
      case 'inbox':
        return getTranslated('inbox', ctx) ?? 'Inbox';
      case 'offers':
        return getTranslated('offers', ctx) ?? 'Offers';
      case 'cart':
        return getTranslated('cart', ctx) ?? 'Cart';
      case 'orders':
        return getTranslated('orders', ctx) ?? 'Orders';
      case 'health_center':
        return getTranslated('health_center', ctx) ?? (Localizations.localeOf(ctx).languageCode == 'ar' ? 'المركز الصحي' : 'Health Center');
      case 'more':
        return getTranslated('more', ctx) ?? 'More';
      default:
        return screen.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── No icon pill container ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isSelected ? 40 : 34,
              height: isSelected ? 26 : 24,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Icon with animated scale
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: screen.name == 'cart'
                          ? AddToCartIcon(
                              key: cartKey,
                              badgeOptions: const BadgeOptions(active: false),
                              icon: Image.asset(
                                screen.icon,
                                width: 18,
                                height: 18,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.white.withOpacity(0.45)
                                        : Colors.black.withOpacity(0.38)),
                              ),
                            )
                          : Image.asset(
                              screen.icon,
                              width: 18,
                              height: 18,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? Colors.white.withOpacity(0.55)
                                      : BrandColors.mutedText),
                            ),
                    ),

                    // Cart badge
                    if (screen.showCartIcon ?? false)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Consumer<CartController>(
                          builder: (_, cart, __) {
                            if (cart.cartList.isEmpty)
                              return const SizedBox.shrink();
                            return Container(
                              constraints: const BoxConstraints(
                                  minWidth: 14, minHeight: 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2.5, vertical: 1),
                              decoration: BoxDecoration(
                                color: BrandColors.magenta,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).cardColor,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                cart.cartList.length > 9
                                    ? '9+'
                                    : cart.cartList.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 2),

            // ── Label ───────────────────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : (isDark
                        ? Colors.white.withOpacity(0.5)
                        : BrandColors.mutedText),
                fontFamily: 'SF-Pro-Rounded-Regular',
                letterSpacing: isSelected ? 0.3 : 0.1,
              ),
              child: Text(_label(context),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep old class name as alias for compatibility
typedef CustomPremiumBottomNavBar = _IosGlassNavBar;
