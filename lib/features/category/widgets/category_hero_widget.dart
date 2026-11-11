import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/banner/domain/models/banner_model.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// The banner heading a category page, for whichever category the shopper is
/// standing on — a main category, a child or a sub-child alike.
///
/// The shop resolves which banner that is: the category's own, else the nearest
/// ancestor's, else none. Nothing is invented here — a category with no banner
/// anywhere above it renders nothing at all rather than stretching its little
/// round icon across the page.
class CategoryHeroWidget extends StatefulWidget {
  const CategoryHeroWidget({
    super.key,
    required this.categoryId,
    this.categoryName,
    this.initialImage,
    this.height = 200, // زيادة الارتفاع من 130 إلى 200
  });

  final int? categoryId;
  final String? categoryName;

  /// A banner the caller already had — shown while this category's own header
  /// is still in flight, so opening a page never flashes an empty band.
  final String? initialImage;

  final double height;

  @override
  State<CategoryHeroWidget> createState() => _CategoryHeroWidgetState();
}

class _CategoryHeroWidgetState extends State<CategoryHeroWidget> {
  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void didUpdateWidget(CategoryHeroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shopper switched sibling: the hero follows the selection.
    if (oldWidget.categoryId != widget.categoryId) _request();
  }

  void _request() {
    final int? id = widget.categoryId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CategoryController>(context, listen: false)
          .getCategoryPageHeaderData(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(builder: (context, categoryProvider, _) {
      final String? resolved =
          categoryProvider.getBannerForCategory(widget.categoryId);
      final bool settled = categoryProvider.hasHeaderFor(widget.categoryId);

      // Until this category's own header answers, the caller's image stands in;
      // once it has answered, its verdict is final — including "no banner".
      final String? image = resolved ?? (settled ? null : widget.initialImage);
      if (image == null || image.trim().isEmpty || image == 'null') {
        return const SizedBox.shrink();
      }

      final BannerModel? hero =
          categoryProvider.getCategoryHero(widget.categoryId);

      final Widget banner = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(
              color: BrandColors.surface,
              child: CustomImageWidget(image: image, fit: BoxFit.fill),
            ),
            // A scrim only where the name sits, so a merchant's artwork keeps
            // its top half untouched.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.55, 1.0],
                  colors: [Color(0x99000000), Color(0x1A000000), Color(0x00000000)],
                ),
              ),
            ),
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text(
                  //   (hero?.title?.isNotEmpty ?? false)
                  //       ? hero!.title!
                  //       : (widget.categoryName ?? ''),
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: tajawalHeavy.copyWith(
                  //       fontSize: 16, color: Colors.white),
                  // ),
                  if (hero?.subTitle?.isNotEmpty ?? false)
                    Text(
                      hero!.subTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textRegular.copyWith(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: .9)),
                    ),
                ],
              ),
            ),
          ]),
        ),
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
        // The hero carries the merchant's own action, resolved by the same
        // gateway every other banner in the app uses.
        child: hero == null
            ? banner
            : InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    Provider.of<BannerController>(context, listen: false)
                        .openBanner(context, hero),
                child: banner,
              ),
      );
    });
  }
}
