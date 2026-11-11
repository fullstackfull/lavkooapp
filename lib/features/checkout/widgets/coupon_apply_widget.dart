import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syriapharmacy/common/basewidget/custom_asset_image_widget.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/features/checkout/widgets/coupon_bottom_sheet_widget.dart';
import 'package:provider/provider.dart';

class CouponApplyWidget extends StatelessWidget {
  final TextEditingController couponController;
  final double orderAmount;
  const CouponApplyWidget(
      {super.key, required this.couponController, required this.orderAmount});

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponController>(builder: (context, couponProvider, _) {
      final bool isApplied =
          couponProvider.discount != null && couponProvider.discount != 0;

      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: isApplied
            ? Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.12), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.green,
                                  size: 20),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${getTranslated('coupon_applied', context)}',
                                    style: textBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          couponProvider.couponCode,
                                          style: textBold.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              Dimensions.paddingSizeExtraSmall),
                                      Text(
                                        '(-${PriceConverter.convertPrice(context, couponProvider.discount)} off)',
                                        style: textBold.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => couponProvider.removeCoupon(),
                        icon: Icon(Icons.cancel_rounded,
                            size: 22,
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withValues(alpha: 0.7)),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              )
            : InkWell(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (c) =>
                      CouponBottomSheetWidget(orderAmount: orderAmount),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: CustomAssetImageWidget(
                              Images.coupon,
                              height: 20,
                              width: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            '${getTranslated('add_coupon', context)}',
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 16),
                            const SizedBox(width: 4),
                            Text(
                              getTranslated('add', context) ?? 'Add',
                              style: textBold.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      )
          .animate()
          .fadeIn(duration: 350.ms)
          .slideX(begin: -0.05, end: 0, curve: Curves.easeOutQuad);
    });
  }
}
