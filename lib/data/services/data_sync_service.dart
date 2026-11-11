import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/reposotories/data_sync_repo_interface.dart';
import 'package:syriapharmacy/data/services/data_sync_service_interface.dart';

class DataSyncService implements DataSyncServiceInterface {
  DataSyncRepoInterface dataSyncRepoInterface;

  DataSyncService({required this.dataSyncRepoInterface});

  @override
  Future<ApiResponseModel<T>> fetchData<T>(
      String uri, DataSourceEnum source) async {
    return await dataSyncRepoInterface.fetchData(uri, source);
  }
}
