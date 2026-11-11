import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/splash/domain/models/business_pages_model.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/splash/domain/services/splash_service_interface.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/helper/color_helper.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/meta_tracking_service.dart';

class SplashController extends ChangeNotifier {
  final SplashServiceInterface? splashServiceInterface;
  SplashController({required this.splashServiceInterface}) {
    loadPricingMode();
  }

  bool _isNewPricingMode = false;
  bool get isNewPricingMode => _isNewPricingMode;

  void togglePricingMode() async {
    _isNewPricingMode = !_isNewPricingMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNewPricingMode', _isNewPricingMode);
  }

  void loadPricingMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isNewPricingMode = prefs.getBool('isNewPricingMode') ?? false;
    notifyListeners();
  }

  ConfigModel? _configModel;
  BaseUrls? _baseUrls;
  CurrencyList? _myCurrency;
  CurrencyList? _usdCurrency;
  CurrencyList? _defaultCurrency;
  int? _currencyIndex;
  bool _hasConnection = true;
  bool _fromSetting = false;
  bool _firstTimeConnectionCheck = true;
  bool _onOff = true;
  bool get onOff => _onOff;
  bool isConfigCall = false;

  ConfigModel? get configModel => _configModel;
  BaseUrls? get baseUrls => _baseUrls;
  CurrencyList? get myCurrency => _myCurrency;
  CurrencyList? get usdCurrency => _usdCurrency ?? _myCurrency ?? _defaultCurrency;
  CurrencyList? get defaultCurrency => _defaultCurrency;
  int? get currencyIndex => _currencyIndex;
  bool get hasConnection => _hasConnection;
  bool get fromSetting => _fromSetting;
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;
  BuildContext? _buildContext;

  List<BusinessPageModel>? _defaultBusinessPages;
  List<BusinessPageModel>? get defaultBusinessPages => _defaultBusinessPages;

  List<BusinessPageModel>? _businessPages;
  List<BusinessPageModel>? get businessPages => _businessPages;

  Future<bool> initConfig(
    BuildContext context,
    Function(ConfigModel? configModel)? onLocalDataReceived,
    Function(ConfigModel? configModel)? onApiDataReceived,
  ) async {
    final ThemeController themeController =
        Provider.of<ThemeController>(context, listen: false);

    var configLocalData =
        await database.getCacheResponseById(AppConstants.configUri);

    bool localMaintainanceMode = false;

    isConfigCall = false;

    if (configLocalData != null) {
      _configModel = ConfigModel.fromJson(jsonDecode(configLocalData.response));

      localMaintainanceMode =
          (_configModel?.maintenanceModeData?.maintenanceStatus == 1 &&
              _configModel?.maintenanceModeData?.selectedMaintenanceSystem
                      ?.customerApp ==
                  1);

      String? currencyCode = splashServiceInterface!.getCurrency();

      for (CurrencyList currencyList in _configModel!.currencyList!) {
        if (currencyList.id == _configModel!.systemDefaultCurrency) {
          if (currencyCode == null || currencyCode.isEmpty) {
            currencyCode = currencyList.code;
          }
          _defaultCurrency = currencyList;
        }
        if (currencyList.code == 'USD') {
          _usdCurrency = currencyList;
        }
      }
      getCurrencyData(currencyCode);

      if (onLocalDataReceived != null) {
        onLocalDataReceived(configModel);
      }
    }

    _hasConnection = true;
    ApiResponseModel apiResponse = await splashServiceInterface!.getConfig();

    // _configModel = ConfigModel.fromJson(apiResponse.response!.data);
    bool isSuccess;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      isSuccess = true;
      _configModel = ConfigModel.fromJson(apiResponse.response!.data);
      isConfigCall = true;

      _baseUrls = ConfigModel.fromJson(apiResponse.response!.data).baseUrls;

      _configModel?.hasLocaldb = configLocalData != null;

      _configModel?.localMaintenanceMode = localMaintainanceMode;

      if (onApiDataReceived != null) {
        onApiDataReceived(configModel);
      }

      String? currencyCode = splashServiceInterface!.getCurrency();

      try {
        await FirebaseMessaging.instance.getToken();
        await FirebaseMessaging.instance
            .subscribeToTopic(AppConstants.maintenanceModeTopic);
        await FirebaseMessaging.instance
            .subscribeToTopic(AppConstants.themeUpdatesTopic);
      } catch (e) {
        debugPrint("====FirebaseException===>>$e");
      }

      themeController.setThemeColor(
        primaryColor:
            ColorHelper.hexCodeToColor(_configModel?.primaryColorCode),
        secondaryColor:
            ColorHelper.hexCodeToColor(_configModel?.secondaryColorCode),
      );

      for (CurrencyList currencyList in _configModel!.currencyList!) {
        if (currencyList.id == _configModel!.systemDefaultCurrency) {
          if (currencyCode == null || currencyCode.isEmpty) {
            currencyCode = currencyList.code;
          }
          _defaultCurrency = currencyList;
        }
        if (currencyList.code == 'USD') {
          _usdCurrency = currencyList;
        }
      }
      getCurrencyData(currencyCode);

      if (_configModel?.maintenanceModeData?.maintenanceStatus == 0) {
        if (_configModel
                ?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp ==
            1) {
          if (_configModel?.maintenanceModeData?.maintenanceTypeAndDuration
                  ?.maintenanceDuration ==
              'customize') {
            DateTime now = DateTime.now();
            DateTime specifiedDateTime = DateTime.parse(_configModel!
                .maintenanceModeData!.maintenanceTypeAndDuration!.startDate!);

            Duration difference = specifiedDateTime.difference(now);

            if (difference.inMinutes > 0 &&
                (difference.inMinutes < 60 || difference.inMinutes == 60)) {
              _startTimer(specifiedDateTime);
            }
          }
        }
      }

      if (configLocalData != null) {
        await database.updateCacheResponse(
            AppConstants.configUri,
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.configUri),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.configUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
      MetaTrackingService().updateConfig(configModel!);
      _configModel = ConfigModel.fromJson(apiResponse.response!.data);

      isSuccess = true;
    } else {
      isSuccess = false;
      if (apiResponse.response == null) {
        _hasConnection = false;
      } else {
        ApiChecker.checkApi(apiResponse);
      }
    }
    notifyListeners();

    return isSuccess;
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  void getCurrencyData(String? currencyCode) {
    if (_configModel?.currencyList != null && _configModel!.currencyList!.isNotEmpty) {
      _myCurrency = null;
      _currencyIndex = null;

      // 1. Priority: Find Syrian Pound (SYP) or System Default Currency
      for (int i = 0; i < _configModel!.currencyList!.length; i++) {
        var currency = _configModel!.currencyList![i];
        if (currency.code == 'SYP' ||
            (currency.id != null &&
                currency.id.toString() == _configModel!.systemDefaultCurrency.toString())) {
          _myCurrency = currency;
          _currencyIndex = i;
          break;
        }
      }

      // 2. Priority: Check saved currency if active
      if (_myCurrency == null && currencyCode != null && currencyCode.isNotEmpty) {
        for (int i = 0; i < _configModel!.currencyList!.length; i++) {
          var currency = _configModel!.currencyList![i];
          if (currency.code == currencyCode && currency.status != false) {
            _myCurrency = currency;
            _currencyIndex = i;
            break;
          }
        }
      }

      // 3. Priority: First active currency
      if (_myCurrency == null) {
        for (int i = 0; i < _configModel!.currencyList!.length; i++) {
          var currency = _configModel!.currencyList![i];
          if (currency.status != false) {
            _myCurrency = currency;
            _currencyIndex = i;
            break;
          }
        }
      }

      // 4. Fallback: First currency in list
      if (_myCurrency == null) {
        _myCurrency = _configModel!.currencyList![0];
        _currencyIndex = 0;
      }

      // Always save resolved currency to SharedPreferences to purge old USD preference
      if (_myCurrency != null) {
        splashServiceInterface?.setCurrency(_myCurrency!.code ?? 'SYP');
      }
    }
  }


  /// Re-read just the payment options from `/api/v1/config`.
  ///
  /// Which payment methods exist is decided entirely by the admin panel, and the app holds a cached
  /// copy of the config (it renders the cached one first so the UI is instant). That cache is the
  /// reason a gateway switched off in the admin panel could still appear on the payment sheet — and a
  /// customer picking a method the server will then refuse gets an error they cannot act on. So the
  /// checkout re-reads this on open.
  ///
  /// Deliberately NOT `initConfig`: that also reloads the theme, the currency and the maintenance
  /// state, and rebuilding all of that while someone is choosing how to pay is both slow and visibly
  /// disruptive. Only the payment fields are replaced here.
  ///
  /// A failure is silent and leaves the cached list in place. The checkout still works, and the server
  /// refuses anything that is genuinely switched off, so a stale list cannot take a payment through a
  /// disabled gateway — it can only offer one that then says no.
  Future<void> refreshPaymentMethods() async {
    if (_configModel == null) return;

    try {
      final ApiResponseModel apiResponse = await splashServiceInterface!.getConfig();

      if (apiResponse.response == null || apiResponse.response!.statusCode != 200) return;

      final ConfigModel fresh = ConfigModel.fromJson(apiResponse.response!.data);

      _configModel!.paymentMethods = fresh.paymentMethods;
      _configModel!.digitalPayment = fresh.digitalPayment;
      _configModel!.cashOnDelivery = fresh.cashOnDelivery;
      _configModel!.offlinePayment = fresh.offlinePayment;
      _configModel!.paymentMethodImagePath = fresh.paymentMethodImagePath;

      notifyListeners();
    } catch (_) {
      // Keep the cached list; see above.
    }
  }

  Future<void> getBusinessPagesList(String type) async {
    ApiResponseModel apiResponse =
        await splashServiceInterface!.getBusinessPages(type);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      if (type == 'default') {
        _defaultBusinessPages = [];
        apiResponse.response?.data.forEach((data) {
          _defaultBusinessPages?.add(BusinessPageModel.fromJson(data));
        });
      } else {
        _businessPages = [];
        apiResponse.response?.data.forEach((data) {
          _businessPages?.add(BusinessPageModel.fromJson(data));
        });
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }

  void setCurrency(int index) {
    splashServiceInterface!
        .setCurrency(_configModel!.currencyList![index].code!);
    getCurrencyData(_configModel!.currencyList![index].code);
    notifyListeners();
  }

  void initSharedPrefData() {
    splashServiceInterface!.initSharedData();
  }

  void setFromSetting(bool isSetting) {
    _fromSetting = isSetting;
  }

  bool? showIntro() {
    return splashServiceInterface!.showIntro();
  }

  void disableIntro() {
    splashServiceInterface!.disableIntro();
  }

  void changeAnnouncementOnOff(bool on) {
    _onOff = !_onOff;
    notifyListeners();
  }

  void _startTimer(DateTime startTime) {
    Timer.periodic(const Duration(seconds: 30), (Timer timer) {
      DateTime now = DateTime.now();

      if (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) {
        timer.cancel();
        RouterHelper.getMaintenanceRoute(action: RouteAction.pushReplacement);
      }
    });
  }

  void setMaintenanceContext(BuildContext context) {
    _buildContext = context;
  }

  void removeMaintenanceContext() {
    _buildContext = null;
  }

  bool isMaintenanceModeScreen() {
    if (_buildContext == null ||
        configModel?.maintenanceModeData?.maintenanceStatus == 1) {
      return false;
    }
    return ModalRoute.of(_buildContext!)?.settings.name == 'MaintenanceScreen';
  }

}
