import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/category/domain/repositories/category_repo_interface.dart';
import 'package:syriapharmacy/features/category/domain/services/category_service_interface.dart';

class CategoryService implements CategoryServiceInterface {
  CategoryRepoInterface categoryRepoInterface;
  CategoryService({required this.categoryRepoInterface});

  @override
  Future<ApiResponseModel<T>> getList<T>(
      {required DataSourceEnum source}) async {
    return await categoryRepoInterface.getCategoryList(source: source);
  }

  @override
  Future getSellerWiseCategoryList(String slug) async {
    return await categoryRepoInterface.getSellerWiseCategoryList(slug);
  }

  @override
  Future<ApiResponseModel> getCategoryPageHeader(int categoryId) async {
    return await categoryRepoInterface.getCategoryPageHeader(categoryId);
  }
}
