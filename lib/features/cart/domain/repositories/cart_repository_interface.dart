import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/product/domain/models/product_model.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';

abstract class CartRepositoryInterface implements RepositoryInterface {
  Future<dynamic> addToCartListData(
      CartModelBody cart,
      List<ChoiceOptions> choiceOptions,
      List<int>? variationIndexes,
      int buyNow,
      int? shippingMethodExist,
      int? shippingMethodId);

  Future<dynamic> updateQuantity(int? key, int quantity);

  Future<dynamic> addRemoveCartSelectedItem(Map<String, dynamic> data);

  Future<dynamic> restockRequest(
      CartModelBody cart,
      List<ChoiceOptions> choiceOptions,
      List<int>? variationIndexes,
      int buyNow,
      int? shippingMethodExist,
      int? shippingMethodId);

  Future<ApiResponseModel<T>> getCartData<T>({required DataSourceEnum source});

  Future<dynamic> mergeGuestCart();

  Future<dynamic> getCartList({String? couponCode});
}
