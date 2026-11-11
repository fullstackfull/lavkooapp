import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// What this shop sells, as aisles the shopper can walk.
///
/// The store page already loaded the shop's own categories and then showed them
/// in one place only: inside the filter sheet. A shopper had to know that sheet
/// existed to discover what the shop stocks. The rail puts them on the page and
/// runs the same filter the sheet runs — same list, same controller, same
/// request — so the two can never disagree about what a category means here.
class ShopCategoryRail extends StatelessWidget {
  final String slug;

  /// Move the store page to its products tab. The rail narrows the listing;
  /// the page it lives on owns which tab is showing.
  final VoidCallback onBrowse;

  const ShopCategoryRail({
    super.key,
    required this.slug,
    required this.onBrowse,
  });

  Future<void> _apply(BuildContext context, CategoryModel category) async {
    final CategoryController categories =
        Provider.of<CategoryController>(context, listen: false);
    final SellerProductController products =
        Provider.of<SellerProductController>(context, listen: false);

    // Tapping the aisle you are already in is the way back out of it.
    if (category.isSelected ?? false) {
      await categories.resetChecked(slug, true);
      onBrowse();
      return;
    }

    categories.selectOnlyCategoryById(category.id ?? 0);
    onBrowse();
    await products.getSellerProductList(slug, 1, '',
        categoryIds: jsonEncode([category.id]));
    products.setFilterApply(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(
        builder: (context, categoryController, _) {
      // THIS shop's categories, never the shared filtered list: that one still
      // holds the marketplace's own categories until the shop's arrive, and a
      // rail drawn from it offered aisles the shop does not stock.
      final List<CategoryModel> categories =
          categoryController.sellerWiseCategoryList;
      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(mainAxisSize: MainAxisSize.min, children: [
        TitleRowWidget(title: getTranslated('shop_by_category', context)),
        // Every aisle is built up front rather than viewported lazily. A shop
        // has a handful of categories, and a lazy horizontal list nested in
        // this page's sliver laid out only its first tile once the tabs had
        // been round-tripped — the rest of the shop simply disappeared.
        SizedBox(
          height: 108,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Row(children: [
              for (int index = 0; index < categories.length; index++)
                _Aisle(
                  category: categories[index],
                  onTap: () => _apply(context, categories[index]),
                ),
            ]),
          ),
        ),
      ]);
    });
  }
}

class _Aisle extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  const _Aisle({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = category.isSelected ?? false;
    return Padding(
      // Directional, not physical: in Arabic the rail runs the other way and a
      // fixed right-hand gap lands on the wrong side of every tile.
      padding: const EdgeInsetsDirectional.only(end: Dimensions.paddingSizeSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? BrandGradients.primary : null,
                color: active ? null : BrandColors.surface,
                border: active ? null : Border.all(color: BrandColors.hairline),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                ),
                padding: const EdgeInsets.all(9),
                child: ClipOval(
                  child: CustomImageWidget(
                    image: category.imageFullUrl?.path ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name ?? '',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                height: 1.25,
                color: active
                    ? BrandColors.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
