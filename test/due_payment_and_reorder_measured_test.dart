import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/order_details/controllers/order_details_controller.dart';
import 'package:syriapharmacy/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:syriapharmacy/features/reorder/controllers/re_order_controller.dart';
import 'package:syriapharmacy/features/reorder/domain/services/re_order_service_interface.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';

import 'app_screen_harness.dart';

const StorefrontCountry _browseOnlyEmirates = StorefrontCountry(
  code: 'AE',
  path: '/ae',
  currency: 'AED',
  sellable: false,
  stopMode: StorefrontCountry.browseOnlyMode,
);

/// Records every request a controller makes, by the name of the service method, and answers each with a failure that is not an order,
/// so a request that is made is told apart from one that is not.
class _Requests {
  final List<Symbol> made = <Symbol>[];

  Future<dynamic> failed(Invocation invocation) {
    made.add(invocation.memberName);

    return Future<dynamic>.value(
        ApiResponseModel<dynamic>.withError('no answer', unanswered: true));
  }
}

class _RecordingOrderDetails extends _Requests
    implements OrderDetailsServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => failed(invocation);
}

class _RecordingReOrder extends _Requests implements ReOrderServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => failed(invocation);
}

/// One way a customer pays what is still due on an order they already have, or orders it again, and the request it makes.
typedef _Path = ({
  String name,
  Symbol request,
  Future<void> Function(
          OrderDetailsController orderDetails, ReOrderController reorder)
      start,
});

final List<_Path> _paths = <_Path>[
  (
    name: 'paying what is due in cash on delivery',
    request: #duePaymentByCod,
    start: (OrderDetailsController orderDetails, ReOrderController _) =>
        orderDetails.duePaymentByCod(4217, 'cash_on_delivery', '20'),
  ),
  (
    name: 'paying what is due by a gateway',
    request: #duePaymentByDigitalPayment,
    start: (OrderDetailsController orderDetails, ReOrderController _) =>
        orderDetails.duePaymentByDigitalPayment(4217, 'gateway', null, null),
  ),
  (
    name: 'paying what is due from the wallet',
    request: #duePaymentByWallet,
    start: (OrderDetailsController orderDetails, ReOrderController _) =>
        orderDetails.duePaymentByWallet(4217, 'wallet'),
  ),
  (
    name: 'paying what is due offline',
    request: #duePaymentByOfflinePayment,
    start: (OrderDetailsController orderDetails, ReOrderController _) =>
        orderDetails.duePaymentByOfflinePayment(4217, 'offline', null, '1'),
  ),
  (
    name: 'ordering the same things again',
    request: #reorder,
    start: (OrderDetailsController _, ReOrderController reorder) =>
        reorder.reorder(orderId: '4217'),
  ),
];

/// A measurement, not a gate. Five paths of the customer app are deliberately NOT asked whether the storefront may sell: the four ways
/// of paying what is still due on an order the customer already has, and ordering the same things again. This file names each of them
/// and records that its request does leave the app on a storefront the server has marked browse-only, so that the record says which
/// they are rather than leaving it to be rediscovered.
///
/// Why they are not gated: the backend keeps the payment of a due balance open by design — the order was accepted while the storefront
/// could sell, and refusing the balance would leave the customer owing money they cannot pay — and whether "order again" should be
/// offered on a browse-only storefront is the owner's open question Q-40. `existing_orders_not_gated_test.dart` holds the same line for
/// the details, the tracking, the refunds, the support tickets and the chats of an order.
///
/// So a guard added to any of the five fails this file. That is the point: it is the record of a decision, and changing the decision
/// has to be deliberate.
///
///   flutter test test/due_payment_and_reorder_measured_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/due_payment_and_reorder_measured_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final String notice = words('en', 'storefront_browse_only_notice');

  group('on a storefront the server has marked browse-only', () {
    for (final _Path path in _paths) {
      testWidgets('${path.name} reaches the server, and shows no notice',
          (WidgetTester tester) async {
        final _RecordingOrderDetails orderDetailsService =
            _RecordingOrderDetails();
        final _RecordingReOrder reOrderService = _RecordingReOrder();
        final OrderDetailsController orderDetails = OrderDetailsController(
            orderDetailsServiceInterface: orderDetailsService);
        final ReOrderController reorder =
            ReOrderController(reOrderServiceInterface: reOrderService);
        addTearDown(orderDetails.dispose);
        addTearDown(reorder.dispose);

        final ScreenHarness harness = await ScreenHarness.open(tester,
            screen: const Scaffold(),
            customerOn: 'AE',
            listed: const <StorefrontCountry>[_browseOnlyEmirates],
            storefrontsEnabled: true);

        expect(harness.storefronts.saleGate.storefrontMaySell, isFalse);
        expect(harness.storefronts.currentEntry?.stopMode,
            StorefrontCountry.browseOnlyMode);

        await path.start(orderDetails, reorder);
        await tester.pump();

        expect(
            <Symbol>[...orderDetailsService.made, ...reOrderService.made],
            <Symbol>[path.request],
            reason:
                '${path.name} is deliberately ungated; see this file for why');
        expect(find.text(notice), findsNothing);
      });
    }
  }, skip: !StorefrontConfig.enabled);
}
