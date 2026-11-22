import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

enum _Use { formatter, rating, health, fileSize, points, rounding }

/// What was decided about the uses of `toStringAsFixed` in one file: how many there are and what they write, so why none of them is an
/// amount of money written the way a screen should write it, through PriceConverter.
class _Looked {
  const _Looked({required this.count, required this.use, required this.reason});

  final int count;
  final _Use use;
  final String reason;
}

const Map<String, _Looked> _looked = <String, _Looked>{
  'lib/helper/price_converter.dart': _Looked(
      count: 13,
      use: _Use.formatter,
      reason:
          'the formatter itself: prices with the decimals of the config, discounts in per cent and the short form of a count'),
  'lib/features/storefront/storefront_money.dart': _Looked(
      count: 1,
      use: _Use.formatter,
      reason:
          'the decimals of a storefront\'s own currency; PriceConverter calls it'),
  'lib/features/order_details/widgets/order_amount_calculation.dart': _Looked(
      count: 1,
      use: _Use.rounding,
      reason:
          'rounds the total of a POS order to two decimals, whatever the currency, before the change is worked out; PriceConverter.convertPrice writes the change'),
  'lib/common/basewidget/product_widget.dart': _Looked(
      count: 1,
      use: _Use.rating,
      reason: 'the average rating of a product card'),
  'lib/common/basewidget/slider_product_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/clearance_sale/widgets/clearance_sale_card.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/compare/screens/compare_product_screen.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/deal/widgets/featured_deal_card_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/dynamic_theme/renderers/taxonomy_section_renderer.dart':
      _Looked(
          count: 2,
          use: _Use.rating,
          reason: 'the rating of an entry of a taxonomy section'),
  'lib/features/dynamic_theme/widgets/theme_shop_header.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a shop'),
  'lib/features/health/calculators/bmi_calculator_screen.dart': _Looked(
      count: 3,
      use: _Use.health,
      reason: 'a body mass index and a weight in kilograms'),
  'lib/features/health/calculators/dosage_converter_screen.dart':
      _Looked(count: 1, use: _Use.health, reason: 'a dosage in milligrams'),
  'lib/features/health/calculators/kids_dosage_screen.dart':
      _Looked(count: 1, use: _Use.health, reason: 'a dose of a medicine'),
  'lib/features/health/health_home_screen.dart': _Looked(
      count: 2,
      use: _Use.health,
      reason: 'the water drunk, in litres, and the sleep, in hours'),
  'lib/features/health/reminders/water_reminder_screen.dart': _Looked(
      count: 2,
      use: _Use.health,
      reason: 'the water drunk and its goal, in litres'),
  'lib/features/health/trackers/sleep_tracker_screen.dart':
      _Looked(count: 1, use: _Use.health, reason: 'the hours of rest'),
  'lib/features/loyaltyPoint/widget/loyalty_point_info_widget.dart': _Looked(
      count: 1, use: _Use.points, reason: 'the loyalty points of the customer'),
  'lib/features/more/widgets/square_item_widget.dart': _Looked(
      count: 1,
      use: _Use.points,
      reason:
          'the loyalty points; the wallet balance in the same widget goes through PriceConverter.convertPrice'),
  'lib/features/order_details/widgets/review_button_widget.dart': _Looked(
      count: 1, use: _Use.rating, reason: 'the rating given to an order'),
  'lib/features/order_details/widgets/review_reply_widget.dart': _Looked(
      count: 1, use: _Use.rating, reason: 'the rating given to an order'),
  'lib/features/product/widgets/latest_product/latest_product_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/product/widgets/recommended_product_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/product_details/widgets/cart_bottom_sheet_widget.dart': _Looked(
      count: 1,
      use: _Use.rating,
      reason:
          'the rating of the product in the sheet that adds it to the cart; its prices go through PriceConverter.convertPrice'),
  'lib/features/product_details/widgets/product_title_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/restock/widgets/restock_list_item_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/features/review/widgets/overall_rating_widget.dart': _Looked(
      count: 1, use: _Use.rating, reason: 'the average rating of reviews'),
  'lib/features/shop/widgets/seller_card.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a shop'),
  'lib/features/shop/widgets/shop_info_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a shop'),
  'lib/features/wishlist/widgets/wishlist_widget.dart':
      _Looked(count: 1, use: _Use.rating, reason: 'the rating of a product'),
  'lib/helper/image_size_checker.dart': _Looked(
      count: 4,
      use: _Use.fileSize,
      reason: 'the size of a file to upload, in megabytes or kilobytes'),
};

/// J-05 criterion 3: the cart, the checkout, the orders, the wallet and the coupons write every amount through one formatter, PriceConverter.
/// The way an amount escapes it is a screen that writes the number itself, and the way a screen does that is `toStringAsFixed`, so every
/// use of it in the app is listed above with what it writes. A new use, a new file and a changed count fail until someone has looked at the
/// number: is it money? And no file of those five features that writes an amount through PriceConverter formats a number with
/// `toStringAsFixed` itself, but a rounding that PriceConverter then writes.
///
/// A line that is a comment is not a use. This sees `toStringAsFixed`, `toStringAsPrecision`, `toStringAsExponential` and `NumberFormat`; an
/// amount a screen writes by interpolating the number into a string is not seen by it.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };

  final RegExp numberToText = RegExp(r'\btoStringAsFixed\b');

  int usesIn(String source) => source
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .fold(
          0,
          (int total, String line) =>
              total + numberToText.allMatches(line).length);

  group('every use of toStringAsFixed in the app', () {
    test('is in the files that were looked at, and in no other', () {
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (usesIn(source.value) > 0) source.key,
      };

      expect(found, _looked.keys.toSet(),
          reason:
              'a file that writes a number with toStringAsFixed has to be looked at: is the number an amount of money? Money is written by PriceConverter.');
    });

    test('is as many in each file as were looked at', () {
      final Map<String, String> changed = <String, String>{
        for (final MapEntry<String, _Looked> entry in _looked.entries)
          if (usesIn(sources[entry.key] ?? '') != entry.value.count)
            entry.key:
                'looked at ${entry.value.count}, found ${usesIn(sources[entry.key] ?? '')}',
      };

      expect(changed, isEmpty,
          reason:
              'a use added to or taken from a file has to be looked at: is the number an amount of money?');
    });
  });

  group(
      'the amounts of the cart, the checkout, the orders, the wallet and the coupons',
      () {
    const List<String> features = <String>[
      'cart',
      'checkout',
      'order',
      'order_details',
      'wallet',
      'coupon',
    ];

    bool isOfTheFiveFeatures(String path) => features
        .any((String feature) => path.startsWith('lib/features/$feature/'));

    final Map<String, String> writtenByPriceConverter = <String, String>{
      for (final MapEntry<String, String> source in sources.entries)
        if (isOfTheFiveFeatures(source.key) &&
            source.value.contains('PriceConverter.'))
          source.key: source.value,
    };

    test('are written by files that were found, in each of the five features',
        () {
      expect(writtenByPriceConverter, isNotEmpty);
      for (final String feature in features) {
        expect(
            writtenByPriceConverter.keys.where(
                (String path) => path.startsWith('lib/features/$feature/')),
            isNotEmpty,
            reason: feature);
      }
    });

    test(
        'are written by no file that formats a number with toStringAsFixed, but a rounding that PriceConverter then writes',
        () {
      final Map<String, int> formatting = <String, int>{
        for (final MapEntry<String, String> source
            in writtenByPriceConverter.entries)
          if (usesIn(source.value) > 0) source.key: usesIn(source.value),
      };
      final Map<String, int> roundings = <String, int>{
        for (final MapEntry<String, _Looked> entry in _looked.entries)
          if (entry.value.use == _Use.rounding) entry.key: entry.value.count,
      };

      expect(formatting, roundings);
    });

    test('are written by no other way of writing a number with decimals', () {
      final RegExp otherWays =
          RegExp(r'toStringAsPrecision|toStringAsExponential|NumberFormat');

      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (isOfTheFiveFeatures(source.key) &&
              otherWays.hasMatch(source.value))
            source.key,
      };

      expect(found, isEmpty);
    });
  });
}
