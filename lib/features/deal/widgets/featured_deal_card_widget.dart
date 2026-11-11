import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/discount_tag_widget.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/favourite_button_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/cart_bottom_sheet_widget.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class FeaturedDealWidget extends StatelessWidget {
  final Product product;
  final bool isHomePage;
  final bool? isCenterElement;
  const FeaturedDealWidget(
      {super.key,
      required this.product,
      required this.isHomePage,
      this.isCenterElement});

  @override
  Widget build(BuildContext context) {
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;

    return InkWell(
      onTap: () => RouterHelper.getProductDetailsRoute(
          action: RouteAction.push, productId: product.id, slug: product.slug),
      child: LayoutBuilder(builder: (context, constrains) {
        return Stack(
          children: [
            AnimatedContainer(
              margin: isCenterElement == null
                  ? null
                  : EdgeInsets.symmetric(vertical: isCenterElement! ? 0 : 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onTertiary),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 5)),
                  ]),
              duration: const Duration(milliseconds: 600),
              child: Stack(children: [
                Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            Dimensions.paddingSizeExtraSmall),
                        border: Border.all(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.05),
                            width: 1),
                        color: Theme.of(context).highlightColor,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(Dimensions.paddingSizeSmall),
                        child: CustomImageWidget(
                          image: '${product.thumbnailFullUrl?.path}',
                          height: constrains.maxHeight * 0.8,
                          width: constrains.maxHeight * 0.8,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((product.currentStock ?? 0) == 0 &&
                            product.productType == 'physical')
                          Text(getTranslated('out_of_stock', context) ?? '',
                              style: textRegular.copyWith(
                                  color: const Color(0xFFF36A6A))),
                        //const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        if ((int.tryParse(product.reviewCount.toString()) ??
                                0) >
                            0)
                          Row(children: [
                            Icon(Icons.star_rate_rounded,
                                color: Provider.of<ThemeController>(context)
                                        .darkTheme
                                    ? Colors.white
                                    : Colors.orange,
                                size: 15),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                product.rating != null &&
                                        product.rating!.isNotEmpty
                                    ? double.parse(product.rating![0].average!)
                                        .toStringAsFixed(1)
                                    : '0.0',
                                style: textMedium.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                            ),
                            Text('(${product.reviewCount.toString()})',
                                style: textMedium.copyWith(
                                  color: Theme.of(context).hintColor,
                                  fontSize: Dimensions.fontSizeDefault,
                                )),
                          ]),

                        if ((int.tryParse(product.reviewCount.toString()) ??
                                0) >
                            0)
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraSmall),

                        Row(children: [
                          Flexible(
                              child: SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: Text(
                              product.name ?? '',
                              style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                              maxLines: ((product.currentStock ?? 0) == 0 &&
                                      product.productType == 'physical')
                                  ? 1
                                  : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ]),
                        const SizedBox(
                            height: Dimensions.paddingSizeExtraSmall),

                        FittedBox(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  ((product.discount != null &&
                                              product.discount! > 0) ||
                                          (product.clearanceSale
                                                      ?.discountAmount ??
                                                  0) >
                                              0)
                                      ? PriceConverter.convertPrice(context,
                                          product.unitPrice!.toDouble())
                                      : '',
                                  style: textRegular.copyWith(
                                      color: Theme.of(context).hintColor,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: Dimensions.fontSizeSmall)),
                              ((product.discount != null &&
                                          product.discount! > 0) ||
                                      (product.clearanceSale?.discountAmount ??
                                              0) >
                                          0)
                                  ? const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall)
                                  : const SizedBox(),
                              Text(
                                PriceConverter.convertPrice(
                                    context, product.unitPrice!.toDouble(),
                                    discountType: (product.clearanceSale
                                                    ?.discountAmount ??
                                                0) >
                                            0
                                        ? product.clearanceSale?.discountType
                                        : product.discountType,
                                    discount: (product.clearanceSale
                                                    ?.discountAmount ??
                                                0) >
                                            0
                                        ? product.clearanceSale?.discountAmount
                                        : product.discount),
                                style: textBold.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Provider.of<ProductDetailsController>(context, listen: false)
                                          .getProductDetails(context, product.id.toString(), product.slug!)
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
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      Provider.of<ProductDetailsController>(context, listen: false)
                                          .getProductDetails(context, product.id.toString(), product.slug!)
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
                                        'استيلاء على الصفقة',
                                        style: textBold.copyWith(
                                          fontSize: 9.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]))
                      ],
                    ),
                  )),
                ]),
                Positioned(
                    top: 10,
                    right: isLtr ? 10 : null,
                    left: !isLtr ? 10 : null,
                    child: FavouriteButtonWidget(
                        backgroundColor:
                            Provider.of<ThemeController>(context).darkTheme
                                ? Theme.of(context).cardColor
                                : Theme.of(context).primaryColor,
                        productId: product.id)),
              ]),
            ),
            ((product.discount! > 0) ||
                    (product.clearanceSale?.discountAmount ?? 0) > 0)
                ? DiscountTagWidget(
                    productModel: product,
                    positionedTop: 0,
                    positionedLeft: 2,
                    topLeftBorderRadius: Dimensions.radiusDefault,
                    bottomRightBorderRadius: Dimensions.radiusDefault)
                : const SizedBox.shrink(),
          ],
        );
      }),
    );
  }
}
