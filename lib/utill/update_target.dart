import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Where the update button sends a customer whose build the shop holds back (`UpdateGate.isRequired` decides whether it is held back at
/// all). The decision lived in the button's own callback, where nothing could test it and where an empty link ended the journey: the
/// live shop publishes a floor of 14.1 with `link: ""` for both platforms, and the screen handed that empty string to the launcher, which
/// refuses it. It is the same decision, in a place a test can reach (test/update_target_test.dart).
class UpdateTarget {
  const UpdateTarget._();

  /// Google Play, addressed by the id the build carries: the Play app's own scheme first, so a customer who has Play lands on the page
  /// inside it, and the web page after it for a device that has no Play app. android/app/src/main/AndroidManifest.xml already declares the
  /// query that lets the launcher see the `market` scheme, which is why it is worth asking about.
  ///
  /// become_merchant_screen.dart builds a Play page of its own and is deliberately left alone: it points at the seller app, under the
  /// seller's id, so it is a different app's page and not another copy of this one.
  static const String _playStoreAppScheme = 'market://details?id=';
  static const String _playStoreAppPage =
      'https://play.google.com/store/apps/details?id=';

  /// The App Store, scoped to the storefront of the live market. A country-less apps.apple.com path is a web page the customer has to
  /// search in again; a storefront path opens the App Store itself, and Apple moves a customer signed into another storefront to their own.
  static const String _appStoreStorefront = 'sa';
  static const String _appStoreSearch =
      'https://apps.apple.com/$_appStoreStorefront/search?media=software&term=';

  /// This build's own place on the store of the platform it runs on, in the order it is worth trying, and never empty.
  ///
  /// Google Play addresses an app by the id the build carries, so Android is sent to the app's own page, twice over. Apple addresses an app
  /// page by a number it issues, and no source in this repository carries that number, so iOS is sent to the store's search for the app by
  /// name: a real App Store destination, but the store's search and not the app's own page. That is the one part of this the sources cannot
  /// supply, and closing it needs the App Store id.
  ///
  /// `itms-apps://`, which would open the App Store app directly the way `market://` opens Play, is deliberately not tried: ios/Runner/
  /// Info.plist does not declare the scheme under `LSApplicationQueriesSchemes`, so the launcher refuses it on a device.
  static List<String> storeTargets({required bool isIos}) => isIos
      ? <String>[
          '$_appStoreSearch${Uri.encodeQueryComponent(AppConstants.appName)}'
        ]
      : <String>[
          '$_playStoreAppScheme${AppConstants.androidApplicationId}',
          '$_playStoreAppPage${AppConstants.androidApplicationId}',
        ];

  /// What the update button tries, in the order it tries them, and never empty.
  ///
  /// The link the shop configured for the platform comes first and is passed on exactly as it was given, so a shop that fills that field
  /// keeps what it has today. A link that is missing, empty or only blank space is no target at all, and the store is then the whole list.
  /// The store also follows a configured link the device cannot open, so a link the shop mistyped no longer leaves the customer with
  /// nowhere to go.
  static List<String> candidates({
    required UserAppVersionControl? control,
    required bool isIos,
  }) {
    final String? configured =
        (isIos ? control?.forIos : control?.forAndroid)?.link;
    final List<String> store = storeTargets(isIos: isIos);

    if (configured == null || configured.trim().isEmpty) {
      return store;
    }

    return <String>[configured, ...store];
  }
}
