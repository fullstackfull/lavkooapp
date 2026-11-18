import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// GCC-05, J-03: a photo, a review, a refund, a ticket or a chat message is sent as a multipart upload, which does not go through Dio and
/// so did not carry the `X-Storefront` header the rest of the app's requests carry: the server read it as the default storefront. The
/// client now hands such an upload the header for the storefront the customer is on, and a source scan fails for an upload that does not
/// ask for it. The test runs in both settings of the build flag and says what each must answer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DioClient> clientOn(String? storefront) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userLoginToken: 'token',
      AppConstants.analyticsClientId: 'test-client-id',
      AppConstants.languageCode: 'en',
      if (storefront != null) AppConstants.storefrontCountry: storefront,
    });

    return DioClient(
      'https://shop.test',
      Dio(),
      loggingInterceptor: LoggingInterceptor(),
      sharedPreferences: await SharedPreferences.getInstance(),
    );
  }

  group('the headers an upload carries', () {
    test('name the storefront the customer is on, and only while storefronts are on',
        () async {
      final DioClient client = await clientOn('AE');

      if (StorefrontConfig.enabled) {
        expect(client.storefrontHeaders,
            <String, String>{AppConstants.storefrontHeader: 'AE'});
      } else {
        expect(client.storefrontHeaders, isEmpty);
      }
    });

    test('name the default storefront for a customer who never chose one',
        () async {
      final DioClient client = await clientOn(null);

      if (StorefrontConfig.enabled) {
        expect(client.storefrontHeaders,
            <String, String>{AppConstants.storefrontHeader: 'SA'});
      } else {
        expect(client.storefrontHeaders, isEmpty);
      }
    });

    test('are the storefront header and nothing else: the token and the language stay the upload\'s own',
        () async {
      final DioClient client = await clientOn('KW');

      expect(client.storefrontHeaders.keys,
          everyElement(equals(AppConstants.storefrontHeader)));
    });
  });

  test('every upload of the app asks the client for them', () {
    final List<String> uncovered = <String>[];
    int uploads = 0;

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final List<String> code = entity
          .readAsLinesSync()
          .where((String line) => !line.trimLeft().startsWith('//'))
          .toList();
      final int built =
          code.where((String line) => line.contains('MultipartRequest(')).length;
      final int asked =
          code.where((String line) => line.contains('.storefrontHeaders')).length;

      uploads += built;
      if (built != asked) {
        uncovered.add(
            '${entity.path.replaceAll(r'\', '/')}: $built uploads, $asked asks');
      }
    }

    expect(uploads, greaterThan(0),
        reason: 'the scan found no upload, so it would pass on nothing');
    expect(uncovered, isEmpty,
        reason:
            'an upload that does not carry X-Storefront is read by the server as the default storefront; add '
            'request.headers.addAll(dioClient.storefrontHeaders) after its Authorization header');
  });
}
