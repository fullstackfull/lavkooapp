import 'package:syriapharmacy/features/marketing_consent/marketing_consent.dart';

/// One answer a person gave about marketing, in the shape the backend's `customer_marketing_consents` row holds it.
///
/// It is a DECISION and not a current state: granting is one of these, withdrawing is another, and the answer in force is the newest one
/// for the same market, channel and purpose. The keys of [toJson] are the backend's own column names, so what this app captures is
/// already what the backend records.
class MarketingConsentDecision {
  const MarketingConsentDecision({
    required this.market,
    required this.channel,
    required this.purpose,
    required this.decision,
    required this.answeredAt,
    this.source = MarketingConsent.sourceAccountPage,
    this.textVersion,
  });

  /// The market the answer was given for: an upper-case ISO code, as the backend's `market` column holds it. On a storefront this app
  /// does not know it is still whatever two-letter code the storefront carries, because the storefront list comes from the server.
  final String market;

  final String channel;
  final String purpose;

  /// [MarketingConsent.decisionGranted] or [MarketingConsent.decisionWithdrawn].
  final String decision;

  /// When the person answered, in UTC, so the record does not move with the device's zone.
  final DateTime answeredAt;

  final String source;

  /// The version of the text the person was shown, when the shop publishes one. The backend's column is nullable and nothing fills it on
  /// the app side yet: the consent texts per country are an open owner decision (tracker A2-13), so a version is never invented here.
  final String? textVersion;

  bool get isGranted => decision == MarketingConsent.decisionGranted;

  /// What the backend files one answer under, and what the newest answer is looked up by.
  String get key => '$market|$channel|$purpose';

  Map<String, Object?> toJson() => <String, Object?>{
        'market': market,
        'channel': channel,
        'purpose': purpose,
        'decision': decision,
        'source': source,
        'recorded_at': answeredAt.toUtc().toIso8601String(),
        if (textVersion != null) 'text_version': textVersion,
      };

  /// Null when the stored entry cannot be read: it is not an object, or its market, channel, purpose, decision or time is missing or is
  /// not one of the names this app and the backend share. A decision that cannot be read is not a decision, and an unreadable store must
  /// never look like a grant.
  static MarketingConsentDecision? tryParse(Object? entry) {
    if (entry is! Map) {
      return null;
    }

    final String market = MarketingConsent.market(_text(entry['market']) ?? '');
    final String? channel = _text(entry['channel']);
    final String? purpose = _text(entry['purpose']);
    final String? decision = _text(entry['decision']);
    final DateTime? answeredAt =
        DateTime.tryParse(_text(entry['recorded_at']) ?? '');

    if (market.length != 2 ||
        channel == null ||
        !MarketingConsent.isChannel(channel) ||
        purpose == null ||
        !MarketingConsent.isPurpose(purpose) ||
        answeredAt == null ||
        (decision != MarketingConsent.decisionGranted &&
            decision != MarketingConsent.decisionWithdrawn)) {
      return null;
    }

    return MarketingConsentDecision(
      market: market,
      channel: channel,
      purpose: purpose,
      decision: decision!,
      answeredAt: answeredAt.toUtc(),
      source: _text(entry['source']) ?? MarketingConsent.sourceAccountPage,
      textVersion: _text(entry['text_version']),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) {
      return null;
    }

    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }
}
