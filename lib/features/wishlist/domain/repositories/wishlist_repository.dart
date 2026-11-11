import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/wishlist/domain/repositories/wishlist_repository_interface.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

class WishListRepository implements WishListRepositoryInterface {
  final DioClient? dioClient;

  WishListRepository({required this.dioClient});

  @override
  Future<ApiResponseModel> getList(
      {int? offset = 1, String? search = ''}) async {
    try {
      final response =
          await dioClient!.get(
          '${AppConstants.getWishListUri}?search=${Uri.encodeQueryComponent(search ?? '')}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getWishList(
      {int? offset = 1, String? search = ''}) async {
    try {
      final response =
          await dioClient!.get(
          '${AppConstants.getWishListUri}?search=${Uri.encodeQueryComponent(search ?? '')}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> add(int productID) async {
    try {
      final response = await dioClient!
          .post(AppConstants.addWishListUri + productID.toString());
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> delete(int productID) async {
    try {
      final response = await dioClient!
          .delete(AppConstants.removeWishListUri + productID.toString());
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
