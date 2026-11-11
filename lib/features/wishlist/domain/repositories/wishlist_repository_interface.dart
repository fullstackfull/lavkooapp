import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class WishListRepositoryInterface implements RepositoryInterface<int> {
  Future<ApiResponseModel> getWishList({int? offset = 1, String? search = ''});
}
