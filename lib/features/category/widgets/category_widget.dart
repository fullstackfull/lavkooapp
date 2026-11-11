import 'package:flutter/material.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final int length;
  const CategoryWidget(
      {super.key,
        required this.category,
        required this.index,
        required this.length});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The approved circle: a thin ink ring, a white gap, then the image —
        // the story-circle treatment from Direction B's home.
        Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BrandColors.ink.withValues(alpha: 0.1),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).cardColor,
                width: 2.5,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                image: '${category.displayImageUrl}',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Category Name
        Text(
          category.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textMedium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
// class CategoryWidget extends StatelessWidget {
//   final CategoryModel category;
//   final int index;
//   final int length;
//   const CategoryWidget(
//       {super.key,
//       required this.category,
//       required this.index,
//       required this.length});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Container(
//           width: 70,
//           height: 70,
//           padding: const EdgeInsets.all(3.0), // Creates the gap/distance from the border
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Theme.of(context).cardColor,
//             border: Border.all(
//               color: Theme.of(context).primaryColor,
//               width: 0.05,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: ClipOval(
//             child: CustomImageWidget(
//               image: '${category.displayImageUrl}',
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         const SizedBox(height: Dimensions.paddingSizeExtraSmall),
//
//         // Category Name
//         Text(
//           category.name ?? '',
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           textAlign: TextAlign.center,
//           style: textMedium.copyWith(
//             color: Theme.of(context).textTheme.bodyLarge?.color,
//             fontSize: Dimensions.fontSizeSmall,
//           ),
//         ),
//       ],
//     );
//   }
// }
