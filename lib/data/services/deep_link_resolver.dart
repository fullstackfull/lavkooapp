import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// A link the shop has already turned into a screen.
///
/// [target] is the shop's vocabulary, not the app's: `home`, `product`, `brand`, `product_list`,
/// `order_tracking`, `web`. Mapping it to a route belongs to the screen that navigates, so the
/// vocabulary stays the one the API documents.
class ResolvedDeepLink {
  final String target;
  final String? parameter;

  /// What a slug parameter turned out to be, when the app's screen cannot open on a slug.
  /// Only the brand target fills it in today; null means the app must fall back.
  final int? subjectId;
  final String? subjectName;

  final String? webUrl;
  final Map<String, String> attribution;

  const ResolvedDeepLink({
    required this.target,
    this.parameter,
    this.subjectId,
    this.subjectName,
    this.webUrl,
    this.attribution = const {},
  });

  bool get isCampaign => attribution['campaign_code'] != null;

  factory ResolvedDeepLink.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'];
    final attribution = json['attribution'];

    return ResolvedDeepLink(
      target: '${json['target'] ?? 'web'}',
      parameter: json['parameter']?.toString(),
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
  static ResolvedDeepLink readLocally(Uri uri) {
    final segments =
    uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

    if (segments.isEmpty) {
      return const ResolvedDeepLink(target: 'home');
    }

    final parameter = segments.length > 1 ? segments[1] : null;

    return switch (segments.first) {
      'product' when parameter != null =>
          ResolvedDeepLink(target: 'product', parameter: parameter),
      'brand' when parameter != null =>
          ResolvedDeepLink(target: 'brand', parameter: parameter),
      'products' => const ResolvedDeepLink(target: 'product_list'),
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
          ResolvedDeepLink(target: 'order_tracking', parameter: parameter),
    // A short link is a code, not a destination: only the shop knows where it points.
      'go' => const ResolvedDeepLink(target: 'home'),
      _ => ResolvedDeepLink(target: 'web', webUrl: uri.toString()),
    };
  }
}