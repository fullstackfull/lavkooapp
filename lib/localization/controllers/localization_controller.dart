import 'package:flutter/material.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationController extends ChangeNotifier {
  final SharedPreferences? sharedPreferences;
  final DioClient? dioClient;

  LocalizationController(
      {required this.sharedPreferences, required this.dioClient}) {
    _loadCurrentLanguage();
  }

  Locale _locale = Locale(AppConstants.languages[0].languageCode!,
      AppConstants.languages[0].countryCode);
  bool _isLtr = true;
  int? _languageIndex;

  Locale get locale => _locale;
  bool get isLtr => _isLtr;
  int? get languageIndex => _languageIndex;

  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    _isLtr = _locale.languageCode != 'ar';

    // 1. Save language to SharedPreferences FIRST so DioClient reads the new language immediately
    await _saveLanguage(_locale);

    // 2. Update Dio headers with new language
    dioClient!.updateHeader(null, locale.languageCode);

    Provider.of<AuthController>(Get.context!, listen: false).setCurrentLanguage(
        locale.languageCode == 'ar' ? 'sy' : 'en');
    
    // 3. Clear all cached responses (Drift DB + Dio Memory + Dio Disk) when language changes
    await database.clearCacheResponses();
    DioClient.clearMemoryCache();
    dioClient?.clearDiskCache();

    // Composed pages are served in the language of the `lang` header just updated above, so what
    // is on screen is now the wrong language until refetched. Guarded: language can be chosen on
    // first run before the theme controller exists in the tree.
    try {
      Provider.of<DynamicThemeController>(Get.context!, listen: false)
          .onLanguageChanged();
    } catch (_) {}
    for (int index = 0; index < AppConstants.languages.length; index++) {
      if (AppConstants.languages[index].languageCode == locale.languageCode) {
        _languageIndex = index;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> _loadCurrentLanguage() async {
    _locale = Locale(
        sharedPreferences!.getString(AppConstants.languageCode) ??
            AppConstants.languages[0].languageCode!,
        sharedPreferences!.getString(AppConstants.countryCode) ??
            AppConstants.languages[0].countryCode);
    _isLtr = _locale.languageCode != 'ar';
    for (int index = 0; index < AppConstants.languages.length; index++) {
      if (AppConstants.languages[index].languageCode == locale.languageCode) {
        _languageIndex = index;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> _saveLanguage(Locale locale) async {
    sharedPreferences!
        .setString(AppConstants.languageCode, locale.languageCode);
    sharedPreferences!.setString(AppConstants.countryCode, locale.countryCode!);
  }

  String? getCurrentLanguage() {
    final String? lang = sharedPreferences!.getString(AppConstants.languageCode);
    return lang == 'ar' ? 'sy' : 'en';
  }
}
