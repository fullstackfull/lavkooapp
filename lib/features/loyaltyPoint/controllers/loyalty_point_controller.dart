import 'package:flutter/material.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/loyaltyPoint/domain/models/loyalty_point_model.dart';
import 'package:syriapharmacy/features/loyaltyPoint/domain/services/loyalty_point_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';

class LoyaltyPointController extends ChangeNotifier
    with StorefrontChangeAware {
  final LoyaltyPointServiceInterface loyaltyPointServiceInterface;
  LoyaltyPointController({
    required this.loyaltyPointServiceInterface,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
  }

  bool _isConvert = false;
  bool get isConvert => _isConvert;

  LoyaltyPointModel? _loyaltyPointModel;
  LoyaltyPointModel? get loyaltyPointModel => _loyaltyPointModel;

  String? _selectedFilterBy;
  String? get selectedFilterBy => _selectedFilterBy;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  Set<String>? _selectedEarnByList;
  Set<String>? get selectedEarnByList => _selectedEarnByList;

  Future<void> getLoyaltyPointList(
    BuildContext context,
    int offset, {
    bool reload = false,
    bool isUpdate = true,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,
  }) =>
      _loadLedger(
        offset,
        reload: reload,
        isUpdate: isUpdate,
        filterBy: filterBy,
        startDate: startDate,
        endDate: endDate,
        transactionTypes: transactionTypes,
      );

  Future<void> _loadLedger(
    int offset, {
    bool reload = false,
    bool isUpdate = true,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,
  }) async {
    if (reload || offset == 1) {
      _loyaltyPointModel = null;

      if (isUpdate) {
        notifyListeners();
      }
    }

    final String? storefront = StorefrontScope.current;
    ApiResponseModel apiResponse = await loyaltyPointServiceInterface.getList(
      offset: offset,
      filterBy: filterBy,
      startDate: startDate,
      endDate: endDate,
      transactionTypes: transactionTypes,
    );

    // The points are read for one storefront: the answer of the storefront the customer has left is never shown as the points of the one
    // they are on.
    if (!StorefrontScope.isCurrent(storefront)) return;

    if (apiResponse.response?.data != null &&
        apiResponse.response?.statusCode == 200) {
      if (offset == 1) {
        _loyaltyPointModel =
            LoyaltyPointModel.fromJson(apiResponse.response?.data);
      } else {
        _loyaltyPointModel?.offset =
            LoyaltyPointModel.fromJson(apiResponse.response?.data).offset;
        _loyaltyPointModel?.totalLoyaltyPoint =
            LoyaltyPointModel.fromJson(apiResponse.response?.data)
                .totalLoyaltyPoint;
        _loyaltyPointModel?.loyaltyPointList?.addAll(
            LoyaltyPointModel.fromJson(apiResponse.response?.data)
                    .loyaltyPointList ??
                []);
      }
    } else {
      _loyaltyPointModel?.loyaltyPointList = [];
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future convertPointToCurrency(BuildContext context, int point) async {
    _isConvert = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await loyaltyPointServiceInterface.convertPointToCurrency(point);
    if (apiResponse.response != null &&
        apiResponse.response?.statusCode == 200) {
      _isConvert = false;
      showCustomSnackBarWidget(
          getTranslated('point_converted_successfully', Get.context!),
          Get.context!,
          snackBarType: SnackBarType.success);
    } else {
      _isConvert = false;
      showCustomSnackBarWidget(
          getTranslated('point_converted_failed', Get.context!), Get.context!,
          snackBarType: SnackBarType.error);
    }
    notifyListeners();
  }

  void setSelectedProductType({String? type, bool isUpdate = true}) {
    _selectedFilterBy = type;

    if (isUpdate) {
      notifyListeners();
    }
  }

  void setSelectedDate(
      {required DateTime? startDate, required DateTime? endDate}) async {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
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

  /// The customer is on another storefront, which has a points ledger of its own: what is held for the one they left is dropped, with the filters
  /// that belonged to it, and a signed-in customer's points are loaded again. A guest has none to ask for, and asking would sign them out.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    _loyaltyPointModel = null;
    _selectedFilterBy = null;
    _selectedEarnByList = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();

    if (change.signedIn) {
      await _loadLedger(1, isUpdate: false);
    }
  }

  void initFilterData() {
    _selectedFilterBy = _loyaltyPointModel?.filterBy;
    _selectedEarnByList = _loyaltyPointModel?.transactionTypes?.toSet();

    _startDate = _loyaltyPointModel?.startDate;
    _endDate = _loyaltyPointModel?.endDate;
  }
}
