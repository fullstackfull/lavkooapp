import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// مساعد للحصول على إذن التتبع على iOS 14.5+
///
/// iOS 14.5+ يتطلب إذن صريح من المستخدم لتتبع النشاط عبر التطبيقات.
/// هذا الإذن ضروري لـ Meta App Events ليعمل بكفاءة.
class TrackingPermissionHelper {

  /// طلب إذن التتبع
  static Future<TrackingStatus> requestTrackingPermission() async {
    try {
      // التحقق من الحالة الحالية
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;

      if (kDebugMode) {
        print('[TRACKING_PERMISSION] Current status: $status');
      }

      TrackingStatus finalStatus = status;
      if (status == TrackingStatus.notDetermined) {
        // طلب الإذن
        finalStatus = await AppTrackingTransparency.requestTrackingAuthorization();

        if (kDebugMode) {
          print('[TRACKING_PERMISSION] New status: $finalStatus');
        }
      }

      // تفعيل تتبع الإعلانات لميتا إذا وافق المستخدم (iOS 14.5+)
      if (finalStatus == TrackingStatus.authorized) {
        await FacebookAppEvents().setAdvertiserTracking(enabled: true);
        if (kDebugMode) {
          print('[TRACKING_PERMISSION] Meta AdvertiserTrackingEnabled: true');
        }
      } else {
        await FacebookAppEvents().setAdvertiserTracking(enabled: false);
      }

      return finalStatus;
    } catch (e) {
      if (kDebugMode) {
        print('[TRACKING_PERMISSION] Error: $e');
      }
      return TrackingStatus.notDetermined;
    }
  }

  /// الحصول على معرّف الإعلان (IDFA على iOS، GAID على Android)
  static Future<String?> getAdvertisingId() async {
    try {
      final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
      if (kDebugMode) {
        print('[TRACKING_PERMISSION] Advertising ID: $uuid');
      }
      return uuid;
    } catch (e) {
      if (kDebugMode) {
        print('[TRACKING_PERMISSION] Failed to get ID: $e');
      }
      return null;
    }
  }

  /// التحقق مما إذا كان التتبع مسموحًا
  static Future<bool> isTrackingAllowed() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    return status == TrackingStatus.authorized;
  }
}