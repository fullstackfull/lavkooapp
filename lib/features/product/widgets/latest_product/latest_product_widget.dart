import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui';
import 'package:syriapharmacy/common/basewidget/discount_tag_widget.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/product_details/widgets/favourite_button_widget.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/product_details/widgets/cart_bottom_sheet_widget.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';

class LatestProductWidget extends StatelessWidget {
  final Product productModel;
  const LatestProductWidget({super.key, required this.productModel});

  @override
  Widget build(BuildContext context) {
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;

    String ratting =
        productModel.rating != null && productModel.rating!.isNotEmpty
            ? productModel.rating![0].average!
            : "0";

    return InkWell(
      onTap: () {
        RouterHelper.getProductDetailsRoute(
            action: RouteAction.push,
            productId: productModel.id,
            slug: productModel.slug!,
            image: productModel.thumbnailFullUrl?.path);
      },
      child: Padding(
        padding: EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Dimensions.paddingSizeSmall)),
                  color: Provider.of<ThemeController>(context, listen: false)
                          .darkTheme
                      ? Theme.of(context).highlightColor
                      : Theme.of(context).highlightColor,
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.075),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 1))
                  ]),
              child: SizedBox(
                height: ResponsiveHelper.isTab(context) ? 250 : 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    productModel.thumbnail != null
                        ? Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).highlightColor,
                                border: Border.all(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .color!
                                        .withValues(alpha: 0.08),
                                    width: .5),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5))),
                            child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                                child: Stack(
                                  children: [
                                    CustomImageWidget(
                                      height: ResponsiveHelper.isTab(context)
                                          ? 250
                                          : 100,
                                      width: ResponsiveHelper.isTab(context)
                                          ? 230
                                          : 100,
                                      image:
                                          '${productModel.thumbnailFullUrl?.path}',
                                    ),
                                    if ((productModel.currentStock ?? 0) == 0 &&
                                        productModel.productType == 'physical')
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          child: Center(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 8, sigmaY: 8),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.15),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 4,
                                                        height: 4,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color:
                                                              Color(0xFFFF3B30),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          getTranslated(
                                                                  'out_of_stock',
                                                                  context) ??
                                                              '',
                                                          style: textBold.copyWith(
                                                            color: Colors.white,
                                                            fontSize: 8.5,
                                                            letterSpacing: 0.05,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )))
                        : const SizedBox(),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((productModel.reviewCount ?? 0) < 0 ||
                              double.parse(ratting) > 0) ...[
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.star,
                                      color:
                                          Provider.of<ThemeController>(context)
                                                  .darkTheme
                                              ? Colors.white
                                              : Colors.orange,
                                      size: 12),
                                  Text(double.parse(ratting).toStringAsFixed(1),
                                      style: textMedium.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color)),
                                  Text('(${productModel.reviewCount ?? '0'})',
                                      style: textRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).hintColor)),
                                ]),
                            const SizedBox(
                                height: Dimensions.paddingSizeExtraSmall),
                          ],
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 3.0,
                              child: Text(productModel.name ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color))),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    // ignore: unused_local_variable
                                    final splash =
                                        context.watch<SplashController>();
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        productModel.discount != null &&
                                                    productModel.discount! > 0 ||
                                                (productModel.clearanceSale
                                                            ?.discountAmount ??
                                                        0) >
                                                    0
                                            ? AutoSizeText(
                                                PriceConverter.convertPrice(
                                                    context,
                                                    productModel.unitPrice),
                                                maxLines: 1,
                                                minFontSize: 8,
                                                style: textRegular.copyWith(
                                                  color:
                                                      Theme.of(context).hintColor,
                                                  decoration:
                                                      TextDecoration.lineThrough,
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraExtraSmall,
                                            width:
                                                Dimensions.paddingSizeExtraSmall),
                                        productModel.unitPrice != null
                                            ? AutoSizeText(
                                                PriceConverter.convertPrice(
                                                    context, productModel.unitPrice,
                                                    discountType:
                                                        (productModel.clearanceSale?.discountAmount ?? 0) > 0
                                                            ? productModel
                                                                .clearanceSale
                                                                ?.discountType
                                                            : productModel
                                                                .discountType,
                                                    discount: (productModel
                                                                    .clearanceSale
                                                                    ?.discountAmount ??
                                                                0) >
                                                            0
                                                        ? productModel
                                                            .clearanceSale
                                                            ?.discountAmount
                                                        : productModel.discount),
                                                maxLines: 1,
                                                minFontSize: 8,
                                                style: textBold.copyWith(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                    fontSize: Dimensions.fontSizeDefault))
                                            : const SizedBox(),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Provider.of<ProductDetailsController>(context, listen: false)
                                          .getProductDetails(context, productModel.id.toString(), productModel.slug!)
                                          .then((_) {
                                        if (!context.mounted) return;
                                        final detailsModel = Provider.of<ProductDetailsController>(context, listen: false).productDetailsModel;
                                        if (detailsModel != null) {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (con) => CartBottomSheetWidget(
                                              product: detailsModel,
                                              callback: () {
                                                if (Navigator.of(con).canPop()) {
                                                  Navigator.of(con).pop();
                                                }
                                                showCustomSnackBarWidget(
                                                  getTranslated('added_to_cart', context)!,
                                                  context,
                                                  snackBarType: SnackBarType.success,
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        getTranslated('grab_this_deal', context) ?? 'Grab this deal',
                                        style: textBold.copyWith(
                                          fontSize: 9.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Provider.of<ProductDetailsController>(context, listen: false)
                                          .getProductDetails(context, productModel.id.toString(), productModel.slug!)
                                          .then((_) {
                                        if (!context.mounted) return;
                                        final detailsModel = Provider.of<ProductDetailsController>(context, listen: false).productDetailsModel;
                                        if (detailsModel != null) {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (con) => CartBottomSheetWidget(
                                              product: detailsModel,
                                              callback: () {
                                                if (Navigator.of(con).canPop()) {
                                                  Navigator.of(con).pop();
                                                }
                                                showCustomSnackBarWidget(
                                                  getTranslated('added_to_cart', context)!,
                                                  context,
                                                  snackBarType: SnackBarType.success,
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: Theme.of(context).primaryColor,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
                top: 8,
                right: isLtr ? 10 : null,
                left: !isLtr ? 10 : null,
                child: FavouriteButtonWidget(
                    backgroundColor:
                        Provider.of<ThemeController>(context).darkTheme
                            ? Theme.of(context).cardColor
                            : Theme.of(context).primaryColor,
                    productId: productModel.id)),
            productModel.discount != null &&
                    ((productModel.discount! > 0) ||
                        (productModel.clearanceSale?.discountAmount ?? 0) > 0)
                ? DiscountTagWidget(
                    productModel: productModel,
                    positionedTop: 0,
                    topLeftBorderRadius: Dimensions.radiusDefault,
                    bottomRightBorderRadius: Dimensions.radiusDefault)
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
