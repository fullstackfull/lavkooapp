import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';

/// The rule that holds a build at the update screen, and the comparison of two version numbers it rests on. It lived in the splash
/// screen's state, where nothing could test it; it is the same code, in a place a test can reach (test/update_gate_test.dart).
class UpdateGate {
  const UpdateGate._();

  /// Whether the build [installedVersion] is too old to run on the platform it is installed on.
  ///
  /// Two things decide it, and only one of them used to be read. The shop stores a minimum version AND a switch next to it, and the switch
  /// was ignored here: a merchant who turned forced updates off in Admin -> Business Settings -> App Settings watched the app go on forcing
  /// them, with no way from the panel to stop it.
  ///
  /// The comparison is only meaningful when both numbers come from the same release line. A shop whose minimum still carries an older
  /// lineage's numbering (the installer's default is 14.1) will hold back a perfectly current build until that field is set to this app's own
  /// numbering.
  static bool isRequired({
    required UserAppVersionControl? control,
    required bool isIos,
    required String installedVersion,
  }) {
    final platform = isIos ? control?.forIos : control?.forAndroid;

    if (platform == null || platform.status != 1) {
      return false;
    }

    final minimum = platform.version;
    if (minimum == null || minimum.trim().isEmpty) {
      return false;
    }

    return compare(minimum, installedVersion) == 1;
  }

  /// 1 when [version1] is higher than [version2], -1 when it is lower, 0 when they are the same, part by part. A part that is missing or is not
  /// a number counts as 0, so a minimum that is not a version never holds a build back.
  static int compare(String version1, String version2) {
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
}
