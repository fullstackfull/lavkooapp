import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/models/language_model.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// I1-16 criterion 5 (the app's half): Arabic is written right to left and English left to right. The app has a list of the languages it
/// ships. The controller of the language says `isLtr` false for Arabic and true for every other language, and an app built with the
/// controller's locale gets the direction of that language from Flutter. The two have to agree for every language of the list, so a
/// language added to the list without its direction decided here fails.
void main() {
  const Map<String, bool> isLeftToRight = <String, bool>{
    'ar': false,
    'en': true,
  };

  Future<LocalizationController> controllerSavedIn(
      {required LanguageModel language}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.languageCode: language.languageCode!,
      AppConstants.countryCode: language.countryCode!,
    });

    return LocalizationController(
      sharedPreferences: await SharedPreferences.getInstance(),
      dioClient: null,
    );
  }

  Locale localeOf({required LanguageModel language}) =>
      Locale(language.languageCode!, language.countryCode);

  test(
      'the app ships Arabic and English, and no language whose direction was not decided',
      () {
    expect(
      AppConstants.languages
          .map((LanguageModel language) => language.languageCode)
          .toSet(),
      isLeftToRight.keys.toSet(),
    );
  });

  group('the controller of the language', () {
    for (final LanguageModel language in AppConstants.languages) {
      final bool expectedLtr = isLeftToRight[language.languageCode] ?? true;

      test(
          'starts in ${language.languageName}, as it was saved, with isLtr $expectedLtr',
          () async {
        final LocalizationController controller =
            await controllerSavedIn(language: language);

        expect(controller.locale, localeOf(language: language));
        expect(controller.isLtr, expectedLtr);
      });

      test(
          'sets isLtr $expectedLtr as soon as ${language.languageName} is chosen',
          () async {
        final LanguageModel other = AppConstants.languages
            .firstWhere((LanguageModel candidate) => candidate != language);
        final LocalizationController controller =
            await controllerSavedIn(language: other);
        expect(controller.isLtr, isLeftToRight[other.languageCode]);

        // What follows the direction in setLanguage needs the whole app (the HTTP client, the auth controller, the cache database), so it
        // fails here, after the direction is set, and is not what is looked at.
        final Future<void> choosing =
            controller.setLanguage(localeOf(language: language));

        expect(controller.locale, localeOf(language: language));
        expect(controller.isLtr, expectedLtr);
        await choosing.then<void>((_) {}, onError: (Object _) {});
      });
    }
  });

  testWidgets(
      'an app built with the controller\'s locale reads right to left in Arabic and left to right in English, as the controller says',
      (WidgetTester tester) async {
    final List<Locale> supportedLocales = <Locale>[
      for (final LanguageModel language in AppConstants.languages)
        localeOf(language: language),
    ];

    for (final LanguageModel language in AppConstants.languages) {
      final LocalizationController controller =
          await controllerSavedIn(language: language);
      late TextDirection direction;

      await tester.pumpWidget(
        MaterialApp(
          locale: controller.locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(builder: (BuildContext context) {
            direction = Directionality.of(context);

            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          direction,
          isLeftToRight[language.languageCode]!
              ? TextDirection.ltr
              : TextDirection.rtl,
          reason: language.languageName);
      expect(controller.isLtr, direction == TextDirection.ltr,
          reason: language.languageName);
    }
  });
}
