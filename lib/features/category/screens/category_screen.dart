import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/common/basewidget/title_row_widget.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/features/category/widgets/category_hero_widget.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// The Direction B category landing: compact sibling tabs on top, the selected
/// parent's children as a full-width visual grid, the category's own campaign
/// banner, and a rail of its real products — one connected hierarchy instead of
/// a permanent sidebar.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key,this.showBackButton = false});
  final bool showBackButton;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  /// The landing is built eagerly inside the dashboard's IndexedStack, often
  /// before the category list has arrived — so the first category's header and
  /// products are requested from the builder, once, when the list exists.
  bool _bootstrapped = false;

  @override
  void initState() {
    Provider.of<CategoryController>(context, listen: false)
        .onChangeSelectedIndex(0, isUpdate: false);
    super.initState();
  }

  void _bootstrap(CategoryController categoryController) {
    if (_bootstrapped || categoryController.categoryList.isEmpty) return;
    _bootstrapped = true;
    final firstCategory = categoryController.categoryList[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      categoryController.getCategoryPageHeaderData(firstCategory.id!);
      Provider.of<ProductController>(context, listen: false)
          .initBrandOrCategoryProductList(
        isBrand: false,
        id: firstCategory.id,
        offset: 1,
      );
    });
  }

  void _selectCategory(BuildContext context, int index) {
    final categoryProvider =
        Provider.of<CategoryController>(context, listen: false);
    final category = categoryProvider.categoryList[index];
    categoryProvider.getCategoryPageHeaderData(category.id!);
    categoryProvider.onChangeSelectedIndex(index);
    Provider.of<ProductController>(context, listen: false)
        .initBrandOrCategoryProductList(
      isBrand: false,
      id: category.id,
      offset: 1,
    );
  }

  void _openPlp(CategoryModel parent, {int? id, String? name}) {
    RouterHelper.getBrandCategoryRoute(
      action: RouteAction.push,
      isBrand: false,
      id: id ?? parent.id,
      name: name ?? parent.name,
      categoryModel: parent,
      isAllProduct: id == null,
      bannerImageUrl: Provider.of<CategoryController>(context, listen: false)
          .getBannerForCategory(parent.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: getTranslated('CATEGORY', context), isBackButtonExist: widget.showBackButton),
      body: Consumer<CategoryController>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.categoryList.isEmpty) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor)));
          }

          _bootstrap(categoryProvider);

          final int selectedIndex =
              categoryProvider.categorySelectedIndex ?? 0;
          final CategoryModel selected =
              categoryProvider.categoryList[selectedIndex];
          final List<SubCategory> subCategories =
              selected.subCategories ?? const [];

          return Column(children: [
            // ── 1. Parent categories as compact underline tabs ──
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: BrandColors.hairline, width: 1)),
              ),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault),
                  itemCount: categoryProvider.categoryList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, index) {
                    final bool isSelected = index == selectedIndex;
                    return InkWell(
                      onTap: () => _selectCategory(context, index),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? BrandColors.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          categoryProvider.categoryList[index].name ?? '',
                          style: isSelected
                              ? robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: BrandColors.primary)
                              : textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).hintColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── 2. The selected category's landing content ──
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                children: [
                  CategoryHeroWidget(
                    categoryId: selected.id,
                    categoryName: selected.name,
                  ),

                  if (subCategories.isNotEmpty)
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeDefault,
                          0),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.98,
                      children: [
                        _AllProductsTile(
                          count: selected.totalProductCount,
                          onTap: () => _openPlp(selected),
                        ),
                        for (final sub in subCategories)
                          _SubCategoryTile(
                            sub: sub,
                            onTap: () => _openPlp(selected,
                                id: sub.id, name: sub.name),
                          ),
                      ],
                    ),

                  // ── 3. The category's real products, previewed ──
                  Consumer<ProductController>(
                      builder: (context, productController, _) {
                    final products = productController
                        .brandOrCategoryProductList?.products;
                    if (products == null || products.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          TitleRowWidget(
                            title: selected.name,
                            onTap: () => _openPlp(selected),
                          ),
                          SizedBox(
                            height: 306,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeSmall),
                              itemCount:
                                  products.length > 8 ? 8 : products.length,
                              itemBuilder: (context, index) => SizedBox(
                                width: 158,
                                child: ProductWidget(
                                    productModel: products[index],
                                    productNameLine: 1),
                              ),
                            ),
                          ),
                        ]);
                  }),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/// The gradient «الكل» tile leading the subcategory grid.
class _AllProductsTile extends StatelessWidget {
  const _AllProductsTile({required this.onTap, this.count});

  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: BrandGradients.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(getTranslated('all', context) ?? '',
                style: tajawalHeavy.copyWith(
                    fontSize: 15, color: Colors.white)),
            if (count != null)
              Text(
                '$count ${getTranslated('products', context)}',
                maxLines: 1,
                style: textRegular.copyWith(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: .85)),
              ),
          ],
        ),
      ),
    );
  }
}

/// One subcategory as the approved landing card: contained image on the soft
/// lilac ramp, the name, and its real product count.
class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({required this.sub, required this.onTap});

  final SubCategory sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.hairline),
          gradient: dark
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [BrandColors.surface, Colors.white],
                ),
          color: dark ? Theme.of(context).cardColor : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 44,
              child: (sub.displayImageUrl?.isNotEmpty ?? false)
                  ? CustomImageWidget(
                      image: sub.displayImageUrl!, fit: BoxFit.contain)
                  : Icon(Icons.category_outlined,
                      size: 30,
                      color: BrandColors.primary.withValues(alpha: .4)),
            ),
            const SizedBox(height: 6),
            Text(
              sub.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textBold.copyWith(fontSize: 10),
            ),
            if (sub.totalProductCount != null)
              Text(
                '${sub.totalProductCount} ${getTranslated('products', context)}',
                maxLines: 1,
                style: textRegular.copyWith(
                    fontSize: 8.5, color: Theme.of(context).hintColor),
              ),
          ],
        ),
      ),
    );
  }
}
