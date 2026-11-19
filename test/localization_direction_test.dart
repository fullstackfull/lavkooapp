import 'dart:io';

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
///
/// The MaterialApp those tests build is a copy of the app's, configured the way the app's is. The app's own (`MaterialApp.router` in
/// `lib/main.dart`) needs the providers of the whole app and the router of the whole app, so it is not built here: the last group pins by
/// the source the lines of it that give the app its direction (the controller's locale, the delegate that turns a locale into a direction, the
/// list of languages, no direction forced on what the router shows, and no other locale put in the place of the controller's). Nothing was
/// run on a device.
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

  group(
      'the MaterialApp of the app, structural only: the source of lib/main.dart, not the app built',
      () {
    final String appSource = File('lib/main.dart')
        .readAsLinesSync()
        .where((String line) => !line.trimLeft().startsWith('//'))
        .join('\n');

    String routerCall() {
      final int start = appSource.indexOf('MaterialApp.router(');
      expect(start, isNonNegative,
          reason: 'the app is built by MaterialApp.router');

      return appSource.substring(start);
    }

    test(
        'is built again with the locale of the controller whenever the customer chooses a language',
        () {
      expect(RegExp(r'Consumer<LocalizationController>\(').hasMatch(appSource),
          isTrue,
          reason: 'the app listens to the controller of the language');
      expect(
          RegExp(r'\blocale:\s*localizationController\.locale\s*,')
              .hasMatch(routerCall()),
          isTrue,
          reason: 'the locale of the app is the controller\'s');
    });

    test(
        'has the delegate that turns the locale into a direction, and the languages of the list',
        () {
      expect(
          RegExp(r'localizationsDelegates:\s*\[[^\]]*GlobalWidgetsLocalizations\.delegate')
              .hasMatch(routerCall()),
          isTrue,
          reason: 'the delegate of the widgets');
      expect(RegExp(r'supportedLocales:\s*locals\s*,').hasMatch(routerCall()),
          isTrue,
          reason: 'the languages the app supports');
      expect(
          RegExp(r'for\s*\(\s*var\s+language\s+in\s+AppConstants\.languages\s*\)\s*\{\s*locals\.add\(')
              .hasMatch(appSource),
          isTrue,
          reason: 'the languages the app supports are the list of the app');
    });

    test(
        'forces no direction on what the router shows: the only Directionality is the left to right one of the splash at the launch',
        () {
      expect('Directionality('.allMatches(appSource).length, 1);
      expect(appSource.indexOf('Directionality('),
          lessThan(appSource.indexOf('MaterialApp.router(')),
          reason: 'it is not inside the router');
    });

    test(
        'puts no other locale in the place of the controller\'s: nothing resolves the locale and nothing overrides it',
        () {
      expect(
          RegExp(r'locale(?:List)?ResolutionCallback|Localizations\.override')
              .firstMatch(appSource)
              ?.group(0),
          isNull);
    });
  });
}
