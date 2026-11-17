import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/deal/domain/services/featured_deal_service_interface.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/helper/data_sync_helper.dart';

class FeaturedDealController extends ChangeNotifier
    with StorefrontChangeAware {
  final FeaturedDealServiceInterface featuredDealServiceInterface;
  FeaturedDealController({
    required this.featuredDealServiceInterface,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
  }

  int? _featuredDealSelectedIndex;
  List<Product>? _featuredDealProductList;
  List<Product>? get featuredDealProductList => _featuredDealProductList;
  int? get featuredDealSelectedIndex => _featuredDealSelectedIndex;

  Future<void> getFeaturedDealList() async {
    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => featuredDealServiceInterface.getFeaturedDeal(
          source: DataSourceEnum.local),
      fetchFromClient: () => featuredDealServiceInterface.getFeaturedDeal(
          source: DataSourceEnum.client),
      onResponse: (data, source) {
        _featuredDealProductList = [];
        data.forEach((featuredDeal) =>
            _featuredDealProductList?.add(Product.fromJson(featuredDeal)));
        _featuredDealSelectedIndex = 0;
        notifyListeners();
      },
    );
  }

  /// The customer is on another storefront: the featured deal's products belong to the one they left.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    _featuredDealProductList = null;
    _featuredDealSelectedIndex = null;
    notifyListeners();

    await getFeaturedDealList();
  }

  void changeSelectedIndex(int selectedIndex) {
    _featuredDealSelectedIndex = selectedIndex;
    notifyListeners();
  }
}
