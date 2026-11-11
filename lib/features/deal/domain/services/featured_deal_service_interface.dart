import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';

abstract class FeaturedDealServiceInterface {
  Future<ApiResponseModel<T>> getFeaturedDeal<T>(
      {required DataSourceEnum source});
}
