import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/product_details/domain/models/product_details_model.dart';
import 'package:syriapharmacy/features/product_details/widgets/cart_bottom_sheet_widget.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/helper/shop_helper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class BottomCartWidget extends StatefulWidget {
  final ProductDetailsModel? product;
  final GlobalKey<CartIconKey>? cartDetailsKey;
  final Function()? onAddToCart;

  const BottomCartWidget({
    super.key,
    required this.product,
    this.cartDetailsKey,
    this.onAddToCart,
  });

  @override
  State<BottomCartWidget> createState() => _BottomCartWidgetState();
}

class _BottomCartWidgetState extends State<BottomCartWidget> {
  bool vacationIsOn = false;
  bool temporaryClose = false;

  @override
  void initState() {
    super.initState();

    vacationIsOn = ShopHelper.isVacationActive(
      context,
      startDate: widget.product?.seller?.shop?.vacationStartDate,
      endDate: widget.product?.seller?.shop?.vacationEndDate,
      vacationDurationType: widget.product?.seller?.shop?.vacationDurationType,
      vacationStatus: widget.product?.seller?.shop?.vacationStatus,
      isInHouseSeller: widget.product?.addedBy == 'admin',
    );

    if (widget.product?.addedBy == 'admin') {
      if (widget.product != null &&
          (Provider.of<SplashController>(context, listen: false)
                  .configModel
                  ?.inhouseTemporaryClose
                  ?.status ??
              false)) {
        temporaryClose = true;
      } else {
        temporaryClose = false;
      }
    } else {
      if (widget.product != null &&
          widget.product!.seller != null &&
          widget.product!.seller!.shop!.temporaryClose!) {
        temporaryClose = true;
      } else {
        temporaryClose = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(children: [
        AddToCartIcon(
          key: widget.cartDetailsKey ?? GlobalKey<CartIconKey>(),
          badgeOptions: const BadgeOptions(active: false),
          icon: InkWell(
            onTap: () =>
                RouterHelper.getCartScreenRoute(action: RouteAction.push),
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.15),
                        width: 1.5),
                  ),
                  child: Center(
                    child: Image.asset(
                      Images.cartArrowDownImage,
                      color: Theme.of(context).primaryColor,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child:
                      Consumer<CartController>(builder: (context, cart, child) {
                    if (cart.cartList.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      height: 18,
                      width: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                        border: Border.all(
                            color: Theme.of(context).cardColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          cart.cartList.length.toString(),
                          style: textBold.copyWith(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
            child: InkWell(
          onTap: () {
            if (vacationIsOn || temporaryClose) {
              showCustomSnackBarWidget(
                  getTranslated('this_shop_is_close_now', context), context,
                  snackBarType: SnackBarType.error);
            } else {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0),
                  builder: (con) => CartBottomSheetWidget(
                        product: widget.product,
                        callback: () {
                          showCustomSnackBarWidget(
                              getTranslated('added_to_cart', context), context,
                              snackBarType: SnackBarType.success);
                          widget.onAddToCart?.call();
                        },
                      ));
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              getTranslated('add_to_cart', context)!,
              style: titilliumSemiBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Colors.white,
              ),
            ),
          ),
        )),
      ]),
    );
  }
}
