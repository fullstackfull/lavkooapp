import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/firebase_options.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// Where the update button sends a customer whose build the shop holds back (`UpdateGate.isRequired` decides whether it is held back at
/// all). The decision lived in the button's own callback, where nothing could test it and where an empty link ended the journey: the
/// live shop publishes a floor of 14.1 with `link: ""` for both platforms, and the screen handed that empty string to the launcher, which
/// refuses it. It is the same decision, in a place a test can reach (test/update_target_test.dart).
class UpdateTarget {
  const UpdateTarget._();

  static const String _playStoreAppPage =
      'https://play.google.com/store/apps/details?id=';
  static const String _appStoreSearch = 'https://apps.apple.com/search?term=';

  /// The id this build carries, read where the app already keeps it: the bundle id its Firebase options were generated with. It is the same
  /// string as `applicationId` in android/app/build.gradle.kts, `package` in the Android manifest and `BUNDLE_ID` in
  /// ios/Runner/GoogleService-Info.plist, and the test holds those to each other so that a build whose id moves cannot keep this one.
  static String get applicationId => DefaultFirebaseOptions.ios.iosBundleId ?? '';

  /// This build's own place on the store of the platform it runs on.
  ///
  /// Google Play addresses an app by the id the build carries, so Android is sent to the app's own page. The App Store addresses an app by a
  /// number Apple issues, and no source in this repository carries one, so iOS is sent to the store's search for the app by name — the
  /// nearest thing to its page that can be addressed without inventing an id.
  static String storePage({required bool isIos}) => isIos
      ? '$_appStoreSearch${Uri.encodeQueryComponent(AppConstants.appName)}'
      : '$_playStoreAppPage$applicationId';

  /// What the update button tries, in the order it tries them, and never empty.
  ///
  /// The link the shop configured for the platform comes first and is passed on exactly as it was given, so a shop that fills that field
  /// keeps what it has today. A link that is missing, empty or only blank space is no target at all, and the store page is then the only
  /// one. The store page also follows a configured link the device cannot open, so a link the shop mistyped no longer leaves the customer
  /// with nowhere to go.
  static List<String> candidates({
    required UserAppVersionControl? control,
    required bool isIos,
  }) {
    final String? configured =
        (isIos ? control?.forIos : control?.forAndroid)?.link;
    final String store = storePage(isIos: isIos);

    if (configured == null || configured.trim().isEmpty) {
      return <String>[store];
    }

    return <String>[configured, store];
  }
}
