import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/storefront/widgets/storefront_browse_only_notice.dart';
import 'package:syriapharmacy/localization/app_localization.dart';

Map<String, dynamic> _languageFile(String code) =>
    json.decode(File('assets/language/$code.json').readAsStringSync())
        as Map<String, dynamic>;

/// The app's translations, read straight from the language files and handed over at once, so the widget is built with the real
/// words and without waiting on the asset bundle.
class _FileLocalization extends AppLocalization {
  _FileLocalization(super.locale)
      : _values = _languageFile(locale.languageCode);

  final Map<String, dynamic> _values;

  @override
  String? translate(String? key) => _values[key] as String?;
}

class _FileLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _FileLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalization> load(Locale locale) =>
      SynchronousFuture<AppLocalization>(_FileLocalization(locale));

  @override
  bool shouldReload(_FileLocalizationsDelegate old) => false;
}

/// The notice the cart and the checkout show while a storefront is browse-only. It is a plain card, so what is worth checking is that
/// it says what the language files say, in both shipped languages, and that it fits a narrow screen at a large text size.
void main() {
  Future<void> pumpNotice(
    WidgetTester tester, {
    required Locale locale,
    double width = 320,
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _FileLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 640),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: width,
                child: const Column(children: [StorefrontBrowseOnlyNotice()]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('the language files', () {
    test('say it in both shipped languages, and in words, not as the key', () {
      for (final String code in <String>['en', 'ar']) {
        final Object? text =
            _languageFile(code)['storefront_browse_only_notice'];

        expect(text, isA<String>(), reason: code);
        expect((text! as String).trim(), isNot('storefront_browse_only_notice'),
            reason: code);
        expect((text as String).length, greaterThan(20), reason: code);
      }
    });

    test('all carry the key, so a language nobody ships yet is not left behind',
        () {
      for (final String code in <String>['en', 'ar', 'bn', 'es', 'hi']) {
        expect(_languageFile(code).containsKey('storefront_browse_only_notice'),
            isTrue,
            reason: code);
      }
    });
  });

  group('the notice', () {
    testWidgets('reads in English', (tester) async {
      await pumpNotice(tester, locale: const Locale('en'));

      expect(
          find.text(
              _languageFile('en')['storefront_browse_only_notice'] as String),
          findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('reads in Arabic', (tester) async {
      await pumpNotice(tester, locale: const Locale('ar'));

      expect(
          find.text(
              _languageFile('ar')['storefront_browse_only_notice'] as String),
          findsOneWidget);
    });

    for (final Locale locale in const <Locale>[Locale('en'), Locale('ar')]) {
      testWidgets(
          'fits a narrow screen at a large text size in ${locale.languageCode}',
          (tester) async {
        await pumpNotice(tester, locale: locale, width: 280, textScale: 2.0);

        expect(tester.takeException(), isNull);
        expect(find.byType(StorefrontBrowseOnlyNotice), findsOneWidget);
        expect(tester.getSize(find.byType(StorefrontBrowseOnlyNotice)).width,
            280.0);
      });
    }

    testWidgets('puts the icon at the start of the line, in either direction',
        (tester) async {
      await pumpNotice(tester, locale: const Locale('en'));
      final Rect noticeInEnglish =
          tester.getRect(find.byType(StorefrontBrowseOnlyNotice));
      final double iconInEnglish =
          tester.getCenter(find.byIcon(Icons.info_outline)).dx;

      await pumpNotice(tester, locale: const Locale('ar'));
      final Rect noticeInArabic =
          tester.getRect(find.byType(StorefrontBrowseOnlyNotice));
      final double iconInArabic =
          tester.getCenter(find.byIcon(Icons.info_outline)).dx;

      expect(iconInEnglish, lessThan(noticeInEnglish.center.dx));
      expect(iconInArabic, greaterThan(noticeInArabic.center.dx));
    });

    testWidgets('takes the margin its screen asks for', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(children: [
              StorefrontBrowseOnlyNotice(margin: EdgeInsets.all(16)),
            ]),
          ),
        ),
      );

      final Finder card = find
          .descendant(
            of: find.byType(StorefrontBrowseOnlyNotice),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getRect(card).left, 16.0);
    });
  });
}
