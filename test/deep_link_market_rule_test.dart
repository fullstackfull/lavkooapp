import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/services/deep_link_resolver.dart';
import 'package:syriapharmacy/features/deep_link/deep_link_storefront_rule.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';

/// What the app does with a link that was made for another market (J-10).
///
/// A six-market shop publishes its pages under a market's own path. The app can read that market off
/// the path, and what it then DOES is the owner's open decision, so all three answers exist and a
/// build flag picks one. The shipped value is `stay`, which is what the app did before a link could
/// name a market at all.
void main() {
  const StorefrontCountry saudi = StorefrontCountry(
      code: 'SA', path: 'sa', currency: 'SAR', sellable: true);
  const StorefrontCountry emirates =
      StorefrontCountry(code: 'AE', path: 'ae', currency: 'AED');
  const StorefrontCountry kuwait =
      StorefrontCountry(code: 'KW', path: 'kw', currency: 'KWD');

  group('the market a link names', () {
    test(
        'is read off the path, and the rest of the path is read as it always was',
        () {
      final ResolvedDeepLink link = DeepLinkResolver.readLocally(
          Uri.parse('https://lavkoo.com/ae/product/some-slug'),
          storefronts: true);

      expect(link.storefront, 'AE');
      expect(link.target, 'product');
      expect(link.parameter, 'some-slug');
    });

    test(
        'is nothing while this build does not know about markets, so the link falls to the browser',
        () {
      final ResolvedDeepLink link = DeepLinkResolver.readLocally(
          Uri.parse('https://lavkoo.com/ae/product/some-slug'),
          storefronts: false);

      expect(link.storefront, isNull);
      expect(link.target, 'web');
    });

    test('is the market itself for a bare market path', () {
      expect(
        DeepLinkResolver.readLocally(Uri.parse('https://lavkoo.com/ae'),
                storefronts: true)
            .target,
        'home',
      );
      expect(
        DeepLinkResolver.readLocally(Uri.parse('https://lavkoo.com/ae'),
                storefronts: true)
            .storefront,
        'AE',
      );
    });
  });

  group('what there is to move to', () {
    test('a market the server lists, which is not the one the customer is on',
        () {
      expect(
        DeepLinkStorefrontTarget.of(
            named: 'AE',
            current: saudi,
            available: <StorefrontCountry>[saudi, emirates],
            storefronts: true),
        emirates,
      );
    });

    test('nothing for a link that names the market the customer is already on',
        () {
      expect(
        DeepLinkStorefrontTarget.of(
            named: 'SA',
            current: saudi,
            available: <StorefrontCountry>[saudi, emirates],
            storefronts: true),
        isNull,
      );
    });

    test(
        'nothing for a market the server does not list, so a link cannot put a customer in a market the shop does not serve',
        () {
      expect(
        DeepLinkStorefrontTarget.of(
            named: 'KW',
            current: saudi,
            available: <StorefrontCountry>[saudi, emirates],
            storefronts: true),
        isNull,
      );
    });

    test(
        'nothing for a link that names no market, and nothing while markets are off',
        () {
      expect(
        DeepLinkStorefrontTarget.of(
            named: null,
            current: saudi,
            available: <StorefrontCountry>[saudi, emirates],
            storefronts: true),
        isNull,
      );
      expect(
        DeepLinkStorefrontTarget.of(
            named: 'AE',
            current: saudi,
            available: <StorefrontCountry>[saudi, emirates],
            storefronts: false),
        isNull,
      );
    });

    test(
        'the market whatever the case of the code, because a link is typed by people',
        () {
      expect(
        DeepLinkStorefrontTarget.of(
            named: ' ae ',
            current: saudi,
            available: <StorefrontCountry>[saudi, emirates, kuwait],
            storefronts: true),
        emirates,
      );
    });
  });

  group('the rule this build follows', () {
    test(
        'ships as staying where the customer is, which is what the app always did',
        () {
      expect(DeepLinkStorefrontRuleConfig.rule, DeepLinkStorefrontRule.stay);
      expect(
        DeepLinkStorefrontTarget.step(target: emirates),
        DeepLinkStorefrontStep.openHere,
      );
    });

    test(
        'is read from the build flag, and anything it does not understand stays',
        () {
      expect(DeepLinkStorefrontRuleConfig.parse('ask'),
          DeepLinkStorefrontRule.ask);
      expect(DeepLinkStorefrontRuleConfig.parse('FOLLOW'),
          DeepLinkStorefrontRule.follow);
      expect(DeepLinkStorefrontRuleConfig.parse('switch'),
          DeepLinkStorefrontRule.follow);
      expect(DeepLinkStorefrontRuleConfig.parse('stay'),
          DeepLinkStorefrontRule.stay);
      for (final String typo in <String>[
        '',
        '  ',
        'folow',
        'yes',
        'true',
        'move'
      ]) {
        expect(DeepLinkStorefrontRuleConfig.parse(typo),
            DeepLinkStorefrontRule.stay,
            reason: typo);
      }
    });

    test(
        'decides each of the three, and never moves when there is nothing to move to',
        () {
      expect(
        DeepLinkStorefrontTarget.step(
            target: emirates, rule: DeepLinkStorefrontRule.stay),
        DeepLinkStorefrontStep.openHere,
      );
      expect(
        DeepLinkStorefrontTarget.step(
            target: emirates, rule: DeepLinkStorefrontRule.ask),
        DeepLinkStorefrontStep.askFirst,
      );
      expect(
        DeepLinkStorefrontTarget.step(
            target: emirates, rule: DeepLinkStorefrontRule.follow),
        DeepLinkStorefrontStep.moveThenOpen,
      );
      for (final DeepLinkStorefrontRule rule in DeepLinkStorefrontRule.values) {
        expect(
          DeepLinkStorefrontTarget.step(target: null, rule: rule),
          DeepLinkStorefrontStep.openHere,
          reason:
              '${rule.name}: a link with no market of its own opens where the customer is',
        );
      }
    });
  });

  /// The Android filter is half of "a prefixed link is accepted by the app": a path the filter does
  /// not claim never reaches the resolver at all, it opens in the browser. Read off the native file,
  /// the way the host of the filter already is.
  group('the paths the Android filter claims', () {
    final String manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    test(
        'are every published path under every market, as well as the unprefixed ones',
        () {
      for (final String path in <String>[
        '/track-order',
        '/referral-login',
        '/product/',
        '/vendor-shop/',
        '/brand/',
        '/products',
        '/go/',
      ]) {
        expect(manifest, contains('android:pathPrefix="$path"'), reason: path);

        for (final String market in <String>[
          'sa',
          'ae',
          'kw',
          'qa',
          'bh',
          'om'
        ]) {
          expect(manifest, contains('android:pathPrefix="/$market$path"'),
              reason: '/$market$path');
        }
      }
    });

    test('and a market\'s own home page', () {
      for (final String market in <String>[
        'sa',
        'ae',
        'kw',
        'qa',
        'bh',
        'om'
      ]) {
        expect(manifest, contains('android:pathPattern="/$market"'),
            reason: market);
      }
    });
  });

  group('what the gateway asks it', () {
    test(
        'without the controllers that would make the move, nothing moves and the link still opens',
        () {
      final decision = DeepLinkStorefrontTarget.decide(
          named: 'AE', context: null, rule: DeepLinkStorefrontRule.follow);

      expect(decision.target, isNull);
      expect(decision.step, DeepLinkStorefrontStep.openHere);
    });
  });
}
