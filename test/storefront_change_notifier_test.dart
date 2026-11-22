import 'dart:async';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// A listener that writes what it does into a shared log, and drops before its first await as the contract asks.
class _Listener implements StorefrontChangeListener {
  _Listener(this.name, this.log, {this.reload, this.failWith});

  final String name;
  final List<String> log;
  final Future<void> Function()? reload;
  final Object? failWith;
  final List<StorefrontChange> told = <StorefrontChange>[];

  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    told.add(change);
    log.add('$name drops');
    if (failWith != null) throw failWith!;
    await reload?.call();
    log.add('$name reloaded');
  }
}

class _Controller extends ChangeNotifier with StorefrontChangeAware {
  _Controller(StorefrontChangeNotifier? notifier) {
    followStorefrontChanges(notifier);
  }

  int told = 0;

  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    told++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;
  late bool signedIn;
  late Future<void> Function(String code) clearLocal;

  StorefrontChangeNotifier notifier({bool enabled = true}) =>
      StorefrontChangeNotifier(
        clearHttpCache: (String code) => log.add('http cache of $code cleared'),
        clearLocalCache: (String code) => clearLocal(code),
        isSignedIn: () => signedIn,
        enabled: enabled,
      );

  setUp(() {
    log = <String>[];
    signedIn = false;
    clearLocal = (String code) async => log.add('local cache of $code cleared');
  });

  group('while storefronts are off', () {
    test('nothing is cleared and nobody is told', () async {
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier off = notifier(enabled: false)
        ..register(listener);

      await off.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.unitedArabEmirates,
      );

      expect(log, isEmpty);
      expect(listener.told, isEmpty);
    });
  });

  group('a change of storefront', () {
    test('clears what the storefront the customer left cached, and only that',
        () async {
      await (notifier()).storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.unitedArabEmirates,
      );

      expect(log, <String>[
        'http cache of SA cleared',
        'local cache of SA cleared',
      ]);
    });

    test('tells every listener once, with both storefronts', () async {
      final _Listener first = _Listener('first', log);
      final _Listener second = _Listener('second', log);
      final StorefrontChangeNotifier subject = notifier()
        ..register(first)
        ..register(second);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      for (final _Listener listener in <_Listener>[first, second]) {
        expect(listener.told, hasLength(1));
        expect(listener.told.single.previous.code, 'SA');
        expect(listener.told.single.current.code, 'KW');
      }
    });

    test(
        'says whether a customer is signed in, as it is when the change is made',
        () async {
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier subject = notifier()..register(listener);

      signedIn = true;
      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );
      signedIn = false;
      await subject.storefrontChanged(
        previous: StorefrontCountry.kuwait,
        current: StorefrontCountry.saudiArabia,
      );

      expect(listener.told.map((StorefrontChange change) => change.signedIn),
          <bool>[true, false]);
    });

    test('lets every listener drop before any of them reloads', () async {
      final Completer<void> firstAnswer = Completer<void>();
      final Completer<void> secondAnswer = Completer<void>();
      final StorefrontChangeNotifier subject = notifier()
        ..register(_Listener('first', log, reload: () => firstAnswer.future))
        ..register(_Listener('second', log, reload: () => secondAnswer.future));

      final Future<void> changing = subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(log, containsAllInOrder(<String>['first drops', 'second drops']));
      expect(log, isNot(contains('first reloaded')));

      secondAnswer.complete();
      firstAnswer.complete();
      await changing;

      expect(log.where((String line) => line.endsWith('reloaded')),
          <String>['second reloaded', 'first reloaded']);
    });

    test('completes when the last listener has reloaded', () async {
      final Completer<void> answer = Completer<void>();
      final StorefrontChangeNotifier subject = notifier()
        ..register(_Listener('slow', log, reload: () => answer.future));
      bool completed = false;

      final Future<void> changing = subject
          .storefrontChanged(
            previous: StorefrontCountry.saudiArabia,
            current: StorefrontCountry.kuwait,
          )
          .then((_) => completed = true);
      await pumpEventQueue();
      expect(completed, isFalse);

      answer.complete();
      await changing;
      expect(completed, isTrue);
    });

    test('is not held up, and does not throw, when a listener fails', () async {
      final _Listener broken =
          _Listener('broken', log, failWith: StateError('no'));
      final _Listener healthy = _Listener('healthy', log);
      final StorefrontChangeNotifier subject = notifier()
        ..register(broken)
        ..register(healthy);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(healthy.told, hasLength(1));
      expect(log, contains('healthy reloaded'));
    });

    test(
        'is not held up, and does not throw, when the local rows cannot be deleted',
        () async {
      clearLocal = (String code) async => throw StateError('disk full');
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier subject = notifier()..register(listener);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(listener.told, hasLength(1));
      expect(log, contains('http cache of SA cleared'));
    });

    test(
        'is not held up, and does not throw, when the HTTP cache cannot be cleared',
        () async {
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier subject = StorefrontChangeNotifier(
        clearHttpCache: (String code) => throw StateError('no preferences'),
        clearLocalCache: (String code) async => log.add('local'),
        isSignedIn: () => false,
        enabled: true,
      )..register(listener);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(listener.told, hasLength(1));
      expect(log, contains('local'));
    });

    test('is nothing when the customer chose the storefront they were on',
        () async {
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier subject = notifier()..register(listener);

      await subject.storefrontChanged(
        previous: StorefrontCountry.kuwait,
        current: StorefrontCountry.kuwait,
      );

      expect(log, isEmpty);
      expect(listener.told, isEmpty);
    });
  });

  group('registering', () {
    test('a listener registered twice is told once', () async {
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier subject = notifier()
        ..register(listener)
        ..register(listener);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(listener.told, hasLength(1));
    });

    test('a listener that left is not told', () async {
      final _Listener listener = _Listener('a', log);
      final StorefrontChangeNotifier subject = notifier()
        ..register(listener)
        ..unregister(listener)
        ..unregister(listener);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(listener.told, isEmpty);
    });

    test(
        'a listener that registers while the others are told waits for the next change',
        () async {
      final _Listener late = _Listener('late', log);
      final _Listener early = _Listener('early', log, reload: () async {});
      final StorefrontChangeNotifier subject = notifier();
      subject.register(_RegistersWhenTold(subject, late));
      subject.register(early);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );

      expect(early.told, hasLength(1));
      expect(late.told, isEmpty);
      expect(subject.listenerCount, 3);
    });

    test(
        'a controller joins the notifier when it is built and leaves when it is disposed',
        () async {
      final StorefrontChangeNotifier subject = notifier();
      final _Controller controller = _Controller(subject);
      expect(subject.listenerCount, 1);

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.kuwait,
      );
      expect(controller.told, 1);

      controller.dispose();
      expect(subject.listenerCount, 0);
    });

    test('a controller built without a notifier is simply not told', () {
      final _Controller controller = _Controller(null);

      expect(controller.dispose, returnsNormally);
    });
  });

  group('over the real caches', () {
    late SharedPreferences preferences;
    late DioClient client;
    late AppDatabase database;

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      database = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues(<String, Object>{
        'api_cache_/api/v1/categories#en#SA': '[]',
        'api_cache_/api/v1/categories#en#SA_time': 1,
        'api_cache_/api/v1/categories#en#AE': '[]',
        'api_cache_/api/v1/categories#en#AE_time': 1,
        'api_cache_/api/v1/categories#en': '[]',
        AppConstants.userLoginToken: 'token',
        AppConstants.analyticsClientId: 'client',
      });
      preferences = await SharedPreferences.getInstance();
      client = DioClient(
        'https://shop.test',
        Dio(),
        loggingInterceptor: LoggingInterceptor(),
        sharedPreferences: preferences,
      );

      for (final String key in <String>[
        '/api/v1/config#SA',
        '/api/v1/config#AE',
        '/api/v1/config',
      ]) {
        await database.into(database.cacheResponse).insert(
              CacheResponseCompanion(
                endPoint: Value(key),
                header: const Value('{}'),
                response: const Value('{}'),
              ),
            );
      }
    });

    tearDown(() async {
      StorefrontScope.publish(null);
      await database.close();
    });

    test('a change clears the old storefront in both, and leaves the rest',
        () async {
      final StorefrontChangeNotifier subject = StorefrontChangeNotifier(
        clearHttpCache: client.clearStorefrontCache,
        clearLocalCache: (String code) =>
            database.deleteCacheResponsesOfStorefront(code),
        isSignedIn: () => false,
        enabled: true,
      );

      await subject.storefrontChanged(
        previous: StorefrontCountry.saudiArabia,
        current: StorefrontCountry.unitedArabEmirates,
      );

      expect(
        preferences
            .getKeys()
            .where((String key) => key.startsWith('api_cache_')),
        unorderedEquals(<String>[
          'api_cache_/api/v1/categories#en#AE',
          'api_cache_/api/v1/categories#en#AE_time',
          'api_cache_/api/v1/categories#en',
        ]),
      );
      expect(
        (await database.getAllCacheResponses())
            .map((CacheResponseData row) => row.endPoint)
            .toList()
          ..sort(),
        <String>['/api/v1/config', '/api/v1/config#AE'],
      );
    });
  });
}

/// A listener that, when told, registers another one: the notifier must not tell that one in the same round.
class _RegistersWhenTold implements StorefrontChangeListener {
  _RegistersWhenTold(this._notifier, this._other);

  final StorefrontChangeNotifier _notifier;
  final StorefrontChangeListener _other;

  @override
  Future<void> onStorefrontChanged(StorefrontChange change) async {
    _notifier.register(_other);
  }
}
