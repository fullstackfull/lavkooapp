import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/di_container.dart';
import 'package:syriapharmacy/features/checkout/domain/models/myfatoorah_payment_status.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Asks the server what happened to a MyFatoorah payment.
///
/// The app cannot decide this for itself. A 3-D Secure step, a wallet hand-off to the STC Pay or Apple
/// Pay app, or simply a slow bank all mean the answer is not ready when the customer arrives back, and
/// the server may only have learnt it from a webhook that landed a second later. So the app polls, and
/// the three outcomes it must keep apart are paid, definitely-failed, and not-known-yet.
///
/// The third is the one that matters. Showing "payment failed" to someone whose money has left their
/// account is the worst thing this screen can do, so a timeout, an offline phone and a `pending` answer
/// are all treated the same way: keep asking, and if time runs out, say it is being confirmed.
class MyFatoorahPaymentService {
  MyFatoorahPaymentService({DioClient? dioClient}) : _dioClient = dioClient ?? sl<DioClient>();

  final DioClient _dioClient;

  /// Gateway keys that route through MyFatoorah. `fatoorah` is the key the backend has always used;
  /// the others are accepted so a title or key change on the server cannot silently strand the app.
  static const Set<String> gatewayKeys = <String>{'fatoorah', 'my_fatoorah', 'myfatoorah'};

  static bool isMyFatoorah(String? paymentMethodKey) {
    if (paymentMethodKey == null) return false;
    return gatewayKeys.contains(paymentMethodKey.trim().toLowerCase());
  }

  /// Pull our payment reference out of a URL the WebView is navigating to.
  ///
  /// The server puts it on the callback it gives MyFatoorah, so the moment the customer is sent back
  /// the app has everything it needs to ask the server directly — and never has to interpret whatever
  /// the final redirect happens to say.
  static String? referenceFromUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);
      if (!_isOurCallback(uri)) return null;

      final String? reference = uri.queryParameters['reference'];
      return (reference != null && reference.trim().isNotEmpty) ? reference.trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// Is this URL one of our MyFatoorah return points?
  ///
  /// The host is checked as well as the path: a payment page is free to contain a link with any path it
  /// likes, and matching on the path alone would let the gateway's own content end a payment early.
  static bool _isOurCallback(Uri uri) {
    final Uri base = Uri.parse(AppConstants.baseUrl);
    if (uri.host.isNotEmpty && uri.host != base.host) return false;

    final String path = uri.path.toLowerCase();
    return path.contains('/payment/myfatoorah/callback') ||
        path.contains('/payment/fatoorah/callback') ||
        path.contains('/payment/myfatoorah/pending') ||
        path.contains('/payment/fatoorah/pending');
  }

  /// True when the WebView should stop and hand over to polling.
  static bool isReturnUrl(String url) => referenceFromUrl(url) != null;

  /// One status read. Never throws: an unreadable answer is "not known yet", not a failure.
  Future<MyFatoorahPaymentStatus> fetchStatus(String reference) async {
    try {
      final Response response = await _dioClient.get(
        AppConstants.myFatoorahStatusUri,
        queryParameters: <String, dynamic>{
          'reference': reference,
          // The Dio client caches some GETs by path+query. This endpoint is not on that list, but a
          // changing parameter guarantees a fresh read even if the list grows later — a cached
          // "pending" would make the screen hang forever on a payment that has since completed.
          '_': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return MyFatoorahPaymentStatus.fromJson(Map<String, dynamic>.from(response.data as Map));
      }

      return MyFatoorahPaymentStatus.unresolved(reference);
    } catch (e) {
      // Offline, timed out, or the server is unhappy. Not evidence of anything about the money.
      if (kDebugMode) debugPrint('MyFatoorah status read failed: $e');
      return MyFatoorahPaymentStatus.unresolved(reference);
    }
  }

  /// Ask repeatedly until the answer is final or we run out of time.
  ///
  /// Backs off: the first answers come quickly because most payments resolve in a second or two, and
  /// the gaps widen so a slow bank does not turn into a tight loop against our own server.
  ///
  /// Returning a non-final status is a normal outcome, not an error. The caller shows "we are
  /// confirming your payment" and the server finishes the job through the webhook or the reconciliation
  /// sweep — the customer's order is not waiting on this screen staying open.
  Future<MyFatoorahPaymentStatus> pollUntilResolved(
    String reference, {
    Duration timeout = const Duration(seconds: 75),
    void Function(MyFatoorahPaymentStatus status)? onUpdate,
  }) async {
    final DateTime deadline = DateTime.now().add(timeout);
    const List<int> waits = <int>[1, 2, 3, 4, 5, 6, 8, 10, 12, 15];

    MyFatoorahPaymentStatus latest = MyFatoorahPaymentStatus.unresolved(reference);
    int attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      latest = await fetchStatus(reference);
      onUpdate?.call(latest);

      if (latest.isFinal) return latest;

      final int waitSeconds = waits[attempt < waits.length ? attempt : waits.length - 1];
      attempt++;

      final Duration remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;

      await Future<void>.delayed(
        remaining < Duration(seconds: waitSeconds) ? remaining : Duration(seconds: waitSeconds),
      );
    }

    return latest;
  }
}
