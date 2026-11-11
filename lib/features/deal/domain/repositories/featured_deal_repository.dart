import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/services/data_sync_service.dart';
import 'package:syriapharmacy/features/deal/domain/repositories/featured_deal_repository_interface.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';

class FeaturedDealRepository extends DataSyncService
    implements FeaturedDealRepositoryInterface {
  final DioClient dioClient;
  FeaturedDealRepository(
      {required this.dioClient, required super.dataSyncRepoInterface});

  @override
  Future<ApiResponseModel<T>> getFeaturedDeal<T>(
      {required DataSourceEnum source}) async {
    return await fetchData<T>(AppConstants.featuredDealUri, source);
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
