import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_decision.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_store.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-11 criterion 4, the capture half: a marketing consent is recorded PER SCOPE — per market, per channel and per purpose — and the
/// answer in force is the newest decision for that scope and no other.
///
/// Nothing here depends on the build flag: the store is the same store in both builds, and what the flag decides is whether anything
/// asks it. Who asks it is storefront_topic_subscriber_test.dart and marketing_consent_sheet_test.dart.
///
/// The shape is the backend's. `toJson`'s keys are the column names of `customer_marketing_consents`, so a decision captured here is
/// already what the backend records — see the contract note in [MarketingConsentStore.pendingForServer] for what is missing.
void main() {
  late SharedPreferences preferences;
  late MarketingConsentStore store;

  MarketingConsentDecision decision({
    String market = 'SA',
    String channel = MarketingConsent.channelPush,
    String purpose = MarketingConsent.purposeBroadcast,
    bool granted = true,
    DateTime? at,
  }) =>
      MarketingConsentDecision(
        market: market,
        channel: channel,
        purpose: purpose,
        decision: granted
            ? MarketingConsent.decisionGranted
            : MarketingConsent.decisionWithdrawn,
        answeredAt: at ?? DateTime.utc(2026, 11, 22, 12),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    store = MarketingConsentStore(preferences);
  });

  group('a person who has answered nothing', () {
    test('is not consenting on any channel, in any market', () {
      for (final String channel in MarketingConsent.channels) {
        for (final String market in <String>['SA', 'AE', 'KW', 'QA', 'BH', 'OM']) {
          expect(
            store.allows(
                market: market,
                channel: channel,
                purpose: MarketingConsent.purposeBroadcast),
            isFalse,
            reason: '$market/$channel',
          );
        }
      }
    });

    test('and the opt-in floor is what says so', () {
      expect(MarketingConsent.optIn, isFalse);
    });

    test('has no decision in force', () {
      expect(
        store.decisionFor(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isNull,
      );
    });
  });

  group('one answer', () {
    test('granting is honoured', () async {
      await store.record(decision());

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
    });

    test('does not reach another market', () async {
      await store.record(decision(market: 'SA'));

      expect(
        store.allows(
            market: 'KW',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    test('does not reach another channel', () async {
      await store.record(decision(channel: MarketingConsent.channelEmail));

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    test('does not reach another purpose', () async {
      await store.record(decision(purpose: MarketingConsent.purposeNewsletter));

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    test('is found under the market however it was spelled, because the column is an upper-case code', () async {
      await store.record(decision(market: 'sa'));

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
      expect(
        store.allows(
            market: ' sa ',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
    });
  });

  group('changing one\'s mind', () {
    test('withdrawing after granting stops it', () async {
      await store.record(decision(at: DateTime.utc(2026, 11, 1)));
      await store.record(
          decision(granted: false, at: DateTime.utc(2026, 11, 20)));

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    test('granting again after withdrawing starts it', () async {
      await store.record(decision(at: DateTime.utc(2026, 11, 1)));
      await store.record(
          decision(granted: false, at: DateTime.utc(2026, 11, 10)));
      await store.record(decision(at: DateTime.utc(2026, 11, 20)));

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
    });

    test('nothing is overwritten: every decision is still in the history, in the order it was made', () async {
      await store.record(decision(at: DateTime.utc(2026, 11, 1)));
      await store.record(
          decision(granted: false, at: DateTime.utc(2026, 11, 10)));
      await store.record(decision(at: DateTime.utc(2026, 11, 20)));

      final List<MarketingConsentDecision> history = store.history();

      expect(history, hasLength(3));
      expect(
        history.map((MarketingConsentDecision one) => one.decision).toList(),
        <String>['granted', 'withdrawn', 'granted'],
      );
      expect(
        history.map((MarketingConsentDecision one) => one.answeredAt).toList(),
        <DateTime>[
          DateTime.utc(2026, 11, 1),
          DateTime.utc(2026, 11, 10),
          DateTime.utc(2026, 11, 20),
        ],
      );
    });

    test('withdrawing in one market leaves another market\'s answer alone', () async {
      await store.record(decision(market: 'SA'));
      await store.record(decision(market: 'KW'));
      await store.record(decision(market: 'KW', granted: false));

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
      expect(
        store.allows(
            market: 'KW',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });
  });

  group('the shape the backend records', () {
    test('the keys of a decision are the column names of customer_marketing_consents', () {
      expect(
        decision().toJson().keys.toSet(),
        <String>{'market', 'channel', 'purpose', 'decision', 'source', 'recorded_at'},
      );
    });

    test('the time is stored in UTC, so the record does not move with the device\'s zone', () {
      final DateTime local = DateTime.utc(2026, 11, 22, 9).toLocal();

      expect(
        decision(at: local).toJson()['recorded_at'],
        DateTime.utc(2026, 11, 22, 9).toIso8601String(),
      );
    });

    test('the source is one of the backend\'s own four, and no fifth name is invented for the app', () {
      expect(decision().source, MarketingConsent.sourceAccountPage);
      expect(decision().toJson()['source'], 'account_page');
    });

    test('a decision survives the round trip through the store', () async {
      await store.record(decision(
          market: 'KW',
          channel: MarketingConsent.channelWhatsapp,
          purpose: MarketingConsent.purposeCartMarketing));

      final MarketingConsentDecision stored = store.history().single;

      expect(stored.market, 'KW');
      expect(stored.channel, MarketingConsent.channelWhatsapp);
      expect(stored.purpose, MarketingConsent.purposeCartMarketing);
      expect(stored.isGranted, isTrue);
    });
  });

  group('a store that cannot be read is never read as a grant', () {
    test('text that is not JSON reads as nothing answered', () async {
      await preferences.setString(AppConstants.marketingConsents, 'not json');

      expect(store.history(), isEmpty);
      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    test('an entry naming a channel this app does not know is left out', () async {
      await preferences.setString(
        AppConstants.marketingConsents,
        jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'market': 'SA',
            'channel': 'carrier_pigeon',
            'purpose': MarketingConsent.purposeBroadcast,
            'decision': 'granted',
            'recorded_at': '2026-11-22T12:00:00Z',
          },
        ]),
      );

      expect(store.history(), isEmpty);
    });

    test('an entry whose decision is neither granted nor withdrawn is left out', () async {
      await preferences.setString(
        AppConstants.marketingConsents,
        jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'market': 'SA',
            'channel': MarketingConsent.channelPush,
            'purpose': MarketingConsent.purposeBroadcast,
            'decision': 'maybe',
            'recorded_at': '2026-11-22T12:00:00Z',
          },
        ]),
      );

      expect(store.history(), isEmpty);
      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    test('a readable entry beside an unreadable one is still honoured', () async {
      await preferences.setString(
        AppConstants.marketingConsents,
        jsonEncode(<Object?>[
          'rubbish',
          <String, Object?>{
            'market': 'SA',
            'channel': MarketingConsent.channelPush,
            'purpose': MarketingConsent.purposeBroadcast,
            'decision': 'granted',
            'recorded_at': '2026-11-22T12:00:00Z',
          },
        ]),
      );

      expect(store.history(), hasLength(1));
      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
    });
  });

  group('what is waiting for a server that has no route for it', () {
    test('every decision is pending while nothing has been sent', () async {
      await store.record(decision());
      await store.record(decision(market: 'KW'));

      expect(store.pendingForServer(), hasLength(2));
    });

    test('nothing is pending once they have been marked sent', () async {
      await store.record(decision());
      await store.markSentToServer();

      expect(store.pendingForServer(), isEmpty);
    });

    test('a decision made after the last send is pending again', () async {
      await store.record(decision());
      await store.markSentToServer();
      await store.record(decision(granted: false));

      expect(store.pendingForServer(), hasLength(1));
      expect(store.pendingForServer().single.isGranted, isFalse);
    });
  });
}
