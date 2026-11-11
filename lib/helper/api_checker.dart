import 'dart:developer';

import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/model/error_response.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class ApiChecker {
  static void checkApi(ApiResponseModel apiResponse,
      {bool firebaseResponse = false}) {
    final String errorStr = apiResponse.error?.toString() ?? '';
    if (errorStr.isEmpty) return;

    dynamic errorResponse = apiResponse.error is String
        ? apiResponse.error
        : ErrorResponse.fromJson(apiResponse.error);
    if (apiResponse.error == "Failed to load data - status code: 401") {
      Provider.of<AuthController>(Get.context!, listen: false)
          .clearSharedData();
    } else if (apiResponse.response?.statusCode == 500) {
      showCustomSnackBarWidget(
          getTranslated('internal_server_error', Get.context!), Get.context!,
          snackBarType: SnackBarType.error);
    } else if (apiResponse.response?.statusCode == 503) {
      showCustomSnackBarWidget(
          apiResponse.response?.data['message'], Get.context!,
          snackBarType: SnackBarType.error);
    } else {
      log("API_RESPONSE.ERROR${apiResponse.error}");
      String? errorMessage = apiResponse.error.toString();
      if (apiResponse.error is String) {
        errorMessage = apiResponse.error.toString();
      } else {
        log(errorResponse.toString());
        //errorMessage = errorResponse.errors?[0].message;
      }
      showCustomSnackBarWidget(
          firebaseResponse ? errorResponse?.replaceAll('_', ' ') : errorMessage,
          Get.context!,
          snackBarType: SnackBarType.error);
    }
  }

  static ErrorResponse getError(ApiResponseModel apiResponse) {
    ErrorResponse error;

    try {
      error = ErrorResponse.fromJson(apiResponse.response?.data);
    } catch (e) {
      if (apiResponse.error is String) {
        error = ErrorResponse(
            errors: [Errors(code: '', message: apiResponse.error.toString())]);
      } else {
        error = ErrorResponse.fromJson(apiResponse.error);
      }
    }
    return error;
  }
}
