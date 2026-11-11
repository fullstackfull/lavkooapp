import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

import '../data/datasource/remote/dio/dio_client.dart';

/// خدمة تتبع الأحداث لـ Meta (Facebook) App Events
class MetaTrackingService {
  static final MetaTrackingService _instance = MetaTrackingService._internal();
  factory MetaTrackingService() => _instance;
  MetaTrackingService._internal();
  static const bool enabled = false;

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  DioClient? _dioClient;
  ConfigModel? _configModel;
  bool _initialized = false;

  /// هل التتبع مفعّل لهذا الجهاز؟
  bool get isTrackingEnabled {
    if (!enabled) return false;
    if (_configModel?.metaAppTracking == null) return true;

    if (Platform.isAndroid) {
      return _configModel!.metaAppTracking!.android?.enabled ?? true;
    } else if (Platform.isIOS) {
      return _configModel!.metaAppTracking!.ios?.enabled ?? true;
    }
    return true;
  }

  /// هل الحدث مفعّل؟
  bool _isEventEnabled(String eventName) {
    if (!isTrackingEnabled) return false;
    if (_configModel?.metaAppTracking == null) return true;

    MetaAppTrackingEvents? events;
    if (Platform.isAndroid) {
      events = _configModel!.metaAppTracking!.android?.events;
    } else if (Platform.isIOS) {
      events = _configModel!.metaAppTracking!.ios?.events;
    }

    if (events == null) return true;

    switch (eventName) {
      case 'app_open':
        return events.appOpen ?? true;
      case 'complete_registration':
        return events.completeRegistration ?? true;
      case 'search':
        return events.search ?? true;
      case 'view_content':
        return events.viewContent ?? true;
      case 'add_to_cart':
        return events.addToCart ?? true;
      case 'initiate_checkout':
        return events.initiateCheckout ?? true;
      case 'purchase':
        return events.purchase ?? true;
      default:
        return true;
    }
  }

  /// التهيئة الأولى للخدمة
  Future<void> initialize({DioClient? dioClient}) async {
    if (_initialized) return;

    _dioClient = dioClient;

    try {
      // طباعة معلومات Facebook App ID من Android Manifest
      debugPrint('🔍 Facebook App Events initialized');
      debugPrint('📱 Platform: ${Platform.operatingSystem}');
      debugPrint('📱 Package Name: ${Platform.isAndroid ? "Android" : "iOS"}');

      // Facebook App ID يتم قراءته تلقائياً من strings.xml في Android
      // القيمة الموجودة في strings.xml هي: 906564681991933
      debugPrint('📱 Facebook App ID from strings.xml: 906564681991933');

      // تسجيل حدث فتح التطبيق إذا كان مفعّلاً
      if (_isEventEnabled('app_open')) {
        await _facebookAppEvents.logEvent(
          name: 'fb_mobile_activate_app',
        );
      }

      _initialized = true;
      debugPrint('✅ MetaTrackingService initialized successfully');
    } catch (e) {
      debugPrint('⚠️ MetaTrackingService init error: $e');
    }
  }

  /// تحديث الإعدادات من الـ Backend
  void updateConfig(ConfigModel? config) {
    _configModel = config;
    debugPrint('🔄 MetaTrackingService config updated');
    debugPrint('   Tracking Enabled: $isTrackingEnabled');

    // The resolved Meta identifiers are not logged: the client token is a credential, and the rest
    // only ever accompanied it. Whether tracking is on is logged above, which is the useful part.
  }

  /// إرسال حدث إلى الـ Backend API
  Future<void> _sendToBackend({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_dioClient == null) return;

    try {
      // ✅ استخدم post() بدل postData()
      await _dioClient!.post(
        AppConstants.analyticsEventsUri,
        data: {
          'event_name': eventName,
          'platform': Platform.operatingSystem,
          'timestamp': DateTime.now().toIso8601String(),
          'parameters': parameters ?? {},
        },
      );
    } catch (e) {
      debugPrint('⚠️ Backend analytics error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة عامة لتسجيل أي حدث (للملفات الأخرى مثل ReOrderController)
  // ═══════════════════════════════════════════════════════════════

  /// تسجيل أي حدث مخصص (Generic Event)
  Future<void> logEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!isTrackingEnabled) return;

    try {
      await _facebookAppEvents.logEvent(
        name: eventName,
        parameters: parameters,
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: eventName,
        parameters: parameters,
      );

      debugPrint('📊 Meta Event: $eventName');
    } catch (e) {
      debugPrint('⚠️ Meta logEvent error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // الأحداث القياسية
  // ═══════════════════════════════════════════════════════════════

  /// تسجيل دخول المستخدم
  Future<void> logLogin({required String loginMethod}) async {
    if (!isTrackingEnabled) return;

    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_login',
        parameters: {
          'fb_login_method': loginMethod,
        },
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'login',
        parameters: {'login_method': loginMethod},
      );

      debugPrint('📊 Meta Event: Login ($loginMethod)');
    } catch (e) {
      debugPrint('⚠️ Meta login error: $e');
    }
  }

  /// إكمال التسجيل
  Future<void> logCompleteRegistration({required String registrationMethod}) async {
    if (!_isEventEnabled('complete_registration')) return;

    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_complete_registration',
        parameters: {
          'fb_registration_method': registrationMethod,
        },
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'complete_registration',
        parameters: {'registration_method': registrationMethod},
      );

      debugPrint('📊 Meta Event: Complete Registration ($registrationMethod)');
    } catch (e) {
      debugPrint('⚠️ Meta registration error: $e');
    }
  }

  /// البحث
  Future<void> logSearch({required String searchString}) async {
    if (!_isEventEnabled('search')) return;

    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_search',
        parameters: {
          'fb_search_string': searchString,
        },
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'search',
        parameters: {'search_string': searchString},
      );

      debugPrint('📊 Meta Event: Search ($searchString)');
    } catch (e) {
      debugPrint('⚠️ Meta search error: $e');
    }
  }

  /// عرض محتوى (منتج)
  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    required String contentName,
    required double price,
    required String currency,
  }) async {
    if (!_isEventEnabled('view_content')) return;

    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_content_view',
        parameters: {
          'fb_content_id': contentId,
          'fb_content_type': contentType,
          'fb_content_name': contentName,
          'fb_currency': currency,
          'value': price,
        },
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'view_content',
        parameters: {
          'content_id': contentId,
          'content_type': contentType,
          'content_name': contentName,
          'price': price,
          'currency': currency,
        },
      );

      debugPrint('📊 Meta Event: View Content ($contentName)');
    } catch (e) {
      debugPrint('⚠️ Meta view content error: $e');
    }
  }

  /// إضافة إلى السلة
  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    required String currency,
    int quantity = 1,
  }) async {
    if (!_isEventEnabled('add_to_cart')) return;

    try {
      // استخدام الطريقة المطلوبة من الـ Backend
      await _facebookAppEvents.logAddToCart(
        id: productId,
        type: 'product',
        currency: currency,
        price: price,
      );

      // Force flush لإرسال البيانات فوراً
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'add_to_cart',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
          'currency': currency,
          'quantity': quantity,
        },
      );

      debugPrint('📊 Meta Event: Add to Cart ($productName)');
    } catch (e) {
      debugPrint('⚠️ Meta add to cart error: $e');
    }
  }

  /// بدء الدفع (Checkout)
  Future<void> logInitiateCheckout({
    required double value,
    required String currency,
    required int numItems,
  }) async {
    if (!_isEventEnabled('initiate_checkout')) return;

    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_initiated_checkout',
        parameters: {
          'fb_num_items': numItems,
          'fb_currency': currency,
          'value': value,
        },
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'initiate_checkout',
        parameters: {
          'value': value,
          'currency': currency,
          'num_items': numItems,
        },
      );

      debugPrint('📊 Meta Event: Initiate Checkout ($value $currency)');
    } catch (e) {
      debugPrint('⚠️ Meta initiate checkout error: $e');
    }
  }

  /// شراء
  Future<void> logPurchase({
    required String orderId,
    required double amount,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!_isEventEnabled('purchase')) return;

    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          'order_id': orderId,
          'num_items': items.length,
        },
      );
      await _facebookAppEvents.flush();

      await _sendToBackend(
        eventName: 'purchase',
        parameters: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'items': items,
        },
      );

      if (kDebugMode) debugPrint('📊 Meta Event: Purchase recorded');
    } catch (e) {
      debugPrint('⚠️ Meta purchase error: $e');
    }
  }
}