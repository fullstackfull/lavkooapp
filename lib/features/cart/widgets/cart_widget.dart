import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_loader_widget.dart';
import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/cart/widgets/cart_quantity_button_widget.dart';
import 'package:syriapharmacy/features/cart/widgets/custom_checkbox_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/min_order_quanty_widget.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class CartWidget extends StatelessWidget {
  final CartModel? cartModel;
  final int index;
  final bool fromCheckout;
  final Color highLightColor;
  final bool isValidate;
  const CartWidget({
    super.key,
    this.cartModel,
    required this.index,
    required this.fromCheckout,
    required this.highLightColor,
    required this.isValidate,
  });

  @override
  Widget build(BuildContext context) {
    bool minOrderQty = (cartModel?.productInfo?.minimumOrderQty ?? 0) > 1 &&
        (cartModel?.quantity == null ||
            (cartModel?.quantity ?? 0) <
                (cartModel?.productInfo?.minimumOrderQty ?? 1));
    return Consumer<CartController>(builder: (context, cartProvider, _) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeSmall,
          Dimensions.paddingSizeDefault,
          0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            boxShadow:
                Provider.of<ThemeController>(context, listen: false).darkTheme
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Slidable(
              key: const ValueKey(0),
              endActionPane: ActionPane(
                extentRatio: .25,
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (value) {
                      cartProvider.removeFromCartAPI(cartModel?.id, index);
                    },
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.1),
                    foregroundColor: Theme.of(context).colorScheme.error,
                    icon: CupertinoIcons.delete_solid,
                    label: getTranslated('delete', context),
                  ),
                ],
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: (highLightColor != Theme.of(context).cardColor &&
                          minOrderQty)
                      ? highLightColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isValidate &&
                            (cartModel?.isChecked ?? false) &&
                            minOrderQty)
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.08),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox (nicely aligned vertically)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CustomCheckbox(
                          key: UniqueKey(),
                          visualDensity: VisualDensity.compact,
                          fillColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).primaryColor;
                            }
                            return Theme.of(context).cardColor;
                          }),
                          side: WidgetStateBorderSide.resolveWith(
                            (states) => BorderSide(
                              width: 2,
                              color: (cartModel?.isChecked ?? false)
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context)
                                      .hintColor
                                      .withValues(alpha: 0.40),
                            ),
                          ),
                          checkColor: Colors.white,
                          value: cartModel!.isChecked!,
                          onChanged: (bool? value) async {
                            showDialog(
                              context: context,
                              builder: (ctx) => const CustomLoaderWidget(),
                            );
                            await cartProvider.addRemoveCartSelectedItem(
                              [cartModel!.id!],
                              cartModel!.isChecked! ? false : true,
                            );
                            Navigator.of(Get.context!).pop();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    // Product Image
                    _CartProductImageWidget(cartModel: cartModel),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    // Details and Quantity controls stacked
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CartProductDetailsWidget(cartModel: cartModel),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          MinOrderQuantityWidget(
                            minOrderQty:
                                cartModel?.productInfo?.minimumOrderQty ?? 1,
                            currentQty: cartModel?.quantity,
                          ),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraSmall),

                          // Symmetrical Row: Delete Icon & Symmetrical Horizontal Quantity controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Quick delete action
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  CupertinoIcons.trash,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                onPressed: () {
                                  cartProvider.removeFromCartAPI(
                                      cartModel?.id, index);
                                },
                              ),

                              // Symmetrical Quantity Pill
                              _CartQuantityControlsWidget(
                                  cartModel: cartModel, index: index),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _CartQuantityControlsWidget extends StatelessWidget {
  final CartModel? cartModel;
  final int index;
  const _CartQuantityControlsWidget({
    required this.cartModel,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          cartModel?.decrement ?? false
              ? Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : CartQuantityButton(
                  isIncrement: false,
                  index: index,
                  quantity: cartModel!.quantity,
                  maxQty: cartModel!.productInfo!.totalCurrentStock,
                  cartModel: cartModel,
                  minimumOrderQuantity: cartModel!.productInfo!.minimumOrderQty,
                  digitalProduct:
                      cartModel!.productType == "digital" ? true : false,
                ),

          // Count text
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            alignment: Alignment.center,
            child: Text(
              cartModel!.quantity.toString(),
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),

          // Increment
          cartModel?.increment ?? false
              ? Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : CartQuantityButton(
                  index: index,
                  isIncrement: true,
                  quantity: cartModel!.quantity,
                  maxQty: cartModel!.productInfo?.totalCurrentStock,
                  cartModel: cartModel,
                  minimumOrderQuantity: cartModel!.productInfo!.minimumOrderQty,
                  digitalProduct:
                      cartModel!.productType == "digital" ? true : false,
                ),
        ],
      ),
    );
  }
}

class _CartProductDetailsWidget extends StatelessWidget {
  final CartModel? cartModel;
  const _CartProductDetailsWidget({required this.cartModel});

  @override
  Widget build(BuildContext context) {
    final isClosedOrVacation = cartModel!.shop != null &&
        cartModel?.shop?.vacationStatus != null &&
        cartModel?.shop?.temporaryClose != null &&
        (cartModel!.shop!.temporaryClose! || cartModel!.shop!.vacationStatus!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  RouterHelper.getProductDetailsRoute(
                    action: RouteAction.push,
                    productId: cartModel?.productId,
                    slug: cartModel?.slug,
                  );
                },
                child: Text(
                  cartModel!.name!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w600,
                    color: isClosedOrVacation
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Row(
          children: [
            // Original Price (strike through)
            if (cartModel!.discount! > 0)
              Text(
                PriceConverter.convertPrice(context, cartModel!.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleRegular.copyWith(
                  color: Theme.of(context).hintColor,
                  decoration: TextDecoration.lineThrough,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),

            if (cartModel!.discount! > 0)
              const SizedBox(width: Dimensions.paddingSizeSmall),

            // Selling/Discounted price
            Text(
              PriceConverter.convertPrice(
                context,
                cartModel!.price,
                discount: cartModel!.discount,
                discountType: 'amount',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textBold.copyWith(
                color: isClosedOrVacation
                    ? Theme.of(context).hintColor
                    : Theme.of(context).primaryColor,
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
          ],
        ),

        // Symmetrical Variations badge
        if (cartModel!.variant != null && cartModel!.variant!.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: Text(
                cartModel?.variant ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Shipping cost
        if (cartModel!.shippingType != 'order_wise')
          Padding(
            padding:
                const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Row(
              children: [
                Text(
                  '${getTranslated('shipping_cost', context)}: ',
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Text(
                  PriceConverter.convertPrice(context, cartModel!.shippingCost),
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),

        // Out of stock warning
        if (cartModel!.quantity! > cartModel!.productInfo!.totalCurrentStock! &&
            cartModel?.productType == "physical")
          Padding(
            padding:
                const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Text(
              "${getTranslated("out_of_stock", context)}",
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _CartProductImageWidget extends StatelessWidget {
  final CartModel? cartModel;
  const _CartProductImageWidget({required this.cartModel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        RouterHelper.getProductDetailsRoute(
          action: RouteAction.push,
          productId: cartModel?.productId,
          slug: cartModel?.slug,
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImageWidget(
                image: '${cartModel?.productInfo?.thumbnailFullUrl?.path}',
                height: 75,
                width: 75,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (cartModel!.isProductAvailable! == 0)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              height: 75,
              width: 75,
              child: Center(
                child: Text(
                  "${getTranslated("not_available", context)}",
                  textAlign: TextAlign.center,
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
