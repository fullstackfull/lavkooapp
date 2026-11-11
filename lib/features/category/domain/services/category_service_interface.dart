import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';

abstract class CategoryServiceInterface {
  Future<dynamic> getSellerWiseCategoryList(String slug);
  Future<ApiResponseModel<T>> getList<T>({required DataSourceEnum source});
  Future<ApiResponseModel> getCategoryPageHeader(int categoryId);
}
