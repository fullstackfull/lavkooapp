import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// The last list of storefronts the server answered with, kept so that a cold start with no network still knows which storefronts may
/// sell. It is read defensively: a value that is missing, is not text, is not JSON or is not the documented shape is no answer at all.
class StoredStorefronts {
  const StoredStorefronts(this._preferences);

  final SharedPreferences _preferences;

  /// The answer last read, kept so that reading it again does not decode and parse the same text afresh. It is read on every request's
  /// headers and behind every price the app writes, through the storefront a customer who has chosen none falls back to. The text itself is
  /// the key, so the list a saved answer gives is parsed once and an older one is never served: there is nothing to invalidate.
  static String? _parsedText;
  static List<StorefrontCountry> _parsedStorefronts =
      const <StorefrontCountry>[];

  List<StorefrontCountry> read() {
    final Object? stored = _preferences.get(AppConstants.storefrontList);
    if (stored is! String) {
      return const <StorefrontCountry>[];
    }

    if (stored == _parsedText) {
      return _parsedStorefronts;
    }

    final List<StorefrontCountry> storefronts = _parse(stored);
    _parsedText = stored;
    _parsedStorefronts = storefronts;

    return storefronts;
  }

  static List<StorefrontCountry> _parse(String stored) {
    try {
      return List<StorefrontCountry>.unmodifiable(
          StorefrontCountry.parseList(jsonDecode(stored)));
    } on FormatException {
      return const <StorefrontCountry>[];
    }
  }

  /// The stored entry for a country code, or null when the server's last answer did not list it.
  StorefrontCountry? find(String code) {
    final String normalizedCode = code.trim().toUpperCase();

    for (final StorefrontCountry storefront in read()) {
      if (storefront.code == normalizedCode) {
        return storefront;
      }
    }

    return null;
  }

  Future<bool> save(List<StorefrontCountry> storefronts) {
    return _preferences.setString(
      AppConstants.storefrontList,
      jsonEncode(<String, Object>{
        'storefronts':
            storefronts.map((storefront) => storefront.toJson()).toList(),
      }),
    );
  }
}
