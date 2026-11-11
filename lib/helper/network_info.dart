import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:provider/provider.dart';

class NetworkInfo {
  final Connectivity connectivity;
  NetworkInfo(this.connectivity);

  Future<bool> get isConnected async {
    List<ConnectivityResult> result = await connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile);
  }

  static void checkConnectivity(BuildContext context) {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (Provider.of<SplashController>(Get.context!, listen: false)
          .firstTimeConnectionCheck) {
        Provider.of<SplashController>(Get.context!, listen: false)
            .setFirstTimeConnectionCheck(false);
      } else {
        bool isConnected = result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile);

        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

        final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

        final bgColor = isConnected
            ? (isDark ? const Color(0xFF1B3D2B) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF4A1A1A) : const Color(0xFFFFEBEE));

        final borderColor = isConnected
            ? (isDark
                ? const Color(0xFF2E7D32).withOpacity(0.4)
                : const Color(0xFF81C784).withOpacity(0.5))
            : (isDark
                ? const Color(0xFFC62828).withOpacity(0.4)
                : const Color(0xFFE57373).withOpacity(0.5));

        final textColor = isConnected
            ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
            : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828));

        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isConnected
                          ? getTranslated('connected', Get.context!)!
                          : getTranslated('no_connection', Get.context!)!,
                      style: TextStyle(
                        fontFamily: 'SF-Pro-Rounded-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    });
  }
}
