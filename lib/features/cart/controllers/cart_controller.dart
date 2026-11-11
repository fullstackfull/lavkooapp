import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/cart/domain/services/cart_service_interface.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

import '../../../services/meta_tracking_service.dart';

class CartController extends ChangeNotifier {
  final CartServiceInterface? cartServiceInterface;
  CartController({required this.cartServiceInterface});

  List<CartModel> _cartList = [];
  List<bool> isSelectedList = [];
  double amount = 0.0;
  bool isSelectAll = true;
  bool _cartLoading = false;
  bool get cartLoading => _cartLoading;
  CartModel? cart;
  String? _updateQuantityErrorText;
  String? get addOrderStatusErrorText => _updateQuantityErrorText;
  bool _getData = true;
  bool _addToCartLoading = false;
  bool get addToCartLoading => _addToCartLoading;
  List<CartModel> get cartList => _cartList;
  bool get getData => _getData;

  void setCartData() {
    _getData = true;
  }

  void getCartDataLoaded() {
    _getData = false;
  }

  Future<ApiResponseModel> getCartData(BuildContext context,
      {bool reload = true, String? couponCode}) async {
    if (reload) {
      _cartLoading = true;
    }
    ApiResponseModel apiResponse =
        await cartServiceInterface!.getCartList(couponCode: couponCode);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _cartList = [];
      apiResponse.response!.data
          .forEach((cart) => _cartList.add(CartModel.fromJson(cart)));
      _cartLoading = false;
    } else {
      _cartLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    _cartLoading = false;
    notifyListeners();
    return apiResponse;
  }

  void setIsCartLoading() {
    _cartLoading = true;
  }

  bool updatingIncrement = false;
  bool updatingDecrement = false;

  /// The row this call is about, found by its own id.
  ///
  /// Every write below happens AFTER a network await, and [getCartData] replaces
  /// the whole list — so the position a caller passed may by then belong to a
  /// different product or to nothing at all. Two carts mutating at once (a grid
  /// of cards makes that ordinary) used to throw a RangeError here and abandon
  /// the second update half-done. The index is still accepted, as a hint.
  CartModel? _row(int? key, int index) {
    final int found = cartList.indexWhere((row) => row.id == key);
    if (found != -1) return cartList[found];
    if (key == null && index >= 0 && index < cartList.length) {
      return cartList[index];
    }
    return null;
  }

  Future<ApiResponseModel> updateCartProductQuantity(int? key, int quantity,
      BuildContext context, bool increment, int index) async {
    CartModel? row = _row(key, index);
    if (increment) {
      row?.increment = true;
    } else {
      row?.decrement = true;
    }
    notifyListeners();
    ApiResponseModel apiResponse;
    apiResponse = await cartServiceInterface!.updateQuantity(key, quantity);
    row = _row(key, index);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      row?.increment = false;
      row?.decrement = false;
      String message = apiResponse.response!.data['message'].toString();
      showCustomSnackBarWidget(message, Get.context!,
          snackBarType: SnackBarType.success);
      await getCartData(Get.context!);
    } else {
      row?.increment = false;
      row?.decrement = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ApiResponseModel> addToCartAPI(
      CartModelBody cart,
      BuildContext context,
      List<ChoiceOptions> choices,
      List<int>? variationIndexes,
      {int buyNow = 0,
      int? shippingMethodExist,
      int? shippingMethodId}) async {
    _addToCartLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await cartServiceInterface!
        .addToCartListData(cart, choices, variationIndexes, buyNow,
            shippingMethodExist, shippingMethodId);
    _addToCartLoading = false;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Navigator.of(Get.context!).pop();
      _addToCartLoading = false;
      showCustomSnackBarWidget(
          apiResponse.response!.data['message'], Get.context!,
          snackBarType: SnackBarType.success);
      getCartData(Get.context!);
      // ✅ Meta Tracking: Add to Cart event
      MetaTrackingService().logAddToCart(
        productId: cart.productId.toString(),
        productName: cart.variant ?? 'Product',
        price: cart.digitalVariantPrice ?? 0.0,
        currency: 'SYP',
      );
    } else {
      _addToCartLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ApiResponseModel> restockRequest(
      CartModelBody cart,
      BuildContext context,
      List<ChoiceOptions> choices,
      List<int>? variationIndexes,
      {int buyNow = 0,
      int? shippingMethodExist,
      int? shippingMethodId,
      String? variationType}) async {
    _addToCartLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await cartServiceInterface!.restockRequest(
        cart,
        choices,
        variationIndexes,
        buyNow,
        shippingMethodExist,
        shippingMethodId);

    _addToCartLoading = false;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Navigator.of(Get.context!).pop();
      _addToCartLoading = false;
      if (context.mounted) {
        Provider.of<ProductDetailsController>(context, listen: false)
            .updateProductRestock(variantKey: variationType);
      }
      await FirebaseMessaging.instance
          .subscribeToTopic(apiResponse.response!.data['topic']);
      showCustomSnackBarWidget(
          apiResponse.response!.data['message'], Get.context!,
          snackBarType: apiResponse.response!.data['status'] == 0
              ? SnackBarType.error
              : SnackBarType.success);
    } else {
      _addToCartLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<void> removeFromCartAPI(int? key, int index) async {
    _row(key, index)?.decrement = true;
    notifyListeners();
    ApiResponseModel apiResponse = await cartServiceInterface!.delete(key!);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _row(key, index)?.decrement = false;
      getCartData(Get.context!);
    } else {
      _row(key, index)?.decrement = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future<void> addRemoveCartSelectedItem(List<int> ids, bool action) async {
    notifyListeners();
    Map<String, dynamic> data = {
      'ids': ids,
      'action': action ? 'checked' : 'unchecked'
    };
    ApiResponseModel apiResponse =
        await cartServiceInterface!.addRemoveCartSelectedItem(data);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      await Future.wait([
        Provider.of<ShippingController>(Get.context!, listen: false)
            .getChosenShippingMethod(Get.context!),
        getCartData(Get.context!, reload: false),
      ]);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void resetCartList({bool isUpdate = true}) {
    _cartList = [];
    if (isUpdate) {
      notifyListeners();
    }
  }

  Future<void> mergeGuestCart() async {
    ApiResponseModel apiResponse = await cartServiceInterface!.mergeGuestCart();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }
}
