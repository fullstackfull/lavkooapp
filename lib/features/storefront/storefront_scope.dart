/// The storefront the app's requests are being made for right now: the code the `X-Storefront` header carries, and null while storefronts
/// are off, when the app has no storefront at all.
///
/// The HTTP client is the only one that writes it, whenever it builds its headers, so the answer is always the storefront a request that
/// starts now will ask for. That is not always the storefront the customer has chosen: between the choice being saved and the headers
/// being rebuilt, requests still ask for the previous one, and an answer has to be filed and judged by the storefront it was asked for.
///
/// Everything that keeps an answer for later (the local database rows, the controllers' lists) reads it from here, and nothing else asks
/// whether storefronts are on, so a build with them off sees `null` everywhere and behaves as it always did.
class StorefrontScope {
  const StorefrontScope._();

  static String? _current;

  static String? get current => _current;

  /// Whether the storefront the app is on now is [captured], the storefront read from [current] before an answer was asked for.
  ///
  /// False means the customer changed storefront while the answer was on its way: it belongs to the storefront they left, so it is
  /// neither shown nor kept. While storefronts are off both sides are null and this is always true.
  static bool isCurrent(String? captured) => captured == _current;

  /// Called by the HTTP client when it rebuilds its headers. Nothing else should call it, except a test that stands in for the client.
  static void publish(String? storefrontCode) {
    _current = storefrontCode;
  }
}
