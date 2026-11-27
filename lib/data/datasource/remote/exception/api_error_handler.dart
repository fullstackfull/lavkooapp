import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:syriapharmacy/data/model/error_response.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/shipping/shipping_refusal.dart';
import 'package:syriapharmacy/features/storefront/storefront_refusal.dart';
import 'package:syriapharmacy/main.dart';
import 'package:provider/provider.dart';

class ApiErrorHandler {
  /// The sentence an answer that is NOT a JSON object carries, or null when it
  /// carries none.
  ///
  /// Several v1 endpoints answer `response()->json('some sentence', 403)`,
  /// which is a bare JSON string and not an object -- a refused chat type is
  /// one. A page is deliberately not a sentence: an HTML error page from a
  /// proxy in front of the API is not something to put in front of a customer,
  /// so it falls back to the status line the app has always shown.
  static String? _textOfANonObjectBody(dynamic body) {
    if (body is! String) {
      return null;
    }

    final String text = body.trim();

    return text.isEmpty || text.startsWith('<') ? null : text;
  }

  /// Did this error mean the request never got an answer, as opposed to being refused?
  ///
  /// The distinction matters wherever a retry is not free. A 403 is the server saying no, and the
  /// customer may try again. A timeout says nothing at all: the order may exist, the payment may
  /// have gone through, and the honest thing to tell the customer is that we do not know yet.
  ///
  /// `unknown` is included because Dio reports a socket failure with no response that way.
  static bool neverAnswered(dynamic error) {
    if (error is! DioException) return false;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.cancel:
        return true;
      case DioExceptionType.unknown:
        return error.response == null;
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  static dynamic getMessage(dynamic error) {
    dynamic errorDescription = "";
    if (error is Exception) {
      try {
        if (error is DioException) {
          // A storefront that may not sell yet refuses with a 422 and its own message, which is already in the customer's language.
          // Without this the 422 reads "Failed to load data - status code: 422".
          final String? storefrontRefusal =
              StorefrontRefusal.messageOf(error.response?.data);
          if (storefrontRefusal != null) {
            return storefrontRefusal;
          }

          // A basket refused for where it is going answers 403 with every reason it was refused for, each already in the customer's
          // language. Without this the customer reads "Failed to load data - status code: 403" and is told nothing they can act on.
          final String? shippingRefusal =
              ShippingRefusal.messageOf(error.response?.data);
          if (shippingRefusal != null) {
            return shippingRefusal;
          }

          switch (error.type) {
            case DioExceptionType.cancel:
              errorDescription = "Request to API server was cancelled";
              break;
            case DioExceptionType.connectionTimeout:
              errorDescription = "Connection timeout with API server";
              break;
            case DioExceptionType.sendTimeout:
              errorDescription = "Send timeout";
              break;
            case DioExceptionType.receiveTimeout:
              errorDescription =
                  "Receive timeout in connection with API server";
              break;
            case DioExceptionType.badResponse:
              switch (error.response!.statusCode) {
                case 403:
                  // A refusal is not always a JSON object. Several v1
                  // endpoints answer `response()->json(translate('...'), 403)`
                  // -- a bare JSON string -- and indexing a String with
                  // 'errors' raises a TypeError, which the catch below does not
                  // hold and which is raised from inside the calling
                  // repository's own catch block, so it escaped the repository
                  // and the customer was shown nothing at all. An object is
                  // read exactly as it always was.
                  if (error.response!.data is! Map) {
                    errorDescription = _textOfANonObjectBody(
                            error.response!.data) ??
                        "Failed to load data - status code: ${error.response!.statusCode}";
                  } else if (error.response!.data['errors'] != null) {
                    ErrorResponse errorResponse =
                        ErrorResponse.fromJson(error.response?.data);
                    errorDescription = errorResponse.errors?[0].message;
                  } else {
                    errorDescription = error.response!.data['message'];
                  }

                  if (kDebugMode) {
                    print(
                        "=================403=============>>$errorDescription");
                  }

                  break;
                case 401:
                  if (error.response!.data['errors'] != null) {
                    ErrorResponse errorResponse =
                        ErrorResponse.fromJson(error.response?.data);
                    errorDescription = errorResponse.errors?[0].message;
                  } else {
                    errorDescription = error.response!.data['message'];
                  }
                  Provider.of<AuthController>(Get.context!, listen: false)
                      .clearSharedData();
                  break;
                case 404:
                  break;
                case 400:
                  // As 403 above: a body that is not an object used to throw
                  // out of the repository.
                  if (error.response!.data is! Map) {
                    errorDescription = _textOfANonObjectBody(
                            error.response!.data) ??
                        "Failed to load data - status code: ${error.response!.statusCode}";
                  } else if (error.response!.data['errors'] != null) {
                    ErrorResponse errorResponse =
                        ErrorResponse.fromJson(error.response?.data);
                    errorDescription = errorResponse.errors?[0].message;
                  } else {
                    errorDescription = error.response?.data['message'] ?? '';
                  }
                  break;
                case 500:
                  if (kDebugMode) {
                    print(
                        "-----------500------------->>${error.response!.data}");
                  }
                  errorDescription = 'Internal server error';
                case 503:
                  if (error.response!.data['message'] != null) {
                    errorDescription = error.response!.data['message'];
                  }
                case 429:
                  errorDescription = error.response!.statusMessage;
                  break;
                default:
                  // The statuses with no case of their own -- a 422 from
                  // anywhere but the two refusals read at the top, a 502 page
                  // from a proxy in front of the API. An object reads exactly
                  // as it always did, including the "Failed to load data"
                  // sentence for one with no `errors`; a body that is not an
                  // object used to throw out of the repository instead.
                  if (error.response!.data is! Map) {
                    errorDescription = _textOfANonObjectBody(
                            error.response!.data) ??
                        "Failed to load data - status code: ${error.response!.statusCode}";
                    break;
                  }

                  ErrorResponse errorResponse =
                      ErrorResponse.fromJson(error.response!.data);
                  if (errorResponse.errors != null &&
                      errorResponse.errors!.isNotEmpty) {
                    errorDescription = errorResponse;
                  } else {
                    errorDescription =
                        "Failed to load data - status code: ${error.response!.statusCode}";
                  }
              }
              break;
            case DioExceptionType.badCertificate:
              // TODO: Handle this case.
              break;
            case DioExceptionType.connectionError:
              // TODO: Handle this case.
              break;
            case DioExceptionType.unknown:
              errorDescription = "Request to API call limit excited ";
              break;
          }
        } else {
          errorDescription = "Unexpected error occured";
        }
      } on FormatException catch (e) {
        errorDescription = e.toString();
      }
    } else {
      errorDescription = "is not a subtype of exception";
    }
    return errorDescription;
  }
}
