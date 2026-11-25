import 'package:dio/dio.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/features/address/address_catalog_config.dart';
import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/address/domain/models/label_model.dart';
import 'package:syriapharmacy/features/address/domain/repositories/address_repository_interface.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:provider/provider.dart';

class AddressRepository implements AddressRepoInterface<ApiResponseModel> {
  final DioClient? dioClient;
  AddressRepository({this.dioClient});

  @override
  Future<ApiResponseModel> getDeliveryRestrictedCountryList() async {
    try {
      final response = await dioClient!.get(
          '${AppConstants.deliveryRestrictedCountryList}?guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  /// The regions of the central catalogue, or none at all (J-14).
  ///
  /// An empty list on every answer the app cannot use: the catalogue switched
  /// off in this build, a store whose address masters are not imported (the
  /// server answers `{"regions": []}`), a refusal, a timeout. The caller draws
  /// the legacy form from an empty list, which is what it drew before this
  /// existed, so nothing has to ask whether the feature is on.
  @override
  Future<List<AddressRegionModel>> getAddressRegions() async {
    if (!AddressCatalogConfig.enabled) {
      return const <AddressRegionModel>[];
    }

    try {
      final Response response = await dioClient!.get(AppConstants.addressRegionsUri);

      return AddressRegionModel.listFrom(response.data);
    } catch (_) {
      return const <AddressRegionModel>[];
    }
  }

  @override
  Future<List<AddressCityModel>> getAddressCities({int? regionId, String? query, int? limit}) async {
    if (!AddressCatalogConfig.enabled) {
      return const <AddressCityModel>[];
    }

    final Map<String, dynamic> parameters = <String, dynamic>{
      if (regionId != null && regionId > 0) 'region_id': regionId,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (limit != null && limit > 0) 'limit': limit,
    };

    try {
      final Response response = await dioClient!.get(
        AppConstants.addressCitiesUri,
        queryParameters: parameters.isEmpty ? null : parameters,
      );

      return AddressCityModel.listFrom(response.data);
    } catch (_) {
      return const <AddressCityModel>[];
    }
  }

  @override
  Future<ApiResponseModel> getDeliveryRestrictedZipList() async {
    try {
      final response = await dioClient!.get(
          '${AppConstants.deliveryRestrictedZipList}?guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getDeliveryRestrictedZipBySearch(
      String zipcode) async {
    try {
      final response = await dioClient!.get(
          '${AppConstants.deliveryRestrictedZipList}?search=$zipcode&guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getDeliveryRestrictedCountryBySearch(
      String country) async {
    try {
      final response = await dioClient!.get(
          '${AppConstants.deliveryRestrictedCountryList}?search=$country&guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getList({int? offset}) async {
    try {
      final response = await dioClient!.get(
          '${AppConstants.addressListUri}?guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> delete(int? id) async {
    try {
      final response = await dioClient!.post(
          '${AppConstants.removeAddressUri}?address_id=$id&guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}',
          data: {"_method": 'delete'});
      ApiResponseModel res = ApiResponseModel.withSuccess(response);
      return res;
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> add(AddressModel addressModel) async {
    try {
      Response response = await dioClient!
          .post(AppConstants.addAddressUri, data: addressModel.toJson());
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> update(
      Map<String, dynamic> addressModel, int addressId) async {
    try {
      Response response = await dioClient!
          .post(AppConstants.updateAddressUri, data: addressModel);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  List<LabelAsModel> getAddressType() {
    List<LabelAsModel> labelAsList = [
      LabelAsModel('home', Images.homeImage),
      LabelAsModel('office', Images.officeImage),
      LabelAsModel('others', Images.address),
    ];
    return labelAsList;
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }
}
