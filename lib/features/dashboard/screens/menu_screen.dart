import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../../../localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/theme/dark_theme.dart';
import 'package:syriapharmacy/theme/light_theme.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/order/controllers/order_controller.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const MenuScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color menuBgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: menuBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile header
              Consumer<AuthController>(
                builder: (context, authController, _) {
                  final isLoggedIn = authController.isLoggedIn();
                  return Consumer<ProfileController>(
                    builder: (context, profileController, _) {
                      final hasUser =
                          isLoggedIn && profileController.userInfoModel != null;

                      // استخدام getTranslated للاسم الافتراضي
                      final name = hasUser
                          ? '${profileController.userInfoModel?.fName} ${profileController.userInfoModel?.lName}'
                          : getTranslated('shoppe_user', context)!;

                      final email = hasUser
                          ? profileController.userInfoModel?.email
                          : getTranslated('welcome_to_shoppe', context);

                      final showProfileImage = hasUser &&
                          profileController.userInfoModel?.imageFullUrl?.path !=
                              null &&
                          profileController.userInfoModel!.imageFullUrl!.path!
                              .trim()
                              .isNotEmpty;

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            backgroundImage: showProfileImage
                                ? NetworkImage(profileController
                                .userInfoModel!.imageFullUrl!.path!)
                                : null,
                            child: !showProfileImage
                                ? const Icon(Icons.person,
                                color: Colors.white, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'IBM_Plex_Sans_Arabic',
                                  ),
                                ),
                                Text(
                                  email ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontFamily: 'IBM_Plex_Sans_Arabic',
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Menu items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMenuItem(
                        Icons.home_outlined,
                        getTranslated("home", context)!,
                        selectedIndex == 0,
                            () {
                          onItemSelected(0);
                          ZoomDrawer.of(context)?.close();
                        },
                      ),
                      _buildMenuItem(
                        Icons.grid_view_outlined,
                        getTranslated("categories", context)!, // تم التعديل
                        selectedIndex == 1,
                            () {
                          onItemSelected(1);
                          ZoomDrawer.of(context)?.close();
                        },
                      ),
                      _buildMenuItem(
                        Icons.local_offer_outlined,
                        getTranslated("offers_discounts", context)!, // تم التعديل
                        false,
                            () {
                          ZoomDrawer.of(context)?.close();
                          RouterHelper.getOfferProductListScreenRoute(
                              action: RouteAction.push);
                        },
                      ),
                      _buildMenuItem(
                        Icons.chat_bubble_outline,
                        getTranslated("messages_contact", context)!, // تم التعديل
                        false,
                            () {
                          ZoomDrawer.of(context)?.close();
                          RouterHelper.getInboxScreenRoute(
                              action: RouteAction.push);
                        },
                      ),
                      _buildMenuItem(
                        Icons.shopping_cart_outlined,
                        getTranslated("shopping_cart", context)!, // تم التعديل
                        selectedIndex == 3,
                            () {
                          onItemSelected(3);
                          ZoomDrawer.of(context)?.close();
                        },
                      ),
                      _buildMenuItem(
                        Icons.receipt_long_outlined,
                        getTranslated("my_orders", context)!, // تم التعديل
                        false,
                            () {
                          ZoomDrawer.of(context)?.close();
                          RouterHelper.getOrderScreenRoute(action: RouteAction.push);
                        },
                      ),
                      _buildMenuItem(
                        Icons.favorite_outline,
                        getTranslated("wishlist", context)!, // تم التعديل
                        false,
                            () {
                          ZoomDrawer.of(context)?.close();
                          RouterHelper.getWishListRoute(action: RouteAction.push);
                        },
                      ),
                      // This menu is where everything the bottom bar no longer
                      // carries has to live.
                      _buildMenuItem(
                        Icons.person_outline_rounded,
                        getTranslated("my_account", context)!,
                        false,
                            () {
                          ZoomDrawer.of(context)?.close();
                          RouterHelper.getMoreRoute(action: RouteAction.push);
                        },
                      ),
                      //const SizedBox(height: 10),

                      // Theme Switcher Widget with Ripple Animation
                      ThemeSwitcher.withTheme(
                        builder: (context, switcher, theme) {
                          final isDark = theme.brightness == Brightness.dark;
                          return GestureDetector(
                            onTapDown: (details) {
                              Provider.of<ThemeController>(context, listen: false)
                                  .toggleThemeSilent();
                              switcher.changeTheme(
                                theme: isDark
                                    ? light(
                                  primaryColor: Provider.of<ThemeController>(
                                      context,
                                      listen: false)
                                      .selectedPrimaryColor,
                                  secondaryColor: Provider.of<ThemeController>(
                                      context,
                                      listen: false)
                                      .selectedSecondaryColor,
                                )
                                    : dark(
                                  primaryColor: Provider.of<ThemeController>(
                                      context,
                                      listen: false)
                                      .selectedPrimaryColor,
                                  secondaryColor: Provider.of<ThemeController>(
                                      context,
                                      listen: false)
                                      .selectedSecondaryColor,
                                ),
                                offset: details.globalPosition,
                              );
                            },
                            child: AbsorbPointer(
                              child: _buildMenuItem(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                isDark ? getTranslated("light_mode", context)! : getTranslated("dark_mode", context)!,
                                false,
                                    () {},
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Logout/Login action
              Consumer<AuthController>(
                builder: (context, authController, _) {
                  final isLoggedIn = authController.isLoggedIn();
                  return InkWell(
                    onTap: () {
                      if (isLoggedIn) {
                        Provider.of<AuthController>(context, listen: false)
                            .logOut()
                            .then((condition) {
                          if (context.mounted) {
                            Provider.of<CartController>(context, listen: false)
                                .resetCartList();
                            Provider.of<AddressController>(context,
                                listen: false)
                                .resetAddressList();
                            Provider.of<AuthController>(context, listen: false)
                                .clearSharedData();
                            Provider.of<ProfileController>(context,
                                listen: false)
                                .clearProfileData();
                            Provider.of<AuthController>(context, listen: false)
                                .getGuestIdUrl();
                            Provider.of<OrderController>(context, listen: false)
                                .resetOrderList();
                            Provider.of<WishListController>(context,
                                listen: false)
                                .emptyWishList();
                            RouterHelper.getSplashRoute(
                                action: RouteAction.pushNamedAndRemoveUntil);
                          }
                        });
                      } else {
                        RouterHelper.getLoginRoute(action: RouteAction.push);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: isLoggedIn
                            ? Colors.redAccent.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLoggedIn
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLoggedIn
                                  ? Colors.redAccent.withOpacity(0.15)
                                  : menuBgColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLoggedIn ? Icons.logout : Icons.login,
                              color:
                              isLoggedIn ? Colors.redAccent : menuBgColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              // تم التعديل
                              isLoggedIn ? getTranslated('logout', context)! : getTranslated('login', context)!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isLoggedIn
                                    ? Colors.redAccent
                                    : menuBgColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'IBM_Plex_Sans_Arabic',
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isLoggedIn
                                ? Colors.redAccent.withOpacity(0.7)
                                : menuBgColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title,
      bool isActive,
      VoidCallback onTap, {
        Color color = Colors.white,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
              isActive ? const Color(0xFFFFBB38) : color.withValues(alpha: 0.8),
              size: 22,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  fontFamily: 'IBM_Plex_Sans_Arabic',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}