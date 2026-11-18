import 'package:flutter/material.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:syriapharmacy/features/wallet/domain/models/wallet_bonus_model.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';

class WalletController extends ChangeNotifier with StorefrontChangeAware {
  final WalletServiceInterface walletServiceInterface;
  WalletController({
    required this.walletServiceInterface,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
  }

  bool _isLoading = false;
  bool _firstLoading = false;
  bool _isConvert = false;
  bool get isConvert => _isConvert;
  bool get isLoading => _isLoading;
  bool get firstLoading => _firstLoading;
  int? _transactionPageSize;
  int? get transactionPageSize => _transactionPageSize;
  WalletTransactionModel? _walletTransactionModel;
  WalletTransactionModel? get walletTransactionModel => _walletTransactionModel;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  String? _selectedFilterBy;
  String? get selectedFilterBy => _selectedFilterBy;

  Set<String>? _selectedEarnByList;
  Set<String>? get selectedEarnByList => _selectedEarnByList;

  Future<void> getTransactionList(
      int offset, {
        bool reload = false,
        bool isUpdate = true,
        String? filterBy,
        DateTime? startDate,
        DateTime? endDate,
        List<String>? transactionTypes,
      }) async {
    if (reload || offset == 1) {
      _walletTransactionModel = null;

      if (isUpdate) {
        notifyListeners();
      }
    }

    final String? storefront = StorefrontScope.current;
    ApiResponseModel apiResponse = await walletServiceInterface.getList(
      offset: offset,
      filterBy: filterBy,
      startDate: startDate,
      endDate: endDate,
      transactionTypes: transactionTypes,
    );

    // The ledger is read for one storefront: the answer of the storefront the customer has left is never shown as the ledger of the one
    // they are on.
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (apiResponse.response?.data != null &&
        apiResponse.response?.statusCode == 200) {
      if (offset == 1) {
        _walletTransactionModel =
            WalletTransactionModel.fromJson(apiResponse.response?.data);
      } else {
        _walletTransactionModel?.offset =
            WalletTransactionModel.fromJson(apiResponse.response?.data).offset;
        _walletTransactionModel?.totalWalletBalance =
            WalletTransactionModel.fromJson(apiResponse.response?.data)
                .totalWalletBalance;
        _walletTransactionModel?.totalSize =
            WalletTransactionModel.fromJson(apiResponse.response?.data)
                .totalSize;
        _walletTransactionModel?.walletTransactionList?.addAll(
            WalletTransactionModel.fromJson(apiResponse.response?.data)
                .walletTransactionList ??
                []);
      }
    } else {
      _walletTransactionModel?.walletTransactionList = [];
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void showBottomLoader() {
    _isLoading = true;
    notifyListeners();
  }

  void removeFirstLoading() {
    _firstLoading = true;
    notifyListeners();
  }

  Future<void> addFundToWallet(String amount, String paymentMethod) async {
    // Adding funds starts a payment, which a storefront that may not sell yet refuses, so it is refused here before any request.
    if (!StorefrontController.maySellIn(Get.context)) {
      showCustomSnackBarWidget(
          getTranslated('storefront_browse_only_notice', Get.context!),
          Get.context!,
          snackBarType: SnackBarType.warning);
      return;
    }

    _isConvert = true;
    notifyListeners();
    ApiResponseModel apiResponse =
    await walletServiceInterface.addFundToWallet(amount, paymentMethod);
    final dynamic redirectLink = apiResponse.response?.data is Map
        ? apiResponse.response?.data['redirect_link']
        : null;
    final bool hasLink = redirectLink is String && redirectLink.isNotEmpty;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        hasLink) {
      _isConvert = false;

      RouterHelper.getAddFundToWalletRoute(
          action: RouteAction.push, url: redirectLink);
    } else if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      // A 200 with no usable payment link. Nothing has been charged, so this is reported as a
      // failure to start the top-up, never as one that succeeded or is pending.
      _isConvert = false;

      showCustomSnackBarWidget(
          getTranslated('failedToGenerateLink', Get.context!), Get.context!,
          snackBarType: SnackBarType.error);
    } else if (apiResponse.response?.statusCode == 202) {
      showCustomSnackBarWidget(
          "Minimum= ${PriceConverter.convertPrice(Get.context!, double.tryParse('${apiResponse.response?.data['minimum_amount']}'))} and Maximum=${PriceConverter.convertPrice(Get.context!, double.tryParse('${apiResponse.response?.data['maximum_amount']}'))}",
          Get.context!,
          snackBarType: SnackBarType.warning);
    } else {
      _isConvert = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  WalletBonusModel? walletBonusModel;
  Future<void> getWalletBonusBannerList() async {
    final String? storefront = StorefrontScope.current;
    ApiResponseModel apiResponse =
    await walletServiceInterface.getWalletBonusBannerList();
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      walletBonusModel = WalletBonusModel.fromJson(apiResponse.response?.data);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  int currentIndex = 0;
  void setCurrentIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  Future<void> setSelectedDate(
      {required DateTime? startDate, required DateTime? endDate}) async {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  void setSelectedProductType({String? type, bool isUpdate = true}) {
    _selectedFilterBy = type;

    if (isUpdate) {
      notifyListeners();
    }
  }

  void onUpdateEarnBy(String value, {bool isUpdate = true}) {
    _selectedEarnByList ??= <String>{};

    // Toggle logic
    if (!_selectedEarnByList!.add(value)) {
      _selectedEarnByList!.remove(value);
    }

    if (isUpdate) {
      notifyListeners();
    }
  }

  /// The customer is on another storefront, which has a wallet ledger and bonuses of its own: what is held for the one they left is dropped, with the filters that
  /// belonged to it, and a signed-in customer's ledger and bonuses are loaded again. A guest has none to ask for, and asking would sign them out.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    _walletTransactionModel = null;
    walletBonusModel = null;
    _selectedFilterBy = null;
    _selectedEarnByList = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();

    if (change.signedIn) {
      await Future.wait(<Future<void>>[
        getTransactionList(1, isUpdate: false),
        getWalletBonusBannerList(),
      ]);
    }
  }

  void initFilterData() {
    _selectedFilterBy = _walletTransactionModel?.filterBy;
    _selectedEarnByList = _walletTransactionModel?.transactionTypes?.toSet();

    _startDate = _walletTransactionModel?.startDate;
    _endDate = _walletTransactionModel?.endDate;
  }
}