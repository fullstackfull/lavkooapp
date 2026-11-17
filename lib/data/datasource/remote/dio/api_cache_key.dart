/// The key a cached GET answer is filed under, in memory and, behind the `api_cache_` prefix, on disk.
///
/// The key holds what the server's answer depends on, so an answer fetched for one reader is never handed to another: the path and the
/// query, the language of the `lang` header and, while storefronts are on, the storefront of the `X-Storefront` header. The query
/// parameters are sorted, so the same request asked with its parameters in another order shares one entry.
class ApiCacheKey {
  const ApiCacheKey._();

  /// [storefrontCode] is null while storefronts are off, and the key is then exactly the one this app built before storefronts
  /// existed, so every answer already cached on a phone stays valid. With a code the key is that same key followed by `#<code>`: no
  /// storefront reads another's answer, and an answer filed without a code is never read while storefronts are on.
  static String build({
    required String uri,
    required String languageCode,
    Map<String, dynamic>? queryParameters,
    String? storefrontCode,
  }) {
    final String scope =
        storefrontCode == null ? languageCode : '$languageCode#$storefrontCode';

    try {
      final parsedUri = Uri.parse(uri);
      final queryMap = <String, String>{};

      parsedUri.queryParameters.forEach((key, value) {
        if (value.isNotEmpty) queryMap[key] = value;
      });

      if (queryParameters != null) {
        queryParameters.forEach((key, value) {
          if (value != null) queryMap[key] = value.toString();
        });
      }

      final sortedKeys = queryMap.keys.toList()..sort();
      final sortedParams = sortedKeys.map((k) => '$k=${queryMap[k]}').join('&');

      final baseKey = sortedParams.isEmpty
          ? parsedUri.path
          : '${parsedUri.path}?$sortedParams';
      return '$baseKey#$scope';
    } catch (_) {
      return '${uri + (queryParameters?.toString() ?? '')}#$scope';
    }
  }
}
