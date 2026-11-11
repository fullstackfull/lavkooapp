import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/paginated_list_view_widget.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/review/controllers/review_controller.dart';
import 'package:syriapharmacy/features/review/widgets/overall_rating_widget.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/features/review/widgets/review_widget.dart';
import 'package:provider/provider.dart';

class ReviewSection extends StatelessWidget {
  final ProductDetailsController details;
  const ReviewSection({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewController>(
      builder: (context, reviewController, _) {
        final reviews = reviewController.reviewList ?? [];
        final bool hasMore = reviews.length < (reviewController.totalReviews);

        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OverallRatingWidget(
                averageRating:
                    double.tryParse(reviewController.averageRating ?? '0') ??
                        0.0,
                totalReviews: reviewController.totalReviews,
                fiveStar: reviewController.getStarCount(5),
                fourStar: reviewController.getStarCount(4),
                threeStar: reviewController.getStarCount(3),
                twoStar: reviewController.getStarCount(2),
                oneStar: reviewController.getStarCount(1),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              PaginatedListView(
                totalSize: reviewController.totalReviews,
                offset: reviewController.currentPage,
                limit: 10,
                onPaginate: (int? offset) async {
                  await reviewController.getReviewList(offset ?? 1);
                },
                itemView: reviewController.isLoading && reviews.isEmpty
                    ? const ReviewShimmer()
                    : reviews.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined,
                                    size: 48,
                                    color: Theme.of(context)
                                        .hintColor
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 10),
                                Text(
                                  getTranslated('no_rating_and_review_found',
                                          context) ??
                                      'No reviews yet',
                                  style: titilliumRegular.copyWith(
                                    color: Theme.of(context).hintColor,
                                    fontSize: Dimensions.fontSizeDefault,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: reviews
                                .map((review) =>
                                    ReviewWidget(reviewModel: review))
                                .toList(),
                          ),
              ),
              if (hasMore) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                reviewController.isLoading
                    ? const CircularProgressIndicator()
                    : InkWell(
                        onTap: () async {
                          await reviewController
                              .getReviewList(reviewController.currentPage + 1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeSmall,
                            horizontal: Dimensions.paddingSizeDefault,
                          ),
                          child: Text(
                            getTranslated('see_more_reviews', context)!,
                            style: titilliumRegular.copyWith(
                              color: Theme.of(context).primaryColor,
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
