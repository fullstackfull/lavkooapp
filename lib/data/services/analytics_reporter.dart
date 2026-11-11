import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/di_container.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// The app's half of the shop's analytics.
///
/// The server records everything it can see for itself, and in the app that is much less than on
/// the web: a shopper who taps a banner and lands on a product screen makes one call for that
/// product and none that says a banner sent them there. So the merchant comparing two banners had
/// numbers for the web half of their audience and nothing for the half on a phone.
///
/// Deliberately small. It reports a name and an id — never a price, never who the shopper is — and
/// the shop refuses anything else anyway. Every path swallows its own failures: measuring a tap
/// must never be the reason the tap does not open.
class AnalyticsReporter {
  const AnalyticsReporter._();

  /// Events waiting to travel together.
  ///
  /// Impressions arrive in bursts — a shopper scrolls and five sections come into view within a
  /// second — and five requests to say so would cost more than the measurement is worth on a phone
  /// connection. A tap is different and leaves immediately: it precedes navigation.
  static final List<Map<String, dynamic>> _queue = [];
  static Timer? _timer;

  /// Section entities already reported this session, so scrolling back up counts nothing.
  static final Set<String> _seenSections = {};

  /// A banner was taken. [bannerId] is the row in Banner Setup, which is what the merchant's
  /// report is keyed on; a card typed straight into the theme builder has no such row and is not
  /// reported rather than being counted against a banner it did not come from.
  static void bannerClicked(int? bannerId) {
    if (bannerId == null || bannerId <= 0) return;

    _queue.add({'name': 'banner_clicked', 'entity_type': 'banner', 'entity_id': '$bannerId'});
    _flush();
  }

  /// A composed section reached the shopper's screen.
  ///
  /// The merchant's real question about an arrangement is how far down it anyone gets, and only
  /// the client that drew the page can answer it. Reported once per section per session: a shopper
  /// scrolling up and back down has not seen it twice, and the shop's own few-second window is
  /// what catches an accidental repeat.
  static void sectionViewed(int? sectionId, {String? experiment}) =>
      sectionSeen(sectionId != null && sectionId > 0 ? '$sectionId' : null, experiment: experiment);

  /// Same report, string identity: stored sections report their row id, campaign overlay
  /// sections report `campaign-{id}` — the shape the shop's ingest names as the one non-numeric
  /// identity it accepts. Without this, campaign reach counted web shoppers only.
  static void sectionSeen(String? entityId, {String? experiment}) {
    if (entityId == null || entityId.isEmpty) return;
    if (!_seenSections.add(entityId)) return;

    _queue.add({
      'name': 'section_viewed',
      'entity_type': 'theme_section',
      'entity_id': entityId,
      // The variant this impression was OF, when the section is one — half the audience is on a
      // phone, and an experiment measured only on the web is measured on somebody else's shop.
      if (experiment != null && experiment.isNotEmpty)
        'properties': {'experiment': experiment},
    });

    if (_queue.length >= 20) {
      _flush();
      return;
    }

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), _flush);
  }

  /// Forget what this session has seen — a new published theme is a new arrangement.
  static void resetSectionViews() => _seenSections.clear();

  static void _flush() {
    _timer?.cancel();
    _timer = null;

    if (_queue.isEmpty) return;

    final events = List<Map<String, dynamic>>.of(_queue);
    _queue.clear();

    _send(events);
  }

  static Future<void> _send(List<Map<String, dynamic>> events) async {
    try {
      await sl<DioClient>().post(AppConstants.analyticsEventsUri, data: {'events': events});
    } catch (error) {
      if (kDebugMode) debugPrint('[analytics] ${events.length} event(s) not reported: $error');
    }
  }
}
