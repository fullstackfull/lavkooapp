import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/enums/data_source_enum.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/services/data_sync_service.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/category/domain/repositories/category_repo_interface.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:provider/provider.dart';

class CategoryRepository extends DataSyncService
    implements CategoryRepoInterface {
  final DioClient? dioClient;
  CategoryRepository(
      {required this.dioClient, required super.dataSyncRepoInterface});

  @override
  Future<ApiResponseModel> getList({int? offset}) async {
    try {
      final response = await dioClient!.get(AppConstants.categoriesUri);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getSellerWiseCategoryList(String slug) async {
    try {
      final response = await dioClient!
          .get('${AppConstants.sellerWiseCategoryList}$slug&guest_id=1');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponseModel<T>> getCategoryList<T>(
      {required DataSourceEnum source}) async {
    return await fetchData<T>(
        '${AppConstants.categoriesUri}?guest_id=1', source);
  }

  @override
  Future<ApiResponseModel> getCategoryPageHeader(int categoryId) async {
    try {
      String guestId = '1';
      try {
        if (Get.context != null) {
          guestId = Provider.of<AuthController>(Get.context!, listen: false)
              .getGuestToken()!;
        }
      } catch (_) {}
      final response = await dioClient!.get(
        '${AppConstants.categoryPageHeaderUri}$categoryId?guest_id=$guestId',
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
