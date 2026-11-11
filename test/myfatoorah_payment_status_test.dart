import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/checkout/domain/models/myfatoorah_payment_status.dart';

/// What the app is allowed to conclude from a payment status.
///
/// The bug these guard against: the screen used to decide a payment had succeeded because the redirect
/// URL contained the substring `success`. The outcome now comes from the server, and the three states
/// have to stay strictly apart — above all the third, because telling a customer whose money has gone
/// that their payment failed is the worst thing this screen can do.
void main() {
  group('MyFatoorahPaymentStatus parsing', () {
    test('a paid payment is final and paid', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'reference': 'pk-abc-1',
        'status': 'paid',
        'is_final': true,
        'paid': true,
        'amount': '150.00',
        'currency': 'SAR',
        'order_ids': [12, 13],
        'message_key': 'payment_successful',
      });

      expect(status.paid, isTrue);
      expect(status.isFinal, isTrue);
      expect(status.isUnresolved, isFalse);
      expect(status.isDefiniteFailure, isFalse);
      expect(status.orderIds, [12, 13]);
      expect(status.amount, '150.00');
      expect(status.currency, 'SAR');
    });

    test('a failed payment is a definite failure', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'reference': 'pk-abc-1',
        'status': 'failed',
        'is_final': true,
        'paid': false,
      });

      expect(status.isDefiniteFailure, isTrue);
      expect(status.paid, isFalse);
      expect(status.isUnresolved, isFalse);
    });

    test('cancelled and expired are definite failures too', () {
      for (final state in ['cancelled', 'expired']) {
        final status = MyFatoorahPaymentStatus.fromJson({
          'status': state,
          'is_final': true,
          'paid': false,
        });

        expect(status.isDefiniteFailure, isTrue, reason: '$state should be a definite failure');
      }
    });

    test('pending is unresolved and must never read as a failure', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'status': 'pending',
        'is_final': false,
        'paid': false,
      });

      expect(status.isUnresolved, isTrue);
      expect(status.isDefiniteFailure, isFalse, reason: 'the customer may already have paid');
      expect(status.paid, isFalse);
    });

    test('confirming is unresolved: paid at the gateway, order not yet created', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'status': 'confirming',
        'is_final': false,
        'paid': false,
      });

      expect(status.isUnresolved, isTrue);
      expect(status.isDefiniteFailure, isFalse);
    });

    test('a status the app does not know is unresolved, not a failure', () {
      // Forward compatibility: a server that grows a new state must not make the app claim failure.
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'status': 'something_new',
        'is_final': false,
        'paid': false,
      });

      expect(status.isUnresolved, isTrue);
      expect(status.isDefiniteFailure, isFalse);
    });

    test('a final status the app does not know is still not a failure', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'status': 'something_new',
        'is_final': true,
        'paid': false,
      });

      expect(status.isDefiniteFailure, isFalse, reason: 'only named failures may be shown as failures');
    });

    test('paid is only trusted when the server says so, not when a status string looks successful', () {
      // `paid` is a separate flag on purpose. The server sets it only once the order exists.
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'status': 'paid',
        'is_final': true,
        'paid': false,
      });

      expect(status.paid, isFalse);
    });

    test('a junk or empty body parses to something safe rather than throwing', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {});

      expect(status.status, 'pending');
      expect(status.paid, isFalse);
      expect(status.isFinal, isFalse);
      expect(status.isUnresolved, isTrue);
      expect(status.isDefiniteFailure, isFalse);
      expect(status.orderIds, isEmpty);
      expect(status.messageKey, 'payment_is_being_processed');
    });

    test('order ids that are not usable integers are dropped, not crashed on', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {
        'order_ids': [7, '8', 'not-a-number', null, 0, -3],
      });

      expect(status.orderIds, [7, 8]);
    });

    test('a non-list order_ids is tolerated', () {
      final status = MyFatoorahPaymentStatus.fromJson(const {'order_ids': 'nope'});

      expect(status.orderIds, isEmpty);
    });

    test('the unresolved fallback is never a failure and keeps the reference', () {
      final status = MyFatoorahPaymentStatus.unresolved('pk-xyz-2');

      expect(status.reference, 'pk-xyz-2');
      expect(status.isUnresolved, isTrue);
      expect(status.isDefiniteFailure, isFalse);
      expect(status.paid, isFalse);
    });
  });
}
