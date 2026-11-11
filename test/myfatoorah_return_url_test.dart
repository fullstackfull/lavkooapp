import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/checkout/domain/services/myfatoorah_payment_service.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Recognising the customer coming back from MyFatoorah, and nothing else.
///
/// This replaced the substring test that decided a payment had succeeded because the URL contained
/// `success`. The rule now is narrow on purpose: only our own callback on our own host counts, and all
/// it does is yield the reference to ask the server about. A payment page is free to contain links with
/// any path it likes, so matching on the path alone would let the gateway's own content end a payment
/// early — and matching on a word like `success` would let anything at all.
void main() {
  final String host = Uri.parse(AppConstants.baseUrl).host;

  group('isMyFatoorah', () {
    test('recognises the gateway keys the backend may send', () {
      for (final key in ['fatoorah', 'my_fatoorah', 'myfatoorah', 'FATOORAH', ' Fatoorah ']) {
        expect(MyFatoorahPaymentService.isMyFatoorah(key), isTrue, reason: key);
      }
    });

    test('does not claim other gateways or nothing at all', () {
      for (final key in [null, '', 'paytabs', 'stripe', 'fatoora', 'myfatoorah2']) {
        expect(MyFatoorahPaymentService.isMyFatoorah(key), isFalse, reason: key ?? 'null');
      }
    });
  });

  group('referenceFromUrl', () {
    test('takes the reference off our callback', () {
      final url = 'https://$host/payment/myfatoorah/callback?reference=pk-abc-1&paymentId=99';

      expect(MyFatoorahPaymentService.referenceFromUrl(url), 'pk-abc-1');
      expect(MyFatoorahPaymentService.isReturnUrl(url), isTrue);
    });

    test('accepts the legacy fatoorah path and the pending page', () {
      for (final path in [
        '/payment/fatoorah/callback',
        '/payment/myfatoorah/pending',
        '/payment/fatoorah/pending',
      ]) {
        final url = 'https://$host$path?reference=pk-abc-1';

        expect(MyFatoorahPaymentService.referenceFromUrl(url), 'pk-abc-1', reason: path);
      }
    });

    test('a callback on another host is not ours', () {
      // The decisive case: anything that can navigate the WebView could otherwise end the payment.
      const url = 'https://evil.example.com/payment/myfatoorah/callback?reference=pk-abc-1';

      expect(MyFatoorahPaymentService.referenceFromUrl(url), isNull);
      expect(MyFatoorahPaymentService.isReturnUrl(url), isFalse);
    });

    test('a word that merely looks successful is not a return', () {
      // What the old code reacted to.
      for (final url in [
        'https://sa.myfatoorah.com/KSA/ie/0101?status=success&token=abc',
        'https://$host/payment-success?token=abc',
        'https://$host/payment-fail?token=abc',
        'https://$host/some/page?cancel=1',
      ]) {
        expect(MyFatoorahPaymentService.isReturnUrl(url), isFalse, reason: url);
      }
    });

    test('our callback without a reference is not actionable', () {
      final url = 'https://$host/payment/myfatoorah/callback?paymentId=99';

      expect(MyFatoorahPaymentService.referenceFromUrl(url), isNull);
      expect(MyFatoorahPaymentService.isReturnUrl(url), isFalse);
    });

    test('an empty or whitespace reference is not actionable', () {
      for (final query in ['reference=', 'reference=%20%20']) {
        final url = 'https://$host/payment/myfatoorah/callback?$query';

        expect(MyFatoorahPaymentService.referenceFromUrl(url), isNull, reason: query);
      }
    });

    test('the gateway page itself is never mistaken for a return', () {
      for (final url in [
        'https://sa.myfatoorah.com/KSA/ie/0101',
        'https://demo.myfatoorah.com/KWT/ie/0202',
        'https://sa.myfatoorah.com/payment/myfatoorah/callback?reference=pk-abc-1',
      ]) {
        expect(MyFatoorahPaymentService.isReturnUrl(url), isFalse, reason: url);
      }
    });

    test('a relative callback is treated as ours, since a WebView resolves it against our host', () {
      expect(
        MyFatoorahPaymentService.referenceFromUrl('/payment/myfatoorah/callback?reference=pk-rel-1'),
        'pk-rel-1',
      );
    });

    test('junk and non-http schemes do not throw', () {
      for (final url in [
        '',
        'not a url at all',
        '::::',
        'stcpay://pay?token=abc',
        'intent://scan/#Intent;scheme=upi;end',
      ]) {
        expect(() => MyFatoorahPaymentService.referenceFromUrl(url), returnsNormally, reason: url);
        expect(MyFatoorahPaymentService.isReturnUrl(url), isFalse, reason: url);
      }
    });

    test('the reference is read from the query, not from anywhere else in the URL', () {
      final url = 'https://$host/payment/myfatoorah/callback?paymentId=pk-not-this&reference=pk-this-1';

      expect(MyFatoorahPaymentService.referenceFromUrl(url), 'pk-this-1');
    });
  });
}
