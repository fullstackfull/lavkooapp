import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/checkout_sale_gate.dart';
import 'package:syriapharmacy/features/storefront/storefront_refusal.dart';

/// The cart, the checkout and the payment entry points ask the gate whether a sale may start in the storefront the customer is on,
/// and read the server's refusal through StorefrontRefusal. Neither knows anything else about storefronts.
void main() {
  group('a storefront that may sell', () {
    const gate = CheckoutSaleGate(storefrontMaySell: true);

    test('shows no browse-only notice', () {
      expect(gate.showsBrowseOnlyNotice, isFalse);
    });

    test('leaves a button as enabled as it was', () {
      expect(gate.permits(otherwiseEnabled: true), isTrue);
      expect(gate.permits(otherwiseEnabled: false), isFalse);
    });
  });

  group('a storefront that is browse-only', () {
    const gate = CheckoutSaleGate(storefrontMaySell: false);

    test('shows the browse-only notice', () {
      expect(gate.showsBrowseOnlyNotice, isTrue);
    });

    test('switches off a button that was enabled', () {
      expect(gate.permits(otherwiseEnabled: true), isFalse);
    });

    test('never switches on a button that was already off', () {
      expect(gate.permits(otherwiseEnabled: false), isFalse);
    });
  });

  group('the server\'s refusal', () {
    const String message = 'This storefront is not open for checkout yet.';

    test('gives its own message', () {
      expect(
        StorefrontRefusal.messageOf(
          <String, Object>{
            'code': 'storefront_not_sellable',
            'message': message
          },
        ),
        message,
      );
    });

    test('is the code the server sends', () {
      expect(StorefrontRefusal.code, 'storefront_not_sellable');
    });

    test('keeps a message in Arabic as it is', () {
      const String arabic = 'هذا المتجر غير متاح للشراء حتى الآن.';

      expect(
        StorefrontRefusal.messageOf(
          <String, Object>{
            'code': 'storefront_not_sellable',
            'message': arabic
          },
        ),
        arabic,
      );
    });

    test('is not any other error, even one with a message', () {
      for (final Object body in <Object>[
        <String, Object>{'code': 'other', 'message': message},
        <String, Object>{'message': message},
        <String, Object>{'code': 'STOREFRONT_NOT_SELLABLE', 'message': message},
        <String, Object>{
          'errors': <Object>[
            <String, Object>{
              'code': 'storefront_not_sellable',
              'message': message
            },
          ],
        },
      ]) {
        expect(StorefrontRefusal.messageOf(body), isNull, reason: '$body');
      }
    });

    test('is not read from a refusal that has no message to show', () {
      for (final Object? missing in <Object?>[null, '', '   ', 7, <Object>[]]) {
        expect(
          StorefrontRefusal.messageOf(
            <String, Object?>{
              'code': 'storefront_not_sellable',
              'message': missing
            },
          ),
          isNull,
          reason: 'message: $missing',
        );
      }
    });

    test('is not read from a body that is not an object, and never throws', () {
      for (final Object? body in <Object?>[
        null,
        'storefront_not_sellable',
        42,
        true,
        <Object>[],
        <Object>['storefront_not_sellable'],
      ]) {
        expect(StorefrontRefusal.messageOf(body), isNull, reason: '$body');
      }
    });
  });
}
