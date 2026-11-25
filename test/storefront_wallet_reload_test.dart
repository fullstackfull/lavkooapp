import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/loyaltyPoint/controllers/loyalty_point_controller.dart';
import 'package:syriapharmacy/features/loyaltyPoint/domain/services/loyalty_point_service_interface.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/profile/domain/models/profile_model.dart';
import 'package:syriapharmacy/features/profile/domain/services/profile_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';
import 'package:syriapharmacy/features/wallet/controllers/wallet_controller.dart';
import 'package:syriapharmacy/features/wallet/domain/services/wallet_service_interface.dart';

const StorefrontChange _guestToEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: false,
);

const StorefrontChange _customerToEmirates = StorefrontChange(
  previous: StorefrontCountry.saudiArabia,
  current: StorefrontCountry.unitedArabEmirates,
  signedIn: true,
);

Response<dynamic> _ok(Object? body) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: body,
    );

String get _who => StorefrontScope.current ?? 'none';

/// The ledger an answer carries says which storefront it was asked for: the balance of SA is 100, of AE 200.
class _FakeWalletService implements WalletServiceInterface {
  /// The first ledger request that comes in waits for this, and the ones after it do not: the answer for the storefront the customer left is the
  /// last to arrive.
  Completer<void>? holdFirstLedger;
  Completer<void>? holdFirstBonuses;
  int ledgerAsked = 0;
  int bonusesAsked = 0;

  @override
  Future<dynamic> getList({
    int? offset = 1,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,
  }) async {
    ledgerAsked++;
    final double balance = _who == 'SA' ? 100 : 200;
    final Completer<void>? gate = holdFirstLedger;
    holdFirstLedger = null;
    await gate?.future;

    return ApiResponseModel.withSuccess(_ok(<String, Object>{
      'limit': 10,
      'offset': 1,
      'total_size': 0,
      'total_wallet_balance': balance,
      'filter_by': 'all',
      'wallet_transaction_list': <Object>[],
    }));
  }

  @override
  Future<dynamic> getWalletBonusBannerList() async {
    bonusesAsked++;
    final String who = _who;
    final int id = who == 'SA' ? 1 : 2;
    final Completer<void>? gate = holdFirstBonuses;
    holdFirstBonuses = null;
    await gate?.future;

    return ApiResponseModel.withSuccess(_ok(<String, Object>{
      'bonus_list': <Object>[
        <String, Object>{'id': id, 'title': 'bonus of $who'},
      ],
    }));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoyaltyPointService implements LoyaltyPointServiceInterface {
  /// The first request that comes in waits for this, and the ones after it do not.
  Completer<void>? holdFirst;
  int asked = 0;

  @override
  Future<dynamic> getList({
    int? offset = 1,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,
  }) async {
    asked++;
    final int points = _who == 'SA' ? 10 : 20;
    final Completer<void>? gate = holdFirst;
    holdFirst = null;
    await gate?.future;

    return ApiResponseModel.withSuccess(_ok(<String, Object>{
      'limit': 10,
      'offset': 1,
      'total_size': 0,
      'total_loyalty_point': points,
      'filter_by': 'all',
      'loyalty_point_list': <Object>[],
    }));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The profile an answer carries says which storefront it was asked for: the wallet of SA is 100 with 10 points, of AE 200 with 20.
class _FakeProfileService implements ProfileServiceInterface {
  int asked = 0;

  @override
  Future<dynamic> getProfileInfo() async {
    asked++;
    final bool saudi = _who == 'SA';

    return ApiResponseModel.withSuccess(_ok(<String, dynamic>{
      'id': saudi ? 1 : 2,
      'f_name': 'A',
      'l_name': 'Customer',
      'wallet_balance': saudi ? 100.0 : 200.0,
      'loyalty_point': saudi ? 10.0 : 20.0,
    }));
  }

  @override
  Future<dynamic> delete(int id) async => throw UnimplementedError();

  @override
  Future<dynamic> updateProfile(ProfileModel userInfoModel, String pass, File? file, String token) async => throw UnimplementedError();
}

/// E-04 criterion 3: a customer who moves to another storefront is never shown the wallet or the points of the one they left. What is held is
/// dropped before anything is asked, a signed-in customer's ledgers are asked for again for the storefront they are on, and an answer that
/// was on its way for the storefront they left is neither shown nor kept.
void main() {
  setUp(() => StorefrontScope.publish('SA'));
  tearDown(() => StorefrontScope.publish(null));

  group('the wallet', () {
    late _FakeWalletService service;
    late WalletController controller;

    setUp(() async {
      service = _FakeWalletService();
      controller = WalletController(walletServiceInterface: service);
      await controller.getTransactionList(1);
      await controller.getWalletBonusBannerList();
      controller.setSelectedProductType(type: 'debit');
      controller.setSelectedDate(
          startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 2, 1));
      service.ledgerAsked = 0;
      service.bonusesAsked = 0;
    });

    tearDown(() => controller.dispose());

    test('is the old storefront\'s before the change', () {
      expect(controller.walletTransactionModel?.totalWalletBalance, 100);
      expect(controller.walletBonusModel?.bonusList?.single.title, 'bonus of SA');
    });

    test('is gone at once, with the filters of the old ledger, before anything answers',
        () async {
      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_customerToEmirates);

      expect(controller.walletTransactionModel, isNull);
      expect(controller.walletBonusModel, isNull);
      expect(controller.selectedFilterBy, isNull);
      expect(controller.selectedEarnByList, isNull);
      expect(controller.startDate, isNull);
      expect(controller.endDate, isNull);

      await told;
    });

    test('of a customer is asked for again, and is the new storefront\'s when it has loaded',
        () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.ledgerAsked, 1);
      expect(service.bonusesAsked, 1);
      expect(controller.walletTransactionModel?.totalWalletBalance, 200);
      expect(controller.walletBonusModel?.bonusList?.single.title, 'bonus of AE');
    });

    test('of a guest is dropped and not asked for, because asking would sign the guest out',
        () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(service.ledgerAsked, 0);
      expect(service.bonusesAsked, 0);
      expect(controller.walletTransactionModel, isNull);
      expect(controller.walletBonusModel, isNull);
    });

    test('never shows an answer that was on its way when the customer moved on, however late it arrives',
        () async {
      final Completer<void> ledgerGate = Completer<void>();
      final Completer<void> bonusGate = Completer<void>();
      service.holdFirstLedger = ledgerGate;
      service.holdFirstBonuses = bonusGate;
      addTearDown(() {
        if (!ledgerGate.isCompleted) ledgerGate.complete();
        if (!bonusGate.isCompleted) bonusGate.complete();
      });

      final Future<void> asked = controller.getTransactionList(1);
      final Future<void> askedBonuses = controller.getWalletBonusBannerList();
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);
      expect(controller.walletTransactionModel?.totalWalletBalance, 200);
      expect(controller.walletBonusModel?.bonusList?.single.title, 'bonus of AE');

      // The answers for Saudi Arabia come last.
      ledgerGate.complete();
      bonusGate.complete();
      await asked;
      await askedBonuses;

      expect(controller.walletTransactionModel?.totalWalletBalance, 200);
      expect(controller.walletBonusModel?.bonusList?.single.title, 'bonus of AE');
    });

    test('keeps nothing of the old storefront when the answer of the old one is the only one that comes',
        () async {
      final Completer<void> hold = Completer<void>();
      service.holdFirstLedger = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      final Future<void> asked = controller.getTransactionList(1);
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      // The customer is on a storefront that has been told nothing yet: what comes back for SA is not theirs.
      hold.complete();
      await asked;

      expect(controller.walletTransactionModel, isNull);
    });
  });

  /// J-09: the account page holds the two balances as well, and it was the only holder in the app that was never told. A customer who moved
  /// from Kuwait to Riyadh saw the Saudi wallet on the wallet screen and a Kuwaiti figure on their account page, in a currency that was no
  /// longer the one being shown.
  group('the profile', () {
    late _FakeProfileService service;
    late ProfileController controller;

    setUp(() async {
      service = _FakeProfileService();
      controller = ProfileController(profileServiceInterface: service);
      await controller.getUserInfo();
      service.asked = 0;
    });

    tearDown(() => controller.dispose());

    test('is the old storefront\'s before the change', () {
      expect(controller.balance, 100);
      expect(controller.loyaltyPoint, 10);
      expect(controller.userID, '1');
    });

    test('is gone at once, before anything answers', () async {
      StorefrontScope.publish('AE');
      final Future<void> told = controller.onStorefrontChanged(_customerToEmirates);

      expect(controller.balance, isNull, reason: 'the money of the storefront the customer left is never on screen');
      expect(controller.userInfoModel, isNull);
      expect(controller.loyaltyPoint, 0);

      await told;
    });

    test('of a customer is asked for again, and is the new storefront\'s when it has loaded', () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.asked, 1);
      expect(controller.balance, 200);
      expect(controller.loyaltyPoint, 20);
      expect(controller.userID, '2');
    });

    test('of a guest is dropped and not asked for, because asking would sign the guest out', () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(service.asked, 0);
      expect(controller.balance, isNull);
    });

    test('that was never asked for is not asked for by a change of storefront', () async {
      final ProfileController untouched = ProfileController(profileServiceInterface: service);
      StorefrontScope.publish('AE');

      await untouched.onStorefrontChanged(_customerToEmirates);

      expect(service.asked, 0, reason: 'a change of storefront reloads what was on screen, and nothing else');
      untouched.dispose();
    });
  });

  group('the points', () {
    late _FakeLoyaltyPointService service;
    late LoyaltyPointController controller;

    setUp(() async {
      service = _FakeLoyaltyPointService();
      controller = LoyaltyPointController(loyaltyPointServiceInterface: service);
      await controller.getLoyaltyPointList(const _NoContext(), 1);
      controller.setSelectedProductType(type: 'earn');
      service.asked = 0;
    });

    tearDown(() => controller.dispose());

    test('are the old storefront\'s before the change', () {
      expect(controller.loyaltyPointModel?.totalLoyaltyPoint, 10);
    });

    test('are gone at once, with the filters of the old ledger, before anything answers',
        () async {
      StorefrontScope.publish('AE');
      final Future<void> told =
          controller.onStorefrontChanged(_customerToEmirates);

      expect(controller.loyaltyPointModel, isNull);
      expect(controller.selectedFilterBy, isNull);
      expect(controller.selectedEarnByList, isNull);
      expect(controller.startDate, isNull);
      expect(controller.endDate, isNull);

      await told;
    });

    test('of a customer are asked for again, and are the new storefront\'s when they have loaded',
        () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.asked, 1);
      expect(controller.loyaltyPointModel?.totalLoyaltyPoint, 20);
    });

    test('of a guest are dropped and not asked for, because asking would sign the guest out',
        () async {
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_guestToEmirates);

      expect(service.asked, 0);
      expect(controller.loyaltyPointModel, isNull);
    });

    test('never show an answer that was on its way when the customer moved on, however late it arrives',
        () async {
      final Completer<void> gate = Completer<void>();
      service.holdFirst = gate;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });

      final Future<void> asked =
          controller.getLoyaltyPointList(const _NoContext(), 1);
      await pumpEventQueue();
      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);
      expect(controller.loyaltyPointModel?.totalLoyaltyPoint, 20);

      // The answer for Saudi Arabia comes last.
      gate.complete();
      await asked;

      expect(controller.loyaltyPointModel?.totalLoyaltyPoint, 20);
    });
  });

  group('what the customer never asked for', () {
    test('is not asked for when they move to another storefront: the wallet and its bonuses', () async {
      final _FakeWalletService service = _FakeWalletService();
      final WalletController controller =
          WalletController(walletServiceInterface: service);
      addTearDown(controller.dispose);

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.ledgerAsked, 0);
      expect(service.bonusesAsked, 0);
      expect(controller.walletTransactionModel, isNull);
      expect(controller.walletBonusModel, isNull);
    });

    test('is not asked for when only the other half was: the ledger alone is loaded again, and the bonuses are not',
        () async {
      final _FakeWalletService service = _FakeWalletService();
      final WalletController controller =
          WalletController(walletServiceInterface: service);
      addTearDown(controller.dispose);
      await controller.getTransactionList(1);
      service.ledgerAsked = 0;

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.ledgerAsked, 1);
      expect(service.bonusesAsked, 0);
      expect(controller.walletTransactionModel?.totalWalletBalance, 200);
      expect(controller.walletBonusModel, isNull);
    });

    test('is not asked for when only the bonuses were: they are loaded again, and the ledger is not',
        () async {
      final _FakeWalletService service = _FakeWalletService();
      final WalletController controller =
          WalletController(walletServiceInterface: service);
      addTearDown(controller.dispose);
      await controller.getWalletBonusBannerList();
      service.bonusesAsked = 0;

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.ledgerAsked, 0);
      expect(service.bonusesAsked, 1);
      expect(controller.walletBonusModel?.bonusList?.single.title, 'bonus of AE');
      expect(controller.walletTransactionModel, isNull);
    });

    test('is not asked for when it is the points: a customer who never opened them makes no request for them',
        () async {
      final _FakeLoyaltyPointService service = _FakeLoyaltyPointService();
      final LoyaltyPointController controller =
          LoyaltyPointController(loyaltyPointServiceInterface: service);
      addTearDown(controller.dispose);

      StorefrontScope.publish('AE');
      await controller.onStorefrontChanged(_customerToEmirates);

      expect(service.asked, 0);
      expect(controller.loyaltyPointModel, isNull);
    });
  });

  group('with storefronts off', () {
    test('a ledger asked for while no storefront is published is kept as it always was',
        () async {
      StorefrontScope.publish(null);
      final _FakeWalletService service = _FakeWalletService();
      final WalletController controller =
          WalletController(walletServiceInterface: service);
      addTearDown(controller.dispose);

      await controller.getTransactionList(1);

      expect(controller.walletTransactionModel?.totalWalletBalance, 200);
    });
  });
}

/// A stand-in for the screen's context, which the points ledger takes and never reads.
class _NoContext implements BuildContext {
  const _NoContext();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
