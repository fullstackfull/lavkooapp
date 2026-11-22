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
/// The sheet is the real widget, the store is the real store, and what is looked at after a switch is thrown is the decision the store
/// now holds and the set of topics the subscriber would then join. Nothing between the finger and the subscription is stubbed except
/// Firebase itself, whose calls are recorded.
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

  Future<void> openSheet(WidgetTester tester, {String on = 'KW'}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.storefrontCountry: on,
    });
    preferences = await SharedPreferences.getInstance();
    await StoredStorefronts(preferences).save(_listed);
    store = MarketingConsentStore(preferences);

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
          body: MarketingConsentSheet(preferences: preferences),
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
    /// The subscriber the app builds for this device, with the topics it would ask Firebase for recorded instead.
    ({List<String> joined, List<String> left}) subscribeWith(
        StorefrontTopicSubscriber Function(
                List<String> joined, List<String> left)
            build) {
      final List<String> joined = <String>[];
      final List<String> left = <String>[];
      build(joined, left);

      return (joined: joined, left: left);
    }

    StorefrontTopicSubscriber subscriber(
        List<String> joined, List<String> left) {
      final StorefrontChoice choice =
          StorefrontChoice(preferences, enabled: true);
      final MarketingConsentStore consents =
          MarketingConsentStore(preferences);

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

    testWidgets('before the person agrees, the device joins no marketing topic',
        (WidgetTester tester) async {
      await openSheet(tester);

      final ({List<String> joined, List<String> left}) calls =
          subscribeWith(subscriber);
      await subscriber(calls.joined, calls.left).apply();

      expect(calls.joined, isEmpty);
      expect(calls.left, contains('sixvalley_kw'));
      expect(calls.left, contains(AppConstants.topic));
    });

    testWidgets('after the person agrees, the device joins this market\'s topic and no other',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      final ({List<String> joined, List<String> left}) calls =
          subscribeWith(subscriber);
      await subscriber(calls.joined, calls.left).apply();

      expect(calls.joined, <String>['sixvalley_kw']);
      expect(calls.left, isNot(contains('sixvalley_kw')));
      expect(calls.left, contains('sixvalley_sa'));
      expect(calls.left, contains(AppConstants.topic));
    });

    testWidgets('after the person changes their mind, the device leaves it again',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();
      await tester.tap(switchFor(MarketingConsent.channelPush));
      await tester.pumpAndSettle();

      final ({List<String> joined, List<String> left}) calls =
          subscribeWith(subscriber);
      await subscriber(calls.joined, calls.left).apply();

      expect(calls.joined, isEmpty);
      expect(calls.left, contains('sixvalley_kw'));
    });

    testWidgets('agreeing to e-mail does not put the device on a push topic',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(switchFor(MarketingConsent.channelEmail));
      await tester.pumpAndSettle();

      final ({List<String> joined, List<String> left}) calls =
          subscribeWith(subscriber);
      await subscriber(calls.joined, calls.left).apply();

      expect(calls.joined, isEmpty);
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
