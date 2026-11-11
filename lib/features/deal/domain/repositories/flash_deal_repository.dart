import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/deal/domain/repositories/flash_deal_repository_interface.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

class FlashDealRepository implements FlashDealRepositoryInterface {
  final DioClient? dioClient;
  FlashDealRepository({required this.dioClient});

  @override
  Future<ApiResponseModel> getFlashDeal() async {
    try {
      final response = await dioClient!.get(AppConstants.flashDealUri);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> get(String productID) async {
    try {
      // The endpoint paginates with a default page of 10; the screen draws the whole
      // deal, so ask for it (offset is the page number).
      final response = await dioClient!.get(
          '${AppConstants.flashDealProductUri}$productID?limit=100&offset=1');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
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
