import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class CategoryRepoInterface extends RepositoryInterface {
  Future<dynamic> getSellerWiseCategoryList(String slug);

  Future<ApiResponseModel<T>> getCategoryList<T>(
      {required DataSourceEnum source});

  Future<ApiResponseModel> getCategoryPageHeader(int categoryId);
}
