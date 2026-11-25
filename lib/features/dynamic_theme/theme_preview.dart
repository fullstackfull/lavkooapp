/// The unpublished draft a merchant asked to see on a real phone (J-V1, GCC-07).
///
/// The theme builder's phone frame is a browser drawing an approximation. What a merchant wants to
/// know before publishing — whether the images crop right on a real screen, whether the Arabic
/// wraps, whether the rail is reachable with a thumb — only the app can answer, and the app only
/// ever saw what was published. So the choice was publish and look, or do not look.
///
/// The backend closed its half a while ago and nothing here could talk to it: `ThemePreviewToken`
/// signs one unpublished version for one hour with the application key, `GET
/// /api/v1/theme/home?preview=TOKEN` answers that version marked `preview: true`, with
/// `Cache-Control: no-store` and no ETag, and a token that is expired, forged, or minted for
/// another storefront's theme is ignored and the published page served instead. The token is
/// opaque here: this app neither reads it nor could forge one, and the server decides every time
/// whether it still means anything.
///
/// Held in one ambient place rather than threaded through the theme interfaces, which is how
/// `StorefrontScope` already carries the other fact a theme request is made under. A token lives
/// for as long as the merchant is looking at the draft and is never written to disk: a preview is
/// one look at somebody's unfinished work, not a state the app comes back up in.
class ThemePreview {
  const ThemePreview._();

  /// The key the builder's own minted link already carries (`?theme_preview=…`, read by
  /// `StorefrontThemeRenderer` on the website), so one link works in a browser and in the app.
  static const String linkKey = 'theme_preview';

  /// The key the theme endpoint reads it under.
  static const String requestKey = 'preview';

  /// Off in every build that does not ask for it: a build without the define accepts no token at
  /// all, so nothing about its theme requests, its cache or its screens can move.
  static const bool enabledInThisBuild =
      bool.fromEnvironment('GCC_THEME_PREVIEW_ENABLED', defaultValue: false);

  static String? _token;

  /// The token the theme requests carry, or null while the app is asking for the published page.
  static String? get token => _token;

  static bool get isAskingForADraft => _token != null;

  /// The token a link carries, or null when it carries none: a link with no such key, an empty
  /// one, and a link this app could not read.
  static String? tokenIn(Uri uri) => _usable(uri.queryParameters[linkKey]);

  /// Start asking for the draft [token] names. False, and nothing held, when this build accepts no
  /// token or there is no token to hold — in which case the published page goes on being asked for,
  /// which is what every build does today.
  static bool show(String? token, {bool enabled = enabledInThisBuild}) {
    final String? usable = enabled ? _usable(token) : null;
    if (usable == null) {
      return false;
    }

    _token = usable;

    return true;
  }

  /// Stop asking for a draft and go back to the published page.
  static void stop() {
    _token = null;
  }

  static String? _usable(String? token) {
    final String trimmed = token?.trim() ?? '';

    return trimmed.isEmpty ? null : trimmed;
  }
}
