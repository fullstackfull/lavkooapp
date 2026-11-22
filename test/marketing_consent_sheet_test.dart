import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent.dart';
import 'package:syriapharmacy/features/marketing_consent/marketing_consent_store.dart';
import 'package:syriapharmacy/features/marketing_consent/widgets/marketing_consent_sheet.dart';
import 'package:syriapharmacy/features/marketing_consent/widgets/marketing_consent_settings_entry.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/localization/app_localization.dart';
import 'package:syriapharmacy/push_notification/storefront_topic_subscriber.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// J-11 criterion 4: marketing consent is CAPTURED per scope, on the real screen, and RESPECTED by the push path.
///
/// The sheet is the real widget and the store is the real store. What is looked at after a switch is thrown is the decision the store now
/// holds AND THE TOPIC CALLS THE SHEET ITSELF MADE: the subscriber handed to the sheet is the one whose calls are recorded, so the sheet
/// acting on the push answer is measured rather than assumed. An earlier version of this file rebuilt its own subscriber and ran it by
/// hand, which proved only that the recorded decision reads back correctly — deleting the sheet's own call left all thirteen tests green.
/// Firebase is the only thing stubbed, and only at the two calls the subscriber would make.
///
/// The sheet does not read the build flag — a decision is a decision in either build — so this file runs in both settings. What the flag
/// decides is whether the SETTINGS ROW is there at all, and that is asserted in both settings too.
Map<String, dynamic> _languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

class _FileLocalization extends AppLocalization {
  _FileLocalization(super.locale) : _values = _languageFile(locale.languageCode);

  final Map<String, dynamic> _values;

  @override
  String? translate(String? key) => _values[key] as String?;
}

class _FileLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _FileLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalization> load(Locale locale) =>
      SynchronousFuture<AppLocalization>(_FileLocalization(locale));

  @override
  bool shouldReload(_FileLocalizationsDelegate old) => false;
}

class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

const List<StorefrontCountry> _listed = <StorefrontCountry>[
  StorefrontCountry.saudiArabia,
  StorefrontCountry(code: 'KW', path: '/kw', currency: 'KWD', sellable: true),
];

void main() {
  late SharedPreferences preferences;
  late MarketingConsentStore store;

  /// The topics the sheet's own subscriber was asked to join and to leave, since the sheet opened.
  late List<String> joined;
  late List<String> left;

  /// The subscriber the sheet is given: the real storefront choice and the real consent store, with only the two Firebase calls
  /// recorded. It is built with storefronts on in either build, because the sheet does not read the build flag — what the flag decides is
  /// whether the settings row exists at all.
  StorefrontTopicSubscriber recordingSubscriber() {
    final StorefrontChoice choice =
        StorefrontChoice(preferences, enabled: true);
    final MarketingConsentStore consents = MarketingConsentStore(preferences);

    return StorefrontTopicSubscriber(
      subscribeToTopic: (String topic) async => joined.add(topic),
      unsubscribeFromTopic: (String topic) async => left.add(topic),
      currentStorefront: choice.current,
      availableStorefronts: choice.available,
      pushMarketingAllowed: (StorefrontCountry storefront) => consents.allows(
        market: storefront.code,
        channel: MarketingConsent.channelPush,
        purpose: MarketingConsent.purposeBroadcast,
      ),
      enabled: true,
    );
  }

  Future<void> openSheet(WidgetTester tester, {String on = 'KW'}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.storefrontCountry: on,
    });
    preferences = await SharedPreferences.getInstance();
    await StoredStorefronts(preferences).save(_listed);
    store = MarketingConsentStore(preferences);
    joined = <String>[];
    left = <String>[];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        _FileLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('en'),
      home: ChangeNotifierProvider<StorefrontController>.value(
        value: StorefrontController(
          storefrontServiceInterface: _NoServer(),
          storefrontChoice: StorefrontChoice(preferences, enabled: true),
        ),
        child: Scaffold(
          body: MarketingConsentSheet(
            preferences: preferences,
            topics: recordingSubscriber(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder switchFor(String channel) =>
      find.byKey(ValueKey<String>('marketing_consent_$channel'));

  bool? valueOf(WidgetTester tester, String channel) =>
      tester.widget<SwitchListTile>(switchFor(channel)).value;

  group('the sheet shows what the person has answered', () {
    testWidgets('a channel for each of the four the backend files a decision under',
        (WidgetTester tester) async {
      await openSheet(tester);

      for (final String channel in MarketingConsent.channels) {
        expect(switchFor(channel), findsOneWidget, reason: channel);
      }
    });

    testWidgets('every switch is off for a person who has answered nothing',
        (WidgetTester tester) async {
      await openSheet(tester);

      for (final String channel in MarketingConsent.channels) {
        expect(valueOf(tester, channel), isFalse, reason: channel);
      }
    });

    testWidgets('it names the market the answers are being given for',
        (WidgetTester tester) async {
      await openSheet(tester);

      expect(
        find.textContaining(_languageFile('en')['storefront_name_kw'] as String),
        findsOneWidget,
      );
    });
  });

  group('throwing a switch captures a decision in the scope it was given for', () {
    testWidgets('agreeing to push records a grant for this market, this channel and this purpose',
        (WidgetTester tester) async {
      await openSheet(tester);

      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect(
        store.allows(
            market: 'KW',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isTrue,
      );
      expect(valueOf(tester, MarketingConsent.channelPush), isTrue);
    });

    testWidgets('and it reaches no other market', (WidgetTester tester) async {
      await openSheet(tester);

      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect(
        store.allows(
            market: 'SA',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    testWidgets('and no other channel', (WidgetTester tester) async {
      await openSheet(tester);

      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect(
        store.allows(
            market: 'KW',
            channel: MarketingConsent.channelEmail,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
      expect(valueOf(tester, MarketingConsent.channelEmail), isFalse);
    });

    testWidgets('changing one\'s mind writes a second decision and keeps the first',
        (WidgetTester tester) async {
      await openSheet(tester);

      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect(store.history(), hasLength(2));
      expect(store.history().first.isGranted, isTrue);
      expect(store.history().last.isGranted, isFalse);
      expect(
        store.allows(
            market: 'KW',
            channel: MarketingConsent.channelPush,
            purpose: MarketingConsent.purposeBroadcast),
        isFalse,
      );
    });

    testWidgets('the e-mail answer is captured too, in the same shape, for the sender that has no route yet',
        (WidgetTester tester) async {
      await openSheet(tester);

      await tester.tap(switchFor(MarketingConsent.channelEmail));
      await tester.pumpAndSettle();

      expect(store.history().single.channel, MarketingConsent.channelEmail);
      expect(store.history().single.market, 'KW');
      expect(store.pendingForServer(), hasLength(1),
          reason: 'it is waiting for an endpoint the backend does not publish');
    });
  });

  group('THE PUSH ANSWER IS RESPECTED: the topics follow it', () {
    /// A subscriber built fresh from what the preferences now hold, to show that the answer SURVIVES the sheet: the live call proves the
    /// sheet acted, this proves the next start would act the same way.
    Future<({List<String> joined, List<String> left})>
        whatTheNextStartWouldDo() async {
      final List<String> joinedThen = <String>[];
      final List<String> leftThen = <String>[];
      final StorefrontChoice choice =
          StorefrontChoice(preferences, enabled: true);
      final MarketingConsentStore consents =
          MarketingConsentStore(preferences);

      final StorefrontTopicSubscriber subscriber = StorefrontTopicSubscriber(
        subscribeToTopic: (String topic) async => joinedThen.add(topic),
        unsubscribeFromTopic: (String topic) async => leftThen.add(topic),
        currentStorefront: choice.current,
        availableStorefronts: choice.available,
        pushMarketingAllowed: (StorefrontCountry storefront) =>
            consents.allows(
          market: storefront.code,
          channel: MarketingConsent.channelPush,
          purpose: MarketingConsent.purposeBroadcast,
        ),
        enabled: true,
      );

      await subscriber.apply();

      return (joined: joinedThen, left: leftThen);
    }

    testWidgets('the sheet asks the topics nothing until an answer is given',
        (WidgetTester tester) async {
      await openSheet(tester);

      expect(joined, isEmpty);
      expect(left, isEmpty);
    });

    testWidgets('agreeing puts the device on this market\'s topic and no other, and THE SHEET ITSELF does it',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect(joined, <String>['sixvalley_kw'],
          reason:
              'these are the calls the sheet made through the subscriber it was given, not a set a test rebuilt afterwards');
      expect(left, isNot(contains('sixvalley_kw')));
      expect(left, contains('sixvalley_sa'));
      expect(left, contains(AppConstants.topic));
    });

    testWidgets('and a start after it would ask for the same topic, so the answer outlives the sheet',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect((await whatTheNextStartWouldDo()).joined, <String>['sixvalley_kw']);
    });

    testWidgets('after the person changes their mind, THE SHEET ITSELF takes the device off it again',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();
      joined.clear();
      left.clear();

      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      expect(joined, isEmpty);
      expect(left, contains('sixvalley_kw'));
      expect((await whatTheNextStartWouldDo()).joined, isEmpty);
    });

    testWidgets('agreeing to e-mail asks the topics nothing at all: a channel the device\'s subscription does not carry',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelEmail));
      await tester.pumpAndSettle();

      expect(joined, isEmpty);
      expect(left, isEmpty);
      expect((await whatTheNextStartWouldDo()).joined, isEmpty,
          reason: 'an e-mail answer is not a push answer');
    });

    testWidgets('the switch moves as soon as the answer is recorded, not after Firebase has answered about every topic',
        (WidgetTester tester) async {
      await openSheet(tester);

      // A subscriber whose calls never complete: the sheet must still have shown the new answer.
      final Completer<void> firebaseNeverAnswers = Completer<void>();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _FileLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('en'),
        home: ChangeNotifierProvider<StorefrontController>.value(
          value: StorefrontController(
            storefrontServiceInterface: _NoServer(),
            storefrontChoice: StorefrontChoice(preferences, enabled: true),
          ),
          child: Scaffold(
            body: MarketingConsentSheet(
              preferences: preferences,
              topics: StorefrontTopicSubscriber(
                subscribeToTopic: (String topic) => firebaseNeverAnswers.future,
                unsubscribeFromTopic: (String topic) =>
                    firebaseNeverAnswers.future,
                currentStorefront: () => StorefrontCountry.kuwait,
                availableStorefronts: () => const <StorefrontCountry>[],
                pushMarketingAllowed: (_) => true,
                enabled: true,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pump();

      expect(valueOf(tester, MarketingConsent.channelPush), isTrue,
          reason:
              'a build with storefronts on leaves half a dozen topics and joins one; the switch must not sit under the finger until all of that returns');

      firebaseNeverAnswers.complete();
      await tester.pumpAndSettle();
    });
  });

  group('the settings row', () {
    testWidgets('is there in a build with storefronts on and nowhere in one with them off',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _FileLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('en'),
        home: const Scaffold(body: MarketingConsentSettingsEntry()),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(_languageFile('en')['marketing_consent'] as String),
        StorefrontConfig.enabled ? findsOneWidget : findsNothing,
      );
    });
  });
}
