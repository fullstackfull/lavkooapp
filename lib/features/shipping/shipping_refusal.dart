/// The server's refusal to ship a basket to the address it is going to: HTTP 403 with
/// `{"message": "...", "reasons": ["...", "..."]}`.
///
/// Every reason, not the first one. A basket can be refused for several things at once -- a product that may not leave the country, a
/// second one no carrier will carry there, a third that needs a licence nobody has recorded -- and a customer told one of three fixes it,
/// is refused again, and fixes the next. The server sends them all for that reason, so the app shows them all.
///
/// The strings arrive already in the customer's language, because the server translates each reason for the `lang` header every request
/// carries. So there is nothing here to translate and no key to keep in step: a reason added on the server reaches the customer without
/// the app being released again.
class ShippingRefusal {
  const ShippingRefusal._();

  /// The refusal's reasons as one message, or null when [body] carries none. It never throws, whatever the body is.
  static String? messageOf(Object? body) {
    if (body is! Map) {
      return null;
    }

    final List<String> reasons = _reasonsOf(body['reasons']);

    if (reasons.isNotEmpty) {
      return reasons.join('\n');
    }

    return null;
  }

  /// @return the non-empty strings of [reasons], in the order the server sent them, with duplicates dropped.
  static List<String> _reasonsOf(Object? reasons) {
    if (reasons is! List) {
      return const <String>[];
    }

    final List<String> lines = <String>[];

    for (final Object? reason in reasons) {
      final String line = reason is String ? reason.trim() : '';

      if (line.isNotEmpty && !lines.contains(line)) {
        lines.add(line);
      }
    }

    return lines;
  }
}
