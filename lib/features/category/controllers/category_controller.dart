import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/model/image_full_url.dart';
import 'package:syriapharmacy/features/category/domain/models/category_model.dart';
import 'package:syriapharmacy/features/category/domain/services/category_service_interface.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/helper/data_sync_helper.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/features/banner/domain/models/banner_model.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:provider/provider.dart';

class CategoryController extends ChangeNotifier {
  final CategoryServiceInterface? categoryServiceInterface;
  CategoryController({required this.categoryServiceInterface});

  final List<CategoryModel> _filteredCategoryList = [];
  final List<CategoryModel> _categoryList = [];
  final List<CategoryModel> _sellerWiseCategoryList = [];
  int? _categorySelectedIndex;

  final Map<int, String?> _categoryBannerMap = {};

  /// The whole banner a category page resolved — image, title and its action —
  /// so the hero can be tapped like any other banner in the app.
  final Map<int, BannerModel> _categoryHeroMap = {};
  final Map<int, List<SubCategory>> _categorySubCategoriesMap = {};
  final Set<int> _loadingHeaderCategories = {};

  List<CategoryModel> get categoryList => _categoryList;
  List<CategoryModel> get sellerWiseCategoryList => _sellerWiseCategoryList;
  List<CategoryModel> get filteredCategoryList => _filteredCategoryList;

  int? get categorySelectedIndex => _categorySelectedIndex;

  String? getBannerForCategory(int? categoryId) {
    if (categoryId == null) return null;
    return _categoryBannerMap[categoryId];
  }

  /// The category's hero banner, or null when neither it nor an ancestor has one.
  BannerModel? getCategoryHero(int? categoryId) {
    if (categoryId == null) return null;
    return _categoryHeroMap[categoryId];
  }

  /// Whether this category's header has been asked for at all — so a caller can
  /// tell "no banner" apart from "not fetched yet".
  bool hasHeaderFor(int? categoryId) =>
      categoryId != null && _categorySubCategoriesMap.containsKey(categoryId);

  List<SubCategory>? getSubCategoriesForCategory(int? categoryId) {
    if (categoryId == null) return null;
    return _categorySubCategoriesMap[categoryId];
  }

  bool isHeaderLoading(int? categoryId) {
    if (categoryId == null) return false;
    return _loadingHeaderCategories.contains(categoryId);
  }

  Future<void> getCategoryPageHeaderData(int categoryId) async {
    if (_categoryBannerMap.containsKey(categoryId) &&
        _categorySubCategoriesMap.containsKey(categoryId)) {
      return;
    }
    if (_loadingHeaderCategories.contains(categoryId)) return;

    _loadingHeaderCategories.add(categoryId);
    notifyListeners();

    ApiResponseModel apiResponse =
        await categoryServiceInterface!.getCategoryPageHeader(categoryId);

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      try {
        final data = apiResponse.response!.data;

        // البانر: الصورة المخصّصة للموبايل أولاً، وإلا صورة الويب — وإلا فلا
        // بانر إطلاقاً. القسم بلا بانر خاص يرث بانر أقرب أصل من الخادم.
        if (data['banner'] != null) {
          final bannerData = data['banner'];
          final BannerModel hero = BannerModel.fromJson(bannerData);

          String? heroPath;
          for (final candidate in [
            bannerData['mobile_photo_full_url'],
            bannerData['photo_full_url'],
          ]) {
            if (candidate == null) continue;
            final image = ImageFullUrl.fromJson(candidate);
            if (image.status == 200 && (image.path?.isNotEmpty ?? false)) {
              heroPath = image.path;
              break;
            }
          }

          if (heroPath != null) {
            _categoryBannerMap[categoryId] = heroPath;
            _categoryHeroMap[categoryId] = hero;
          }
        }

        if (data['sub_categories'] != null) {
          final List<SubCategory> subCats = [];
          data['sub_categories'].forEach((v) {
            subCats.add(SubCategory.fromJson(v));
          });
          _categorySubCategoriesMap[categoryId] = subCats;
        }

        // ✅ تحديث الـ CategoryModel في القائمة
        final int catIndex =
            _categoryList.indexWhere((c) => c.id == categoryId);
        if (catIndex != -1) {
          final cat = _categoryList[catIndex];
          if (_categoryBannerMap[categoryId] != null) {
            cat.bannerFullUrl = ImageFullUrl(
                key: '', path: _categoryBannerMap[categoryId], status: 200);
          }
          // The header's sub_categories carry NO sub-sub level (the endpoint sends id, name,
          // icon and count only). The category LIST already loaded the full tree — overwriting
          // it here was why sub-subs flashed on screen and then vanished the moment this fetch
          // landed. The header copy stands in only when the list brought nothing.
          if ((cat.subCategories == null || cat.subCategories!.isEmpty) &&
              _categorySubCategoriesMap[categoryId] != null &&
              _categorySubCategoriesMap[categoryId]!.isNotEmpty) {
            cat.subCategories = _categorySubCategoriesMap[categoryId];
          }
        }
      } catch (e) {
        debugPrint('Error parsing category page header: $e');
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    _loadingHeaderCategories.remove(categoryId);
    notifyListeners();
  }

  Future<void> getCategoryList(bool reload) async {
    if (_categoryList.isEmpty || reload) {
      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: () =>
            categoryServiceInterface!.getList(source: DataSourceEnum.local),
        fetchFromClient: () =>
            categoryServiceInterface!.getList(source: DataSourceEnum.client),
        onResponse: (data, source) {
          if (data != null) {
            _categoryList.clear();

            data.forEach((category) =>
                _categoryList.add(CategoryModel.fromJson(category)));
            _categorySelectedIndex = 0;

            onUpdateFilteredCategoryList(isSeller: false);
            notifyListeners();
          }
        },
      );
    }
  }

  void onUpdateFilteredCategoryList({required bool isSeller}) {
    _filteredCategoryList.clear();
    _filteredCategoryList
        .addAll(isSeller ? _sellerWiseCategoryList : _categoryList);
  }

  Future<void> getSellerWiseCategoryList(String slug) async {
    ApiResponseModel apiResponse =
        await categoryServiceInterface!.getSellerWiseCategoryList(slug);

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _sellerWiseCategoryList.clear();
      apiResponse.response!.data.forEach((category) =>
          _sellerWiseCategoryList.add(CategoryModel.fromJson(category)));
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    onUpdateFilteredCategoryList(isSeller: true);

    notifyListeners();
  }

  final List<int> _selectedCategoryIds = [];
  List<int> get selectedCategoryIds => _selectedCategoryIds;

  void checkedToggleCategory(int index) {
    _filteredCategoryList[index].isSelected =
        !_filteredCategoryList[index].isSelected!;

    if (_filteredCategoryList[index].isSelected ?? false) {
      if (!_selectedCategoryIds.contains(index)) {
        _selectedCategoryIds.add(index);
      }
    } else {
      _selectedCategoryIds.remove(index);
      _onDisableSubCategorySelection(index);
    }
    notifyListeners();
  }

  /// Narrow a shop's listing to one of its own categories.
  ///
  /// Keyed by the category's id, not by a position: the rail draws the shop's
  /// own list while the filter sheet reads the shared filtered one, and the two
  /// are the same entries only once both have loaded. An id means the same
  /// category in either, whatever order they are in.
  void selectOnlyCategoryById(int categoryId) {
    for (int i = 0; i < _filteredCategoryList.length; i++) {
      _filteredCategoryList[i].isSelected =
          _filteredCategoryList[i].id == categoryId;
      if (!(_filteredCategoryList[i].isSelected ?? false)) {
        _onDisableSubCategorySelection(i);
      }
    }
    _selectedCategoryIds.clear();
    final int index = _filteredCategoryList
        .indexWhere((category) => category.id == categoryId);
    if (index != -1) {
      _selectedCategoryIds.add(index);
    }
    notifyListeners();
  }

  void _onDisableSubCategorySelection(int index) {
    _filteredCategoryList[index].subCategories?.forEach((subCategory) {
      subCategory.isSelected = false;
    });
  }

  void checkedToggleSubCategory(int index, int subCategoryIndex) {
    _filteredCategoryList[index].subCategories![subCategoryIndex].isSelected =
        !_filteredCategoryList[index]
            .subCategories![subCategoryIndex]
            .isSelected!;
    notifyListeners();
  }

  Future<void> resetChecked(String? slug, bool fromShop) async {
    if (fromShop) {
      await getSellerWiseCategoryList(slug!);
      Provider.of<BrandController>(Get.context!, listen: false)
          .getSellerWiseBrandList(slug);
      Provider.of<SellerProductController>(Get.context!, listen: false)
          .getSellerProductList(slug.toString(), 1, "");
      Provider.of<SellerProductController>(Get.context!, listen: false)
          .setFilterApply(false);
    } else {
      await getCategoryList(true);
      Provider.of<BrandController>(Get.context!, listen: false)
          .getBrandList(offset: 1);
    }
  }

  void onChangeSelectedIndex(int selectedIndex, {bool isUpdate = true}) {
    _categorySelectedIndex = selectedIndex;
    if (isUpdate) {
      notifyListeners();
    }
  }

  void uncheckSellerCategoryList() {
    if (_filteredCategoryList.isNotEmpty) {
      _filteredCategoryList.map((category) {
        category.isSelected = false;
      }).toList();
    }
  }
}
