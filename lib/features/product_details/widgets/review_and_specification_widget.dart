import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/review/controllers/review_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ReviewAndSpecificationSectionWidget extends StatelessWidget {
  final double? averageReview;
  const ReviewAndSpecificationSectionWidget({super.key, this.averageReview});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailsController>(
      builder: (context, productDetailsController, _) {
        final bool hasReviews = (averageReview ?? 0) > 0;

        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.homePagePadding,
              vertical: Dimensions.paddingSizeDefault),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      productDetailsController.selectReviewSection(false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !productDetailsController.isReviewSelected
                          ? Theme.of(context).cardColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !productDetailsController.isReviewSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      '${getTranslated('specification', context)}',
                      textAlign: TextAlign.center,
                      style: textBold.copyWith(
                        color: !productDetailsController.isReviewSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).hintColor,
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                  ),
                ),
              ),
              if (hasReviews) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        productDetailsController.selectReviewSection(true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: productDetailsController.isReviewSelected
                            ? Theme.of(context).cardColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: productDetailsController.isReviewSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${getTranslated('reviews', context)}',
                            style: textBold.copyWith(
                              color: productDetailsController.isReviewSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Consumer<ReviewController>(
                            builder: (context, reviewController, _) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      productDetailsController.isReviewSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context)
                                              .hintColor
                                              .withValues(alpha: 0.3),
                                ),
                                child: Text(
                                  '${reviewController.totalReviews}',
                                  style: textBold.copyWith(
                                    fontSize: 10,
                                    color: productDetailsController
                                            .isReviewSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
