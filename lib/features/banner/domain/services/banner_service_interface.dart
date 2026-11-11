import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';

abstract class BannerServiceInterface {
  Future<ApiResponseModel<T>> getList<T>({required DataSourceEnum source});
}
