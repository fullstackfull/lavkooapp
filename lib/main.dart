// assets/lottie copy/chat.json assets/lottie copy/empty.json assets/lottie copy/fire.json assets/lottie copy/getnotification.json assets/lottie copy/succes.json assets/lottie copy/Whatsapp.json
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:syriapharmacy/services/meta_tracking_service.dart';
import 'package:syriapharmacy/services/tracking_permission_helper.dart';

import 'firebase_options.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/local/cache_response.dart';
import 'package:syriapharmacy/data/services/app_health_reporter.dart';
import 'package:syriapharmacy/features/health/domain/models/news_model.dart';
import 'package:syriapharmacy/features/auth/controllers/facebook_login_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/google_login_controller.dart';
import 'package:syriapharmacy/features/banner/controllers/banner_controller.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/compare/controllers/compare_controller.dart';
import 'package:syriapharmacy/features/contact_us/controllers/contact_us_controller.dart';
import 'package:syriapharmacy/features/deal/controllers/featured_deal_controller.dart';
import 'package:syriapharmacy/features/deal/controllers/flash_deal_controller.dart';
import 'package:syriapharmacy/features/location/controllers/location_controller.dart';
import 'package:syriapharmacy/features/loyaltyPoint/controllers/loyalty_point_controller.dart';
import 'package:syriapharmacy/features/notification/controllers/notification_controller.dart';
import 'package:syriapharmacy/features/onboarding/controllers/onboarding_controller.dart';
import 'package:syriapharmacy/features/order/controllers/order_controller.dart';
import 'package:syriapharmacy/features/order_details/controllers/order_details_controller.dart';
import 'package:syriapharmacy/features/product/controllers/product_controller.dart';
import 'package:syriapharmacy/features/product/controllers/seller_product_controller.dart';
import 'package:syriapharmacy/features/product_details/controllers/product_details_controller.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/refund/controllers/refund_controller.dart';
import 'package:syriapharmacy/features/reorder/controllers/re_order_controller.dart';
import 'package:syriapharmacy/features/restock/controllers/restock_controller.dart';
import 'package:syriapharmacy/features/review/controllers/review_controller.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer_registry.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/screens/splash_screen.dart';
import 'package:syriapharmacy/features/support/controllers/support_ticket_controller.dart';
import 'package:syriapharmacy/features/wallet/controllers/wallet_controller.dart';
import 'package:syriapharmacy/features/wishlist/controllers/wishlist_controller.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/push_notification/models/notification_body.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/brand/controllers/brand_controller.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/category/controllers/category_controller.dart';
import 'package:syriapharmacy/features/chat/controllers/chat_controller.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/search_product/controllers/search_product_controller.dart';
import 'package:syriapharmacy/features/shop/controllers/shop_controller.dart';
import 'package:syriapharmacy/push_notification/notification_helper.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/theme/dark_theme.dart';
import 'package:syriapharmacy/theme/light_theme.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'di_container.dart' as di;
import 'features/splash/domain/models/config_model.dart';
import 'helper/custom_delegate.dart';
import 'localization/app_localization.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final database = AppDatabase();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  // A widget that throws while BUILDING shows Flutter's grey box to shoppers in release mode.
  // Collapsing it to nothing is strictly better on a shop screen — a missing card beats a grey
  // rectangle — and it is the only mechanism that truly isolates server-driven theme sections,
  // because their descendants build after any scoped override has been restored. Debug builds
  // keep the red screen so developers still see every error.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const SizedBox.shrink();
  }

  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Installed before anything else can fail: a crash during startup is exactly the one the
  // Monitoring panel never hears about otherwise.
  AppHealthReporter.install();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Hive.initFlutter();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  await di.init();
  // Initialize Meta Tracking Service
  await MetaTrackingService().initialize(dioClient: di.sl<DioClient>());

  // Request tracking permission (iOS 14.5+)
  if (MetaTrackingService.enabled) {
    await TrackingPermissionHelper.requestTrackingPermission();
  }

  // Fire-and-forget: this launch, plus any crash the previous one left behind. Never awaited —
  // the app must not wait on a monitoring counter to start.
  unawaited(AppHealthReporter.reportLaunch(di.sl<DioClient>()));

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  String? path;
  NotificationBody? body;

  try {
    final RemoteMessage? remoteMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (remoteMessage != null) {
      body = NotificationHelper.convertNotification(remoteMessage.data);
    }
    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    path = await initDynamicLinks();
  } catch (_) {}

  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => NewsProvider()),
      ChangeNotifierProvider(create: (context) => di.sl<CategoryController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ShopController>()),
      ChangeNotifierProvider(create: (context) => di.sl<FlashDealController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<FeaturedDealController>()),
      ChangeNotifierProvider(create: (context) => di.sl<BrandController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductController>()),
      ChangeNotifierProvider(create: (context) => di.sl<BannerController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<ProductDetailsController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<OnBoardingController>()),
      ChangeNotifierProvider(create: (context) => di.sl<AuthController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<SearchProductController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CouponController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ChatController>()),
      ChangeNotifierProvider(create: (context) => di.sl<OrderController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<NotificationController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProfileController>()),
      ChangeNotifierProvider(create: (context) => di.sl<WishListController>()),
      ChangeNotifierProvider(create: (context) => di.sl<SplashController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<DynamicThemeController>()),
      // Not a ChangeNotifier: the registry never changes after startup. Provided so a renderer
      // can be reached from the widget tree instead of the service locator, which is what keeps
      // the renderers testable with a registry built for the test.
      Provider<SectionRendererRegistry>(
          create: (context) => di.sl<SectionRendererRegistry>()),
      ChangeNotifierProvider(create: (context) => di.sl<CartController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<SupportTicketController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<LocalizationController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ThemeController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<GoogleSignInController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<FacebookLoginController>()),
      ChangeNotifierProvider(create: (context) => di.sl<AddressController>()),
      ChangeNotifierProvider(create: (context) => di.sl<WalletController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CompareController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CheckoutController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<LoyaltyPointController>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocationController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ContactUsController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ShippingController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<OrderDetailsController>()),
      ChangeNotifierProvider(create: (context) => di.sl<RefundController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ReOrderController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ReviewController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<SellerProductController>()),
      ChangeNotifierProvider(create: (context) => di.sl<RestockController>()),
    ],
    child: MyApp(body: body, route: path),
  ));
}

/// The path the app was opened on, when it was opened by a link.
///
/// Navigation itself is not done here. Both platforms have `flutter_deeplinking_enabled`, so the
/// engine hands the link to the router and `RouterHelper` matches it — a published path lands on
/// the gateway, which asks the shop what the link means. Routing it a second time from this stream
/// would open the screen twice. What is still needed here is the answer to "did a link start this
/// launch", because the app has to finish loading its config before that screen can be built.
Future<String?> initDynamicLinks() async {
  final uri = await AppLinks().getInitialLink();

  return uri?.path;
}

class MyApp extends StatefulWidget {
  final NotificationBody? body;
  final String? route;
  const MyApp({super.key, required this.body, this.route});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData? _initialTheme;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize once — never rebuilt by ThemeController
    _initialTheme ??= _resolveTheme(
      Provider.of<ThemeController>(context, listen: false),
    );
  }

  ThemeData _resolveTheme(ThemeController tc) {
    return tc.darkTheme
        ? dark(
            primaryColor: tc.selectedPrimaryColor,
            secondaryColor: tc.selectedSecondaryColor)
        : light(
            primaryColor: tc.selectedPrimaryColor,
            secondaryColor: tc.selectedSecondaryColor);
  }

  void _loadData() async {
    if (widget.route != null) {
      final AuthController authProvider =
          Provider.of<AuthController>(context, listen: false);

      if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
        await Provider.of<ProfileController>(context, listen: false)
            .getUserInfo(context);
      }

      if (mounted) {
        Provider.of<SplashController>(context, listen: false)
            .initConfig(context, (_) {}, (ConfigModel? configModel) async {
          if (configModel != null) {
            if (authProvider.isLoggedIn()) {
              await authProvider.updateToken(context);
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Locale> locals = [];
    for (var language in AppConstants.languages) {
      locals.add(Locale(language.languageCode!, language.countryCode));
    }

    // Initialise on first build if didChangeDependencies hasn't run yet
    _initialTheme ??= _resolveTheme(
      Provider.of<ThemeController>(context, listen: false),
    );

    return Consumer<SplashController>(builder: (context, splashController, _) {
      if ((widget.route != null && splashController.configModel == null)) {
        // Splash screen — use ThemeController directly (no animation needed)
        return Consumer<ThemeController>(
          builder: (context, themeController, _) => Theme(
            data: _resolveTheme(themeController),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: MediaQueryData.fromView(View.of(context)),
                child: SplashWidget(),
              ),
            ),
          ),
        );
      }

      // ThemeProvider is created ONCE — ripple animation works correctly
      return ThemeProvider(
        initTheme: _initialTheme!,
        duration: const Duration(milliseconds: 700),
        builder: (_, theme) {
          return Consumer<LocalizationController>(
            builder: (context, localizationController, _) {
              return MaterialApp.router(
                routerConfig: RouterHelper.goRoutes,
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: theme,
                locale: localizationController.locale,
            localizationsDelegates: [
              AppLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackLocalizationDelegate()
            ],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: SafeArea(top: false, child: child!),
              );
            },
            supportedLocales: locals,
              );
            },
          );
        },
      );
    });
  }
}

class Get {
  static BuildContext? get context => navigatorKey.currentContext;
  static NavigatorState? get navigator => navigatorKey.currentState;
}
