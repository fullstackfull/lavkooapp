import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/helper/network_info.dart';
import 'package:syriapharmacy/features/splash/widgets/launch_transition_widget.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/push_notification/models/notification_body.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/common/basewidget/no_internet_screen_widget.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBody? body;
  const SplashScreen({super.key, this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  // late StreamSubscription<ConnectivityResult> _onConnectivityChanged;

  /// Resolves when this screen has been replaced by the shopper's destination —
  /// which is precisely the moment the app is ready and the next screen exists
  /// underneath the opening.
  final Completer<void> _appReady = Completer<void>();

  /// The launch sequence, held in the root overlay rather than in this route.
  ///
  /// Concept 3A ends by shrinking its dark cover into the very gradient the home
  /// header wears, over the real screen — so the sequence has to outlive the
  /// route that started it. Drawing it inside this route instead would make the
  /// replacement a hard cut, which is the one thing the handover exists to
  /// prevent.
  OverlayEntry? _launchOverlay;

  @override
  void initState() {
    super.initState();

    // bool firstTime = true;
    // _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    //   if(!firstTime) {
    //     bool isNotConnected = result != ConnectivityResult.wifi && result != ConnectivityResult.mobile;
    //     isNotConnected ? const SizedBox() : ScaffoldMessenger.of(context).hideCurrentSnackBar();
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //       backgroundColor: isNotConnected ? Colors.red : Colors.green,
    //       duration: Duration(seconds: isNotConnected ? 6000 : 3),
    //       content: Text(isNotConnected ? getTranslated('no_connection', context)! : getTranslated('connected', context)!,
    //         textAlign: TextAlign.center)));
    //     if(!isNotConnected) {
    //       _route();
    //     }
    //   }
    //   firstTime = false;
    // });

    // The launch sequence decides WHEN Home appears; the config work starts
    // now so a fast device is not made to wait out a fixed delay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLaunchOverlay();
      _route();
    });
  }

  @override
  void dispose() {
    // This route being replaced IS the readiness signal: the destination is
    // mounted, and the opening may hand the screen over to it.
    if (!_appReady.isCompleted) {
      _appReady.complete();
    }
    super.dispose();
    // _onConnectivityChanged.cancel();
  }

  void _showLaunchOverlay() {
    final OverlayState? overlay =
        Navigator.maybeOf(context, rootNavigator: true)?.overlay;
    if (overlay == null || _launchOverlay != null) {
      return;
    }
    _launchOverlay = OverlayEntry(
      // No backdrop of its own: the sequence's gradient block starts full-height
      // and shrinks, and what it uncovers has to be the screen underneath — an
      // opaque layer here would hide exactly what the handover is revealing.
      builder: (_) => LaunchTransitionWidget(
        appReady: _appReady.future,
        onFinished: _removeLaunchOverlay,
      ),
    );
    overlay.insert(_launchOverlay!);

    // Insurance, not choreography: an opening that somehow never reported
    // finished would leave an opaque layer over the whole app. Nothing may
    // outlive its own sequence by this much.
    Future.delayed(const Duration(seconds: 20), _removeLaunchOverlay);
  }

  void _removeLaunchOverlay() {
    _launchOverlay?.remove();
    _launchOverlay = null;
  }

  void _route() {
    NetworkInfo.checkConnectivity(context);
    Provider.of<SplashController>(context, listen: false).initConfig(context,
            (ConfigModel? configModel) {
          Provider.of<SplashController>(Get.context!, listen: false)
              .initSharedPrefData();
          // Timer(const Duration(seconds: 2), () {
          final config = Provider.of<SplashController>(Get.context!, listen: false)
              .configModel;

          Future.delayed(const Duration(milliseconds: 0)).then((_) {
            if (_updateIsRequired(config?.userAppVersionControl)) {
              RouterHelper.getUpdateRoute(action: RouteAction.pushReplacement);
            } else if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
                config?.maintenanceModeData?.selectedMaintenanceSystem
                    ?.customerApp ==
                    1 &&
                !Provider.of<SplashController>(Get.context!, listen: false)
                    .isConfigCall) {
              RouterHelper.getMaintenanceRoute(action: RouteAction.pushReplacement);
            } else if (Provider.of<AuthController>(Get.context!, listen: false)
                .isLoggedIn()) {
              Provider.of<AuthController>(Get.context!, listen: false)
                  .updateToken(Get.context!);
              if (widget.body != null) {
                if (widget.body!.type == 'order') {
                  RouterHelper.getOrderDetailsScreenRoute(
                    action: RouteAction.pushReplacement,
                    orderId: widget.body!.orderId!,
                  );
                } else if (widget.body!.type == 'notification') {
                  RouterHelper.getNotificationRoute(
                      action: RouteAction.pushReplacement);
                } else if (widget.body!.type == 'wallet') {
                  RouterHelper.getWalletRoute(
                      action: RouteAction.pushReplacement, isBackButtonExist: true);
                } else if (widget.body!.type == 'chatting') {
                  RouterHelper.getInboxScreenRoute(
                    action: RouteAction.pushReplacement,
                    isBackButtonExist: true,
                    fromNotification: true,
                    initIndex:
                    widget.body!.messageKey == 'message_from_delivery_man'
                        ? 0
                        : 1,
                  );
                } else if (widget.body!.type == 'product_restock_update') {
                  RouterHelper.getProductDetailsRoute(
                      action: RouteAction.pushReplacement,
                      productId: int.parse(widget.body!.productId!),
                      slug: widget.body!.slug,
                      isNotification: true);
                } else {
                  RouterHelper.getNotificationRoute(
                      action: RouteAction.pushReplacement, fromNotification: true);
                }
              } else {
                // Navigator.of(Get.context!).pushReplacement(
                //   PageRouteBuilder(
                //     pageBuilder: (context, animation, secondaryAnimation) => const DashBoardScreen(),
                //     transitionDuration: Duration.zero, // Removes transition duration
                //     reverseTransitionDuration: Duration.zero, // Removes reverse transition
                //     transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                //   ),
                // );

                RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement);
              }
            } else if (Provider.of<SplashController>(Get.context!, listen: false)
                .showIntro()!) {
              RouterHelper.getOnboardingRoute(
                action: RouteAction.pushReplacement,
                indicatorColor:
                Provider.of<ThemeController>(Get.context!, listen: false)
                    .darkTheme
                    ? Theme.of(Get.context!).colorScheme.onTertiary
                    : Theme.of(Get.context!).hintColor,
                selectedIndicatorColor: Theme.of(Get.context!).primaryColor,
              );
            } else {
              if (Provider.of<AuthController>(Get.context!, listen: false)
                  .getGuestToken() !=
                  null &&
                  Provider.of<AuthController>(Get.context!, listen: false)
                      .getGuestToken() !=
                      '1') {
                // Navigator.of(Get.context!).pushReplacement(
                //   PageRouteBuilder(
                //     pageBuilder: (context, animation, secondaryAnimation) => const DashBoardScreen(),
                //     transitionDuration: Duration.zero, // Removes transition duration
                //     reverseTransitionDuration: Duration.zero, // Removes reverse transition
                //     transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                //   ),
                // );

                RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement);
              } else {
                Provider.of<AuthController>(Get.context!, listen: false)
                    .getGuestIdUrl();
                RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement);

                // Navigator.of(Get.context!).pushReplacement(
                //   PageRouteBuilder(
                //     pageBuilder: (context, animation, secondaryAnimation) => const DashBoardScreen(),
                //     transitionDuration: Duration.zero, // Removes transition duration
                //     reverseTransitionDuration: Duration.zero, // Removes reverse transition
                //     transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                //   ),
                // );
              }
            }
          });
          //  });
        }, (ConfigModel? configModel) {
          Provider.of<SplashController>(Get.context!, listen: false)
              .initSharedPrefData();
          // Timer(const Duration(seconds: 1), () {
          final config = Provider.of<SplashController>(Get.context!, listen: false)
              .configModel;
          if (_updateIsRequired(config?.userAppVersionControl)) {
            RouterHelper.getUpdateRoute(action: RouteAction.pushReplacement);
          } else if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
              config?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp ==
                  1 &&
              !config!.localMaintenanceMode!) {
            RouterHelper.getMaintenanceRoute(action: RouteAction.pushReplacement);
          } else if (Provider.of<AuthController>(Get.context!, listen: false)
              .isLoggedIn() &&
              !configModel!.hasLocaldb!) {
            Provider.of<AuthController>(Get.context!, listen: false)
                .updateToken(Get.context!);
            if (widget.body != null) {
              if (widget.body!.type == 'order') {
                RouterHelper.getOrderDetailsScreenRoute(
                  action: RouteAction.pushReplacement,
                  orderId: widget.body!.orderId!,
                );
              } else if (widget.body!.type == 'notification') {
                RouterHelper.getNotificationRoute(
                    action: RouteAction.pushReplacement);
              } else if (widget.body!.type == 'wallet') {
                RouterHelper.getWalletRoute(
                    action: RouteAction.pushReplacement, isBackButtonExist: true);
              } else if (widget.body!.type == 'chatting') {
                RouterHelper.getInboxScreenRoute(
                  action: RouteAction.push,
                  isBackButtonExist: true,
                  fromNotification: true,
                  initIndex: widget.body!.messageKey == 'message_from_delivery_man'
                      ? 0
                      : 1,
                );
              } else if (widget.body!.type == 'product_restock_update') {
                RouterHelper.getProductDetailsRoute(
                    action: RouteAction.push,
                    productId: int.parse(widget.body!.productId!),
                    slug: widget.body!.slug,
                    isNotification: true);
              } else {
                RouterHelper.getNotificationRoute(
                    action: RouteAction.pushReplacement, fromNotification: true);
              }
            } else {
              RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement);
            }
          } else if (Provider.of<SplashController>(Get.context!, listen: false)
              .showIntro()! &&
              !configModel!.hasLocaldb!) {
            RouterHelper.getOnboardingRoute(
              action: RouteAction.pushReplacement,
              indicatorColor:
              Provider.of<ThemeController>(Get.context!, listen: false)
                  .darkTheme
                  ? Theme.of(Get.context!).colorScheme.onTertiary
                  : Theme.of(Get.context!).hintColor,
              selectedIndicatorColor: Theme.of(Get.context!).primaryColor,
            );
          } else if (!configModel!.hasLocaldb! ||
              (configModel.hasLocaldb! &&
                  configModel.localMaintenanceMode! &&
                  !(config?.maintenanceModeData?.maintenanceStatus == 1 &&
                      config?.maintenanceModeData?.selectedMaintenanceSystem
                          ?.customerApp ==
                          1))) {
            if (Provider.of<AuthController>(Get.context!, listen: false)
                .getGuestToken() !=
                null &&
                Provider.of<AuthController>(Get.context!, listen: false)
                    .getGuestToken() !=
                    '1') {
              RouterHelper.getDashboardRoute(action: RouteAction.pushReplacement);
            } else {
              Provider.of<AuthController>(Get.context!, listen: false)
                  .getGuestIdUrl();
              RouterHelper.getDashboardRoute(
                  action: RouteAction.pushNamedAndRemoveUntil);
            }
          }
          // });
        }).then((bool isSuccess) {
      if (isSuccess) {}
    });
  }

  /// Whether this build is too old to run, per the shop's own setting.
  ///
  /// Two things decide it, and only one of them used to be read. The shop stores a minimum version
  /// AND a switch next to it, and the switch was ignored here: a merchant who turned forced updates
  /// off in Admin -> Business Settings -> App Settings watched the app go on forcing them, with no
  /// way from the panel to stop it.
  ///
  /// The comparison is only meaningful when both numbers come from the same release line. A shop
  /// whose minimum still carries an older lineage's numbering (the installer's default is 14.1)
  /// will hold back a perfectly current build until that field is set to this app's own numbering.
  bool _updateIsRequired(UserAppVersionControl? control) {
    final platform = Platform.isIOS ? control?.forIos : control?.forAndroid;

    if (platform == null || platform.status != 1) {
      return false;
    }

    final minimum = platform.version;
    if (minimum == null || minimum.trim().isEmpty) {
      return false;
    }

    return compareVersions(minimum, AppConstants.appVersion) == 1;
  }

  int compareVersions(String version1, String version2) {
    List<String> v1Components = version1.split('.');
    List<String> v2Components = version2.split('.');

    int maxLength = v1Components.length > v2Components.length
        ? v1Components.length
        : v2Components.length;

    for (int i = 0; i < maxLength; i++) {
      int v1Part =
      i < v1Components.length ? int.tryParse(v1Components[i]) ?? 0 : 0;
      int v2Part =
      i < v2Components.length ? int.tryParse(v2Components[i]) ?? 0 : 0;

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      backgroundColor: const Color(0xFF063523),
      body: Provider.of<SplashController>(context).hasConnection
      // The opening is drawn by the overlay above this route; the route
      // itself only holds the brand colour behind it.
          ? const SplashWidget()
          : Builder(builder: (context) {
        // Nothing to open into: the sequence steps aside for the message.
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _removeLaunchOverlay());
        return const NoInternetOrDataScreenWidget(
            isNoInternet: true, child: SplashScreen());
      }),
    );
  }
}

/// The launch surface — the approved Concept 3A sequence.
///
/// It is shown both while the shop's config is still loading and while the
/// splash screen decides where to send the shopper; the sequence holds its
/// resting frame until the app is ready and then hands over to Home itself, so
/// there is one opening rather than a splash followed by a second animation.
class SplashWidget extends StatelessWidget {
  const SplashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // A branded surface: the device's dark-mode choice does not apply here.
    // The animated layer lives in the root overlay, so it can outlive this
    // route and finish over the screen that replaces it.
    return const ColoredBox(color: Color(0xFF063523));
  }
}
