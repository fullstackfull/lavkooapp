import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef _Looked = ({
  Map<String, int> writers,
  List<String> markets,
  String reason,
});

const Map<String, _Looked> _looked = <String, _Looked>{
  'lib/features/order/widgets/order_widget.dart': (
    writers: <String, int>{'convertOrderPrice': 1},
    markets: <String>['widget.orderModel!.market'],
    reason:
        'the amount of the order on the list item, whether it is the amount the server sent or the one worked out for a POS order',
  ),
  'lib/features/order_details/widgets/order_amount_calculation.dart': (
    writers: <String, int>{'convertOrderPrice': 1},
    markets: <String>['orderProvider.orders!.market'],
    reason:
        'every amount of the billing summary, through the one helper of the widget',
  ),
  'lib/features/order_details/widgets/order_details_widget.dart': (
    writers: <String, int>{'convertOrderPrice': 1, 'percentageCalculation': 2},
    markets: <String>['widget.orderDetailsModel.order?.market'],
    reason:
        'the price of a line is the order\'s; the badge on a line writes the discount of its product, a percentage or an amount in the platform\'s money, and is not changed',
  ),
  'lib/features/order_details/screens/order_details_screen.dart': (
    writers: <String, int>{'convertOrderPrice': 2},
    markets: <String>[
      'orderProvider.orders!.market',
      'orderProvider.orders!.market'
    ],
    reason:
        'the cards of what is due on an edited order and of what is to be returned',
  ),
  'lib/features/home/widgets/aster_theme/order_again_list_view_widget.dart': (
    writers: <String, int>{'convertOrderPrice': 1},
    markets: <String>['orders.market'],
    reason: 'the total of a delivered order on the order again card',
  ),
  'lib/features/order_details/widgets/order_payment_info_widget.dart': (
    writers: <String, int>{'convertOrderPrice': 1},
    markets: <String>['orderProvider.orders?.market'],
    reason:
        'the change the customer asked the courier to bring, an amount of the order, on the same screen as the billing summary',
  ),
  'lib/features/order_details/widgets/order_offline_payment_screen.dart': (
    writers: <String, int>{'convertOrderPrice': 1},
    markets: <String>['orderDetailsController.orders?.market'],
    reason:
        'what is still due on the order, the same amount the billing summary and the card of what is due write, carried to the screen the customer pays it from',
  ),
  'lib/features/order_details/widgets/order_payment_bottomsheet_widget.dart': (
    writers: <String, int>{'currencySymbolToShow': 1},
    markets: <String>[],
    reason:
        'the mark beside the amount the customer types when paying what is still due: the money the payment itself is made in, which is the storefront the customer is on, not the currency the order was sold in',
  ),
  'lib/features/order_details/controllers/order_details_controller.dart': (
    writers: <String, int>{'currencyCodeToSend': 1},
    markets: <String>[],
    reason:
        'the currency a payment of what is still due is sent with, which is not written on a screen: the storefront the customer is on, as the mark on the field they type in says',
  ),
  'lib/features/review/widgets/review_dialog_widget.dart': (
    writers: <String, int>{'convertOrderPrice': 1, 'percentageCalculation': 1},
    markets: <String>['widget.orderDetailsModel.order?.market'],
    reason:
        'the price of the line the customer is reviewing, the same line the details screen they came from writes; the badge on it writes the discount of its product, an amount in the platform\'s money, and is not changed',
  ),
  'lib/features/order_details/widgets/refund_product_widget.dart': (
    writers: <String, int>{'convertPrice': 1, 'percentageCalculation': 2},
    markets: <String>[],
    reason:
        'the refund request of a line: the price and the discount of its product, not changed',
  ),
  'lib/features/refund/widgets/refund_request_widget.dart': (
    writers: <String, int>{'convertPrice': 7},
    markets: <String>[],
    reason: 'the amounts of a refund request, not changed',
  ),
  'lib/features/refund/widgets/refunded_details_widget.dart': (
    writers: <String, int>{'convertPrice': 1},
    markets: <String>[],
    reason: 'the amount of a refunded line, not changed',
  ),
};

/// The files that show an order or a part of it, and how each writes an amount: through `PriceConverter.convertOrderPrice`, in the currency
/// the order was sold in, or by another writer of PriceConverter, in the money of the platform or of the storefront the customer is on now,
/// with the reason. Every writer is counted by the way it is called, so a screen that goes back to `convertPrice`, a screen that is added,
/// and a writer that is added to a screen all fail here until someone has looked at the amount: whose currency is it?
///
/// This is the source scan of J-13 criterion 1. What it proves is where each amount is written and by what; that the order's currency is
/// what `convertOrderPrice` writes is proved by order_price_converter_test.dart, and that each screen passes it the order's own record, for
/// the screens that can be built with fakes, by order_screens_currency_test.dart. The two cards of what is due and what is to be returned on
/// the details screen, and the screen the customer pays what is due from, are covered by this scan alone: neither is built by a test.
///
/// A line that is a comment is not a use. The scan sees a call written `PriceConverter.name(`, wherever the formatter breaks the line; an
/// amount a screen writes by interpolating a number into a string is not seen by it, which is what money_formatter_inventory_test.dart
/// looks for.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path.replaceAll(r'\', '/'): entity.readAsStringSync(),
  };

  const List<String> features = <String>[
    'order',
    'order_details',
    'refund',
    'review',
    'tracking',
    'reorder',
  ];
  const String orderAgainCard =
      'lib/features/home/widgets/aster_theme/order_again_list_view_widget.dart';

  bool showsAnOrder(String path) =>
      path == orderAgainCard ||
      features
          .any((String feature) => path.startsWith('lib/features/$feature/'));

  final RegExp writer = RegExp(r'PriceConverter\s*\.\s*(\w+)\s*\(');

  String codeOf(String source) => source
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  Map<String, int> writersIn(String source) {
    final Map<String, int> counted = <String, int>{};
    for (final RegExpMatch match in writer.allMatches(codeOf(source))) {
      counted.update(match.group(1)!, (int count) => count + 1,
          ifAbsent: () => 1);
    }

    return counted;
  }

  /// What each writer in the currency of the order is given as the record of the order, as written once the spaces are taken out.
  List<String> marketsIn(String source) => <String>[
        for (final RegExpMatch match in RegExp(r'\bmarket:([\w.!?]+)')
            .allMatches(codeOf(source).replaceAll(RegExp(r'\s+'), '')))
          match.group(1)!,
      ];

  group('the writers of an amount in the files that show an order', () {
    test('are in the files that were looked at, and in no other', () {
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (showsAnOrder(source.key) && writersIn(source.value).isNotEmpty)
            source.key,
      };

      expect(found, _looked.keys.toSet(),
          reason:
              'a file that writes an amount of an order has to be looked at: in whose currency is the amount, the order\'s or the platform\'s?');
    });

    test('are as many of each kind in each file as were looked at', () {
      final Map<String, Map<String, int>> found = <String, Map<String, int>>{
        for (final String path in _looked.keys) path: writersIn(sources[path]!),
      };

      expect(found, <String, Map<String, int>>{
        for (final MapEntry<String, _Looked> entry in _looked.entries)
          entry.key: entry.value.writers,
      });
    });

    test(
        'write the amount in the currency of the order in the screens that show the order, and in no other file',
        () {
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (writersIn(source.value).containsKey('convertOrderPrice'))
            source.key,
      };

      expect(found, <String>{
        for (final MapEntry<String, _Looked> entry in _looked.entries)
          if (entry.value.writers.containsKey('convertOrderPrice')) entry.key,
      });
    });

    test(
        'are given the record of their own order, and of no other source, where they write in its currency',
        () {
      final Map<String, List<String>> found = <String, List<String>>{
        for (final String path in _looked.keys) path: marketsIn(sources[path]!),
      };

      expect(found, <String, List<String>>{
        for (final MapEntry<String, _Looked> entry in _looked.entries)
          entry.key: entry.value.markets,
      });
    });
  });
}
