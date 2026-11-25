import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/services/deep_link_resolver.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

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

  /// J-10: a six-market shop publishes each market's pages under that market's own path, and the
  /// app could not see that such a link named a market at all — `ae` was an unknown first segment
  /// and the whole link fell through to the browser. The market is now read off the path and
  /// recorded; what a link naming ANOTHER market than the customer's choice should do is the
  /// owner's open decision, so nothing switches and the customer stays where they chose to be.
  group('a link that names its market', () {
    test('is read as the same screen, with the market recorded, while storefronts are on', () {
      expect(
          DeepLinkResolver.readLocally(
              Uri.parse('https://shop.test/ae/product/vitamin-c'),
              storefronts: true),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'product')
              .having((link) => link.parameter, 'parameter', 'vitamin-c')
              .having((link) => link.storefront, 'storefront', 'AE'));
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/kw/brand/panadol'),
              storefronts: true),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'brand')
              .having((link) => link.parameter, 'parameter', 'panadol')
              .having((link) => link.storefront, 'storefront', 'KW'));
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/bh/products'),
              storefronts: true),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'product_list')
              .having((link) => link.storefront, 'storefront', 'BH'));
      expect(
          DeepLinkResolver.readLocally(
              Uri.parse('https://shop.test/om/track-order/100234'),
              storefronts: true),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'order_tracking')
              .having((link) => link.parameter, 'parameter', '100234')
              .having((link) => link.storefront, 'storefront', 'OM'));
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/qa/go/rmd26'),
              storefronts: true),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'home')
              .having((link) => link.storefront, 'storefront', 'QA'));
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/sa/'),
              storefronts: true),
          isA<ResolvedDeepLink>()
              .having((link) => link.target, 'target', 'home')
              .having((link) => link.storefront, 'storefront', 'SA'));
    });

    test('every one of the six markets is a path this app knows', () {
      for (final StorefrontCountry storefront in StorefrontCountry.all) {
        expect(
            DeepLinkResolver.readLocally(
                    Uri.parse('https://shop.test${storefront.path}/product/x'),
                    storefronts: true)
                .storefront,
            storefront.code,
            reason: 'the path ${storefront.path} is the ${storefront.code} market');
      }
    });

    test('and a first segment that is no market is still the path it always was', () {
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/checkout'),
                  storefronts: true)
              .target,
          'web');
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/product/vitamin-c'),
                  storefronts: true)
              .storefront,
          isNull);
      expect(
          DeepLinkResolver.readLocally(Uri.parse('https://shop.test/zz/product/x'),
                  storefronts: true)
              .target,
          'web');
    });

    test('while storefronts are off a market path is not a path this app knows', () {
      final ResolvedDeepLink link = DeepLinkResolver.readLocally(
          Uri.parse('https://shop.test/ae/product/vitamin-c'),
          storefronts: false);

      expect(link.target, 'web',
          reason:
              'the default build must leave it to the browser rather than open a product under whatever market the customer is on');
      expect(link.webUrl, 'https://shop.test/ae/product/vitamin-c');
      expect(link.storefront, isNull);
    });

    test('and the shop\'s own answer may name the market, when it starts to', () {
      expect(
          ResolvedDeepLink.fromJson(
                  const {'target': 'product', 'storefront': 'kw'}).storefront,
          'KW');
      expect(
          ResolvedDeepLink.fromJson(const {'target': 'product'}).storefront,
          isNull);
      expect(
          ResolvedDeepLink.fromJson(
                  const {'target': 'product', 'storefront': 'ZZ'}).storefront,
          isNull);
    });
  });

  /// J-10 criterion 3: a universal link and an App Link have to name the SAME host, and that host
  /// has to be the one the app actually talks to. iOS claimed only the shop's old domain, so no
  /// universal link to this shop could open the app at all. These read the native files.
  group('the host both platforms claim', () {
    String host(String path) => File(path).readAsStringSync();

    test('is the host the app itself talks to, in the Android filter', () {
      expect(
          host('android/app/src/main/AndroidManifest.xml'),
          contains(
              'android:host="${Uri.parse(AppConstants.baseUrl).host}"'));
    });

    test('and the same host is an associated domain on iOS', () {
      expect(
          host('ios/Runner/Runner.entitlements'),
          contains(
              '<string>applinks:${Uri.parse(AppConstants.baseUrl).host}</string>'));
    });
  });
}
