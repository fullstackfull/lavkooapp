import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class BannerRepositoryInterface<T> implements RepositoryInterface {
  Future<ApiResponseModel<T>> getBannerList<T>(
      {required DataSourceEnum source});
}
