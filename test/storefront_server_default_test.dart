import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/storefront/storefront_switcher.dart';
import 'package:syriapharmacy/features/storefront/stored_storefronts.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// What the server is asked for after a choice, written into the log of the test so the order of everything a move does is one list.
///
/// A service built with [movesTo] stores that answer when it is asked, the way the real one stores an answer it could read: it is the
/// server moving its `default_country` under a customer. One built without it leaves the stored list as the test saved it, the way a
/// refresh that brings nothing new does.
class _RecordingService implements StorefrontServiceInterface {
  _RecordingService(this._log, this._preferences, {this.movesTo});

  final List<String> _log;
  final SharedPreferences _preferences;
  final Object? movesTo;

  @override
  Future<bool> refreshStorefronts() async {
    _log.add(
        'server asked, choice then ${_preferences.getString(AppConstants.storefrontCountry)}');

    final Object? answer = movesTo;
    if (answer == null) {
      return false;
    }

    return StoredStorefronts(_preferences)
        .save(StorefrontCountry.parseList(answer));
  }
}

const Map<String, Object> _saudiEntry = <String, Object>{
  'country': 'SA',
  'path': 'sa',
  'currency': 'SAR',
  'sellable': true,
};

const Map<String, Object> _emiratesEntry = <String, Object>{
  'country': 'AE',
  'path': 'ae',
  'currency': 'AED',
  'sellable': true,
};

const Map<String, Object> _kuwaitEntry = <String, Object>{
  'country': 'KW',
  'path': 'kw',
  'currency': 'KWD',
  'sellable': false,
};

const List<Map<String, Object>> _threeStorefronts = <Map<String, Object>>[
  _saudiEntry,
  _emiratesEntry,
  _kuwaitEntry,
];

/// J-01 criterion 4: when the server changes `default_country` the storefront the app falls back to follows it. The fallback is the
/// storefront a customer is on while they have chosen none the app can honour, and the one a customer is moved to when the server stops
/// listing theirs.
///
/// Saudi Arabia stays the floor: an answer that names no default, names one it does not list, or names one that cannot be read leaves the
/// app on the storefront it serves today, so a customer is never left without one. Nothing of this is read or written while storefronts are
/// off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;

  /// The answer of `GET /api/v1/storefronts`, naming [defaultCountry] the default storefront of the list.
  Map<String, Object?> answerNaming(Object? defaultCountry,
          {List<Map<String, Object>> entries = _threeStorefronts}) =>
      <String, Object?>{
        'default_country': defaultCountry,
        'storefronts': entries,
      };

  /// The same answer with no `default_country` in it at all.
  Map<String, Object?> answerNamingNothing(
          {List<Map<String, Object>> entries = _threeStorefronts}) =>
      <String, Object?>{'storefronts': entries};

  /// The device of a customer, with [answer] stored the way the service stores it: read into storefronts, then kept as the last answer.
  Future<SharedPreferences> deviceWith({
    Map<String, Object> stored = const <String, Object>{},
    Object? answer,
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (answer != null) {
      await StoredStorefronts(preferences)
          .save(StorefrontCountry.parseList(answer));
    }

    return preferences;
  }

  String fallbackOf(SharedPreferences preferences) =>
      StorefrontChoice(preferences, enabled: true).current().code;

  /// A switcher whose `applyHeaders` does what the HTTP client's does: it resolves the storefront afresh, writes it where `X-Storefront`
  /// goes — the log — and publishes it as the storefront the app's requests are being made for, which is what names the cache of every
  /// answer. The storefront it finds is therefore the one the app would ask the server for, not the choice stored for it.
  StorefrontSwitcher switcherOver(SharedPreferences preferences,
          {bool enabled = true, Object? movesTo}) =>
      StorefrontSwitcher(
        storefrontController: StorefrontController(
          storefrontServiceInterface:
              _RecordingService(log, preferences, movesTo: movesTo),
          storefrontChoice: StorefrontChoice(preferences, enabled: enabled),
        ),
        applyHeaders: () {
          final String asked = StorefrontConfig.resolve(preferences).code;
          log.add('headers rebuilt, X-Storefront $asked');
          StorefrontScope.publish(asked);
        },
        changeNotifier: StorefrontChangeNotifier(
          clearHttpCache: (String code) => log.add('http cache cleared of $code'),
          clearLocalCache: (String code) async =>
              log.add('local cache cleared of $code'),
          isSignedIn: () => false,
          enabled: true,
        ),
      );

  setUp(() {
    log = <String>[];
    StorefrontScope.publish(null);
  });

  group('the default the answer names', () {
    test('is read from default_country, and is the only default of the list',
        () {
      final List<StorefrontCountry> listed =
          StorefrontCountry.parseList(answerNaming('AE'));

      expect(
        listed.map((StorefrontCountry storefront) =>
            '${storefront.code} ${storefront.isDefault}'),
        <String>['SA false', 'AE true', 'KW false'],
      );
      expect(StorefrontCountry.fallbackAmong(listed).code, 'AE');
    });

    test('is read regardless of case and surrounding spaces', () {
      expect(
        StorefrontCountry.fallbackAmong(
                StorefrontCountry.parseList(answerNaming(' ae ')))
            .code,
        'AE',
      );
    });

    test('is the entry\'s own is_default when the answer carries no default_country',
        () {
      final List<StorefrontCountry> listed = StorefrontCountry.parseList(
        answerNamingNothing(entries: <Map<String, Object>>[
          _saudiEntry,
          <String, Object>{..._kuwaitEntry, 'is_default': true},
        ]),
      );

      expect(StorefrontCountry.fallbackAmong(listed).code, 'KW');
    });

    test('is the one default_country names, when an entry\'s is_default says otherwise',
        () {
      final List<StorefrontCountry> listed = StorefrontCountry.parseList(
        answerNaming('KW', entries: <Map<String, Object>>[
          <String, Object>{..._saudiEntry, 'is_default': true},
          _kuwaitEntry,
        ]),
      );

      expect(
        listed.map((StorefrontCountry storefront) =>
            '${storefront.code} ${storefront.isDefault}'),
        <String>['SA false', 'KW true'],
      );
    });

    test('is nothing at all when the answer names one that cannot be read, or one it does not list, whatever an entry says of itself',
        () {
      for (final Object? unusable in <Object?>[
        '',
        '   ',
        'E',
        'EGY',
        'A1',
        7,
        true,
        null,
        <Object?>[],
        'EG',
      ]) {
        // Kuwait carries the `is_default` of an older answer: an answer that carries `default_country` has spoken about its default, and
        // one it cannot be read from names none, so the entry's own word is not a second way to be the default.
        final List<StorefrontCountry> listed = StorefrontCountry.parseList(
          answerNaming(unusable, entries: <Map<String, Object>>[
            _saudiEntry,
            <String, Object>{..._kuwaitEntry, 'is_default': true},
          ]),
        );

        expect(
            listed.where((StorefrontCountry storefront) => storefront.isDefault),
            isEmpty,
            reason: 'default_country: $unusable');
        expect(StorefrontCountry.fallbackAmong(listed).code, 'SA',
            reason: 'default_country: $unusable');
      }
    });

    test('is kept with the stored list, under the key the server writes it with',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));

      expect(jsonDecode(preferences.getString(AppConstants.storefrontList)!), {
        'storefronts': [
          {'country': 'SA', 'path': '/sa', 'currency': 'SAR', 'sellable': true},
          {
            'country': 'AE',
            'path': '/ae',
            'currency': 'AED',
            'is_default': true,
            'sellable': true,
          },
          {
            'country': 'KW',
            'path': '/kw',
            'currency': 'KWD',
            'sellable': false,
          },
        ],
      });
      expect(
        StorefrontCountry.fallbackAmong(StoredStorefronts(preferences).read())
            .code,
        'AE',
      );
    });
  });

  group('the storefront a customer with no choice of their own is on', () {
    test('is the one the server names its default', () async {
      expect(fallbackOf(await deviceWith(answer: answerNaming('AE'))), 'AE');
    });

    test('follows the server when it moves its default', () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));
      final StoredStorefronts stored = StoredStorefronts(preferences);
      expect(fallbackOf(preferences), 'AE');

      await stored.save(StorefrontCountry.parseList(answerNaming('KW')));
      expect(fallbackOf(preferences), 'KW');

      await stored.save(StorefrontCountry.parseList(answerNamingNothing()));
      expect(fallbackOf(preferences), 'SA');
    });

    test('is the server\'s default for a stored choice the app cannot honour',
        () async {
      for (final Object storedChoice in <Object>['US', 7]) {
        expect(
          fallbackOf(await deviceWith(
            stored: <String, Object>{
              AppConstants.storefrontCountry: storedChoice
            },
            answer: answerNaming('AE'),
          )),
          'AE',
          reason: 'stored choice: $storedChoice',
        );
      }
    });

    test('is Saudi Arabia before the server has answered once', () async {
      expect(fallbackOf(await deviceWith()), 'SA');
    });

    test('is Saudi Arabia when the answer names no default, even when it does not list Saudi Arabia',
        () async {
      expect(
        fallbackOf(await deviceWith(
            answer: answerNamingNothing(entries: <Map<String, Object>>[
          _emiratesEntry,
          _kuwaitEntry,
        ]))),
        'SA',
      );
    });

    test('is Saudi Arabia when the answer names a default it does not list',
        () async {
      expect(
        fallbackOf(await deviceWith(
            answer: answerNaming('OM', entries: <Map<String, Object>>[
          _emiratesEntry,
          _kuwaitEntry,
        ]))),
        'SA',
      );
    });

    test('is not the server\'s default for a customer who chose a storefront the answer lists',
        () async {
      expect(
        fallbackOf(await deviceWith(
          stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
          answer: answerNaming('AE'),
        )),
        'KW',
      );
    });
  });

  group('while storefronts are off', () {
    test('the server\'s default is not read: the storefront is Saudi Arabia, and nothing is written',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        answer: answerNaming('AE'),
      );
      final StorefrontChoice choice =
          StorefrontChoice(preferences, enabled: false);

      expect(choice.current().code, 'SA');
      expect(choice.available(), isEmpty);
      expect(await choice.choose(StorefrontCountry.unitedArabEmirates), isFalse);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
    });

    test('a storefront the answer no longer lists is left alone, and nothing is asked',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNaming('AE'),
      );

      expect(
          await switcherOver(preferences, enabled: false)
              .followTheServersList(),
          StorefrontSwitch.unchanged);
      expect(log, isEmpty);
      expect(preferences.getString(AppConstants.storefrontCountry), 'OM');
    });
  });

  group('following the list the server answers with', () {
    test('moves a customer whose storefront it no longer lists to the default it names, the way a choice moves them',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNaming('AE', entries: <Map<String, Object>>[
          _saudiEntry,
          _emiratesEntry,
        ]),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();
      await Future<void>.delayed(Duration.zero);

      expect(result, StorefrontSwitch.switched);
      expect(preferences.getString(AppConstants.storefrontCountry), 'AE');
      expect(log, <String>[
        'server asked, choice then OM',
        'server asked, choice then AE',
        'headers rebuilt, X-Storefront AE',
        'http cache cleared of OM',
        'local cache cleared of OM',
      ]);
      expect(StorefrontScope.current, 'AE');
    });

    test('moves them to Saudi Arabia when it names no default, even when it does not list Saudi Arabia',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNamingNothing(entries: <Map<String, Object>>[
          _emiratesEntry,
          _kuwaitEntry,
        ]),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();

      expect(result, StorefrontSwitch.switched);
      expect(preferences.getString(AppConstants.storefrontCountry), 'SA');
    });

    test('moves them to Saudi Arabia when the default it names is one it does not list',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'OM'},
        answer: answerNaming('OM', entries: <Map<String, Object>>[
          _saudiEntry,
          _emiratesEntry,
        ]),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();

      expect(result, StorefrontSwitch.switched);
      expect(preferences.getString(AppConstants.storefrontCountry), 'SA');
    });

    test('leaves a customer the answer still lists where they are, whichever storefront is its default',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        answer: answerNaming('AE'),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences).followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
      expect(log, <String>['server asked, choice then KW']);
    });
  });

  group('when a newer answer moves the default under a customer who chose none',
      () {
    test('the storefront the app asks for moves with it, and what the one they were on cached is dropped',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));
      expect(fallbackOf(preferences), 'AE');

      final StorefrontSwitch result =
          await switcherOver(preferences, movesTo: answerNaming('KW'))
              .followTheServersList();
      await Future<void>.delayed(Duration.zero);

      expect(result, StorefrontSwitch.switched);
      expect(fallbackOf(preferences), 'KW');
      expect(log, <String>[
        'server asked, choice then null',
        'headers rebuilt, X-Storefront KW',
        'http cache cleared of AE',
        'local cache cleared of AE',
      ]);
      expect(StorefrontScope.current, 'KW');
    });

    test('nothing is written for it, so the answer after that moves them again',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));

      await switcherOver(preferences, movesTo: answerNaming('KW'))
          .followTheServersList();

      expect(preferences.containsKey(AppConstants.storefrontCountry), isFalse);

      final StorefrontSwitch again =
          await switcherOver(preferences, movesTo: answerNaming('SA'))
              .followTheServersList();
      await Future<void>.delayed(Duration.zero);

      expect(again, StorefrontSwitch.switched);
      expect(fallbackOf(preferences), 'SA');
      expect(log.last, 'local cache cleared of KW');
    });

    test('the first answer moves them off Saudi Arabia, which is where a device with no answer starts',
        () async {
      final SharedPreferences preferences = await deviceWith();
      expect(fallbackOf(preferences), 'SA');

      final StorefrontSwitch result =
          await switcherOver(preferences, movesTo: answerNaming('AE'))
              .followTheServersList();
      await Future<void>.delayed(Duration.zero);

      expect(result, StorefrontSwitch.switched);
      expect(log, <String>[
        'server asked, choice then null',
        'headers rebuilt, X-Storefront AE',
        'http cache cleared of SA',
        'local cache cleared of SA',
      ]);
      expect(StorefrontScope.current, 'AE');
    });

    test('an answer that clears its default moves them back to Saudi Arabia',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));

      final StorefrontSwitch result =
          await switcherOver(preferences, movesTo: answerNaming(''))
              .followTheServersList();
      await Future<void>.delayed(Duration.zero);

      expect(result, StorefrontSwitch.switched);
      expect(fallbackOf(preferences), 'SA');
      expect(log, <String>[
        'server asked, choice then null',
        'headers rebuilt, X-Storefront SA',
        'http cache cleared of AE',
        'local cache cleared of AE',
      ]);
    });

    test('a customer who chose a storefront the answer still lists is left where they are',
        () async {
      final SharedPreferences preferences = await deviceWith(
        stored: <String, Object>{AppConstants.storefrontCountry: 'KW'},
        answer: answerNaming('AE'),
      );

      final StorefrontSwitch result =
          await switcherOver(preferences, movesTo: answerNaming('QA'))
              .followTheServersList();

      expect(result, StorefrontSwitch.unchanged);
      expect(preferences.getString(AppConstants.storefrontCountry), 'KW');
      expect(log, <String>['server asked, choice then KW']);
      expect(StorefrontScope.current, isNull);
    });

    test('nothing of it happens while storefronts are off: the server is not even asked',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));
      final String storedList =
          preferences.getString(AppConstants.storefrontList)!;

      expect(
          await switcherOver(preferences,
                  enabled: false, movesTo: answerNaming('KW'))
              .followTheServersList(),
          StorefrontSwitch.unchanged);

      expect(log, isEmpty);
      expect(StorefrontScope.current, isNull);
      expect(preferences.getString(AppConstants.storefrontList), storedList);
      expect(preferences.containsKey(AppConstants.storefrontCountry), isFalse);
    });
  });

  group('the stored answer', () {
    test('is parsed once however often it is read, and afresh once it is saved again',
        () async {
      final SharedPreferences preferences =
          await deviceWith(answer: answerNaming('AE'));
      final StoredStorefronts stored = StoredStorefronts(preferences);

      expect(stored.read(), same(stored.read()));
      expect(StoredStorefronts(preferences).read(), same(stored.read()));

      await stored.save(StorefrontCountry.parseList(answerNaming('KW')));

      expect(StorefrontCountry.fallbackAmong(stored.read()).code, 'KW');
    });
  });
}
