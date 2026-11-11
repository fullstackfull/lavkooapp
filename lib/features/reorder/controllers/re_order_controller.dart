// import 'package:syriapharmacy/data/model/api_response.dart';
// import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
// import 'package:syriapharmacy/features/reorder/domain/services/re_order_service_interface.dart';
// import 'package:syriapharmacy/helper/api_checker.dart';
// import 'package:syriapharmacy/helper/route_healper.dart';
// import 'package:syriapharmacy/main.dart';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
// import 'package:provider/provider.dart';
//
// class ReOrderController with ChangeNotifier {
//   final ReOrderServiceInterface reOrderServiceInterface;
//   ReOrderController({required this.reOrderServiceInterface});
//
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;
//
//   Future<ApiResponseModel> reorder({String? orderId}) async {
//     _isLoading = true;
//     notifyListeners();
//     ApiResponseModel apiResponse =
//         await reOrderServiceInterface.reorder(orderId!);
//     if (apiResponse.response != null &&
//         apiResponse.response!.statusCode == 200) {
//       Provider.of<CartController>(Get.context!, listen: false)
//           .setIsCartLoading();
//       showCustomSnackBarWidget(
//           apiResponse.response?.data['message'], Get.context!,
//           snackBarType: SnackBarType.success);
//       RouterHelper.getCartScreenRoute(action: RouteAction.push);
//     } else {
//       ApiChecker.checkApi(apiResponse);
//     }
//     _isLoading = false;
//     notifyListeners();
//     return apiResponse;
//   }
// }

import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/reorder/domain/services/re_order_service_interface.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/services/meta_tracking_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class ReOrderController with ChangeNotifier {
  final ReOrderServiceInterface reOrderServiceInterface;
  ReOrderController({required this.reOrderServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<ApiResponseModel> reorder({String? orderId}) async {
    _isLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
    await reOrderServiceInterface.reorder(orderId!);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Provider.of<CartController>(Get.context!, listen: false)
          .setIsCartLoading();
      showCustomSnackBarWidget(
          apiResponse.response?.data['message'], Get.context!,
          snackBarType: SnackBarType.success);

      // ✅ Meta Tracking: Re-order event
      MetaTrackingService().logEvent(
        eventName: 'Purchase',
        parameters: {
          'order_id': orderId,
          'type': 'reorder',
        },
      );

      RouterHelper.getCartScreenRoute(action: RouteAction.push);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    _isLoading = false;
    notifyListeners();
    return apiResponse;
  }
}