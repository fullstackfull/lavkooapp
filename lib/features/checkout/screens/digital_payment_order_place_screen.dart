import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/checkout/domain/models/myfatoorah_payment_status.dart';
import 'package:syriapharmacy/features/checkout/domain/services/myfatoorah_payment_service.dart';
import 'package:syriapharmacy/features/checkout/widgets/order_place_bottomsheet_widget.dart';
import 'package:syriapharmacy/features/wallet/controllers/wallet_controller.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/order_place_dialog_widget.dart';
import 'package:provider/provider.dart';

class DigitalPaymentScreen extends StatefulWidget {
  final String url;
  final bool fromWallet;
  final String orderId;
  const DigitalPaymentScreen(
      {super.key,
        required this.url,
        this.fromWallet = false,
        this.orderId = ''});

  @override
  DigitalPaymentScreenState createState() => DigitalPaymentScreenState();
}

class DigitalPaymentScreenState extends State<DigitalPaymentScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _canRedirect = true;
  bool _isInitialized = false;

  /// MyFatoorah is handled differently from the other gateways on purpose.
  ///
  /// Every other gateway here is trusted to tell the truth in its redirect URL — the screen reads
  /// `success` or `fail` out of the address and acts on it. For MyFatoorah that is not good enough:
  /// 3-D Secure and the STC Pay / Apple Pay hand-offs mean the customer frequently arrives back before
  /// the bank has told anyone the outcome, and a URL is in any case something a page can put in front
  /// of this WebView. So for MyFatoorah the redirect is treated as nothing more than "the customer is
  /// back", and the result is read from our own server, which checks with MyFatoorah directly.
  ///
  /// Detected from the URL the screen was opened with, which is the one the backend generated, so this
  /// works from checkout, from a wallet top-up and from paying an order's remaining balance without
  /// any of those paths having to know about it.
  bool get _isMyFatoorah =>
      widget.url.contains('/payment/myfatoorah/') || widget.url.contains('/payment/fatoorah/');

  final MyFatoorahPaymentService _myFatoorahService = MyFatoorahPaymentService();

  /// Set once the customer is back and we are asking the server what happened.
  bool _confirmingPayment = false;
  String? _confirmingMessageKey;

  @override
  void initState() {
    super.initState();

    controller = WebViewController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initWebViewController();
      _isInitialized = true;
    }
  }

  void _initWebViewController() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).cardColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) => _onUrl(url),
          onPageFinished: (String url) => _onUrl(url),
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            // A wallet or a bank app. Anything that is not http(s) is not something a WebView can show:
            // mada and STC Pay 3-D Secure steps, and Apple Pay, hand off to an installed app with their
            // own scheme, and letting the WebView try to load it shows the customer an error page in
            // the middle of paying. Hand it to the OS instead and leave the WebView where it is, so the
            // customer comes back to a live payment session.
            if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) {
              _launchExternally(request.url);
              return NavigationDecision.prevent;
            }

            // The customer is back from MyFatoorah. Stop here and ask our server; do not let the
            // address decide the outcome.
            if (_isMyFatoorah && MyFatoorahPaymentService.isReturnUrl(request.url)) {
              _handleMyFatoorahReturn(request.url);
              return NavigationDecision.prevent;
            }

            if (_isRedirectUrl(request.url)) {
              _checkRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isRedirectUrl(String url) {
    // MyFatoorah never resolves this way. Its own return is handled by _handleMyFatoorahReturn, and
    // leaving this matcher able to fire for it would reintroduce exactly the bug being fixed: the
    // pending page's address contains neither `success` nor `fail`, but the final page it forwards to
    // does, and reacting to that address instead of to the server's answer is what shows "payment
    // failed" to someone who has in fact paid.
    if (_isMyFatoorah) return false;

    return ((url.contains('success') && url.contains('token')) ||
        url.contains('fail') ||
        url.contains('cancel')) &&
        url.contains(AppConstants.baseUrl);
  }

  /// Every URL the WebView visits, from either lifecycle callback.
  void _onUrl(String url) {
    if (_isMyFatoorah && MyFatoorahPaymentService.isReturnUrl(url)) {
      _handleMyFatoorahReturn(url);
      return;
    }

    _checkRedirect(url);
  }

  /// Open a wallet or banking app the payment page asked for.
  ///
  /// Launched without asking `canLaunchUrl` first, which is the point. On iOS that call is
  /// `canOpenURL:`, which answers NO for any scheme not listed in `LSApplicationQueriesSchemes`, and
  /// Info.plist lists five Facebook schemes and nothing for payments; on Android 11 and above the
  /// `<queries>` block has the same effect. So the gate refused every scheme MyFatoorah actually
  /// uses: the WebView was told not to load `stcpay://`, the launch was then skipped, and the
  /// customer got a dead tap in the middle of paying — no app, no error, no message.
  ///
  /// The schemes a gateway may hand us cannot be enumerated ahead of time, so they are not declared;
  /// the launch is simply attempted, and a PlatformException is the only honest signal that nothing
  /// on the device can open it. Then the customer is told to pick another method, and the WebView is
  /// left on a live session — never a payment failure, because nothing has been paid at this point.
  Future<void> _launchExternally(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // The exception is not logged: a wallet hand-off URL can carry a payment token, and the
      // message embeds the URL.
      if (!mounted) return;

      showCustomSnackBarWidget(
        getTranslated('could_not_open_payment_app', context),
        context,
        snackBarType: SnackBarType.warning,
      );
    }
  }

  /// The customer is back from MyFatoorah. Ask the server what actually happened.
  ///
  /// This is the whole point of the MyFatoorah path: the outcome comes from a server that has checked
  /// with MyFatoorah, not from the address bar. While the answer is unknown the customer is told it is
  /// being confirmed — never that it failed, because their money may already have moved.
  Future<void> _handleMyFatoorahReturn(String url) async {
    if (!_canRedirect) return;
    _canRedirect = false;

    final String? reference = MyFatoorahPaymentService.referenceFromUrl(url);

    if (reference == null) {
      // Back, but with no reference to ask about. Shown as unresolved rather than failed.
      _showMyFatoorahUnresolved();
      return;
    }

    if (mounted) {
      setState(() {
        _confirmingPayment = true;
        _isLoading = false;
        _confirmingMessageKey = 'confirming_your_payment';
      });
    }

    final MyFatoorahPaymentStatus status = await _myFatoorahService.pollUntilResolved(
      reference,
      onUpdate: (MyFatoorahPaymentStatus update) {
        if (mounted) {
          setState(() => _confirmingMessageKey = update.messageKey);
        }
      },
    );

    if (!mounted) return;

    if (status.paid) {
      _onMyFatoorahPaid(status);
      return;
    }

    if (status.isDefiniteFailure) {
      // The server says, on MyFatoorah's authority, that no money moved. Safe to say so.
      RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement, page: 'home');

      _showResultUI(
        isBottomSheet: false,
        icon: Icons.clear,
        titleKey: status.status == 'cancelled' ? 'payment_cancelled' : 'payment_failed',
        descKey: status.status == 'cancelled' ? 'your_payment_cancelled' : 'your_payment_failed',
        isFailed: true,
      );
      return;
    }

    // Still unknown. The server finishes the job from MyFatoorah's webhook or its reconciliation
    // sweep, so the customer's order is not waiting on this screen.
    _showMyFatoorahUnresolved();
  }

  void _onMyFatoorahPaid(MyFatoorahPaymentStatus status) {
    final bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

    if (widget.orderId.trim().isNotEmpty && widget.orderId.trim() != 'null') {
      RouterHelper.getOrderDetailsScreenRoute(
        orderId: int.tryParse(widget.orderId) ?? 0,
        action: RouteAction.pushReplacement,
        isNotification: true,
      );
      return;
    }

    if (widget.fromWallet) {
      _onWalletFunded();
      return;
    }

    if (isLoggedIn && status.orderIds.isNotEmpty) {
      RouterHelper.getOrderScreenRoute(
        isBackButtonExist: true,
        action: RouteAction.push,
        fromPlaceOrder: true,
      );
    } else {
      RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement, page: 'home');
    }

    _showResultUI(
      isBottomSheet: true,
      orderIds: status.orderIds.isNotEmpty ? status.orderIds.join(',') : null,
      icon: Icons.check,
      titleKey: 'order_placed',
      descKey: 'your_order_placed',
    );
  }

  /// A wallet top-up that the server has confirmed.
  ///
  /// The balance is re-read rather than adjusted locally: the credited amount is the server's to
  /// state, bonuses included, and this screen has no business computing it.
  void _onWalletFunded() {
    Provider.of<WalletController>(context, listen: false).getTransactionList(1, isUpdate: false);

    RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement, page: 'home');

    _showResultUI(
      isBottomSheet: false,
      icon: Icons.done,
      titleKey: 'fund_added_into_wallet',
      descKey: 'your_fund_successfully_added_to_your_wallet',
    );
  }

  /// "We are confirming your payment." Deliberately not an error, and deliberately tells the customer
  /// not to pay again — paying twice is the mistake an ambiguous screen provokes.
  void _showMyFatoorahUnresolved() {
    RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement, page: 'home');

    _showResultUI(
      isBottomSheet: false,
      icon: Icons.schedule,
      titleKey: 'confirming_your_payment',
      descKey: 'we_are_confirming_your_payment_do_not_pay_again',
      isFailed: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafePadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (val, _) {
        if (_canRedirect) _exitApp(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: AppBar(
          title: Text(getTranslated('payment', context) ?? 'Payment'),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => _exitApp(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: controller),
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor),
                      ),
                    ),

                  // Covers the WebView while the server is being asked what happened. Opaque on
                  // purpose: behind it is MyFatoorah's own "thank you" page, and letting the customer
                  // read that while we do not yet know the outcome is how they end up believing an
                  // unconfirmed payment succeeded.
                  if (_confirmingPayment)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context).cardColor,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              getTranslated(
                                  _confirmingMessageKey ?? 'confirming_your_payment', context) ??
                                  'Confirming your payment…',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              getTranslated(
                                  'we_are_confirming_your_payment_do_not_pay_again', context) ??
                                  'Please wait and do not pay again.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: bottomSafePadding),
          ],
        ),
      ),
    );
  }

  void _checkRedirect(String url) {
    if (_canRedirect && _isRedirectUrl(url)) {
      _canRedirect = false;

      bool isSuccess = url.contains('success');
      bool isFailed = url.contains('fail');
      bool isCancel = url.contains('cancel');
      bool isNewUser = _getIsNewUser(url);
      String? orderIds = _getOrderIds(url);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePaymentResult(
            isSuccess, isFailed, isCancel, isNewUser, orderIds);
      });
    }
  }

  void _handlePaymentResult(bool isSuccess, bool isFailed, bool isCancel,
      bool isNewUser, String? orderIds) {
    bool isLoggedIn =
    Provider.of<AuthController>(context, listen: false).isLoggedIn();

    // if (Navigator.canPop(context)) {
    //   Navigator.pop(context);
    // }

    if (isSuccess) {
      if (widget.fromWallet) {
        _onWalletFunded();
        return;
      }

      if (widget.orderId.trim().isNotEmpty && orderIds == null) {
        RouterHelper.getOrderDetailsScreenRoute(
            orderId: int.parse(widget.orderId),
            action: RouteAction.pushReplacement,
            isNotification: true);
      } else if (isLoggedIn && orderIds != null && orderIds.isNotEmpty) {
        RouterHelper.getOrderScreenRoute(
            isBackButtonExist: true,
            action: RouteAction.push,
            fromPlaceOrder: true);
      } else {
        RouterHelper.getDashboardRoute(
            action: RouteAction.pushReplacement, page: 'home');
      }

      if (widget.orderId.trim() == 'null') {
        _showResultUI(
            isBottomSheet: true,
            orderIds: orderIds,
            isNewUser: isNewUser,
            icon: Icons.check,
            titleKey:
            isNewUser ? 'order_placed_Account_Created' : 'order_placed',
            descKey: 'your_order_placed');
      }
    } else {
      RouterHelper.getDashboardRoute(
          action: RouteAction.pushReplacement, page: 'home');

      _showResultUI(
          isBottomSheet: false,
          icon: Icons.clear,
          titleKey: isFailed ? 'payment_failed' : 'payment_cancelled',
          descKey: isFailed ? 'your_payment_failed' : 'your_payment_cancelled',
          isFailed: true);
    }
  }

  void _showResultUI(
      {required bool isBottomSheet,
        String? orderIds,
        bool isNewUser = false,
        required IconData icon,
        required String titleKey,
        required String descKey,
        bool isFailed = false}) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (isBottomSheet) {
        showModalBottomSheet(
          context: Get.context!,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SafeArea(
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
              child: OrderPlaceBottomSheetWidget(
                  orderID: orderIds,
                  icon: icon,
                  title: getTranslated(titleKey, Get.context!),
                  description: getTranslated(descKey, Get.context!),
                  isFailed: isFailed),
            ),
          ),
        );
      } else {
        showAnimatedDialog(
            Get.context!,
            OrderPlaceDialogWidget(
                icon: icon,
                title: getTranslated(titleKey, Get.context!),
                description: getTranslated(descKey, Get.context!),
                isFailed: isFailed),
            dismissible: false,
            willFlip: true);
      }
    });
  }

  bool _getIsNewUser(String url) {
    try {
      Uri uri = Uri.parse(url);
      return uri.queryParameters['new_user'] == '1';
    } catch (e) {
      return false;
    }
  }

  String? _getOrderIds(String url) {
    try {
      Uri uri = Uri.parse(url);
      String? encodedData = uri.queryParameters['order_ids'];
      if (encodedData != null && encodedData.isNotEmpty) {
        String decoded = utf8.decode(base64.decode(encodedData));
        return Provider.of<CheckoutController>(context, listen: false)
            .extractId(decoded);
      }
    } catch (e) {
      debugPrint("Order ID Extraction Error: $e");
    }
    return '';
  }

  Future<void> _exitApp(BuildContext context) async {
    // While the server is being asked, backing out must not claim the payment was cancelled: the money
    // may already have moved. The confirmation keeps running and the server settles it regardless.
    if (_confirmingPayment) {
      RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement, page: 'home');
      return;
    }

    if (!_canRedirect) return;
    _canRedirect = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      RouterHelper.getDashboardRoute(
          action: RouteAction.pushReplacement, page: 'home');
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      showAnimatedDialog(
        Get.context!,
        OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: getTranslated('payment_cancelled', Get.context!),
          description: getTranslated('your_payment_cancelled', Get.context!),
          isFailed: true,
        ),
        dismissible: false,
        willFlip: true,
      );
    });
  }
}