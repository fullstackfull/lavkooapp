import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/chat/controllers/chat_controller.dart';
import 'package:syriapharmacy/features/chat/domain/models/message_body.dart';
import 'package:syriapharmacy/features/chat/domain/services/chat_service_interface.dart';
import 'package:syriapharmacy/features/order_details/controllers/order_details_controller.dart';
import 'package:syriapharmacy/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:syriapharmacy/features/refund/controllers/refund_controller.dart';
import 'package:syriapharmacy/features/refund/domain/services/refund_service_interface.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/services/storefront_service_interface.dart';
import 'package:syriapharmacy/features/storefront/storefront_choice.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/support/controllers/support_ticket_controller.dart';
import 'package:syriapharmacy/features/support/domain/models/support_ticket_body.dart';
import 'package:syriapharmacy/features/support/domain/services/support_ticket_service_interface.dart';
import 'package:syriapharmacy/main.dart' show navigatorKey;
import 'package:syriapharmacy/utill/app_constants.dart';

/// Records the name of every request a controller makes, in one list for all of them, and answers each with a failure that carries nothing, so
/// a request that is made is told apart from one that is not.
class _Requests {
  final List<Symbol> made = <Symbol>[];

  Future<dynamic> failed(Symbol request) {
    made.add(request);

    return Future<dynamic>.value(
        ApiResponseModel<dynamic>.withError('no answer', unanswered: true));
  }

  Future<http.StreamedResponse> refused(Symbol request) async {
    made.add(request);

    return http.StreamedResponse(const Stream<List<int>>.empty(), 400);
  }
}

class _FakeOrderDetailsService implements OrderDetailsServiceInterface {
  _FakeOrderDetailsService(this._requests);

  final _Requests _requests;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _requests.failed(invocation.memberName);
}

class _FakeRefundService implements RefundServiceInterface {
  _FakeRefundService(this._requests);

  final _Requests _requests;

  @override
  Future<dynamic> refundRequest(int? orderDetailsId, double? amount,
          String refundReason, List<XFile?> file) =>
      _requests.refused(#refundRequest);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _requests.failed(invocation.memberName);
}

class _FakeSupportTicketService implements SupportTicketServiceInterface {
  _FakeSupportTicketService(this._requests);

  final _Requests _requests;

  @override
  Future<dynamic> sendReply(
          String ticketID, String message, List<XFile?> file) =>
      _requests.refused(#sendReply);

  @override
  Future<dynamic> createNewSupportTicket(
          SupportTicketBody supportTicketModel, List<XFile?> file) =>
      _requests.refused(#createNewSupportTicket);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _requests.failed(invocation.memberName);
}

class _FakeChatService implements ChatServiceInterface {
  _FakeChatService(this._requests);

  final _Requests _requests;

  @override
  Future<dynamic> sendMessage(MessageBody messageBody, String type,
          List<XFile?> file, List<PlatformFile>? platformFile) =>
      _requests.refused(#sendMessage);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _requests.failed(invocation.memberName);
}

class _NoServer implements StorefrontServiceInterface {
  @override
  Future<bool> refreshStorefronts() async => false;
}

class _Controllers {
  _Controllers() {
    orderDetails = OrderDetailsController(
        orderDetailsServiceInterface: _FakeOrderDetailsService(requests));
    refund =
        RefundController(refundServiceInterface: _FakeRefundService(requests));
    support = SupportTicketController(
        supportTicketServiceInterface: _FakeSupportTicketService(requests));
    chat = ChatController(chatServiceInterface: _FakeChatService(requests));
  }

  final _Requests requests = _Requests();
  late final OrderDetailsController orderDetails;
  late final RefundController refund;
  late final SupportTicketController support;
  late final ChatController chat;
}

/// One thing a customer does with an order they already have, and the request it makes.
typedef _Call = ({
  String name,
  Symbol request,
  Future<void> Function(_Controllers controllers) make,
});

final List<_Call> _calls = <_Call>[
  (
    name: 'asking for the details of an order',
    request: #getOrderDetails,
    make: (_Controllers controllers) =>
        controllers.orderDetails.getOrderDetails('4217'),
  ),
  (
    name: 'asking for the tracking of an order',
    request: #getTrackOrderDetailsId,
    make: (_Controllers controllers) =>
        controllers.orderDetails.getTrackOrderDetailsId(orderId: '4217'),
  ),
  (
    name: 'asking for the tracking of an order, as a guest',
    request: #trackOrder,
    make: (_Controllers controllers) => controllers.orderDetails
        .trackOrder(orderId: '4217', phoneNumber: '5550100'),
  ),
  (
    name: 'asking for a refund',
    request: #refundRequest,
    make: (_Controllers controllers) =>
        controllers.refund.refundRequest('4217', 7, 10, 'damaged'),
  ),
  (
    name: 'asking what a refund is about',
    request: #getRefundInfo,
    make: (_Controllers controllers) => controllers.refund.getRefundReqInfo(7),
  ),
  (
    name: 'asking for the support tickets',
    request: #getList,
    make: (_Controllers controllers) =>
        controllers.support.getSupportTicketList(),
  ),
  (
    name: 'replying to a support ticket',
    request: #sendReply,
    make: (_Controllers controllers) =>
        controllers.support.sendReply(5, 'hello'),
  ),
  (
    name: 'asking for the chats',
    request: #getChatList,
    make: (_Controllers controllers) =>
        controllers.chat.getChatList(1, userType: 0),
  ),
];

/// J-13 criterion 2: the details, the tracking, the refund, the support and the chat of an order the customer already has work on any
/// storefront, a browse-only one included. The sale gate is for what starts a sale (the cart's Proceed, the checkout, a payment, a top-up of
/// the wallet); an order that exists is not asked.
///
/// The scan lists every file that refers to the gate, with what it does with it, and fails for one that was not looked at; and none of the
/// sources of the order list, the order, its tracking, its refund, its support tickets and its chat refers to it. The behaviour is the
/// controllers of the order screens started by hand on a browse-only storefront: each makes its request. The behaviour runs only in a build with
/// storefronts on, where a storefront can be browse-only:
///
///   flutter test test/existing_orders_not_gated_test.dart
///   flutter test --dart-define=GCC_STOREFRONTS_ENABLED=true test/existing_orders_not_gated_test.dart
///
/// The payment of what is still due on an order (`OrderDetailsController.duePayment*`) is a source of order_details too, so it is not gated
/// today, and the scan would fail on purpose the day it is.
void main() {
  final Map<String, String> sources = <String, String>{
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };

  String codeOf(String source) => source
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  group('what refers to the sale gate', () {
    const String gateFile = 'lib/features/storefront/checkout_sale_gate.dart';
    final String gateClass =
        RegExp(r'class (\w+)').firstMatch(sources[gateFile]!)!.group(1)!;
    final RegExp mentionsTheGate = RegExp(
        '$gateClass|checkout_sale_gate|saleGate|storefrontMaySell|maySellIn|showsBrowseOnlyNotice|BrowseOnlyNotice|browse_only_notice|canSell|sellable|StorefrontRefusal|not_sellable|\\.permits\\(');

    /// Each file that refers to the gate or to the flag it reads, and what it does with it.
    const Map<String, String> looked = <String, String>{
      gateFile: 'the gate itself',
      'lib/features/storefront/controllers/storefront_controller.dart':
          'builds the gate from the server\'s answer, and gives it to the controllers that have no widget to listen from',
      'lib/features/storefront/storefront_choice.dart':
          'works out from the stored answer whether a storefront may sell',
      'lib/features/storefront/domain/models/storefront_country.dart':
          'holds the flag the server sends for each storefront',
      'lib/features/storefront/storefront_refusal.dart':
          'reads the refusal the server sends when a sale is started on a storefront that may not sell',
      'lib/features/storefront/widgets/storefront_browse_only_notice.dart':
          'the notice that a storefront is browse-only',
      'lib/features/storefront/widgets/storefront_chooser_sheet.dart':
          'says in the chooser which storefronts take orders',
      'lib/features/cart/screens/cart_screen.dart':
          'the Proceed of the cart, which starts a checkout, and the notice above the cart',
      'lib/features/checkout/screens/checkout_screen.dart':
          'the button that places the order, which starts a sale, and the notice above it',
      'lib/features/checkout/controllers/checkout_controller.dart':
          'places an order (cash on delivery, offline payment, wallet) and starts a digital payment',
      'lib/features/wallet/controllers/wallet_controller.dart':
          'starts the payment that adds money to the wallet',
      'lib/data/datasource/remote/exception/api_error_handler.dart':
          'turns the server\'s refusal of a sale into its own message for any request that failed; it refuses nothing itself',
    };

    test('is by the files that were looked at, and by no other', () {
      final Set<String> found = <String>{
        for (final MapEntry<String, String> source in sources.entries)
          if (mentionsTheGate.hasMatch(codeOf(source.value))) source.key,
      };

      expect(found, looked.keys.toSet(),
          reason:
              'a file that refers to the gate has to be looked at: does it start a sale? A thing that already exists, an order, is not asked.');
    });

    test(
        'is by no source of the order list, the order, its tracking, its refund, its support tickets or its chat',
        () {
      const List<String> features = <String>[
        'order',
        'order_details',
        'tracking',
        'refund',
        'support',
        'chat',
      ];

      for (final String feature in features) {
        final List<String> paths = <String>[
          for (final String path in sources.keys)
            if (path.startsWith('lib/features/$feature/')) path,
        ];
        final Map<String, String> found = <String, String>{
          for (final String path in paths)
            if (mentionsTheGate.firstMatch(codeOf(sources[path]!)) != null)
              path:
                  mentionsTheGate.firstMatch(codeOf(sources[path]!))!.group(0)!,
        };

        expect(paths, isNotEmpty, reason: feature);
        expect(found, isEmpty, reason: feature);
      }
    });
  });

  group('on a browse-only storefront', () {
    for (final _Call call in _calls) {
      testWidgets('${call.name} reaches the server',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(
            <String, Object>{AppConstants.storefrontCountry: 'AE'});
        final SharedPreferences preferences =
            await SharedPreferences.getInstance();
        final StorefrontController storefronts = StorefrontController(
          storefrontServiceInterface: _NoServer(),
          storefrontChoice: StorefrontChoice(preferences, enabled: true),
        );
        await tester.pumpWidget(
          ChangeNotifierProvider<StorefrontController>.value(
            value: storefronts,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              home: const Scaffold(),
            ),
          ),
        );
        expect(storefronts.saleGate.storefrontMaySell, isFalse);

        // The support controller asks for a translation when it is built, so it needs the app's context first.
        final _Controllers controllers = _Controllers();
        addTearDown(controllers.orderDetails.dispose);
        addTearDown(controllers.refund.dispose);
        addTearDown(controllers.support.dispose);
        addTearDown(controllers.chat.dispose);

        await call.make(controllers);

        expect(controllers.requests.made, <Symbol>[call.request]);
      });
    }
  }, skip: !StorefrontConfig.enabled);
}
