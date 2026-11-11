import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'dart:ui';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/product_details/widgets/favourite_button_widget.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';

int? _discountPercent(Product product) {
  final double price = (product.unitPrice ?? 0).toDouble();
  final clearance = product.clearanceSale;
  final bool clearanceWins = (clearance?.discountAmount ?? 0) > 0;
  final double amount =
      ((clearanceWins ? clearance?.discountAmount : product.discount) ?? 0)
          .toDouble();
  final String? type =
      clearanceWins ? clearance?.discountType : product.discountType;
  if (amount <= 0 || price <= 0) return null;
  final double percent = (type == 'percent' || type == 'percentage')
      ? amount
      : (amount / price) * 100;
  final int rounded = percent.round();
  return (rounded > 0 && rounded <= 99) ? rounded : null;
}

class SliderProductWidget extends StatelessWidget {
  final Product product;
  final bool isCurrentIndex;
  const SliderProductWidget(
      {super.key, required this.product, this.isCurrentIndex = true});

  @override
  Widget build(BuildContext context) {
    bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;
    double ratting = (product.rating?.isNotEmpty ?? false)
        ? double.parse('${product.rating?[0].average}')
        : 0;

    return InkWell(
      onTap: () {
        RouterHelper.getProductDetailsRoute(
          action: RouteAction.push,
          productId: product.id,
          slug: product.slug,
          fromFlashDeals: true,
        );
      },
      child: AnimatedContainer(
        margin: EdgeInsets.symmetric(
            vertical: isCurrentIndex ? Dimensions.paddingSizeExtraSmall : 45),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          color: Theme.of(context).cardColor,
          border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
              width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
        // curve: Curves.easeInCubic,z
        child: Stack(children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: LayoutBuilder(builder: (context, constrains) {
                      return Stack(children: [
                        Container(
                          width: constrains.maxWidth,
                          height: constrains.maxWidth * 0.9,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: .1)),
                            color: Theme.of(context).highlightColor,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: Stack(
                              children: [
                                CustomImageWidget(
                                  image: '${product.thumbnailFullUrl?.path}',
                                  width: constrains.maxWidth,
                                  height: constrains.maxWidth * 0.9,
                                ),
                                if ((product.currentStock ?? 0) == 0 &&
                                    product.productType == 'physical') ...[
                                  Positioned.fill(
                                    child: Container(
                                      color:
                                          Colors.black.withValues(alpha: 0.18),
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 8, sigmaY: 8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.5),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xFFFF3B30),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    getTranslated(
                                                            'out_of_stock',
                                                            context) ??
                                                        '',
                                                    style: textBold.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      letterSpacing: 0.1,
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
                              ],
                            ),
                          ),
                        ),
                        if (isCurrentIndex) ...[
                          // ((product.discount! > 0) || (product.clearanceSale != null)) ?
                          // DiscountTagWidget(product: product) : const SizedBox.shrink(),

                          Positioned.fill(
                              child: Align(
                            alignment:
                                isLtr ? Alignment.topRight : Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                  vertical: Dimensions.paddingSizeExtraSmall),
                              child: FavouriteButtonWidget(
                                backgroundColor:
                                    Provider.of<ThemeController>(context)
                                            .darkTheme
                                        ? Theme.of(context).cardColor
                                        : Theme.of(context).primaryColor,
                                productId: product.id,
                              ),
                            ),
                          )),
                        ],
                        if (_discountPercent(product) != null)
                          // The approved magenta «−X%» pill, computed from the
                          // deal's real discount, in place of the static icon.
                          PositionedDirectional(
                            top: Dimensions.paddingSizeSmall,
                            start: Dimensions.paddingSizeExtraSmall,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: BrandColors.magenta,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '−${_discountPercent(product)}%',
                                style: textBold.copyWith(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                      ]);
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                        vertical: Dimensions.paddingSizeExtraSmall),
                    child: Builder(
                      builder: (context) {
                        // ignore: unused_local_variable
                        final splash = context.watch<SplashController>();
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ratting > 0)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.star_rate_rounded,
                                          color: Colors.orange,
                                          size: Dimensions.paddingSizeDefault),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        child: Text(ratting.toStringAsFixed(1),
                                            style: textRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            )),
                                      ),
                                      Text(
                                        '(${PriceConverter.longToShortPrice(product.reviewCount?.toDouble() ?? 0, withDecimalPoint: false)})',
                                        style: textRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context).hintColor),
                                      ),
                                    ]),
                              Text(product.name ?? '',
                                  textAlign: TextAlign.center,
                                  style: textMedium.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (hasDiscount())
                                Text(
                                    PriceConverter.convertPrice(
                                        context, product.unitPrice),
                                    style: titleRegular.copyWith(
                                      color: Theme.of(context).hintColor,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Theme.of(context).hintColor,
                                      fontSize: Dimensions.fontSizeSmall,
                                    )),
                              Text(
                                PriceConverter.convertPrice(
                                  context,
                                  product.unitPrice,
                                  discountType:
                                      (product.clearanceSale?.discountAmount ?? 0) >
                                              0
                                          ? product.clearanceSale?.discountType
                                          : product.discountType,
                                  discount:
                                      (product.clearanceSale?.discountAmount ?? 0) >
                                              0
                                          ? product.clearanceSale?.discountAmount
                                          : product.discount,
                                ),
                                style: robotoBold.copyWith(
                                    color: ((product.discount ?? 0) > 0 ||
                                            (product.clearanceSale
                                                        ?.discountAmount ??
                                                    0) >
                                                0)
                                        ? BrandColors.magenta
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                    fontSize: Dimensions.fontSizeDefault),
                              ),
                            ]);
                      },
                    ),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }

  bool hasDiscount() =>
      (product.discount != null && product.discount! > 0) ||
      (product.clearanceSale?.discountAmount ?? 0) > 0;
}




// Positioned(
//   top: Dimensions.paddingSizeDefault,
//   child: Container(
//     padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
//     alignment: Alignment.center,
//     decoration: BoxDecoration(
//       color: ColorResources.getPrimary(context),
//       borderRadius: BorderRadius.only(
//         topRight: isLtr ? const Radius.circular(5) : Radius.zero,
//         bottomRight: isLtr ? const Radius.circular(5) : Radius.zero,
//         topLeft: !isLtr ? const Radius.circular(5) : Radius.zero,
//         bottomLeft: !isLtr ? const Radius.circular(5) : Radius.zero,
//       ),
//     ),
//     child: Directionality(
//       textDirection: TextDirection.ltr,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
//         child: Text(
//           PriceConverter.percentageCalculation(context, product.unitPrice, product.discount, product.discountType),
//           style: textBold.copyWith(color: Theme.of(context).highlightColor, fontSize: Dimensions.fontSizeExtraSmall),
//         ),
//       ),
//     ),
//   ),
// ),


