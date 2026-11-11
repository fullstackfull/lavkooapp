import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/discount_tag_widget.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/home/shimmers/recommended_product_shimmer.dart';
import 'package:syriapharmacy/features/product_details/widgets/favourite_button_widget.dart';
import 'package:provider/provider.dart';

class RecommendedProductWidget extends StatelessWidget {
  final bool fromAsterTheme;
  const RecommendedProductWidget({super.key, this.fromAsterTheme = false});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(
          top: Dimensions.paddingSizeSmall,
          bottom: Dimensions.paddingSizeDefault),
      color:
          isDarkMode ? Theme.of(context).colorScheme.onTertiary : Colors.white,
      child: Column(
        children: [
          Consumer<ProductController>(
            builder: (context, recommended, child) {
              String? ratting = recommended.recommendedProduct != null &&
                      recommended.recommendedProduct!.rating != null &&
                      recommended.recommendedProduct!.rating!.isNotEmpty
                  ? recommended.recommendedProduct!.rating![0].average
                  : "0";

              return (recommended.recommendedProduct != null)
                  ? recommended.recommendedProduct?.id != -1
                      ? InkWell(
                          onTap: () {
                            RouterHelper.getProductDetailsRoute(
                                action: RouteAction.push,
                                productId: recommended.recommendedProduct!.id,
                                slug: recommended.recommendedProduct!.slug);
                          },
                          child: Column(
                            children: [
                              fromAsterTheme
                                  ? Column(children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical:
                                                Dimensions.paddingSizeSmall),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              getTranslated(
                                                      'dont_miss_the_chance',
                                                      context) ??
                                                  '',
                                              style: textBold.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeLarge,
                                                  color:
                                                      Provider.of<ThemeController>(
                                                                  context,
                                                                  listen: false)
                                                              .darkTheme
                                                          ? Theme.of(context)
                                                              .hintColor
                                                          : Theme.of(context)
                                                              .primaryColor),
                                            ),
                                            const SizedBox(
                                                width: Dimensions
                                                    .paddingSizeDefault),
                                            const FakeCountdownTimerWidget(),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              bottom:
                                                  Dimensions.paddingSizeSmall),
                                          child: Text(
                                              getTranslated(
                                                      'lets_shopping_today',
                                                      context) ??
                                                  '',
                                              style: textBold.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeExtraLarge,
                                                  color: Provider.of<ThemeController>(
                                                              context,
                                                              listen: false)
                                                          .darkTheme
                                                      ? Theme.of(context)
                                                          .hintColor
                                                      : Theme.of(context)
                                                          .primaryColor)))
                                    ])
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: Dimensions.paddingSizeDefault,
                                          top:
                                              Dimensions.paddingSizeExtraSmall),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            getTranslated(
                                                    'deal_of_the_day', context) ??
                                                '',
                                            style: textBold.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeExtraLarge,
                                                color: Provider.of<ThemeController>(
                                                            context,
                                                            listen: false)
                                                        .darkTheme
                                                    ? Theme.of(context).hintColor
                                                    : Theme.of(context)
                                                        .primaryColor),
                                          ),
                                          const SizedBox(width: Dimensions.paddingSizeDefault),
                                          const FakeCountdownTimerWidget(),
                                        ],
                                      ),
                                    ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.homePagePadding),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(16)),
                                      color: Theme.of(context).cardColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ]),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (recommended.recommendedProduct !=
                                              null &&
                                          recommended.recommendedProduct!
                                                  .thumbnail !=
                                              null) ...[
                                        Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .highlightColor,
                                                  border: Border.all(
                                                      color: Theme.of(context)
                                                          .hintColor
                                                          .withValues(
                                                              alpha: 0.1),
                                                      width: .5),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(12))),
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(12)),
                                                child: CustomImageWidget(
                                                  height:
                                                      ResponsiveHelper.isTab(
                                                              context)
                                                          ? 200
                                                          : 100,
                                                  width: ResponsiveHelper.isTab(
                                                          context)
                                                      ? 200
                                                      : 100,
                                                  image:
                                                      '${recommended.recommendedProduct?.thumbnailFullUrl?.path}',
                                                ),
                                              ),
                                            ),
                                            if (recommended.recommendedProduct!
                                                        .currentStock! ==
                                                    0 &&
                                                recommended.recommendedProduct!
                                                        .productType ==
                                                    'physical')
                                              Positioned.fill(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(12)),
                                                  child: Container(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.4),
                                                    child: Center(
                                                      child: Text(
                                                        getTranslated(
                                                                'out_of_stock',
                                                                context) ??
                                                            '',
                                                        style:
                                                            textBold.copyWith(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Positioned(
                                              top: 8,
                                              right: isLtr ? 10 : null,
                                              left: !isLtr ? 10 : null,
                                              child: FavouriteButtonWidget(
                                                backgroundColor:
                                                    Provider.of<ThemeController>(context, listen: false).darkTheme
                                                        ? Theme.of(context).cardColor
                                                        : Theme.of(context).primaryColor,
                                                productId: recommended
                                                    .recommendedProduct?.id,
                                              ),
                                            ),
                                            if (recommended
                                                        .recommendedProduct !=
                                                    null &&
                                                recommended.recommendedProduct!
                                                        .discount !=
                                                    null &&
                                                ((recommended
                                                            .recommendedProduct!
                                                            .discount! >
                                                        0) ||
                                                    (recommended
                                                                .recommendedProduct
                                                                ?.clearanceSale
                                                                ?.discountAmount ??
                                                            0) >
                                                        0))
                                              DiscountTagWidget(
                                                productModel: recommended
                                                    .recommendedProduct!,
                                                positionedTop: 0,
                                                topLeftBorderRadius: 12,
                                                bottomRightBorderRadius: 12,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(
                                            width: Dimensions.paddingSizeSmall),
                                      ],
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if ((recommended.recommendedProduct
                                                            ?.reviewCount ??
                                                        0) >
                                                    0 ||
                                                double.parse(ratting!) > 0) ...[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                      Icons.star_rate_rounded,
                                                      color: Colors.orange,
                                                      size: 16),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    double.parse(ratting!)
                                                        .toStringAsFixed(1),
                                                    style: textBold.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        color:
                                                            Colors.orange[800]),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '(${recommended.recommendedProduct?.reviewCount ?? '0'})',
                                                    style: textRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        color: Theme.of(context)
                                                            .hintColor),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Text(
                                              recommended.recommendedProduct!
                                                      .name ??
                                                  '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textBold.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color),
                                            ),
                                            const SizedBox(height: 4),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (recommended.recommendedProduct != null &&
                                                    recommended
                                                            .recommendedProduct!
                                                            .discount !=
                                                        null &&
                                                    (recommended.recommendedProduct!
                                                                .discount! >
                                                            0 ||
                                                        (recommended
                                                                    .recommendedProduct
                                                                    ?.clearanceSale
                                                                    ?.discountAmount ??
                                                                0) >
                                                            0))
                                                  Text(
                                                    PriceConverter.convertPrice(
                                                        context,
                                                        recommended
                                                            .recommendedProduct!
                                                            .unitPrice),
                                                    style: textRegular.copyWith(
                                                      color: Theme.of(context)
                                                          .hintColor,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                    ),
                                                  ),
                                                const SizedBox(height: 2),
                                                if (recommended
                                                            .recommendedProduct !=
                                                        null &&
                                                    recommended
                                                            .recommendedProduct!
                                                            .unitPrice !=
                                                        null)
                                                  Text(
                                                    PriceConverter.convertPrice(
                                                      context,
                                                      recommended
                                                          .recommendedProduct!
                                                          .unitPrice,
                                                      discountType: (recommended
                                                                      .recommendedProduct
                                                                      ?.clearanceSale
                                                                      ?.discountAmount ??
                                                                  0) >
                                                              0
                                                          ? recommended
                                                              .recommendedProduct
                                                              ?.clearanceSale
                                                              ?.discountType
                                                          : recommended
                                                              .recommendedProduct
                                                              ?.discountType,
                                                      discount: (recommended
                                                                      .recommendedProduct
                                                                      ?.clearanceSale
                                                                      ?.discountAmount ??
                                                                  0) >
                                                              0
                                                          ? recommended
                                                              .recommendedProduct
                                                              ?.clearanceSale
                                                              ?.discountAmount
                                                          : recommended
                                                              .recommendedProduct
                                                              ?.discount,
                                                    ),
                                                    style: textBold.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: AlignmentDirectional
                                                  .centerEnd,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: isDarkMode
                                                      ? Theme.of(context)
                                                          .highlightColor
                                                      : Theme.of(context)
                                                          .primaryColor,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.2),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  getTranslated(
                                                      'grab_this_deal',
                                                      context)!,
                                                  style: textBold.copyWith(
                                                      color: Colors.white,
                                                      fontSize: Dimensions
                                                          .fontSizeSmall),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox()
                  : const RecommendedProductShimmer();
            },
          ),
        ],
      ),
    );
  }
}

class FakeCountdownTimerWidget extends StatefulWidget {
  const FakeCountdownTimerWidget({super.key});

  @override
  State<FakeCountdownTimerWidget> createState() =>
      _FakeCountdownTimerWidgetState();
}

class _FakeCountdownTimerWidgetState extends State<FakeCountdownTimerWidget> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _timeLeft = endOfDay.difference(now);
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int hours = _timeLeft.inHours;
    int minutes = _timeLeft.inMinutes.remainder(60);
    int seconds = _timeLeft.inSeconds.remainder(60);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _timeBox(context, hours.toString().padLeft(2, '0'),
              getTranslated('hour', context) ?? 'ساعة'),
          const SizedBox(width: 4),
          _timeSeparator(context),
          const SizedBox(width: 4),
          _timeBox(context, minutes.toString().padLeft(2, '0'),
              getTranslated('min', context) ?? 'دقيقة'),
          const SizedBox(width: 4),
          _timeSeparator(context),
          const SizedBox(width: 4),
          _timeBox(context, seconds.toString().padLeft(2, '0'),
              getTranslated('sec', context) ?? 'ثانية'),
        ],
      ),
    );
  }

  Widget _timeBox(BuildContext context, String time, String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).highlightColor
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            time,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textRegular.copyWith(
            fontSize: 9,
            color: isDark
                ? Theme.of(context).hintColor
                : Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _timeSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        ':',
        style: textBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Provider.of<ThemeController>(context, listen: false).darkTheme
              ? Theme.of(context).hintColor
              : Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
