import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

class OverallRatingWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  const OverallRatingWidget({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<int, int>> starData = [
      MapEntry(5, fiveStar),
      MapEntry(4, fourStar),
      MapEntry(3, threeStar),
      MapEntry(2, twoStar),
      MapEntry(1, oneStar),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeLarge,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).hintColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progress bars on the start side
          Expanded(
            flex: 3,
            child: Column(
              children: starData.map((entry) {
                final percent =
                    totalReviews > 0 ? entry.value / totalReviews : 0.0;
                return _buildBar(context, star: entry.key, percent: percent);
              }).toList(),
            ),
          ),

          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Divider
          Container(
              width: 1,
              height: 100,
              color: Theme.of(context).hintColor.withValues(alpha: 0.15)),

          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Score on the end side
          SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: textBold.copyWith(
                    fontSize: 40,
                    color: Colors.amber.shade700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                RatingBarIndicator(
                  rating: averageRating,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star_rounded, color: Colors.amber),
                  unratedColor: Colors.amber.withValues(alpha: 0.25),
                  itemCount: 5,
                  itemSize: 14,
                ),
                const SizedBox(height: 6),
                Text(
                  "$totalReviews ${getTranslated('ratings', context) ?? 'ratings'}",
                  style: titilliumRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context,
      {required int star, required double percent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$star',
            style: titilliumRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 5,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                backgroundColor: Color(0xFFF0F0F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
