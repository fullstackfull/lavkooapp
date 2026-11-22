import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/shop/domain/models/more_store_model.dart';
import 'package:syriapharmacy/features/shop/domain/models/seller_info_model.dart';
import 'package:syriapharmacy/features/shop/domain/models/seller_model.dart';
import 'package:syriapharmacy/features/shop/domain/services/shop_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/helper/data_sync_helper.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

class ShopController extends ChangeNotifier with StorefrontChangeAware {
  final ShopServiceInterface? shopServiceInterface;

  /// The database a shop's clearance products are kept in: the app's one, unless a test hands in another.
  final AppDatabase? localDatabase;

  ShopController({
    required this.shopServiceInterface,
    this.localDatabase,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
  }

  AppDatabase get _database => localDatabase ?? database;

  String? _searchText;
  String? get searchText => _searchText;

  String? shopName;
  void setShopName(String? name, {bool notify = true}) {
    shopName = name;
    if (notify) {
      notifyListeners();
    }
  }

  int shopMenuIndex = 0;
  void setMenuItemIndex(int index, {bool notify = true}) {
    shopMenuIndex = index;
    if (notify) {
      notifyListeners();
    }
  }

  SellerInfoModel? sellerInfoModel;
  Future<void> getSellerInfo(String slug) async {
    ApiResponseModel apiResponse = await shopServiceInterface!.get(slug);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      sellerInfoModel = SellerInfoModel.fromJson(apiResponse.response!.data);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  bool isLoading = false;
  List<MostPopularStoreModel> moreStoreList = [];

  Future<void> getMoreStore() async {
    moreStoreList = [];
    isLoading = true;

    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () =>
          shopServiceInterface!.getMoreStore(source: DataSourceEnum.local),
      fetchFromClient: () =>
          shopServiceInterface!.getMoreStore(source: DataSourceEnum.client),
      onResponse: (data, source) {
        moreStoreList.clear();
        data.forEach((store) =>
            moreStoreList.add(MostPopularStoreModel.fromJson(store)));
        isLoading = false;
        notifyListeners();
      },
    );
  }

  String sellerType = "top";
  String sellerTypeTitle = "top_seller";
  void setSellerType(String type, {bool notify = true}) {
    sellerType = type;
    filteredSellerModel = null;
    if (sellerType == "top") {
      sellerTypeTitle = "top_seller";
    } else if (sellerType == "new") {
      sellerTypeTitle = "new_seller";
    } else {
      sellerTypeTitle = "all_seller";
    }

    getFilteredSellerList(type: type, offset: 1, isUpdate: notify);

    if (notify) {
      notifyListeners();
    }
  }

  SellerModel? topSellerModel;
  Future<void> getTopSellerList(
      {required int offset, bool isUpdate = true}) async {
    if (offset == 1) {
      topSellerModel = null;

      if (isUpdate) {
        notifyListeners();
      }
    }

    if (offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: () => shopServiceInterface!.getSellerList(
            type: 'top',
            offset: offset,
            limit: 10,
            source: DataSourceEnum.local),
        fetchFromClient: () => shopServiceInterface!.getSellerList(
            type: 'top',
            offset: offset,
            limit: 10,
            source: DataSourceEnum.client),
        onResponse: (data, source) {
          topSellerModel = SellerModel.fromJson(data);
          notifyListeners();
        },
      );
    } else {
      final String? storefront = StorefrontScope.current;
      final ApiResponseModel apiResponse = await shopServiceInterface!
          .getSellerList(
              type: 'top',
              limit: 10,
              offset: offset,
              source: DataSourceEnum.client);

      // A page of the shops of the storefront the customer has left is not added to the ones of the storefront they are on.
      if (!StorefrontScope.isCurrent(storefront)) return;

      if (apiResponse.response?.statusCode == 200) {
        final SellerModel parseSellerModel =
            SellerModel.fromJson(apiResponse.response.data);

        topSellerModel?.offset = parseSellerModel.offset;
        topSellerModel?.limit = parseSellerModel.limit;
        topSellerModel?.sellers?.addAll(parseSellerModel.sellers ?? []);
      } else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();
    }
  }

  SellerModel? filteredSellerModel;
  Future<void> getFilteredSellerList(
      {required int offset, required String type, bool isUpdate = true}) async {
    if (offset == 1) {
      filteredSellerModel = null;

      if (isUpdate) {
        notifyListeners();
      }
    }

    if (offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: () => shopServiceInterface!.getSellerList(
            type: type,
            limit: 10,
            offset: offset,
            source: DataSourceEnum.local),
        fetchFromClient: () => shopServiceInterface!.getSellerList(
            type: type,
            limit: 10,
            offset: offset,
            source: DataSourceEnum.client),
        onResponse: (data, source) {
          filteredSellerModel = SellerModel.fromJson(data);
          notifyListeners();
        },
      );
    } else {
      final String? storefront = StorefrontScope.current;
      final ApiResponseModel apiResponse = await shopServiceInterface!
          .getSellerList(
              type: type,
              limit: 10,
              offset: offset,
              source: DataSourceEnum.client);

      // A page of the shops of the storefront the customer has left is not added to the ones of the storefront they are on.
      if (!StorefrontScope.isCurrent(storefront)) return;

      if (apiResponse.response?.statusCode == 200) {
        final SellerModel parseSellerModel =
            SellerModel.fromJson(apiResponse.response.data);

        filteredSellerModel?.offset = parseSellerModel.offset;
        filteredSellerModel?.limit = parseSellerModel.limit;
        filteredSellerModel?.sellers?.addAll(parseSellerModel.sellers ?? []);
      } else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();
    }
  }

  SellerModel? allSellerModel;
  Future<void> getAllSellerList(
      {required int offset, bool isUpdate = true}) async {
    if (offset == 1) {
      allSellerModel = null;

      if (isUpdate) {
        notifyListeners();
      }
    }

    if (offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: () => shopServiceInterface!.getSellerList(
            type: 'all',
            limit: 100,
            offset: offset,
            source: DataSourceEnum.local),
        fetchFromClient: () => shopServiceInterface!.getSellerList(
            type: 'all',
            limit: 100,
            offset: offset,
            source: DataSourceEnum.client),
        onResponse: (data, source) {
          allSellerModel = SellerModel.fromJson(data);

          notifyListeners();
        },
      );
    } else {
      final String? storefront = StorefrontScope.current;
      final ApiResponseModel apiResponse = await shopServiceInterface!
          .getSellerList(
              type: 'all',
              limit: 100,
              offset: offset,
              source: DataSourceEnum.client);

      // A page of the shops of the storefront the customer has left is not added to the ones of the storefront they are on.
      if (!StorefrontScope.isCurrent(storefront)) return;

      if (apiResponse.response?.statusCode == 200) {
        final SellerModel parseSellerModel =
            SellerModel.fromJson(apiResponse.response.data);

        allSellerModel?.offset = parseSellerModel.offset;
        allSellerModel?.limit = parseSellerModel.limit;
        allSellerModel?.sellers?.addAll(parseSellerModel.sellers ?? []);
      } else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();
    }
  }

  ProductModel? clearanceProductModel;
  Future<void> getClearanceShopProductList(
      String type, String offset, String slug,
      {bool reload = false}) async {
    // A shop's clearance products are read and kept for the storefront the customer is on now; if they choose another while an answer is
    // on its way, that answer is neither shown nor kept.
    final String? storefront = StorefrontScope.current;

    var localData = await _database.getCacheResponseById(
        "${AppConstants.clearanceShopProductUri}$slug/products?guest_id=1&limit=10&offset=$offset&offer_type=$type");
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (localData != null) {
      clearanceProductModel =
          ProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

    ApiResponseModel apiResponse = await shopServiceInterface!
        .getClearanceShopProductList(type, offset, slug);
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      if (offset == '1') {
        clearanceProductModel = null;
        // SellerModel.fromJson(apiResponse.response?.data);
        clearanceProductModel =
            ProductModel.fromJson(apiResponse.response?.data);
      } else {
        clearanceProductModel?.products?.addAll(
            ProductModel.fromJson(apiResponse.response!.data).products ?? []);
        clearanceProductModel?.offset =
            (ProductModel.fromJson(apiResponse.response!.data).offset!);
        clearanceProductModel?.totalSize =
            (ProductModel.fromJson(apiResponse.response!.data).totalSize!);
      }

      if (localData != null) {
        await _database.updateCacheResponse(
            "${AppConstants.clearanceShopProductUri}$slug/products?guest_id=1&limit=10&offset=$offset&offer_type=$type",
            CacheResponseCompanion(
              endPoint: Value(
                  "${AppConstants.clearanceShopProductUri}$slug/products?guest_id=1&limit=10&offset=$offset&offer_type=$type"),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ));
      } else {
        await _database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: Value(
                "${AppConstants.clearanceShopProductUri}$slug/products?guest_id=1&limit=10&offset=$offset&offer_type=$type"),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    }
    notifyListeners();
  }

  void emptyClearanceProductList() {
    clearanceProductModel = null;
  }

  /// The customer is on another storefront: the shops, the products a shop's page showed and the shop's own info belong to the one they
  /// left. The lists the home showed are loaded again, and only those; what belongs to one shop is dropped and loads when its screen is
  /// opened again.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    final bool hadMoreStores = moreStoreList.isNotEmpty;
    final bool hadTopSellers = topSellerModel != null;
    final bool hadAllSellers = allSellerModel != null;
    final bool hadFilteredSellers = filteredSellerModel != null;

    moreStoreList = [];
    isLoading = false;
    topSellerModel = null;
    allSellerModel = null;
    filteredSellerModel = null;
    clearanceProductModel = null;
    clearanceSearchProductModel = null;
    sellerInfoModel = null;
    sellerInfoModelProductDetails = null;
    notifyListeners();

    await Future.wait(<Future<void>>[
      if (hadMoreStores) getMoreStore(),
      if (hadTopSellers) getTopSellerList(offset: 1, isUpdate: false),
      if (hadAllSellers) getAllSellerList(offset: 1, isUpdate: false),
      if (hadFilteredSellers)
        getFilteredSellerList(type: sellerType, offset: 1, isUpdate: false),
    ]);
  }

  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future<ApiResponseModel> getClearanceSearchProduct(
      String sellerId, int offset, String productId,
      {bool reload = true,
      String search = '',
      String? categoryIds = '[]',
      String? brandIds = '[]',
      String? authorIds = '[]',
      String? publishingIds = '[]',
      String? productType = 'all',
      String? offerType = 'clearance_sale',
      bool fromPaginantion = false}) async {
    !fromPaginantion ? isSearchLoading = true : null;
    notifyListeners();

    // if(reload) {
    //   sellerProduct = null;
    // }

    ApiResponseModel apiResponse = await shopServiceInterface!
        .getClearanceSearchProduct(sellerId, offset.toString(), productId,
            categoryIds: categoryIds,
            brandIds: brandIds,
            search: search,
            authorIds: authorIds,
            publishingIds: publishingIds,
            productType: productType,
            offerType: offerType);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      if (offset == 1) {
        clearanceSearchProductModel = null;
        clearanceSearchProductModel =
            ProductModel.fromJson(apiResponse.response!.data);
      } else {
        clearanceSearchProductModel?.products?.addAll(
            ProductModel.fromJson(apiResponse.response!.data).products!);
        clearanceSearchProductModel?.offset =
            (ProductModel.fromJson(apiResponse.response!.data).offset!);
        clearanceSearchProductModel?.totalSize =
            ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    isSearchLoading = false;

    notifyListeners();
    return apiResponse;
  }

  int? _clearanceSaleProductSelectedIndex;
  int? get clearanceSaleProductSelectedIndex =>
      _clearanceSaleProductSelectedIndex;

  void changeSelectedIndex(int selectedIndex) {
    _clearanceSaleProductSelectedIndex = selectedIndex;
    notifyListeners();
  }

  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
  }

  void toggleSearchActive() {
    isSearchActive = !isSearchActive;
    notifyListeners();
  }

  void disableSearch({bool isUpdate = true}) {
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if (isUpdate) {
      notifyListeners();
    }
  }

  void nullShopInfoModel({bool isUpdate = true}) {
    sellerInfoModel = null;
    if (isUpdate) {
      notifyListeners();
    }
  }

  SellerInfoModel? sellerInfoModelProductDetails;
  Future<void> getSellerInfoProductDetails(String sellerId) async {
    ApiResponseModel apiResponse = await shopServiceInterface!.get(sellerId);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      sellerInfoModelProductDetails =
          SellerInfoModel.fromJson(apiResponse.response!.data);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void emptyProductDetailsSeller() {
    sellerInfoModelProductDetails = null;
  }
}
