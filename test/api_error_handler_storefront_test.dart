import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';

/// The server's refusal to start a sale in a storefront that may not sell yet reaches the customer as its own message. Every other
/// answer reads exactly as it did before.
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

  group('the refusal of a storefront that may not sell yet', () {
    const String message = 'This storefront is not open for checkout yet.';

    test('is shown as the server wrote it', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(
        422,
        <String, Object>{'code': 'storefront_not_sellable', 'message': message},
      ));

      expect(shown, message);
    });

    test('is shown in Arabic as the server wrote it', () {
      const String arabic = 'هذا المتجر غير متاح للشراء حتى الآن.';

      final Object? shown = ApiErrorHandler.getMessage(answerOf(
        422,
        <String, Object>{'code': 'storefront_not_sellable', 'message': arabic},
      ));

      expect(shown, arabic);
    });

    test('is not mistaken for a payment that was not set up', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(
        422,
        <String, Object>{'code': 'storefront_not_sellable', 'message': message},
      ));

      expect(shown, isNot(contains('status code')));
    });
  });

  group('every other answer', () {
    test('a 422 that is not the refusal still reads as it did', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(
        422,
        <String, Object>{'message': 'The given data was invalid.'},
      ));

      expect(shown, 'Failed to load data - status code: 422');
    });

    test('a 422 with a different code still reads as it did', () {
      final Object? shown = ApiErrorHandler.getMessage(answerOf(
        422,
        <String, Object>{'code': 'other', 'message': 'Something else.'},
      ));

      expect(shown, 'Failed to load data - status code: 422');
    });

    test('a 403 still shows its own message', () {
      final Object? shown = ApiErrorHandler.getMessage(
        answerOf(403, <String, Object>{'message': 'address_not_found'}),
      );

      expect(shown, 'address_not_found');
    });

    test('a connection that timed out still reads as it did', () {
      final RequestOptions request = RequestOptions(path: '/api/v1/config');

      final Object? shown = ApiErrorHandler.getMessage(DioException(
        requestOptions: request,
        type: DioExceptionType.connectionTimeout,
      ));

      expect(shown, 'Connection timeout with API server');
    });

    test('an error that is not a Dio error still reads as it did', () {
      expect(ApiErrorHandler.getMessage(const FormatException('bad')),
          'Unexpected error occured');
    });
  });
}
