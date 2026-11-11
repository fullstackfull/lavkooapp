import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:syriapharmacy/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

import '../../../services/meta_tracking_service.dart';

class CheckoutController with ChangeNotifier {
  final CheckoutServiceInterface checkoutServiceInterface;

  CheckoutController({
    required this.checkoutServiceInterface,
  });

  // ============================================================
  // ADDRESS
  // ============================================================

  int? _addressIndex;

  // Billing will ALWAYS use the same index as Delivery
  int? _billingAddressIndex;

  int? get billingAddressIndex => _billingAddressIndex;

  int? _shippingIndex;

  // ============================================================
  // GENERAL STATES
  // ============================================================

  bool _isLoading = false;
  bool _isCheckCreateAccount = false;
  bool _newUser = false;

  /// One key for one checkout attempt, kept across retries of that attempt.
  ///
  /// The server commits the order and then talks to the courier in the same request — up to 30
  /// seconds per vendor — while the app gives up at 60. So a timeout here is routinely a placed
  /// order, and the tap that follows it used to create a second one: two stock decrements, two
  /// deliveries, two COD collections, discovered only when both arrived.
  ///
  /// The key is minted when an attempt begins and deliberately NOT replaced while that attempt is
  /// unresolved, so a retry carries the same key and a server that honours it answers with the first
  /// attempt's order instead of creating another. It is cleared once the outcome is known either
  /// way, which is what makes the customer's next, deliberate order a new one.
  String? _attemptKey;
  int _attemptCounter = 0;

  String _beginAttempt() => _attemptKey ??=
  'app-${DateTime.now().microsecondsSinceEpoch}-${_attemptCounter++}';

  void _endAttempt() => _attemptKey = null;

  int _paymentMethodIndex = -1;

  bool _onlyDigital = true;

  bool get onlyDigital => _onlyDigital;

  int? get addressIndex => _addressIndex;

  int? get shippingIndex => _shippingIndex;

  bool get isLoading => _isLoading;

  int get paymentMethodIndex => _paymentMethodIndex;

  bool get isCheckCreateAccount => _isCheckCreateAccount;

  // ============================================================
  // CHANGE AMOUNT
  // ============================================================

  bool _changeAmountShow = false;

  bool get changeAmountShow => _changeAmountShow;

  double? _cashChangesAmount;

  double? get cashChangesAmount => _cashChangesAmount;

  // ============================================================
  // REFERRAL
  // ============================================================

  ReferralAmount? _referralAmount;

  ReferralAmount? get referralAmount => _referralAmount;

  // ============================================================
  // PAYMENT NAME
  // ============================================================

  String selectedPaymentName = '';

  void setSelectedPayment(String payment) {
    selectedPaymentName = payment;
    notifyListeners();
  }

  // ============================================================
  // TERMS
  // ============================================================

  bool _isAcceptTerms = false;

  bool get isAcceptTerms => _isAcceptTerms;

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController orderNoteController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  List<String> inputValueList = [];

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> placeOrder({
    required Function callback,
    String? addressID,
    String? couponCode,
    String? couponAmount,
    String? billingAddressId,
    String? orderNote,
    String? transactionId,
    String? paymentNote,
    int? id,
    String? name,
    bool isfOffline = false,
    bool wallet = false,
  }) async {
    // ============================================================
    // IMPORTANT:
    // Billing Address must always be the same as Delivery Address.
    //
    // If addressID exists, use it as billingAddressId.
    // ============================================================

    if (addressID != null && addressID.isNotEmpty) {
      billingAddressId = addressID;
    }

    for (TextEditingController textEditingController
    in inputFieldControllerList) {
      inputValueList.add(
        textEditingController.text.trim(),
      );
    }

    _isLoading = true;
    _newUser = false;

    final String attemptKey = _beginAttempt();

    notifyListeners();

    ApiResponseModel apiResponse;

    // ============================================================
    // OFFLINE PAYMENT
    // ============================================================

    isfOffline
        ? apiResponse =
    await checkoutServiceInterface.offlinePaymentPlaceOrder(
      addressID,
      couponCode,
      couponAmount,
      billingAddressId,
      orderNote,
      keyList,
      inputValueList,
      offlineMethodSelectedId,
      offlineMethodSelectedName,
      paymentNote,
      _isCheckCreateAccount,
      passwordController.text.trim(),
      attemptKey,
    )

    // ========================================================
    // WALLET PAYMENT
    // ========================================================

        : wallet
        ? apiResponse =
    await checkoutServiceInterface.walletPaymentPlaceOrder(
      addressID,
      couponCode,
      couponAmount,
      billingAddressId,
      orderNote,
      _isCheckCreateAccount,
      passwordController.text.trim(),
      attemptKey,
    )

    // ====================================================
    // CASH ON DELIVERY
    // ====================================================

        : apiResponse =
    await checkoutServiceInterface
        .cashOnDeliveryPlaceOrder(
      addressID: addressID,
      couponCode: couponCode,
      couponDiscountAmount: couponAmount,

      // IMPORTANT:
      // Billing = Delivery
      billingAddressId: billingAddressId,

      orderNote: orderNote,
      isCheckCreateAccount:
      _isCheckCreateAccount,
      password:
      passwordController.text.trim(),
      cashChangeAmount:
      _cashChangesAmount,
      currentCurrencyCode:
      Provider.of<SplashController>(
        Get.context!,
        listen: false,
      ).myCurrency?.code,
      idempotencyKey: attemptKey,
    );

    // ============================================================
    // ORDER SUCCESS
    // ============================================================

    // An HTTP 200 is not proof that an order exists.
    //
    // Three of the placement endpoints answer 200 with nothing but a message when they refuse —
    // offline payment returns `{"message":"address_not_found"}` with that status where the COD and
    // wallet paths return 403 for the very same condition. Taking the status alone as success showed
    // the customer a placed-order sheet, navigated them away from their cart and fired the purchase
    // analytics for an order that was never created, with an id of the literal string "null".
    //
    // The order ids are the proof, so they are what is checked. A refusal now goes down the same path
    // as any other failure, where the server's own message reaches the customer.
    final String? placedOrderIds = _placedOrderIds(apiResponse);

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        placedOrderIds != null) {
      _isCheckCreateAccount = false;

      _isLoading = false;

      // Clear selected addresses after order
      _addressIndex = null;
      _billingAddressIndex = null;

      // Keep Same As Delivery enabled
      sameAsBilling = true;

      if (!Provider.of<AuthController>(
        Get.context!,
        listen: false,
      ).isLoggedIn()) {
        // true/false from the API, 1/0 from some builds, and absent on a refusal. Assigning that
        // last case to a non-nullable bool threw, which left a guest on a dead checkout screen.
        final dynamic newUser =
        apiResponse.response!.data['new_user'];

        _newUser = newUser == true || newUser == 1 || newUser == '1';
      }

      String message =
      apiResponse.response!.data.toString();

      // ✅ Meta Tracking: Initiate Checkout event
      // This should be called when user proceeds to checkout/payment
      // For now, we'll add it when order is successfully placed
      // In a real implementation, this should be called when user clicks "Proceed to Checkout"
      MetaTrackingService().logInitiateCheckout(
        value: 0.0, // You might want to calculate the actual total value
        currency: Provider.of<SplashController>(
          Get.context!,
          listen: false,
        ).myCurrency?.code ?? 'SYP',
        numItems: 1, // You might want to calculate the actual number of items
      );

      _endAttempt();

      callback(
        true,
        message,
        placedOrderIds,
        _newUser,
      );
    } else if (apiResponse.unanswered) {
      // No answer came back, so nothing is known: the order may well exist. Saying it failed is what
      // invites the second one, so the customer is told we could not confirm it and pointed at their
      // orders. _attemptKey is deliberately kept, so if they do try again it is the same attempt.
      _isLoading = false;

      callback(
        false,
        getTranslated('order_could_not_be_confirmed', Get.context!) ??
            'We could not confirm your order. Check My Orders before trying again.',
        '',
        false,
      );
    } else if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      // A refusal dressed as a success. ApiChecker has nothing to work with here, because Dio raises
      // no error for a 200, so the message is read out of the body the server did send.
      _isLoading = false;

      _endAttempt();

      showCustomSnackBarWidget(
        _refusalMessage(apiResponse) ??
            getTranslated('order_could_not_be_placed', Get.context!),
        Get.context!,
        snackBarType: SnackBarType.error,
      );
    } else {
      _isLoading = false;
      _endAttempt();

      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }

  // ============================================================
  // EXTRACT ID
  // ============================================================

  /// The ids of the orders the server says it created, or null if it created none.
  ///
  /// Absent, empty, `[]` and the literal `"null"` all mean the same thing: no order. `extractId`
  /// cannot tell the last of those from a real id, because it reaches it as the four characters
  /// `null` after `.toString()`.
  String? _placedOrderIds(ApiResponseModel apiResponse) {
    final dynamic body = apiResponse.response?.data;
    if (body is! Map) return null;

    final dynamic ids = body['order_ids'];
    if (ids == null) return null;
    if (ids is List && ids.isEmpty) return null;

    final String? extracted = extractId(ids.toString());
    if (extracted == null || extracted == 'null' || extracted == 'false') {
      return null;
    }

    return extracted;
  }

  /// What the server said when it refused with a 200.
  String? _refusalMessage(ApiResponseModel apiResponse) {
    final dynamic body = apiResponse.response?.data;
    if (body is! Map) return null;

    final dynamic errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final dynamic first = errors.first;
      if (first is Map && first['message'] != null) {
        return first['message'].toString();
      }
    }

    final dynamic message = body['message'];
    return message == null ? null : message.toString();
  }

  String? extractId(String idsString) {
    String cleaned =
    idsString.replaceAll(
      RegExp(r'[\[\]\s]'),
      '',
    );

    return cleaned.isNotEmpty
        ? cleaned
        : null;
  }

  String? getFirstOrderId(String idsString) {
    if (idsString.trim().isEmpty) {
      return null;
    }

    List<String> ids = idsString
        .split(',')
        .map((e) => e.trim())
        .toList();

    return ids.isNotEmpty
        ? ids.first
        : null;
  }

  // ============================================================
  // DELIVERY ADDRESS
  // ============================================================

  void setAddressIndex(int index) {
    // Delivery Address
    _addressIndex = index;

    // Billing Address = Delivery Address
    _billingAddressIndex = index;

    // Always enabled
    sameAsBilling = true;

    notifyListeners();
  }

  // ============================================================
  // BILLING ADDRESS
  // ============================================================

  void setBillingAddressIndex(int index) {
    // Ignore the passed billing index.
    // Billing must always follow Delivery.
    _billingAddressIndex = _addressIndex;

    // Always enabled
    sameAsBilling = true;

    notifyListeners();
  }

  // ============================================================
  // PAYMENT RESET
  // ============================================================

  void resetPaymentMethod() {
    _paymentMethodIndex = -1;

    isCODChecked = false;
    isWalletChecked = false;
    isOfflineChecked = false;
  }

  // ============================================================
  // CLEAR DELIVERY ADDRESS
  // ============================================================

  void shippingAddressNull() {
    _addressIndex = null;

    // Billing follows Delivery
    _billingAddressIndex = null;

    sameAsBilling = true;

    notifyListeners();
  }

  // ============================================================
  // CLEAR BILLING ADDRESS
  // ============================================================

  void billingAddressNull() {
    // Never allow Billing to be independent.
    _billingAddressIndex = _addressIndex;

    sameAsBilling = true;

    notifyListeners();
  }

  // ============================================================
  // SELECTED SHIPPING ADDRESS
  // ============================================================

  void setSelectedShippingAddress(int index) {
    _shippingIndex = index;

    notifyListeners();
  }

  // ============================================================
  // SELECTED BILLING ADDRESS
  // ============================================================

  void setSelectedBillingAddress(int index) {
    // Ignore separate billing selection.
    // Billing = Delivery.
    _billingAddressIndex = _addressIndex;

    sameAsBilling = true;

    notifyListeners();
  }

  // ============================================================
  // PAYMENT CHECKBOXES
  // ============================================================

  bool isOfflineChecked = false;

  bool isCODChecked = false;

  bool isWalletChecked = false;

  void setOfflineChecked(
      String type, {
        bool notify = true,
      }) {
    if (type == 'offline') {
      isOfflineChecked = !isOfflineChecked;

      isCODChecked = false;

      isWalletChecked = false;

      _paymentMethodIndex = -1;

      setOfflinePaymentMethodSelectedIndex(0);
    } else if (type == 'cod') {
      isCODChecked = !isCODChecked;

      isOfflineChecked = false;

      isWalletChecked = false;

      _paymentMethodIndex = -1;
    } else if (type == 'wallet') {
      isWalletChecked = !isWalletChecked;

      isOfflineChecked = false;

      isCODChecked = false;

      _paymentMethodIndex = -1;
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // DIGITAL PAYMENT
  // ============================================================

  String selectedDigitalPaymentMethodName = '';

  void setDigitalPaymentMethodName(
      int index,
      String name,
      ) {
    _paymentMethodIndex = index;

    selectedDigitalPaymentMethodName = name;

    isCODChecked = false;

    isWalletChecked = false;

    isOfflineChecked = false;

    notifyListeners();
  }

  // ============================================================
  // DIGITAL ONLY
  // ============================================================

  void digitalOnly(
      bool value, {
        bool isUpdate = false,
      }) {
    _onlyDigital = value;

    if (isUpdate) {
      notifyListeners();
    }
  }

  // ============================================================
  // OFFLINE PAYMENT
  // ============================================================

  OfflinePaymentModel? offlinePaymentModel;

  Future<ApiResponseModel> getOfflinePaymentList() async {
    ApiResponseModel apiResponse =
    await checkoutServiceInterface
        .offlinePaymentList();

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      offlineMethodSelectedIndex = 0;

      offlinePaymentModel =
          OfflinePaymentModel.fromJson(
            apiResponse.response?.data,
          );
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();

    return apiResponse;
  }

  // ============================================================
  // OFFLINE PAYMENT FIELDS
  // ============================================================

  List<TextEditingController>
  inputFieldControllerList = [];

  List<String?> keyList = [];

  int offlineMethodSelectedIndex = -1;

  int offlineMethodSelectedId = 0;

  String offlineMethodSelectedName = '';

  // ============================================================
  // SELECT OFFLINE PAYMENT METHOD
  // ============================================================

  void setOfflinePaymentMethodSelectedIndex(
      int index, {
        bool notify = true,
      }) {
    keyList = [];

    inputFieldControllerList = [];

    offlineMethodSelectedIndex = index;

    if (offlinePaymentModel != null &&
        offlinePaymentModel!.offlineMethods != null &&
        offlinePaymentModel!
            .offlineMethods!
            .isNotEmpty) {
      offlineMethodSelectedId =
      offlinePaymentModel!
          .offlineMethods![
      offlineMethodSelectedIndex]
          .id!;

      offlineMethodSelectedName =
      offlinePaymentModel!
          .offlineMethods![
      offlineMethodSelectedIndex]
          .methodName!;
    }

    if (offlinePaymentModel!.offlineMethods != null &&
        offlinePaymentModel!
            .offlineMethods!
            .isNotEmpty &&
        offlinePaymentModel!
            .offlineMethods![index]
            .methodInformations!
            .isNotEmpty) {
      for (int i = 0;
      i <
          offlinePaymentModel!
              .offlineMethods![index]
              .methodInformations!
              .length;
      i++) {
        inputFieldControllerList.add(
          TextEditingController(),
        );

        keyList.add(
          offlinePaymentModel!
              .offlineMethods![index]
              .methodInformations![i]
              .customerInput,
        );
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // DIGITAL PAYMENT PLACE ORDER
  // ============================================================

  Future<ApiResponseModel> digitalPaymentPlaceOrder({
    String? orderNote,
    String? customerId,
    String? addressId,
    String? billingAddressId,
    String? couponCode,
    String? couponDiscount,
    String? paymentMethod,
  }) async {
    // ============================================================
    // Billing = Delivery
    // ============================================================

    if (addressId != null && addressId.isNotEmpty) {
      billingAddressId = addressId;
    }

    _isLoading = true;

    notifyListeners();

    ApiResponseModel apiResponse =
    await checkoutServiceInterface
        .digitalPaymentPlaceOrder(
      orderNote,
      customerId,
      addressId,
      billingAddressId,
      couponCode,
      couponDiscount,
      paymentMethod,
      _isCheckCreateAccount,
      passwordController.text.trim(),
    );

    if (apiResponse.response != null &&
        apiResponse.response?.statusCode == 200) {
      _addressIndex = null;

      _billingAddressIndex = null;

      // Keep enabled
      sameAsBilling = true;

      _isLoading = false;

      // ✅ Meta Tracking: Initiate Checkout event for digital payment
      MetaTrackingService().logInitiateCheckout(
        value: 0.0, // You might want to calculate the actual total value
        currency: Provider.of<SplashController>(
          Get.context!,
          listen: false,
        ).myCurrency?.code ?? 'SYP',
        numItems: 1, // You might want to calculate the actual number of items
      );

      // ✅ Meta Tracking: Purchase event will be called after payment completion
      // For digital payments, the purchase event should be called after successful payment redirect

      RouterHelper.getDigitalPaymentScreenRoute(
        url: apiResponse.response
            ?.data['redirect_link'] ??
            '',
        fromWallet: false,
        action: RouteAction.pushReplacement,
      );
    } else if (apiResponse.error ==
        'Already registered ') {
      _isLoading = false;

      showCustomSnackBarWidget(
        getTranslated(
          apiResponse.error,
          Get.context!,
        ),
        Get.context!,
        snackBarType:
        SnackBarType.warning,
      );
    } else if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 403) {
      _isLoading = false;

      showCustomSnackBarWidget(
        getTranslated(
          apiResponse.error,
          Get.context!,
        ),
        Get.context!,
        snackBarType:
        SnackBarType.error,
      );
    } else {
      _isLoading = false;

      showCustomSnackBarWidget(
        getTranslated(
          'payment_method_not_properly_configured',
          Get.context!,
        ),
        Get.context!,
        snackBarType:
        SnackBarType.error,
      );
    }

    notifyListeners();

    return apiResponse;
  }

  // ============================================================
  // SAME AS DELIVERY
  // ============================================================

  // IMPORTANT:
  // This is ALWAYS true.
  bool sameAsBilling = true;

  void setSameAsBilling({
    bool isUpdate = true,
  }) {
    // Never toggle.
    // Always enabled.
    sameAsBilling = true;

    // Billing = Delivery
    _billingAddressIndex = _addressIndex;

    if (isUpdate) {
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clearData() {
    orderNoteController.clear();

    passwordController.clear();

    confirmPasswordController.clear();

    _isCheckCreateAccount = false;

    _cashChangesAmount = null;
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  void setIsCheckCreateAccount(
      bool isCheck, {
        bool update = true,
      }) {
    _isCheckCreateAccount = isCheck;

    if (update) {
      notifyListeners();
    }
  }

  // ============================================================
  // CHANGE AMOUNT
  // ============================================================

  void toggleChangeAmountShow() {
    _changeAmountShow = !_changeAmountShow;

    notifyListeners();
  }

  void onChangeCashChangesAmount(
      double? amount,
      ) {
    _cashChangesAmount = amount;
  }

  // ============================================================
  // REFERRAL
  // ============================================================

  Future<ApiResponseModel> getReferralAmount(
      String? amount,
      ) async {
    ApiResponseModel apiResponse =
    await checkoutServiceInterface
        .getReferralAmount(amount);

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _referralAmount =
          ReferralAmount.fromJson(
            apiResponse.response.data,
          );
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();

    return apiResponse;
  }

  // ============================================================
  // TERMS
  // ============================================================

  void toggleTermsCheck({
    bool isUpdate = true,
  }) {
    _isAcceptTerms = !_isAcceptTerms;

    if (isUpdate) {
      notifyListeners();
    }
  }

  // ============================================================
  // PAYMENT SELECTION
  // ============================================================

  void updatePaymentSelection() {
    notifyListeners();
  }
}

// import 'package:syriapharmacy/data/model/api_response.dart';
// import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
// import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
// import 'package:syriapharmacy/features/checkout/domain/services/checkout_service_interface.dart';
// import 'package:syriapharmacy/features/offline_payment/domain/models/offline_payment_model.dart';
// import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
// import 'package:syriapharmacy/helper/api_checker.dart';
// import 'package:syriapharmacy/helper/route_healper.dart';
// import 'package:syriapharmacy/localization/language_constrants.dart';
// import 'package:syriapharmacy/main.dart';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
// import 'package:provider/provider.dart';
//
// class CheckoutController with ChangeNotifier {
//   final CheckoutServiceInterface checkoutServiceInterface;
//   CheckoutController({required this.checkoutServiceInterface});
//
//   int? _addressIndex;
//   int? _billingAddressIndex;
//   int? get billingAddressIndex => _billingAddressIndex;
//   int? _shippingIndex;
//   bool _isLoading = false;
//   bool _isCheckCreateAccount = false;
//   bool _newUser = false;
//
//   int _paymentMethodIndex = -1;
//   bool _onlyDigital = true;
//   bool get onlyDigital => _onlyDigital;
//   int? get addressIndex => _addressIndex;
//   int? get shippingIndex => _shippingIndex;
//   bool get isLoading => _isLoading;
//   int get paymentMethodIndex => _paymentMethodIndex;
//   bool get isCheckCreateAccount => _isCheckCreateAccount;
//
//   bool _changeAmountShow = false;
//   bool get changeAmountShow => _changeAmountShow;
//
//   double? _cashChangesAmount;
//   double? get cashChangesAmount => _cashChangesAmount;
//
//   ReferralAmount? _referralAmount;
//   ReferralAmount? get referralAmount => _referralAmount;
//
//   String selectedPaymentName = '';
//   void setSelectedPayment(String payment) {
//     selectedPaymentName = payment;
//     notifyListeners();
//   }
//
//   bool _isAcceptTerms = false;
//   bool get isAcceptTerms => _isAcceptTerms;
//
//   final TextEditingController orderNoteController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();
//   List<String> inputValueList = [];
//
//   Future<void> placeOrder(
//       {required Function callback,
//       String? addressID,
//       String? couponCode,
//       String? couponAmount,
//       String? billingAddressId,
//       String? orderNote,
//       String? transactionId,
//       String? paymentNote,
//       int? id,
//       String? name,
//       bool isfOffline = false,
//       bool wallet = false}) async {
//     for (TextEditingController textEditingController
//         in inputFieldControllerList) {
//       inputValueList.add(textEditingController.text.trim());
//     }
//
//     _isLoading = true;
//     _newUser = false;
//     notifyListeners();
//     ApiResponseModel apiResponse;
//     isfOffline
//         ? apiResponse = await checkoutServiceInterface.offlinePaymentPlaceOrder(
//             addressID,
//             couponCode,
//             couponAmount,
//             billingAddressId,
//             orderNote,
//             keyList,
//             inputValueList,
//             offlineMethodSelectedId,
//             offlineMethodSelectedName,
//             paymentNote,
//             _isCheckCreateAccount,
//             passwordController.text.trim())
//         : wallet
//             ? apiResponse =
//                 await checkoutServiceInterface.walletPaymentPlaceOrder(
//                     addressID,
//                     couponCode,
//                     couponAmount,
//                     billingAddressId,
//                     orderNote,
//                     _isCheckCreateAccount,
//                     passwordController.text.trim())
//             : apiResponse =
//                 await checkoutServiceInterface.cashOnDeliveryPlaceOrder(
//                 addressID: addressID,
//                 couponCode: couponCode,
//                 couponDiscountAmount: couponAmount,
//                 billingAddressId: billingAddressId,
//                 orderNote: orderNote,
//                 isCheckCreateAccount: _isCheckCreateAccount,
//                 password: passwordController.text.trim(),
//                 cashChangeAmount: _cashChangesAmount,
//                 currentCurrencyCode:
//                     Provider.of<SplashController>(Get.context!, listen: false)
//                         .myCurrency
//                         ?.code,
//               );
//
//     if (apiResponse.response != null &&
//         apiResponse.response!.statusCode == 200) {
//       _isCheckCreateAccount = false;
//       _isLoading = false;
//       _addressIndex = null;
//       _billingAddressIndex = null;
//       sameAsBilling = false;
//       if (!Provider.of<AuthController>(Get.context!, listen: false)
//           .isLoggedIn()) {
//         _newUser = apiResponse.response!.data['new_user'];
//       }
//
//       String message = apiResponse.response!.data.toString();
//       callback(
//           true,
//           message,
//           extractId(apiResponse.response!.data['order_ids'].toString()),
//           _newUser);
//     } else {
//       _isLoading = false;
//       ApiChecker.checkApi(apiResponse);
//     }
//     notifyListeners();
//   }
//
//   String? extractId(String idsString) {
//     String cleaned = idsString.replaceAll(RegExp(r'[\[\]\s]'), '');
//     return cleaned.isNotEmpty ? cleaned : null;
//   }
//
//   String? getFirstOrderId(String idsString) {
//     if (idsString.trim().isEmpty) return null;
//
//     List<String> ids = idsString.split(',').map((e) => e.trim()).toList();
//
//     return ids.isNotEmpty ? ids.first : null;
//   }
//
//   void setAddressIndex(int index) {
//     _addressIndex = index;
//     notifyListeners();
//   }
//
//   void setBillingAddressIndex(int index) {
//     _billingAddressIndex = index;
//     notifyListeners();
//   }
//
//   void resetPaymentMethod() {
//     _paymentMethodIndex = -1;
//     isCODChecked = false;
//     isWalletChecked = false;
//     isOfflineChecked = false;
//   }
//
//   void shippingAddressNull() {
//     _addressIndex = null;
//     notifyListeners();
//   }
//
//   void billingAddressNull() {
//     _billingAddressIndex = null;
//     notifyListeners();
//   }
//
//   void setSelectedShippingAddress(int index) {
//     _shippingIndex = index;
//     notifyListeners();
//   }
//
//   void setSelectedBillingAddress(int index) {
//     _billingAddressIndex = index;
//     notifyListeners();
//   }
//
//   bool isOfflineChecked = false;
//   bool isCODChecked = false;
//   bool isWalletChecked = false;
//
//   void setOfflineChecked(String type, {bool notify = true}) {
//     if (type == 'offline') {
//       isOfflineChecked = !isOfflineChecked;
//       isCODChecked = false;
//       isWalletChecked = false;
//       _paymentMethodIndex = -1;
//       setOfflinePaymentMethodSelectedIndex(0);
//     } else if (type == 'cod') {
//       isCODChecked = !isCODChecked;
//       isOfflineChecked = false;
//       isWalletChecked = false;
//       _paymentMethodIndex = -1;
//     } else if (type == 'wallet') {
//       isWalletChecked = !isWalletChecked;
//       isOfflineChecked = false;
//       isCODChecked = false;
//       _paymentMethodIndex = -1;
//     }
//
//     if (notify) {
//       notifyListeners();
//     }
//   }
//
//   String selectedDigitalPaymentMethodName = '';
//
//   void setDigitalPaymentMethodName(int index, String name) {
//     _paymentMethodIndex = index;
//     selectedDigitalPaymentMethodName = name;
//     isCODChecked = false;
//     isWalletChecked = false;
//     isOfflineChecked = false;
//     notifyListeners();
//   }
//
//   void digitalOnly(bool value, {bool isUpdate = false}) {
//     _onlyDigital = value;
//     if (isUpdate) {
//       notifyListeners();
//     }
//   }
//
//   OfflinePaymentModel? offlinePaymentModel;
//   Future<ApiResponseModel> getOfflinePaymentList() async {
//     ApiResponseModel apiResponse =
//         await checkoutServiceInterface.offlinePaymentList();
//     if (apiResponse.response != null &&
//         apiResponse.response!.statusCode == 200) {
//       offlineMethodSelectedIndex = 0;
//       offlinePaymentModel =
//           OfflinePaymentModel.fromJson(apiResponse.response?.data);
//     } else {
//       ApiChecker.checkApi(apiResponse);
//     }
//     notifyListeners();
//     return apiResponse;
//   }
//
//   List<TextEditingController> inputFieldControllerList = [];
//   List<String?> keyList = [];
//   int offlineMethodSelectedIndex = -1;
//   int offlineMethodSelectedId = 0;
//   String offlineMethodSelectedName = '';
//
//   void setOfflinePaymentMethodSelectedIndex(int index, {bool notify = true}) {
//     keyList = [];
//     inputFieldControllerList = [];
//     offlineMethodSelectedIndex = index;
//     if (offlinePaymentModel != null &&
//         offlinePaymentModel!.offlineMethods != null &&
//         offlinePaymentModel!.offlineMethods!.isNotEmpty) {
//       offlineMethodSelectedId =
//           offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].id!;
//       offlineMethodSelectedName = offlinePaymentModel!
//           .offlineMethods![offlineMethodSelectedIndex].methodName!;
//     }
//
//     if (offlinePaymentModel!.offlineMethods != null &&
//         offlinePaymentModel!.offlineMethods!.isNotEmpty &&
//         offlinePaymentModel!
//             .offlineMethods![index].methodInformations!.isNotEmpty) {
//       for (int i = 0;
//           i <
//               offlinePaymentModel!
//                   .offlineMethods![index].methodInformations!.length;
//           i++) {
//         inputFieldControllerList.add(TextEditingController());
//         keyList.add(offlinePaymentModel!
//             .offlineMethods![index].methodInformations![i].customerInput);
//       }
//     }
//     if (notify) {
//       notifyListeners();
//     }
//   }
//
//   Future<ApiResponseModel> digitalPaymentPlaceOrder(
//       {String? orderNote,
//       String? customerId,
//       String? addressId,
//       String? billingAddressId,
//       String? couponCode,
//       String? couponDiscount,
//       String? paymentMethod}) async {
//     _isLoading = true;
//     notifyListeners();
//
//     ApiResponseModel apiResponse =
//         await checkoutServiceInterface.digitalPaymentPlaceOrder(
//             orderNote,
//             customerId,
//             addressId,
//             billingAddressId,
//             couponCode,
//             couponDiscount,
//             paymentMethod,
//             _isCheckCreateAccount,
//             passwordController.text.trim());
//
//     if (apiResponse.response != null &&
//         apiResponse.response?.statusCode == 200) {
//       _addressIndex = null;
//       _billingAddressIndex = null;
//       sameAsBilling = false;
//       _isLoading = false;
//
//       RouterHelper.getDigitalPaymentScreenRoute(
//         url: apiResponse.response?.data['redirect_link'] ?? '',
//         fromWallet: false,
//         action: RouteAction.pushReplacement,
//       );
//     } else if (apiResponse.error == 'Already registered ') {
//       _isLoading = false;
//       showCustomSnackBarWidget(
//           getTranslated(apiResponse.error, Get.context!), Get.context!,
//           snackBarType: SnackBarType.warning);
//     } else if (apiResponse.response != null &&
//         apiResponse.response!.statusCode == 403) {
//       _isLoading = false;
//       showCustomSnackBarWidget(
//           getTranslated(apiResponse.error, Get.context!), Get.context!,
//           snackBarType: SnackBarType.error);
//     } else {
//       _isLoading = false;
//       showCustomSnackBarWidget(
//           getTranslated('payment_method_not_properly_configured', Get.context!),
//           Get.context!,
//           snackBarType: SnackBarType.error);
//     }
//     notifyListeners();
//     return apiResponse;
//   }
//
//   bool sameAsBilling = false;
//   void setSameAsBilling({bool isUpdate = true}) {
//     sameAsBilling = !sameAsBilling;
//     if (isUpdate) {
//       notifyListeners();
//     }
//   }
//
//   void clearData() {
//     orderNoteController.clear();
//     passwordController.clear();
//     confirmPasswordController.clear();
//     _isCheckCreateAccount = false;
//     _cashChangesAmount = null;
//   }
//
//   void setIsCheckCreateAccount(bool isCheck, {bool update = true}) {
//     _isCheckCreateAccount = isCheck;
//     if (update) {
//       notifyListeners();
//     }
//   }
//
//   void toggleChangeAmountShow() {
//     _changeAmountShow = !_changeAmountShow;
//     notifyListeners();
//   }
//
//   void onChangeCashChangesAmount(double? amount) => _cashChangesAmount = amount;
//
//   Future<ApiResponseModel> getReferralAmount(String? amount) async {
//     ApiResponseModel apiResponse =
//         await checkoutServiceInterface.getReferralAmount(amount);
//     if (apiResponse.response != null &&
//         apiResponse.response!.statusCode == 200) {
//       _referralAmount = ReferralAmount.fromJson(apiResponse.response.data);
//     } else {
//       ApiChecker.checkApi(apiResponse);
//     }
//     notifyListeners();
//     return apiResponse;
//   }
//
//   void toggleTermsCheck({bool isUpdate = true}) {
//     _isAcceptTerms = !_isAcceptTerms;
//     if (isUpdate) {
//       notifyListeners();
//     }
//   }
//
//   void updatePaymentSelection() {
//     notifyListeners();
//   }
// }