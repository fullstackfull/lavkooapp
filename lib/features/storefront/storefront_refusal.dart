/// The server's refusal to start an order or a payment in a storefront that may not sell yet: HTTP 422 with
/// `{"code": "storefront_not_sellable", "message": "..."}`. The message is already in the customer's language, because the server
/// writes it for the `lang` header every request carries.
class StorefrontRefusal {
  const StorefrontRefusal._();

  static const String code = 'storefront_not_sellable';

  /// The refusal's own message, or null when [body] is not that refusal. It never throws, whatever the body is.
  static String? messageOf(Object? body) {
    if (body is! Map || body['code'] != code) {
      return null;
    }

    final Object? message = body['message'];

    return message is String && message.trim().isNotEmpty ? message : null;
  }
}
