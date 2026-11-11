import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// The app's side of the Monitoring panel's crash-free rate.
///
/// A crash produces no request — the server cannot tell it from a quiet evening — so the app
/// reports the one thing only it knows: that it launched, and whether the previous run died.
/// Counters only, exactly what the endpoint accepts: no stack traces, no device ids, no user ids
/// ever leave the phone.
///
/// The mechanics are deliberately dumb. An uncaught error increments a persisted counter (writing
/// a network call from inside a dying process is how a crash reporter causes a second crash); the
/// NEXT launch sends `{sessions: 1, crashes: N}` and clears the counter only after the server's
/// 204. Every path swallows its own failures — monitoring must never be the reason the app
/// misbehaves.
class AppHealthReporter {
  const AppHealthReporter._();

  /// A ceiling on the pending counter: one broken run can throw thousands of errors, and "it
  /// crashed a lot" is fully said by a small number.
  static const int _maxPending = 50;

  /// Install the uncaught-error hook. Call once, before runApp.
  ///
  /// Only [PlatformDispatcher.onError] — genuinely uncaught errors, the ones that end a session.
  /// [FlutterError.onError] stays untouched: a render overflow is a layout bug, not a crash, and
  /// counting it would drown the number this exists to report.
  static void install() {
    final previous = PlatformDispatcher.instance.onError;

    PlatformDispatcher.instance.onError = (error, stack) {
      _recordCrash();
      return previous?.call(error, stack) ?? false;
    };
  }

  /// Report one launch, plus whatever the previous run left behind. Fire-and-forget.
  static Future<void> reportLaunch(DioClient dioClient) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final pendingCrashes =
          preferences.getInt(AppConstants.pendingCrashCount) ?? 0;

      final response = await dioClient.post(AppConstants.appHealthUri, data: {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': AppConstants.appVersion,
        'sessions': 1,
        'crashes': pendingCrashes,
        'anrs': 0,
      });

      // Cleared only after the 204: a report that never arrived stays owed, not forgotten.
      if (pendingCrashes > 0 && (response.statusCode ?? 0) < 400) {
        await preferences.remove(AppConstants.pendingCrashCount);
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[health] launch report failed: $error');
    }
  }

  static Future<void> _recordCrash() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final pending = preferences.getInt(AppConstants.pendingCrashCount) ?? 0;
      if (pending >= _maxPending) return;
      await preferences.setInt(AppConstants.pendingCrashCount, pending + 1);
    } catch (_) {}
  }
}
