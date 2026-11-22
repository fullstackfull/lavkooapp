import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_decision.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// What this device has recorded about marketing, per market, channel and purpose, append-only, the way the backend's table is.
///
/// Nothing is edited and nothing is deleted: a person who changes their mind adds another decision, and [allows] answers by the newest
/// one for that key. The history is kept because a consent record is the evidence that a person agreed, and an overwritten record is no
/// evidence at all.
///
/// A person who has answered nothing is NOT consenting: [allows] falls back to [MarketingConsent.optIn], which is false. That is the
/// strictest of the two policies the backend can be configured with, and it is what keeps a device off a marketing topic it was never
/// given permission for.
class MarketingConsentStore {
  const MarketingConsentStore(this._preferences);

  final SharedPreferences _preferences;

  /// Every decision this device has recorded, oldest first. Entries that cannot be read are left out rather than guessed at, so a store
  /// that has been corrupted reads as "nothing was answered" and never as a grant.
  List<MarketingConsentDecision> history() {
    final Object? stored = _preferences.get(AppConstants.marketingConsents);
    if (stored is! String || stored.isEmpty) {
      return const <MarketingConsentDecision>[];
    }

    final Object? decoded = _decode(stored);
    if (decoded is! List) {
      return const <MarketingConsentDecision>[];
    }

    final List<MarketingConsentDecision> decisions =
        <MarketingConsentDecision>[];
    for (final Object? entry in decoded) {
      final MarketingConsentDecision? decision =
          MarketingConsentDecision.tryParse(entry);
      if (decision != null) {
        decisions.add(decision);
      }
    }

    return decisions;
  }

  /// The answer in force for one market, channel and purpose: the newest decision recorded for it, and null when the person has answered
  /// nothing for that key. A decision for another market, another channel or another purpose is not an answer for this one.
  MarketingConsentDecision? decisionFor({
    required String market,
    required String channel,
    required String purpose,
  }) {
    final String key =
        '${MarketingConsent.market(market)}|$channel|$purpose';

    MarketingConsentDecision? newest;
    for (final MarketingConsentDecision decision in history()) {
      if (decision.key == key) {
        newest = decision;
      }
    }

    return newest;
  }

  /// Whether marketing may be sent on this market, channel and purpose. False while the person has answered nothing.
  bool allows({
    required String market,
    required String channel,
    required String purpose,
  }) =>
      decisionFor(market: market, channel: channel, purpose: purpose)
          ?.isGranted ??
      MarketingConsent.optIn;

  /// Adds one decision to the history. False when it could not be written, in which case nothing was recorded and [allows] still answers
  /// by whatever was recorded before.
  ///
  /// The stored string grows by one entry, about 130 bytes, per answer, and nothing trims it. That is deliberate while there is nowhere
  /// to send the decisions: each entry costs one deliberate tap on a switch, and dropping the oldest would be dropping the evidence that
  /// a person agreed. It is the device's copy, not the record of account — that is the backend's table.
  Future<bool> record(MarketingConsentDecision decision) {
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[
      for (final MarketingConsentDecision recorded in history())
        recorded.toJson(),
      decision.toJson(),
    ];

    return _preferences.setString(
      AppConstants.marketingConsents,
      jsonEncode(rows),
    );
  }

  /// The decisions no server has been told about yet, oldest first.
  ///
  /// THERE IS NOWHERE TO SEND THEM. The backend records consent in `customer_marketing_consents` and gates its e-mail and WhatsApp
  /// senders on it, but it publishes NO API route for a customer to record a decision through: the only public entry point is the signed
  /// unsubscribe link in an e-mail footer. Until such a route exists this queue only grows, is read by nothing, and costs one string in
  /// the preferences. It is here so that the choice the person made is not lost before there is somewhere to send it, and so that what is
  /// missing is one named endpoint rather than a scheme.
  List<MarketingConsentDecision> pendingForServer() {
    final int sent = _sentCount();
    final List<MarketingConsentDecision> recorded = history();

    return sent >= recorded.length
        ? const <MarketingConsentDecision>[]
        : recorded.sublist(sent);
  }

  /// Marks every decision recorded so far as sent. Called by whatever sends them, once there is a route to send them to.
  ///
  /// What is stored is a COUNT, not a mark on each decision, so an entry that becomes unreadable shifts the boundary and a later
  /// decision could be taken for one already sent. Nothing sends anything today, so nothing acts on that; whatever ends up sending
  /// these should key the boundary to the decision itself.
  Future<bool> markSentToServer() => _preferences.setInt(
        AppConstants.marketingConsentsSent,
        history().length,
      );

  int _sentCount() {
    final Object? stored = _preferences.get(AppConstants.marketingConsentsSent);

    return stored is int && stored > 0 ? stored : 0;
  }

  static Object? _decode(String stored) {
    try {
      return jsonDecode(stored);
    } on FormatException catch (error) {
      // A store that cannot be decoded is read as "nothing was answered", which refuses marketing rather than allowing it.
      if (kDebugMode) {
        debugPrint('[marketing consent] unreadable store: ${error.message}');
      }

      return null;
    }
  }
}
