import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';

abstract class DataSyncServiceInterface {
  Future<ApiResponseModel<T>> fetchData<T>(String uri, DataSourceEnum source);
}
