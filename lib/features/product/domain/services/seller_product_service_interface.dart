import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';

abstract class SellerProductServiceInterface {
  Future<dynamic> getSellerProductList(
      String sellerId, String offset, String productId,
      {String search = '',
      String? categoryIds,
      String? brandIds,
      String? authorIds,
      String? publishingIds,
      String? productType});

  Future<dynamic> getSellerWiseBestSellingProductList(
      String slug, String offset);

  Future<dynamic> getSellerWiseFeaturedProductList(String slug, String offset);

  Future<dynamic> getSellerWiseRecomendedProductList(
      String slug, String offset);

  Future<ApiResponseModel<T>> getShopAgainFromRecentStore<T>(
      {required DataSourceEnum source});
}
