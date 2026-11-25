import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// A link the shop has already turned into a screen.
///
/// [target] is the shop's vocabulary, not the app's: `home`, `product`, `brand`, `product_list`,
/// `order_tracking`, `web`. Mapping it to a route belongs to the screen that navigates, so the
/// vocabulary stays the one the API documents.
class ResolvedDeepLink {
  final String target;
  final String? parameter;

  /// The storefront the link names, as a two-letter country code, or null when it names none
  /// (J-10, GCC-19).
  ///
  /// A six-market shop publishes its pages under a market's own path (`/ae/product/x`), and the app
  /// could not even see that such a link named a market: `readLocally` switched on the first
  /// segment, so `ae` was simply not a path it knew and the link fell through to the browser.
  ///
  /// Recorded and NOT acted on. What a link that names a market OTHER than the one the customer
  /// chose should do — switch to it, ask, or open as the market they are on — is the owner's
  /// decision, still open (axis J, J-10), and the plan's own rule is that a manual choice is never
  /// overridden by something inferred (plan line 189). So the customer stays where they chose to
  /// be, which is exactly what the app does today, and the market the link named is here for
  /// whoever implements that decision.
  final String? storefront;

  /// What a slug parameter turned out to be, when the app's screen cannot open on a slug.
  /// Only the brand target fills it in today; null means the app must fall back.
  final int? subjectId;
  final String? subjectName;

  final String? webUrl;
  final Map<String, String> attribution;

  const ResolvedDeepLink({
    required this.target,
    this.parameter,
    this.storefront,
    this.subjectId,
    this.subjectName,
    this.webUrl,
    this.attribution = const {},
  });

  bool get isCampaign => attribution['campaign_code'] != null;

  /// A storefront's own code, as the storefront list writes it, or null for anything that is not
  /// one of the six markets. Read from the server's answer and from a path segment alike, so one
  /// vocabulary decides both.
  static String? _storefrontCode(Object? value) {
    final String code = value is String ? value.trim().toUpperCase() : '';

    return StorefrontCountry.all.any((storefront) => storefront.code == code)
        ? code
        : null;
  }

  factory ResolvedDeepLink.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'];
    final attribution = json['attribution'];

    return ResolvedDeepLink(
      target: '${json['target'] ?? 'web'}',
      parameter: json['parameter']?.toString(),
      // The shop does not send this yet (`config/deeplinks.php` publishes unprefixed paths only).
      // Read anyway, so that the day it does, the app reads the market from the side that resolved
      // the link rather than from a path it parsed itself.
      storefront: _storefrontCode(json['storefront']),
      subjectId: subject is Map ? int.tryParse('${subject['id']}') : null,
      subjectName: subject is Map ? subject['name']?.toString() : null,
      webUrl: json['web_url']?.toString(),
      attribution: attribution is Map
          ? attribution.map((key, value) => MapEntry('$key', '$value'))
          : const {},
    );
  }
}

/// Asks the shop what an incoming link means.
///
/// The alternative — parsing the shop's URLs in the app — puts the routing rules in two codebases
/// and lets them drift in one. It also cannot follow a campaign short link: `/go/RMD26` is only a
/// screen after the server has looked the code up, and asking is what gets the tap counted against
/// the campaign that caused it.
///
/// The network is not allowed to swallow a link, so every failure falls back to reading the path
/// locally. That fallback covers the published paths and nothing else; a campaign code it cannot
/// resolve opens the home screen rather than a wrong one.
class DeepLinkResolver {
  final DioClient dioClient;

  const DeepLinkResolver({required this.dioClient});

  /// A tapped link has a person waiting behind it; a slow shop must not hold the screen.
  static const Duration _timeout = Duration(seconds: 6);

  Future<ResolvedDeepLink> resolve(Uri uri) async {
    try {
      final response = await dioClient.get(
        AppConstants.deepLinkResolveUri,
        queryParameters: {'url': uri.toString()},
      ).timeout(_timeout);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return ResolvedDeepLink.fromJson(data);
      }
    } catch (_) {
      // Falls through to the local reading below.
    }

    return readLocally(uri);
  }

  /// The offline reading of a link: the published paths, and nothing invented.
  ///
  /// [storefronts] is whether this build knows about markets at all, and defaults to the build's own
  /// switch, the way `OrderMarket` already takes it. While it is off a market's path is not a path
  /// this app knows, exactly as before: `/ae/product/x` is left to the browser rather than silently
  /// opening a product under whatever market the customer is on.
  static ResolvedDeepLink readLocally(Uri uri,
      {bool storefronts = StorefrontConfig.enabled}) {
    final segments =
    uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

    // A market's own path prefix (`/ae/product/x`), which the six-market web publishes and which
    // the app read as an unknown first segment. The rest of the path is then read exactly as the
    // unprefixed one is, so one reading serves both and a prefixed link can never mean something a
    // bare link does not.
    final String? storefront =
        storefronts && segments.isNotEmpty ? ResolvedDeepLink._storefrontCode(segments.first) : null;
    if (storefront != null) {
      segments.removeAt(0);
    }

    if (segments.isEmpty) {
      return ResolvedDeepLink(target: 'home', storefront: storefront);
    }

    final parameter = segments.length > 1 ? segments[1] : null;

    return switch (segments.first) {
      'product' when parameter != null => ResolvedDeepLink(
          target: 'product', parameter: parameter, storefront: storefront),
      'brand' when parameter != null => ResolvedDeepLink(
          target: 'brand', parameter: parameter, storefront: storefront),
      'products' =>
          ResolvedDeepLink(target: 'product_list', storefront: storefront),
    // An order id, and only an order id.
    //
    // This used to accept any second segment, and the shop serves `result`, `result-view`, `last`
    // and `order-wise-result-view` under this prefix — the order identifier travels in the QUERY
    // STRING, never as a path segment. So the Track Order button in the order-placed email, which
    // links to /track-order/result?order_id=..., opened the app on an order called "result".
    //
    // Narrowed rather than removed: a numeric segment is unambiguous, so a link that really does
    // carry an id still works, while every page under this prefix falls through to the web view
    // where its query string means something.
      'track-order' when parameter != null && int.tryParse(parameter) != null =>
          ResolvedDeepLink(
              target: 'order_tracking',
              parameter: parameter,
              storefront: storefront),
    // A short link is a code, not a destination: only the shop knows where it points.
      'go' => ResolvedDeepLink(target: 'home', storefront: storefront),
      _ => ResolvedDeepLink(
          target: 'web', webUrl: uri.toString(), storefront: storefront),
    };
  }
}