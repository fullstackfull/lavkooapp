import 'package:flutter/material.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
import 'package:syriapharmacy/common/basewidget/custom_directionality_widget.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/product_details/domain/models/product_details_model.dart';
import 'package:syriapharmacy/features/review/controllers/review_controller.dart';
import 'package:syriapharmacy/helper/color_helper.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/product_helper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ProductTitleWidget extends StatelessWidget {
  final ProductDetailsModel? productModel;
  final String? averageRatting;
  const ProductTitleWidget(
      {super.key, required this.productModel, this.averageRatting});

  @override
  Widget build(BuildContext context) {
    ({double? end, double? start})? priceRange =
        ProductHelper.getProductPriceRange(productModel);
    double? startingPrice = priceRange.start;
    double? endingPrice = priceRange.end;

    return productModel != null
        ? Container(
            // margin: const EdgeInsets.symmetric(
            //     horizontal: Dimensions.homePagePadding,
            //     vertical: Dimensions.paddingSizeSmall),
            padding:EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeExtraExtraSmall),
            //const EdgeInsets.all(Dimensions.paddingSizeDefault),
            // decoration: BoxDecoration(
            //   color: Theme.of(context).cardColor,
            //   borderRadius: BorderRadius.circular(16),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.black.withValues(alpha: 0.03),
            //       blurRadius: 15,
            //       spreadRadius: 1,
            //       offset: const Offset(0, 4),
            //     ),
            //   ],
            // ),
            child: Consumer<ProductDetailsController>(
              builder: (context, details, child) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// اسم المنيج ===========================
                      Text(
                        productModel!.name ?? '',
                        style: textBold.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge,
                          fontFamily: 'IBM_Plex_Sans_Arabic',
                          height: 1.3,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Consumer<ReviewController>(
                          builder: (context, reviewController, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [


                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ...List.generate(5, (index) {
                                            final rating = double.tryParse(averageRatting ?? '0') ?? 0;
                                            IconData iconData;
                                            if (rating >= index + 1) {
                                              iconData = Icons.star_rate_rounded; // نجمة كاملة
                                            } else if (rating > index && rating < index + 1) {
                                              iconData = Icons.star_half_rounded; // نص نجمة
                                            } else {
                                              iconData = Icons.star_outline_rounded; // نجمة فاضية
                                            }
                                            return Icon(iconData, color: Colors.amber, size: 16);
                                          }),
                                          const SizedBox(width: 4),
                                          Text(
                                            (double.tryParse(averageRatting ?? '0') ?? 0).toStringAsFixed(1),
                                            style: textBold.copyWith(
                                                fontSize: Dimensions.fontSizeDefault,
                                                color: Theme.of(context).textTheme.bodyLarge?.color),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (productModel!.reviewsCount != null &&
                                        productModel!.reviewsCount! > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${productModel?.reviewsCount} ${getTranslated('reviews', context)}',
                                        style: textRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context).hintColor),
                                      ),
                                    ],
                                  ],
                                ),
                                //// هون كان عدد الطلبات
                              ],
                            );
                          }),
//////////////////م السعر قبل الخصم وبعده=======================
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if ((productModel!.discount != null &&
                                    productModel!.discount! > 0) ||
                                (productModel!.clearanceSale != null &&
                                    productModel!
                                            .clearanceSale!.discountAmount! >
                                        0)) ...[
                              const SizedBox(
                                  width: Dimensions.paddingSizeSmall),
                              CustomDirectionalityWidget(
                                child: Text(
                                    '${PriceConverter.convertPrice(context, startingPrice)}'
                                    '${endingPrice != null ? ' - ${PriceConverter.convertPrice(context, endingPrice)}' : ''}',
                                    style: titilliumRegular.copyWith(
                                        color: Theme.of(context).hintColor,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: Theme.of(context).hintColor,
                                        fontSize: 12)),
                              ),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  productModel!.discountType == 'percent'
                                      ? '-${productModel!.discount}%'
                                      : '-${PriceConverter.convertPrice(context, productModel!.discount)}',
                                  style: textBold.copyWith(
                                      color: Colors.red, fontSize: 11),
                                ),
                              ),
                            ],
                          ]),
                     SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomDirectionalityWidget(
                            child: Text(
                              '${startingPrice != null ? PriceConverter.convertPrice(
                                context,
                                startingPrice,
                                discount: (productModel?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? productModel?.clearanceSale?.discountAmount
                                    : productModel?.discount,
                                discountType: (productModel?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? productModel?.clearanceSale?.discountType
                                    : productModel?.discountType,
                              ) : ''}'
                                  '${endingPrice != null ? ' - ${PriceConverter.convertPrice(
                                context,
                                endingPrice,
                                discount: (productModel?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? productModel?.clearanceSale?.discountAmount
                                    : productModel?.discount,
                                discountType: (productModel?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? productModel?.clearanceSale?.discountType
                                    : productModel?.discountType,
                              )}' : ''}',
                              style: titilliumBold.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontSize:20,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if ((details.orderCount ?? 0) > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${details.orderCount} ${getTranslated('orders', context)}',
                                    style: textMedium.copyWith(
                                        fontSize: 11, color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ],
                              if ((details.wishCount ?? 0) > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${details.wishCount} ${getTranslated('wish_listed', context)}',
                                    style: textMedium.copyWith(fontSize: 11, color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      // Divider(
                      //     color: Theme.of(context)
                      //         .hintColor
                      //         .withValues(alpha: 0.08),
                      //     height: 24),



                      if (_isVariationAvailable() ||
                          (productModel!.colors != null &&
                              productModel!.colors!.isNotEmpty) ||
                          (productModel!.choiceOptions != null &&
                              productModel!.choiceOptions!.isNotEmpty)) ...[
                        Divider(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.08),
                            height: 24),
                        Text(
                          '${getTranslated('available', context)}',
                          style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ],

                      /// Available color
                      productModel!.colors != null &&
                              productModel!.colors!.isNotEmpty
                          ? Row(children: [
                              Text('${getTranslated('color', context)} : ',
                                  style: titilliumRegular.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context).hintColor,
                                  )),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Expanded(
                                  child: SizedBox(
                                      height: 32,
                                      child: ListView.separated(
                                        itemCount: productModel!.colors!.length,
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) {
                                          final color =
                                              ColorHelper.hexCodeToColor(
                                                  productModel
                                                      ?.colors?[index].code);
                                          return Center(
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                    width: 1.5),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 4,
                                                    spreadRadius: 0.5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder:
                                            (BuildContext context, int index) =>
                                                const SizedBox(
                                                    width: Dimensions
                                                        .paddingSizeSmall),
                                      ))),
                            ])
                          : const SizedBox(),

                      productModel!.colors != null &&
                              productModel!.colors!.isNotEmpty
                          ? const SizedBox(height: Dimensions.paddingSizeSmall)
                          : const SizedBox(),

                      productModel!.choiceOptions != null &&
                              productModel!.choiceOptions!.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: productModel!.choiceOptions!.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        '${productModel!.choiceOptions![index].title?.toCapitalized()} : ',
                                        style: titilliumRegular.copyWith(
                                          fontSize: Dimensions.fontSizeLarge,
                                          color: Theme.of(context).hintColor,
                                        )),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Expanded(
                                        child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              Dimensions.paddingSizeExtraSmall),
                                      child: SizedBox(
                                          height: 30,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: productModel!
                                                .choiceOptions![index]
                                                .options!
                                                .length,
                                            itemBuilder: (context, i) {
                                              return Container(
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: Dimensions
                                                        .paddingSizeDefault),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .hintColor
                                                      .withValues(alpha: 0.06),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Theme.of(context)
                                                          .hintColor
                                                          .withValues(
                                                              alpha: 0.15),
                                                      width: 0.5),
                                                ),
                                                child: Text(
                                                  productModel!
                                                      .choiceOptions![index]
                                                      .options![i]
                                                      .trim(),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: textMedium.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                  ),
                                                ),
                                              );
                                            },
                                            separatorBuilder:
                                                (BuildContext context,
                                                        int index) =>
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                          )),
                                    )),
                                  ],
                                );
                              },
                            )
                          : const SizedBox(),
                    ]);
              },
            ),
          )
        : const SizedBox();
  }

  bool _isVariationAvailable() =>
      ((productModel!.colors != null && productModel!.colors!.isNotEmpty) &&
          productModel!.choiceOptions != null &&
          productModel!.choiceOptions!.isNotEmpty);
}
