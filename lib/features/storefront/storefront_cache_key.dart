/// How a cache that is not the HTTP cache files a row for a storefront.
///
/// The HTTP cache already ends its keys with the storefront (`ApiCacheKey`: `<path>?<query>#<language>#<code>`). The local database rows
/// follow the same rule so one ending means one thing: a key that ends with `#<code>` was filed for that storefront, and a key without
/// it was filed before storefronts existed.
class StorefrontCacheKey {
  const StorefrontCacheKey._();

  /// [key] as it is filed for [storefrontCode]. With no code, which is every build made without storefronts, it is [key] itself, so the
  /// rows already on a phone are still found and nothing is written under a new name. With a code it is [key] followed by `#<code>`: no
  /// storefront reads another's row, and a row filed without a code is never read while storefronts are on.
  static String scoped(String key, {required String? storefrontCode}) =>
      storefrontCode == null ? key : '$key#$storefrontCode';

  /// Whether [key] was filed for [storefrontCode] by [scoped].
  static bool isScopedTo(String key, {required String storefrontCode}) =>
      key.endsWith('#$storefrontCode');
}
