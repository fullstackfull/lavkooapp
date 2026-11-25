import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/shipping/customs_duty.dart';

/// What the shop answers at `/api/v1/cart/customs-duty`, and what the checkout screen may say about it (H1-09).
///
/// The reading that matters is the difference between `none` and `not_quoted`. A zero in the second place would say the goods cross free,
/// which is a claim the shop has not made: nobody has written a duty rule for that route, so the customer is told so in the shop's own
/// words. A screen that showed "0.00" there would be the app inventing the answer.
///
/// The amounts come back as numbers and PHP writes a whole float without its decimal point, so 5.0 arrives as `5`. They are read as
/// numbers for that reason, never cast to double.
void main() {
  group('the quote the shop sends', () {
    test('an amount payable by the buyer, with the sentence that says so', () {
      final CustomsDuty? duty = CustomsDuty.fromBody(jsonDecode(
        '{"customs_duty":{"kind":"payable","amount":5,"payer":"buyer_on_delivery","basis":100,"route":"SA:KW",'
        '"notice":"Customs duty is paid by you when the parcel is delivered."}}',
      ));

      expect(duty, isNotNull);
      expect(duty!.kind, CustomsDuty.payable);
      expect(duty.isPayable, isTrue);
      expect(duty.amount, 5);
      expect(duty.basis, 100);
      expect(duty.payer, 'buyer_on_delivery');
      expect(duty.notice, 'Customs duty is paid by you when the parcel is delivered.');
    });

    test('a third decimal survives, because a dinar has one', () {
      final CustomsDuty? duty = CustomsDuty.fromBody(jsonDecode('{"customs_duty":{"kind":"payable","amount":5.751,"basis":115.025}}'));

      expect(duty!.amount, 5.751);
      expect(duty.basis, 115.025);
    });

    test('a route nobody has a rule for is not quoted, and that is not nothing payable', () {
      final CustomsDuty? duty = CustomsDuty.fromBody(jsonDecode(
        '{"customs_duty":{"kind":"not_quoted","amount":0,"payer":null,"basis":0,'
        '"notice":"Customs duty has not been quoted for this country."}}',
      ));

      expect(duty!.kind, CustomsDuty.notQuoted);
      expect(duty.isPayable, isFalse);
      expect(duty.notice, 'Customs duty has not been quoted for this country.');
    });

    test('nothing payable needs no sentence', () {
      final CustomsDuty? duty = CustomsDuty.fromBody(jsonDecode('{"customs_duty":{"kind":"none","amount":0,"notice":null}}'));

      expect(duty!.kind, CustomsDuty.none);
      expect(duty.notice, isNull);
    });

    test('an Arabic sentence is read as the server wrote it', () {
      final CustomsDuty? duty = CustomsDuty.fromBody(jsonDecode(
        '{"customs_duty":{"kind":"payable","amount":5,"notice":"تُدفع الرسوم الجمركية منك عند تسليم الشحنة."}}',
      ));

      expect(duty!.notice, 'تُدفع الرسوم الجمركية منك عند تسليم الشحنة.');
    });

    test('a basket that crosses no border says nothing at all, and the screen draws no row', () {
      for (final Object? body in <Object?>[
        null,
        'a string',
        <String, Object?>{},
        <String, Object?>{'customs_duty': null},
        <String, Object?>{'customs_duty': 'not a map'},
        <String, Object?>{'customs_duty': <String, Object?>{'kind': ''}},
      ]) {
        expect(CustomsDuty.fromBody(body), isNull);
      }
    });
  });
}
