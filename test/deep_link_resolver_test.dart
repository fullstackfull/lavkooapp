import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/services/deep_link_resolver.dart';

/// A tapped link must open something, network or no network.
///
/// The shop's answer is the one that matters — it is the only side that can follow a campaign code
/// or turn a brand slug into the id the app's screen opens with. These cover the two halves the app
/// owns: reading the shop's answer, and what happens when there is no answer to read.
void main() {
  group('the shop answered', () {
    test('a brand link arrives with the id the brand screen needs', () {
      final link = ResolvedDeepLink.fromJson(const {
        'resolved': true,
        'target': 'brand',
        'parameter': 'panadol',
        'subject': {'id': 12, 'name': 'Panadol'},
        'web_url': 'https://shop.test/brand/panadol',
        'attribution': <String, dynamic>{},
      });

      expect(link.target, 'brand');
      expect(link.subjectId, 12);
      expect(link.subjectName, 'Panadol');
      expect(link.isCampaign, isFalse);
    });

    test('a campaign short link carries its attribution to the screen', () {
      final link = ResolvedDeepLink.fromJson(const {
        'target': 'product',
        'parameter': 'vitamin-c-1000',
        'subject': null,
        'attribution': {'utm_source': 'instagram', 'campaign_code': 'rmd26'},
      });

      expect(link.target, 'product');
      expect(link.parameter, 'vitamin-c-1000');
      expect(link.isCampaign, isTrue);
      expect(link.attribution['utm_source'], 'instagram');
    });

    test('a payload with nothing in it still produces a usable link', () {
      final link = ResolvedDeepLink.fromJson(const {});

      expect(link.target, 'web', reason: 'the safe default opens the browser');
      expect(link.parameter, isNull);
      expect(link.subjectId, isNull);
      expect(link.attribution, isEmpty);
    });
  });

  group('the shop could not be reached', () {
    test('the published paths are read locally', () {
      expect(DeepLinkResolver.readLocally(Uri.parse('https://shop.test/')).target,
          'home');
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/product/vitamin-c')),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'product')
              .having((link) => link.parameter, 'parameter', 'vitamin-c'));
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/brand/panadol')),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'brand')
              .having((link) => link.subjectId, 'subject id', isNull));
      expect(DeepLinkResolver.readLocally(Uri.parse('https://shop.test/products')).target,
          'product_list');
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/track-order/100234')),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'order_tracking')
              .having((link) => link.parameter, 'parameter', '100234'));
    });

    test('a short link with no one to resolve it lands on home, never on a guess', () {
      expect(DeepLinkResolver.readLocally(Uri.parse('https://shop.test/go/rmd26')).target,
          'home');
    });

    test('an unpublished path is left to the browser', () {
      final link = DeepLinkResolver.readLocally(Uri.parse('https://shop.test/checkout'));

      expect(link.target, 'web');
      expect(link.webUrl, 'https://shop.test/checkout');
    });

    test('a bare path is read the same as a full url', () {
      expect(DeepLinkResolver.readLocally(Uri.parse('/product/vitamin-c')).parameter,
          'vitamin-c');
    });
  });
}
