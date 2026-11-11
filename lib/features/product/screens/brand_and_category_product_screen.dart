import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/paginated_list_view_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/features/category/widgets/category_hero_widget.dart';
import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/helper/debounce_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_shimmer_widget.dart';
import 'package:syriapharmacy/common/basewidget/product_widget.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class BrandAndCategoryProductScreen extends StatefulWidget {
  final bool isBrand;
  final int? id;
  final String? name;
  final String? image;
  final CategoryModel? categoryModel;
  final SubCategory? subCategory;
  final bool isInsideSubSubCategory;
  final bool isAllProduct;
  final String? bannerImageUrl;

  const BrandAndCategoryProductScreen(
      {super.key,
      required this.isBrand,
      required this.id,
      required this.name,
      this.image,
      this.subCategory,
      this.isInsideSubSubCategory = false,
      this.categoryModel,
      this.isAllProduct = false,
        this.bannerImageUrl, // 2. أضفه هنا
      });

  @override
  State<BrandAndCategoryProductScreen> createState() =>
      _BrandAndCategoryProductScreenState();
}

class _BrandAndCategoryProductScreenState
    extends State<BrandAndCategoryProductScreen> {
  final TextEditingController searchTextEditingController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  late List<SubSubCategory>? subSubCategoryList;
  late List<SubCategory>? subCategoryList;

  /// Hierarchy this screen resolved for itself when the caller passed only an id — a banner,
  /// a theme section or a deep link knows the category's id, not its family.
  CategoryModel? _resolvedCategory;
  SubCategory? _resolvedSub;

  /// The names ABOVE the current category, top first — "Beauty / Skin Care" over Cleansers.
  List<_TrailStop> _trail = const [];

  /// The approved sort/filter chips' state. When any is set the grid is fed by
  /// the filter endpoint (the only sort-capable listing API), scoped to the
  /// category the shopper is looking at; cleared, it returns to the plain list.
  String? _sortText;
  String? _priceMin;
  String? _priceMax;
  bool get _filtered =>
      _sortText != null || _priceMin != null || _priceMax != null;

  /// Bumped whenever the applied filter changes, so a page still in flight for
  /// the previous filter can tell that its results are stale.
  Object _filterToken = Object();

  /// This page's own filtered results.
  ///
  /// Drilling into a subcategory pushes a second copy of this screen, and the
  /// filter controller is app-scoped — one `searchedProduct` for both. Holding
  /// the model this page fetched is what stops the page underneath redrawing
  /// with the deeper page's products, and what makes it still correct when the
  /// shopper comes back. The controller replaces the model on every fresh
  /// query rather than mutating it, so the copy kept here stays whole.
  ProductModel? _filterResults;
  bool _filterLoading = false;

  static const List<String> _sortKeys = [
    'latest_products',
    'alphabetically_az',
    'alphabetically_za',
    'low_to_high_price',
    'high_to_low_price',
  ];
  static const List<String> _sortValues = [
    'latest',
    'a-z',
    'z-a',
    'low-high',
    'high-low',
  ];

  Future<void> _applyFilters() async {
    final Object token = Object();
    _filterToken = token;
    final SearchProductController searchController =
        Provider.of<SearchProductController>(context, listen: false);
    final int? id =
        Provider.of<ProductController>(context, listen: false)
                .selectedCategoryId ??
            widget.id;
    setState(() {
      _filterLoading = true;
      _filterResults = null;
    });
    await searchController.searchProduct(
      query: searchTextEditingController.text.trim(),
      updateSearchField: false,
      categoryIds: widget.isBrand ? null : '[$id]',
      brandIds: widget.isBrand ? '[$id]' : null,
      sort: _sortText ?? 'default',
      priceMin: _priceMin ?? '',
      priceMax: _priceMax ?? '',
      offset: 1,
    );
    // The shopper changed the filter, or left, while this was in flight.
    if (!mounted || token != _filterToken) {
      return;
    }
    setState(() {
      _filterResults = searchController.searchedProduct;
      _filterLoading = false;
    });
  }

  void _clearFilters() {
    _filterToken = Object();
    setState(() {
      _sortText = null;
      _priceMin = null;
      _priceMax = null;
      _filterResults = null;
      _filterLoading = false;
    });
  }

  Widget _sortFilterChip({
    required String label,
    required bool active,
    bool lilac = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? (lilac ? BrandColors.surfaceDeep : BrandColors.inkSoft)
              : null,
          border: active
              ? null
              : Border.all(color: BrandColors.ink.withValues(alpha: .14)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: textBold.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: active
                ? (lilac ? BrandColors.primary : Colors.white)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  /// The approved chips row: an ink-filled sort chip when a sort is applied,
  /// lilac removable chips for applied filters, outline chips otherwise.
  Widget _filterChipsRow() {
    final String sortLabel = _sortText == null
        ? '⇅ ${getTranslated('sort_by', context)}'
        : '⇅ ${getTranslated(_sortKeys[_sortValues.indexOf(_sortText!)], context)}';
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault, vertical: 8),
      child: Row(children: [
        _sortFilterChip(
            label: sortLabel,
            active: _sortText != null,
            onTap: _openFilterSheet),
        const SizedBox(width: 7),
        _sortFilterChip(
            label: '${getTranslated('price', context)} ▾',
            active: false,
            onTap: _openFilterSheet),
        if (_priceMin != null || _priceMax != null) ...[
          const SizedBox(width: 7),
          _sortFilterChip(
            label:
                '${getTranslated('price', context)}: \u2066${_priceMin ?? '0'}–${_priceMax ?? '∞'}\u2069 ✕',
            active: true,
            lilac: true,
            onTap: () {
              setState(() {
                _priceMin = null;
                _priceMax = null;
              });
              if (_filtered) {
                _applyFilters();
              }
            },
          ),
        ],
        if (_sortText != null) ...[
          const SizedBox(width: 7),
          _sortFilterChip(
            label:
                '${getTranslated(_sortKeys[_sortValues.indexOf(_sortText!)], context)} ✕',
            active: true,
            lilac: true,
            onTap: () {
              setState(() => _sortText = null);
              if (_filtered) {
                _applyFilters();
              }
            },
          ),
        ],
      ]),
    ));
  }

  /// The inline flash strip from the approved PLP — shown only while a real
  /// campaign is live, counting its true remainder, linking to the deal screen.
  Widget _flashStrip() {
    return Consumer<FlashDealController>(builder: (context, megaDeal, _) {
      final Duration remain = megaDeal.duration ?? Duration.zero;
      if (megaDeal.flashDeal == null || remain <= Duration.zero) {
        return const SizedBox.shrink();
      }
      String two(int v) => v < 10 ? '0$v' : '$v';
      final String clock =
          '${two(remain.inHours)}:${two(remain.inMinutes % 60)}:${two(remain.inSeconds % 60)}';
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => RouterHelper.getFlashDealScreenViewRoute(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: BrandGradients.flash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ ${megaDeal.flashDeal?.title ?? getTranslated('flash_deal', context)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Colors.white),
                      ),
                      Text(
                        '${getTranslated('ends_in', context)} $clock',
                        style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Colors.white.withValues(alpha: .9)),
                      ),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  getTranslated('VIEW_ALL', context) ?? '',
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: BrandColors.inkSoft),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }

  /// «كل منتجات <القسم>» with the real total, above the grid.
  Widget _allProductsHeader(int? totalSize) {
    if (totalSize == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault, 8, Dimensions.paddingSizeDefault, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              '${getTranslated('all_products', context)} · ${widget.name ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tajawalBlack.copyWith(fontSize: 15),
            ),
          ),
          Text(
            '$totalSize ${getTranslated('products', context)}',
            style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final TextEditingController minController =
        TextEditingController(text: _priceMin ?? '');
    final TextEditingController maxController =
        TextEditingController(text: _priceMax ?? '');
    String? sortChoice = _sortText;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              top: Dimensions.paddingSizeDefault,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                  Dimensions.paddingSizeDefault),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Text(getTranslated('sort_by', sheetContext) ?? '',
                style: tajawalBlack.copyWith(
                    fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_sortKeys.length, (index) {
                final bool selected = sortChoice == _sortValues[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setSheetState(() => sortChoice =
                      selected ? null : _sortValues[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? BrandColors.inkSoft : null,
                      border: selected
                          ? null
                          : Border.all(
                              color:
                                  BrandColors.ink.withValues(alpha: .14)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getTranslated(_sortKeys[index], sheetContext) ?? '',
                      style: textBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: selected
                              ? Colors.white
                              : Theme.of(sheetContext)
                                  .textTheme
                                  .bodyLarge
                                  ?.color),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Row(children: [
              Text(getTranslated('price', sheetContext) ?? '',
                  style: tajawalBlack.copyWith(
                      fontSize: Dimensions.fontSizeLarge)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: getTranslated('min_price', sheetContext),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: getTranslated('max_price', sheetContext),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                _sortText = sortChoice;
                _priceMin = minController.text.trim().isEmpty
                    ? null
                    : minController.text.trim();
                _priceMax = maxController.text.trim().isEmpty
                    ? null
                    : maxController.text.trim();
                Navigator.pop(sheetContext);
                if (_filtered) {
                  _applyFilters();
                } else {
                  _clearFilters();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: BrandGradients.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(getTranslated('apply', sheetContext) ?? '',
                    style: robotoBold.copyWith(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  final DebounceHelper debounceHelper = DebounceHelper(milliseconds: 500);

  CategoryModel? get _categoryContext =>
      widget.categoryModel ?? _resolvedCategory;
  SubCategory? get _subContext => widget.subCategory ?? _resolvedSub;

  void _initializeCategoryList(String categoryName) {
    subCategoryList = [];
    subSubCategoryList = [];

    final subContext = _subContext;
    final categoryContext = _categoryContext;

    if ((subContext?.subSubCategories?.isNotEmpty ?? false) &&
        widget.id != null) {
      subSubCategoryList =
          subContext?.subSubCategories?.map((element) => element).toList() ??
              [];
      subSubCategoryList?.insert(
          0,
          SubSubCategory(
            name: categoryName,
            id: subContext?.id,
            totalProductCount: subContext?.totalProductCount,
          ));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        int index = subSubCategoryList!.indexWhere((category) =>
            category.id ==
            (Provider.of<ProductController>(context, listen: false)
                    .selectedCategoryId ??
                widget.id));
        if (index != -1) {
          _horizontalScrollToIndex(index);
        }
      });
    } else if ((categoryContext?.subCategories?.isNotEmpty ?? false) &&
        widget.id != null) {
      subCategoryList =
          categoryContext?.subCategories?.map((element) => element).toList() ??
              [];
      subCategoryList?.insert(
          0,
          SubCategory(
            name: categoryName,
            id: categoryContext?.id,
            totalProductCount: categoryContext?.totalProductCount,
          ));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        int index = subCategoryList!.indexWhere((category) =>
            category.id ==
            (Provider.of<ProductController>(context, listen: false)
                    .selectedCategoryId ??
                widget.id));
        if (index != -1) {
          _horizontalScrollToIndex(index);
        }
      });
    }
  }

  /// A category opened by id alone finds its own family in the category tree.
  ///
  /// Every entry point that only knows an id — a banner tap, a theme section's link, a deep
  /// link, search — used to land on an isolated page: no siblings, no children, no way back up.
  /// The tree the app already fetches holds the whole hierarchy; this looks the id up at any
  /// depth and rebuilds the same context a caller from the category browser would have passed.
  Future<void> _hydrateHierarchy() async {
    if (widget.isBrand || widget.id == null) return;

    final categoryController =
        Provider.of<CategoryController>(context, listen: false);
    if (categoryController.categoryList.isEmpty) {
      await categoryController.getCategoryList(false);
      if (!mounted) return;
    }

    CategoryModel? topContext;
    SubCategory? subContext;
    List<_TrailStop> trail = const [];

    for (final top in categoryController.categoryList) {
      if (top.id == widget.id) {
        topContext = top;
        break;
      }
      for (final sub in top.subCategories ?? const <SubCategory>[]) {
        if (sub.id == widget.id) {
          // A middle category with children opens onto THEM; a leaf keeps its siblings.
          if (sub.subSubCategories?.isNotEmpty ?? false) {
            subContext = sub;
          } else {
            topContext = top;
          }
          trail = [_TrailStop(top.name, top.id, top)];
          break;
        }
        for (final subSub
            in sub.subSubCategories ?? const <SubSubCategory>[]) {
          if (subSub.id == widget.id) {
            subContext = sub;
            trail = [
              _TrailStop(top.name, top.id, top),
              _TrailStop(sub.name, sub.id, null, sub: sub),
            ];
            break;
          }
        }
        if (subContext != null || topContext != null) break;
      }
      if (subContext != null || topContext != null) break;
    }

    if (topContext == null && subContext == null && trail.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _resolvedCategory = topContext;
      _resolvedSub = subContext;
      _trail = trail;
      _initializeCategoryList(getTranslated('all_products', context)!);
    });
  }

  void _horizontalScrollToIndex(int index) {
    if (index > 1) {
      _categoryScrollController.animateTo(
        index * 100,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _getProducts(int? id) async {
    await Provider.of<ProductController>(context, listen: false)
        .initBrandOrCategoryProductList(
            isBrand: widget.isBrand, id: id, offset: 1, isUpdate: false);
  }


  @override
  void initState() {

    final ProductController productController =
        Provider.of<ProductController>(context, listen: false);

    productController.setCategorySearchProductText('', isUpdate: false);

    if (widget.id != null) {
      productController.updateSelectedCategoryId(
          id: widget.id!, isUpdate: false);
    }
    _getProducts(widget.id);

    _initializeCategoryList(getTranslated('all_products', Get.context!)!);
    _hydrateHierarchy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = widget.bannerImageUrl;
    final hasValidBanner = bannerUrl != null &&
        bannerUrl.trim().isNotEmpty &&
        bannerUrl.toLowerCase() != 'null';

    return Scaffold(
      appBar: CustomAppBar(title: widget.name),
      body: Consumer<ProductController>(
        builder: (context, productController, child) {
          return Column(children: [

            // Where this category lives: "Beauty / Skin Care" over Cleansers. Each ancestor is
            // a real destination, so a shopper who arrived from a banner can climb the tree.
            if (_trail.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                      top: Dimensions.paddingSizeExtraSmall),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final stop in _trail) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => RouterHelper.getBrandCategoryRoute(
                            action: RouteAction.push,
                            isBrand: false,
                            id: stop.id,
                            name: stop.name,
                            categoryModel: stop.category,
                            subCategory: stop.sub,
                            isAllProduct: stop.category != null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 2),
                            child: Text(
                              stop.name ?? '',
                              style: textMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            size: 14,
                            color: Theme.of(context).hintColor),
                      ],
                      Text(
                        widget.name ?? '',
                        style: textBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withValues(alpha: .75),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall)
                  .copyWith(right: Dimensions.paddingSizeDefault),
              child: TextFormField(
                controller: searchTextEditingController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  productController.setCategorySearchProductText(value);
                },
                onFieldSubmitted: (value) {
                  if (_filtered) {
                    _applyFilters();
                    return;
                  }
                  productController.initBrandOrCategoryProductList(
                    isBrand: widget.isBrand,
                    id: productController.selectedCategoryId,
                    searchProduct: searchTextEditingController.text.trim(),
                    offset: 1,
                    isUpdate: true,
                  );
                },
                style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.15),
                        width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.15),
                        width: 1),
                  ),
                  hintText:
                      '${getTranslated('search_in', context)} ${widget.name ?? ''}…',
                  hintStyle: textRegular.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: 0.6)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (searchTextEditingController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () {
                              searchTextEditingController.clear();
                              productController
                                  .setCategorySearchProductText('');
                              if (_filtered) {
                                _applyFilters();
                                return;
                              }
                              productController.initBrandOrCategoryProductList(
                                isBrand: widget.isBrand,
                                id: productController.selectedCategoryId,
                                offset: 1,
                                isUpdate: true,
                              );
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Icons.clear,
                                  size: 20, color: Theme.of(context).hintColor),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: InkWell(
                          onTap: () {
                            if (searchTextEditingController.text
                                .trim()
                                .isNotEmpty) {
                              if (_filtered) {
                                debounceHelper.run(_applyFilters);
                                return;
                              }
                              debounceHelper.run(() {
                                Provider.of<ProductController>(context,
                                        listen: false)
                                    .initBrandOrCategoryProductList(
                                  isBrand: widget.isBrand,
                                  id: productController.selectedCategoryId,
                                  searchProduct:
                                      searchTextEditingController.text.trim(),
                                  offset: 1,
                                  isUpdate: true,
                                );
                              });
                            } else {
                              showCustomSnackBarWidget(
                                  getTranslated('enter_somethings', context),
                                  Get.context!,
                                  snackBarType: SnackBarType.warning);
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(Images.search,
                                color: Colors.white,
                                height: Dimensions.iconSizeSmall,
                                width: Dimensions.iconSizeSmall,
                                fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // The hero belongs to the category being LOOKED at: entering
            // «المنظّفات» from «العناية بالبشرة» shows the cleansers' own banner,
            // and the caller's image only stands in until that answer arrives.
            if (!widget.isBrand)
              CategoryHeroWidget(
                categoryId:
                    productController.selectedCategoryId ?? widget.id,
                categoryName: widget.name,
                initialImage: hasValidBanner ? bannerUrl : null,
                height: 200, // زيادة الارتفاع من 120 إلى 200
              )
            else if (hasValidBanner)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImageWidget(
                    image: bannerUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (subCategoryList?.isNotEmpty ?? false)

              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeLarge,
                  top: Dimensions.paddingSizeSmall,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeSmall,
                ),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: subCategoryList!.length,
                    itemBuilder: (context, index) {
                      final bool isSubCategorySelected =
                          subCategoryList?[index].id ==
                              productController.selectedCategoryId;

                      return _CategoryItemWidget(
                        categoryName: index == 0
                            ? (getTranslated('all', context) ??
                                subCategoryList?[index].name ??
                                '')
                            : subCategoryList?[index].name ?? '',
                        totalProductCount:
                            '(${subCategoryList?[index].totalProductCount.toString() ?? ''})',
                        isSelected: isSubCategorySelected,
                        onTap: () {
                          searchTextEditingController.clear();
                          _clearFilters();

                          if (productController.selectedCategoryId !=
                              subCategoryList?[index].id) {
                            debounceHelper.run(() {
                              productController.updateSelectedCategoryId(
                                  id: subCategoryList![index].id!);
                              _getProducts(subCategoryList?[index].id);
                            });
                          }
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                  ),
                ),
              ),
            if (subSubCategoryList?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeLarge,
                  top: Dimensions.paddingSizeSmall,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeSmall,
                ),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: subSubCategoryList!.length,
                    itemBuilder: (context, index) {
                      final bool isSubSubCategorySelected =
                          subSubCategoryList?[index].id ==
                              productController.selectedCategoryId;

                      return _CategoryItemWidget(
                        categoryName: index == 0
                            ? (getTranslated('all', context) ??
                                subSubCategoryList?[index].name ??
                                '')
                            : subSubCategoryList?[index].name ?? '',
                        totalProductCount:
                            '(${subSubCategoryList?[index].totalProductCount.toString() ?? ''})',
                        isSelected: isSubSubCategorySelected,
                        onTap: () {
                          searchTextEditingController.clear();
                          _clearFilters();

                          if (productController.selectedCategoryId !=
                              subSubCategoryList?[index].id) {
                            debounceHelper.run(() {
                              productController.updateSelectedCategoryId(
                                  id: subSubCategoryList![index].id!);
                              _getProducts(subSubCategoryList?[index].id);
                            });
                          }
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                  ),
                ),
              ),
            _filterChipsRow(),
            _flashStrip(),
            _allProductsHeader(_filtered
                ? _filterResults?.totalSize
                : productController.brandOrCategoryProductList?.totalSize),
            if (_filtered)
              Flexible(child: Builder(builder: (context) {
                if (_filterLoading) {
                  return const Padding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: ProductShimmer(isHomePage: false, isEnabled: true));
                }
                // A request that failed leaves no model behind: offer the way
                // back rather than shimmering forever.
                final products = _filterResults?.products;
                if (_filterResults == null) {
                  return Center(
                    child: TextButton(
                      onPressed: _applyFilters,
                      child: Text(
                        '${getTranslated('retry', context)} ⟳',
                        style: robotoBold.copyWith(
                            color: BrandColors.primary,
                            fontSize: Dimensions.fontSizeSmall),
                      ),
                    ),
                  );
                }
                if (products == null || products.isEmpty) {
                  return const _PremiumEmptyStateWidget();
                }
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                  child: PaginatedListView(
                    scrollController: _scrollController,
                    onPaginate: (offset) async {
                      final SearchProductController searchProvider =
                          Provider.of<SearchProductController>(context,
                              listen: false);
                      final int? id =
                          productController.selectedCategoryId ?? widget.id;
                      final Object token = _filterToken;
                      final int before = products.length;
                      await searchProvider.searchProduct(
                        query: searchTextEditingController.text.trim(),
                        updateSearchField: false,
                        categoryIds: widget.isBrand ? null : '[$id]',
                        brandIds: widget.isBrand ? '[$id]' : null,
                        sort: _sortText ?? 'default',
                        priceMin: _priceMin ?? '',
                        priceMax: _priceMax ?? '',
                        offset: offset ?? 1,
                      );
                      // The filter changed while this page was in flight: its
                      // results belong to a query nobody is looking at.
                      if (!mounted || token != _filterToken) return false;
                      final ProductModel? page = searchProvider.searchedProduct;
                      final bool grew = (page?.products?.length ?? 0) > before;
                      if (grew) {
                        setState(() => _filterResults = page);
                      }
                      return grew;
                    },
                    limit: 20,
                    totalSize: _filterResults?.totalSize,
                    offset: _filterResults?.offset,
                    itemView: Expanded(
                      child: MasonryGridView.count(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall)
                            .copyWith(top: Dimensions.paddingSizeExtraSmall),
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 480 ? 3 : 2,
                        itemCount: products.length,
                        itemBuilder: (context, index) => ProductWidget(
                            productModel: products[index],
                            productNameLine: 1),
                      ),
                    ),
                  ),
                );
              }))
            else
            (productController
                        .brandOrCategoryProductList?.products?.isNotEmpty ??
                    false)
                ? Flexible(
                    child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeLarge),
                    child: PaginatedListView(
                      scrollController: _scrollController,
                      onPaginate: (offset) async {
                        // Page 2 belongs to the category the shopper is LOOKING at — after a
                        // sibling switch that is selectedCategoryId, not the id this screen
                        // happened to open with.
                        final int before = productController
                                .brandOrCategoryProductList?.products?.length ??
                            0;
                        await productController.initBrandOrCategoryProductList(
                            isBrand: widget.isBrand,
                            id: productController.selectedCategoryId ??
                                widget.id,
                            offset: offset ?? 1,
                            searchProduct: searchTextEditingController.text);
                        // The page either arrived or it did not; the list's own
                        // length is the only honest answer.
                        return (productController.brandOrCategoryProductList
                                    ?.products?.length ??
                                0) >
                            before;
                      },
                      limit:
                          productController.brandOrCategoryProductList?.limit,
                      totalSize: productController
                          .brandOrCategoryProductList?.totalSize,
                      offset:
                          productController.brandOrCategoryProductList?.offset,
                      itemView: Expanded(
                        child: MasonryGridView.count(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeSmall)
                              .copyWith(top: Dimensions.paddingSizeExtraSmall),
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 480 ? 3 : 2,
                          itemCount: productController
                                  .brandOrCategoryProductList
                                  ?.products
                                  ?.length ??
                              0,
                          itemBuilder: (BuildContext context, int index) {
                            return ProductWidget(
                              productModel: productController
                                  .brandOrCategoryProductList!.products![index],
                              productNameLine: 1,
                            );
                          },
                        ),
                      ),
                    ),
                  ))
                : productController.brandOrCategoryProductList == null
                    ? Flexible(
                        child: Padding(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: ProductShimmer(
                            isHomePage: false,
                            isEnabled:
                                productController.brandOrCategoryProductList ==
                                    null),
                      ))
                    : const Flexible(child: _PremiumEmptyStateWidget()),
          ]);
        },
      ),
    );
  }
}

class _CategoryItemWidget extends StatelessWidget {
  final String categoryName;
  final String totalProductCount;
  final bool isSelected;
  final Function()? onTap;
  const _CategoryItemWidget({
    required this.categoryName,
    required this.totalProductCount,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The approved tab treatment: the active sibling wears a 2.5px violet
    // underline, the rest sit muted on the baseline — no filled pills.
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? BrandColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                categoryName,
                style: isSelected
                    ? robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: BrandColors.primary,
                      )
                    : textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraExtraSmall),
              Text(
                totalProductCount,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: isSelected
                      ? BrandColors.primary.withValues(alpha: 0.7)
                      : Theme.of(context).hintColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumEmptyStateWidget extends StatelessWidget {
  const _PremiumEmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeOverLarge,
            vertical: Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/no_result.json',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              getTranslated('no_product_found', context) ??
                  (isArabic ? 'لم يتم العثور على منتج' : 'No Product Found'),
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              isArabic
                  ? 'لا توجد منتجات في هذه الفئة حالياً. جرب استخدام كلمات بحث أخرى أو تصفح فئات مختلفة.'
                  : 'There are no products in this category. Try searching with different keywords or browse other categories.',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge,
                    vertical: Dimensions.paddingSizeTwelve),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  isArabic ? 'الرجوع' : 'Go Back',
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).cardColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ancestor in the category trail — tappable, so the hierarchy is a ladder, not a label.
class _TrailStop {
  const _TrailStop(this.name, this.id, this.category, {this.sub});

  final String? name;
  final int? id;
  final CategoryModel? category;
  final SubCategory? sub;
}