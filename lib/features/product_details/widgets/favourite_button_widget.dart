import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/features/shop/domain/models/shop_navigation_model.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:provider/provider.dart';

class FavouriteButtonWidget extends StatelessWidget {
  final Color backgroundColor;
  final Color? iconColor;
  final int? productId;
  final bool? fromProductDetails;
  final SellerNavigationModel? sellerNavigationModel;
  const FavouriteButtonWidget(
      {super.key,
      this.backgroundColor = Colors.black,
      this.iconColor,
      this.productId,
      this.fromProductDetails = false,
      this.sellerNavigationModel});
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeController>(context).darkTheme;

    return Consumer<AuthController>(builder: (context, authController, _) {
      bool isGuestMode = !authController.isLoggedIn();
      return Consumer<WishListController>(builder: (context, wishProvider, _) {
        bool isAdded = wishProvider.addedIntoWish.contains(productId);
        return GestureDetector(
          onTap: () {
            String? currentRouteName = ModalRoute.of(context)?.settings.name;
            final searchProvider =
                Provider.of<SearchProductController>(context, listen: false);

            if (isGuestMode) {
              if (searchProvider.searchFocusNode.hasFocus) {
                searchProvider.searchFocusNode.unfocus();
              }
              showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (_) => NotLoggedInBottomSheetWidget(
                        fromFavoriteButton: true,
                        fromPage: currentRouteName,
                        onLoginSuccess: sellerNavigationModel?.sellerId == null
                            ? null
                            : () {
                                RouterHelper.getTopSellerRoute(
                                  action: RouteAction.pushReplacement,
                                  slug: sellerNavigationModel?.slug,
                                  sellerId: sellerNavigationModel?.sellerId,
                                  temporaryClose:
                                      sellerNavigationModel?.temporaryClose,
                                  vacationStatus:
                                      sellerNavigationModel?.vacationStatus,
                                  vacationEndDate:
                                      sellerNavigationModel?.vacationEndDate,
                                  vacationStartDate:
                                      sellerNavigationModel?.vacationStartDate,
                                  vacationDurationType: sellerNavigationModel
                                      ?.vacationDurationType,
                                  name: sellerNavigationModel?.name,
                                  banner: sellerNavigationModel?.banner,
                                  image: sellerNavigationModel?.image,
                                  fromMore: sellerNavigationModel?.fromMore,
                                  totalReview:
                                      sellerNavigationModel?.totalReview,
                                  totalProduct:
                                      sellerNavigationModel?.totalProduct,
                                );
                              },
                      ));
            } else {
              isAdded
                  ? wishProvider.removeWishList(
                      productId,
                    )
                  : wishProvider.addWishList(productId);
            }
          },
          child: Container(
            height: (fromProductDetails ?? false) ? 38 : 30,
            width: (fromProductDetails ?? false) ? 38 : 30,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: (fromProductDetails ?? false)
                  ? null
                  : Border.all(
                      color: isDarkMode
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 1),
              shape: BoxShape.circle,
              boxShadow: (backgroundColor == Colors.transparent ||
                      (fromProductDetails ?? false))
                  ? []
                  : [
                      BoxShadow(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withValues(alpha: 0.10),
                        spreadRadius: 0,
                        blurRadius: 15,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: Center(
              child: Icon(
                isAdded ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: iconColor ??
                    (backgroundColor == Colors.transparent ||
                            backgroundColor == Theme.of(context).cardColor ||
                            backgroundColor == Colors.white
                        ? Theme.of(context).primaryColor
                        : Colors.white),
                size: (fromProductDetails ?? false)
                    ? 18
                    : Dimensions.paddingSizeDefaultAddress,
              ),
            ),
          ),
        );
      });
    });
  }
}
