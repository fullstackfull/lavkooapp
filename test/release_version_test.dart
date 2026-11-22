import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:syriapharmacy/utill/update_gate.dart';

/// The version the app reports is not below the floor the live shop publishes. If it were, every build would be held at the update screen,
/// and the shop's `link` is empty, so the customer would have nowhere to go. The reasons are written on `AppConstants.appVersion`.
void main() {
  /// What /api/v1/config published as `user_app_version_control` on 2026-11-11: 14.1 with the switch on, for both platforms.
  UserAppVersionControl liveFloor() => UserAppVersionControl(
        forAndroid: ForAndroid(status: 1, version: '14.1', link: ''),
        forIos: ForAndroid(status: 1, version: '14.1', link: ''),
      );

  test('the live floor does not hold back the version the app reports', () {
    for (final bool isIos in [false, true]) {
      expect(
        UpdateGate.isRequired(
          control: liveFloor(),
          isIos: isIos,
          installedVersion: AppConstants.appVersion,
        ),
        isFalse,
        reason: '${AppConstants.appVersion} is below the live floor of 14.1 '
            'on ${isIos ? 'iOS' : 'Android'}. Change the app version and the '
            "shop's floor together, as AppConstants.appVersion explains.",
      );
    }
  });

  test('the same floor would hold back a build numbered 3.0.6', () {
    expect(
      UpdateGate.isRequired(
        control: liveFloor(),
        isIos: false,
        installedVersion: '3.0.6',
      ),
      isTrue,
      reason: 'this is why the reported version is not the one in pubspec.yaml',
    );
  });
}
