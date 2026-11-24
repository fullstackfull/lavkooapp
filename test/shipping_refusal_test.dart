import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';
import 'package:syriapharmacy/features/shipping/shipping_refusal.dart';

/// A basket refused for where it is going reaches the customer as every reason it was refused for (H1-04, H1-06).
///
/// The server answers 403 with a `reasons` list, each line already in the customer's language -- it translates them for the `lang` header
/// every request carries. A customer told one of three problems fixes it, is refused again, and fixes the next; so the app shows them all.
/// Without this the 403 reads "Failed to load data - status code: 403", which tells a shopper nothing they can act on.
void main() {
  DioException answerOf(int statusCode, Object? body) {
    final RequestOptions request =
        RequestOptions(path: '/api/v1/customer/order/place');

    return DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: request,
        statusCode: statusCode,
        data: body,
      ),
    );
  }

  group('reading the reasons', () {
    test('every reason is shown, in the order the server sent them', () {
      expect(
        ShippingRefusal.messageOf(<String, Object>{
          'message': 'This product is not permitted to be shipped to that country.',
          'reasons': <String>[
            'This product is not permitted to be shipped to that country.',
            'No carrier serves the route to that country.',
          ],
        }),
        'This product is not permitted to be shipped to that country.\n'
        'No carrier serves the route to that country.',
      );
    });

    test('Arabic reasons are shown as the server wrote them', () {
      expect(
        ShippingRefusal.messageOf(<String, Object>{
          'reasons': <String>['لا يوجد ناقل يخدم الخط إلى ذلك البلد.'],
        }),
        'لا يوجد ناقل يخدم الخط إلى ذلك البلد.',
      );
    });

    test('the same reason twice is shown once', () {
      expect(
        ShippingRefusal.messageOf(<String, Object>{
          'reasons': <String>['One reason.', 'One reason.'],
        }),
        'One reason.',
      );
    });

    test('blank and non-string entries are dropped', () {
      expect(
        ShippingRefusal.messageOf(<String, Object?>{
          'reasons': <Object?>['  A reason.  ', '   ', null, 7],
        }),
        'A reason.',
      );
    });

    test('a body with no reasons is not this refusal', () {
      for (final Object? body in <Object?>[
        null,
        'a string',
        <String, Object?>{'message': 'Something else went wrong.'},
        <String, Object?>{'reasons': <Object?>[]},
        <String, Object?>{'reasons': 'not a list'},
      ]) {
        expect(ShippingRefusal.messageOf(body), isNull);
      }
    });
  });

  group('through the error handler every other answer reads as before', () {
    test('the reasons reach the customer', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(403, <String, Object>{
        'message': 'This product is regulated and needs a recorded clearance for that country before it can be shipped there.',
        'reasons': <String>[
          'This product is regulated and needs a recorded clearance for that country before it can be shipped there.',
        ],
      }));

      expect(shown, 'This product is regulated and needs a recorded clearance for that country before it can be shipped there.');
    });

    test('a storefront refusal still wins, because it is the older and more specific one', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(422, <String, Object>{
        'code': 'storefront_not_sellable',
        'message': 'This storefront is not open for checkout yet.',
        'reasons': <String>['ignored'],
      }));

      expect(shown, 'This storefront is not open for checkout yet.');
    });

    test('an ordinary 403 still reads as its own message', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(403, <String, Object>{'message': 'cart_is_empty'}));

      expect(shown, 'cart_is_empty');
    });
  });
}
