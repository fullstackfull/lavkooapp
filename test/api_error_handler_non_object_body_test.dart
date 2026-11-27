import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/datasource/remote/exception/api_error_handler.dart';

/// A refusal the API sends as a bare JSON string rather than as a JSON object.
///
/// Several v1 endpoints answer `response()->json(translate('...'), 403)` -- a bare string, not an object.
/// `ChatController::...` is one: `response()->json(translate('Invalid_Chatting_Type'), 403)`. The handler indexed that body
/// with `['errors']`, which on a String raises
///
///     type 'String' is not a subtype of type 'int' of 'index'
///
/// a TypeError, which the handler's own `catch` does not hold and which is raised from inside the CALLING repository's
/// `catch (e) { return ApiResponse.withError(ApiErrorHandler.getMessage(e)); }` -- so it escaped the repository
/// altogether. The customer was shown nothing, and whatever the caller does after the call never ran.
///
/// Measured before the fix, in this order: 403, 401, 400 all raised
/// `type 'String' is not a subtype of type 'int' of 'index'`, and a 502 raised
/// `type 'String' is not a subtype of type 'Map<String, dynamic>'`.
///
/// Every object-shaped answer is unchanged, which the group at the bottom pins alongside the file that already pins the
/// storefront refusal.
void main() {
  DioException answerOf(int statusCode, Object? body) {
    final RequestOptions request =
        RequestOptions(path: '/api/v1/customer/chat/send');

    return DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
          requestOptions: request, statusCode: statusCode, data: body),
    );
  }

  group('a refusal sent as a bare string', () {
    const String refusal = 'Invalid_Chatting_Type';

    test('on 403 reads as the sentence the server sent, and raises nothing',
        () {
      expect(ApiErrorHandler.getMessage(answerOf(403, refusal)), refusal);
    });

    test('on 400 reads as the sentence the server sent, and raises nothing',
        () {
      expect(ApiErrorHandler.getMessage(answerOf(400, refusal)), refusal);
    });

    test(
        'on a status with no case of its own reads as the sentence the server sent',
        () {
      expect(ApiErrorHandler.getMessage(answerOf(422, refusal)), refusal);
      expect(ApiErrorHandler.getMessage(answerOf(409, refusal)), refusal);
    });

    test('in Arabic reads as the server wrote it', () {
      const String arabic = 'نوع المحادثة غير صحيح';

      expect(ApiErrorHandler.getMessage(answerOf(403, arabic)), arabic);
    });
  });

  group('a body that is not an answer at all', () {
    test('an HTML page from a proxy is never put in front of the customer', () {
      for (final int status in <int>[400, 403, 502]) {
        final Object? shown = ApiErrorHandler.getMessage(answerOf(status,
            '<html><head><title>502 Bad Gateway</title></head></html>'));

        expect(shown, 'Failed to load data - status code: $status',
            reason: 'status $status');
        expect('$shown', isNot(contains('<')), reason: 'status $status');
      }
    });

    test(
        'an empty body falls back to the status line, as an unreadable answer always did',
        () {
      expect(ApiErrorHandler.getMessage(answerOf(403, '   ')),
          'Failed to load data - status code: 403');
    });

    test(
        'a list, which is neither an object nor a sentence, falls back to the status line',
        () {
      expect(ApiErrorHandler.getMessage(answerOf(403, <Object?>['a', 'b'])),
          'Failed to load data - status code: 403');
    });
  });

  group('every object-shaped answer reads exactly as it did', () {
    test('a 403 with a message', () {
      expect(
          ApiErrorHandler.getMessage(
              answerOf(403, <String, Object>{'message': 'address_not_found'})),
          'address_not_found');
    });

    test('a 403 with validation errors', () {
      final Object? shown =
          ApiErrorHandler.getMessage(answerOf(403, <String, Object>{
        'errors': <Object>[
          <String, Object>{
            'code': 'phone',
            'message': 'The phone field is required.'
          },
        ],
      }));

      expect(shown, 'The phone field is required.');
    });

    test('a 400 with a message', () {
      expect(
          ApiErrorHandler.getMessage(
              answerOf(400, <String, Object>{'message': 'coupon_expired'})),
          'coupon_expired');
    });

    test(
        'a 422 that is not one of the two refusals still reads as the status line',
        () {
      // Pinned in test/api_error_handler_storefront_test.dart too. Repeated here because the default branch is the one
      // this change touches, and a body that IS an object must come out of it unchanged.
      expect(
          ApiErrorHandler.getMessage(answerOf(
              422, <String, Object>{'message': 'The given data was invalid.'})),
          'Failed to load data - status code: 422');
    });

    test('a 502 with validation errors still answers the ErrorResponse itself',
        () {
      final Object? shown =
          ApiErrorHandler.getMessage(answerOf(502, <String, Object>{
        'errors': <Object>[
          <String, Object>{'code': 'x', 'message': 'y'},
        ],
      }));

      expect(shown, isNot(isA<String>()),
          reason: 'the default branch answers the object, not a sentence');
    });
  });
}
