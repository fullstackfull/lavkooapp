import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/wishlist/domain/models/wishlist_model.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/wishlist/domain/services/wishlist_service_interface.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';

class WishListController extends ChangeNotifier with StorefrontChangeAware {
  final WishlistServiceInterface? wishlistServiceInterface;
  WishListController({
    required this.wishlistServiceInterface,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
  }

  final bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<WishlistModel>? _wishList;
  List<WishlistModel>? get wishList => _wishList;
  List<int> addedIntoWish = [];

  void addWishList(int? productID) async {
    addedIntoWish.add(productID!);
    ApiResponseModel apiResponse =
        await wishlistServiceInterface!.add(productID);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(
          getTranslated("successfully_added_to_wishlist", Get.context!),
          Get.context!,
          snackBarType: SnackBarType.success);
    } else {
      showCustomSnackBarWidget(apiResponse.error.toString(), Get.context!,
          snackBarType: SnackBarType.warning);
    }
    notifyListeners();
  }

  void removeWishList(int? productID, {int? index}) async {
    addedIntoWish.removeAt(addedIntoWish.indexOf(productID!));
    ApiResponseModel apiResponse =
        await wishlistServiceInterface!.delete(productID);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      getWishList('');
      showCustomSnackBarWidget(
          getTranslated("successfully_removed_from_wishlist", Get.context!),
          Get.context!,
          snackBarType: SnackBarType.success);
    } else {
      showCustomSnackBarWidget(apiResponse.error.toString(), Get.context!,
          snackBarType: SnackBarType.warning);
    }
    notifyListeners();
  }

  Future<void> getWishList(String searchText,
      {bool clearSearch = false}) async {
    if (clearSearch) {
      _wishList = null;
      notifyListeners();
    }
    final String? storefront = StorefrontScope.current;
    ApiResponseModel apiResponse =
        await wishlistServiceInterface!.getWishList(search: searchText);

    // The wishlist is kept per storefront: the answer of the storefront the customer has left is never shown as the wishlist of the one
    // they are on.
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _wishList = [];
      addedIntoWish = [];
      apiResponse.response?.data
          .forEach((wish) => _wishList?.add(WishlistModel.fromJson(wish)));
      if (_wishList!.isNotEmpty) {
        for (int i = 0; i < _wishList!.length; i++) {
          addedIntoWish.add(_wishList![i].productId!);
        }
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  /// The customer is on another storefront, which has a wishlist of its own. A guest has none to ask for, and asking would sign them out.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    _wishList = change.signedIn ? null : [];
    addedIntoWish = [];
    notifyListeners();

    if (change.signedIn) {
      await getWishList('');
    }
  }

  void emptyWishList() {
    _wishList = [];
    addedIntoWish = [];
    notifyListeners();
  }
}
