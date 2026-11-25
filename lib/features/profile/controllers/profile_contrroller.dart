import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/model/response_model.dart';
import 'package:syriapharmacy/features/profile/domain/models/profile_model.dart';
import 'package:syriapharmacy/features/profile/domain/services/profile_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:http/http.dart' as http;

class ProfileController extends ChangeNotifier with StorefrontChangeAware {
  final ProfileServiceInterface? profileServiceInterface;
  ProfileController({
    required this.profileServiceInterface,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
  }

  ProfileModel? _userInfoModel;
  bool _isLoading = false;
  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;
  double? _balance;
  double? get balance => _balance;
  ProfileModel? get userInfoModel => _userInfoModel;
  bool get isLoading => _isLoading;
  double? loyaltyPoint = 0;
  String userID = '-1';

  /// Whether the profile has been asked for at all, so a change of storefront reloads what was on screen and nothing else.
  bool _profileWasAsked = false;

  /// The customer is on another storefront, whose wallet money and loyalty points are its own (J-09, E-01, E-04).
  ///
  /// This controller holds the two balances the account screen shows, and it was the only holder of a balance in the app that was not
  /// told: the wallet screen and the points screen both drop theirs, so a customer who moved from Kuwait to Riyadh saw the Saudi wallet
  /// on one screen and a Kuwaiti figure on their account page, in a currency that was no longer the one being shown.
  ///
  /// Dropped BEFORE the first await, as the contract of a listener requires, so the money of the storefront the customer left is never on
  /// screen. A guest has no profile to ask for and asking would sign them out.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    final bool reloadProfile = _profileWasAsked;
    _userInfoModel = null;
    _balance = null;
    loyaltyPoint = 0;
    userID = '-1';
    _profileWasAsked = false;
    notifyListeners();

    if (change.signedIn && reloadProfile) {
      await getUserInfo();
    }
  }

  /// [context] is accepted because every screen passes one and is not read: the profile is asked for over the client, and a reload that
  /// follows a change of storefront has no screen to take one from.
  Future<String> getUserInfo([BuildContext? context]) async {
    _profileWasAsked = true;
    ApiResponseModel apiResponse =
        await profileServiceInterface!.getProfileInfo();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _userInfoModel = ProfileModel.fromJson(apiResponse.response!.data);
      userID = _userInfoModel!.id.toString();
      _balance = _userInfoModel?.walletBalance ?? 0;
      loyaltyPoint = _userInfoModel?.loyaltyPoint ?? 0;
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return userID;
  }

  Future<ApiResponseModel> deleteCustomerAccount(
      BuildContext context, int customerId) async {
    _isDeleting = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await profileServiceInterface!.delete(customerId);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _isDeleting = false;
      Map map = apiResponse.response!.data;
      String message = map['message'];
      showCustomSnackBarWidget(message, Get.context!,
          snackBarType: SnackBarType.error);
    } else {
      _isDeleting = false;

      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ResponseModel> updateUserInfo(ProfileModel updateUserModel,
      String pass, File? file, String token) async {
    _isLoading = true;
    notifyListeners();

    ResponseModel responseModel;
    http.StreamedResponse response = await profileServiceInterface!
        .updateProfile(updateUserModel, pass, file, token);
    _isLoading = false;
    if (response.statusCode == 200) {
      Map map = jsonDecode(await response.stream.bytesToString());
      String? message = map["message"];
      _userInfoModel = updateUserModel;
      responseModel = ResponseModel(message, true);
      Navigator.of(Get.context!).pop();
    } else {
      final String responseBody = await response.stream.bytesToString();
      var decodedData = jsonDecode(responseBody);

      String? errorMessage;

      if (decodedData != null) {
        errorMessage = decodedData['errors']?[0]?['message'];
      }
      responseModel =
          ResponseModel('${errorMessage ?? response.reasonPhrase}', false);
    }
    notifyListeners();
    return responseModel;
  }

  void clearProfileData() {
    _userInfoModel = null;
    notifyListeners();
  }
}
