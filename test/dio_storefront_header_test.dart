import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/dio_client.dart';
import 'package:syriapharmacy/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/utill/app_constants.dart';

/// With storefronts off, every request must carry exactly the headers it carried before they
/// existed: both when the client is built and after a login rewrites the headers. A storefront
/// choice is stored on purpose, so a header leaking past the flag would show up here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioClient dioClient;

  Map<String, String> expectedHeaders({required String token}) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Platform': Platform.isIOS ? 'ios' : 'android',
        'X-App-Version': AppConstants.appVersion,
        'X-Client-Id': 'test-client-id',
        AppConstants.langKey: 'en',
      };

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.userLoginToken: 'token-before-login',
      AppConstants.analyticsClientId: 'test-client-id',
      AppConstants.languageCode: 'en',
      AppConstants.storefrontCountry: 'AE',
    });
    dio = Dio();
    dioClient = DioClient(
      'https://shop.test',
      dio,
      loggingInterceptor: LoggingInterceptor(),
      sharedPreferences: await SharedPreferences.getInstance(),
    );
  });

  test('a new client sends no storefront header', () {
    expect(dio.options.headers, isNot(contains(AppConstants.storefrontHeader)));
    expect(dio.options.headers,
        equals(expectedHeaders(token: 'token-before-login')));
  }, skip: _assertsTheBuildWithoutTheFlag);

  test('updateHeader with no new values leaves the headers as they were', () {
    dioClient.updateHeader(null, null);

    expect(dio.options.headers, isNot(contains(AppConstants.storefrontHeader)));
    expect(dio.options.headers,
        equals(expectedHeaders(token: 'token-before-login')));
  }, skip: _assertsTheBuildWithoutTheFlag);

  test('a login rewrites only the token and still sends no storefront header',
      () {
    dioClient.updateHeader('token-after-login', 'SA');

    expect(dio.options.headers, isNot(contains(AppConstants.storefrontHeader)));
    expect(dio.options.headers,
        equals(expectedHeaders(token: 'token-after-login')));
  }, skip: _assertsTheBuildWithoutTheFlag);
}

/// These cases pin the build as it ships today. In a build made with the flag a request does carry the header, which the storefront cases of the other suites pin.
final String? _assertsTheBuildWithoutTheFlag =
    StorefrontConfig.enabled ? 'asserts the build made without GCC_STOREFRONTS_ENABLED' : null;
