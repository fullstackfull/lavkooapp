import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/review/domain/models/review_model.dart';
import 'package:syriapharmacy/helper/date_converter.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/image_diaglog_widget.dart';
import 'package:syriapharmacy/common/basewidget/rating_bar_widget.dart';
import 'package:readmore/readmore.dart';
import 'package:shimmer/shimmer.dart';

class ReviewWidget extends StatelessWidget {
  final ReviewModel reviewModel;
  const ReviewWidget({super.key, required this.reviewModel});

  @override
  Widget build(BuildContext context) {
    final int rating = reviewModel.rating?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeExtraSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(
          color: Theme.of(context).hintColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row: avatar + name + date + rating badge
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FadeInImage.assetNetwork(
                placeholder: Images.placeholder,
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                image:
                    '${reviewModel.customer != null ? reviewModel.customer!.imageFullUrl?.path : ''}',
                imageErrorBuilder: (c, o, s) => Image.asset(
                  Images.placeholder,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Name & date
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${reviewModel.customer == null ? getTranslated('user_not_exist', context) : reviewModel.customer!.fName ?? ''} ${reviewModel.customer == null ? '' : reviewModel.customer!.lName ?? ''}',
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (reviewModel.createdAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateConverter.compareDates(reviewModel.createdAt!),
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ]
            ]),
          ),

          // Rating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 3),
              Text(
                '$rating',
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.amber.shade700,
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // Comment
        if ((reviewModel.comment ?? '').isNotEmpty) ...[
          ReadMoreText(
            reviewModel.comment ?? '',
            trimMode: TrimMode.Line,
            trimLines: 3,
            textAlign: TextAlign.start,
            preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color
                  ?.withValues(alpha: 0.85),
              height: 1.5,
              fontSize: 13,
            ),
            colorClickableText: Theme.of(context).primaryColor,
            trimCollapsedText: getTranslated('see_more', context)!,
            trimExpandedText: getTranslated('see_less', context)!,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],

        // Attached images
        if (reviewModel.attachmentFullUrl != null &&
            reviewModel.attachmentFullUrl!.isNotEmpty) ...[
          SizedBox(
            height: 70,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: reviewModel.attachmentFullUrl!.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ImageDialog(
                          imageUrl:
                              '${reviewModel.attachmentFullUrl![index].path}'),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                        right: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            Theme.of(context).hintColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FadeInImage.assetNetwork(
                        placeholder: Images.placeholder,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        image: '${reviewModel.attachmentFullUrl![index].path}',
                        imageErrorBuilder: (c, o, s) => Image.asset(
                          Images.placeholder,
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],

        // Seller reply
        if (reviewModel.reply != null) ...[
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              border: Border.all(
                  color:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Image.asset(Images.sellerReplyIcon,
                        height: 16, width: 16),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text(
                    getTranslated('reply_by_seller', context)!,
                    style: textBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ]),
                Text(
                  DateConverter.dateTimeStringToMonthDateAndTime(
                      reviewModel.reply!.createdAt!),
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              ReadMoreText(
                reviewModel.reply?.replyText ?? '',
                trimMode: TrimMode.Line,
                trimLines: 3,
                textAlign: TextAlign.start,
                preDataTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.5,
                  fontSize: 13,
                ),
                colorClickableText: Theme.of(context).primaryColor,
                trimCollapsedText: getTranslated('see_more', context)!,
                trimExpandedText: getTranslated('see_less', context)!,
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class ReviewShimmer extends StatelessWidget {
  const ReviewShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
            3,
            (i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const CircleAvatar(
                        maxRadius: 20, backgroundColor: Colors.white),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 10, width: 100, color: Colors.white),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                                height: 10, width: 50, color: Colors.white),
                            const SizedBox(width: 5),
                            const RatingBar(rating: 0, size: 12),
                          ]),
                        ]),
                  ]),
                )),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Theme.of(Get.context!).primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double dashWidth = 5, dashSpace = 3;
    Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height - size.width / 2)
      ..arcToPoint(Offset(size.width, size.height),
          radius: Radius.circular(size.width / 2), clockwise: false);

    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
