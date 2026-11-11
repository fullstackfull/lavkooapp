import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/auth/domain/models/signup_model.dart';
import 'package:syriapharmacy/features/auth/domain/models/social_login_model.dart';
import 'package:syriapharmacy/features/auth/enums/from_page.dart';
import 'package:syriapharmacy/features/auth/enums/social_login_options.dart';
import 'package:syriapharmacy/features/auth/widgets/existing_account_bottom_sheet.dart';
import 'package:syriapharmacy/features/profile/domain/models/profile_model.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/helper/responsive_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/facebook_login_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/google_login_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialLoginWidget extends StatefulWidget {
  final String? fromPage;
  final VoidCallback? onLoginSuccess;
  const SocialLoginWidget({super.key, this.fromPage, this.onLoginSuccess});

  @override
  SocialLoginWidgetState createState() => SocialLoginWidgetState();
}

class SocialLoginWidgetState extends State<SocialLoginWidget> {
  SocialLoginModel socialLogin = SocialLoginModel();

  @override
  Widget build(BuildContext context) {
    final ConfigModel? configModel =
        Provider.of<SplashController>(context, listen: false).configModel;
    final socialLoginConfig =
        configModel?.customerLogin?.socialMediaLoginOptions;
    List<String> socialLoginList = [];

    if (false /* socialLoginConfig?.facebook == 1 */) {
      socialLoginList.add("facebook");
    }

    if (socialLoginConfig?.google == 1) {
      socialLoginList.add("google");
    }

    if (socialLoginConfig?.apple == 1) {
      socialLoginList.add("apple");
    }

    return Consumer<AuthController>(builder: (context, authProvider, _) {
      if (socialLoginList.isNotEmpty) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: Dimensions.paddingSizeLarge,
          children: [
            if (socialLoginConfig?.google == 1)
              InkWell(
                onTap: () => googleLogin(context, widget.fromPage, widget.onLoginSuccess),
                child: const SocialLoginButtonWidget(
                  image: Images.google,
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                ),
              ),
            if (false /* socialLoginConfig?.facebook == 1 */)
              InkWell(
                onTap: () => facebookLogin(context, widget.fromPage, widget.onLoginSuccess),
                child: const SocialLoginButtonWidget(
                  image: Images.facebook,
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                ),
              ),
            if (socialLoginConfig?.apple == 1 && defaultTargetPlatform == TargetPlatform.iOS)
              InkWell(
                onTap: () => appleLogin(context, widget.fromPage, widget.onLoginSuccess),
                child: const SocialLoginButtonWidget(
                  image: Images.appleLogo,
                  color: Colors.black,
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                ),
              ),
          ],
        );
      } else {
        return const SizedBox();
      }
    });
  }
}

Future<void> route(
    bool isRoute,
    String? token,
    String? temporaryToken,
    ProfileModel? profileModel,
    String? errorMessage,
    String? loginMedium,
    String? phone,
    String? email,
    String? name,
    String? fromPage,
    VoidCallback? onLoginSuccess) async {
  final AuthController authProvider =
  Provider.of<AuthController>(Get.context!, listen: false);

  if (isRoute) {
    if (phone != null) {
      await authProvider.sendVerificationCode(
          Provider.of<SplashController>(Get.context!, listen: false)
              .configModel!,
          SignUpModel(email: null, phone: phone),
          type: 'phone',
          fromPage: FromPage.login,
          toNavigateScreen: fromPage,
          onLoginSuccess: onLoginSuccess);
    } else if (token != null) {
      authProvider.navigateToHome(fromPage, onLoginSuccess);
    } else if (temporaryToken != null && temporaryToken.isNotEmpty) {
      RouterHelper.getOtpRegistrationRoute(
          tempToken: temporaryToken,
          userInput: email ?? '',
          userName: name ?? '',
          action: RouteAction.pushNamedAndRemoveUntil,
          toNavigateScreen: fromPage,
          onLoginSuccess: onLoginSuccess);
    } else if (profileModel != null) {
      showModalBottomSheet(
          context: Get.context!,
          isScrollControlled: true,
          backgroundColor:
          Theme.of(Get.context!).primaryColor.withValues(alpha: 0),
          builder: (con) => ExistingAccountBottomSheet(
            profileModel: profileModel,
            socialLoginMedium: loginMedium!,
            con: con,
          ));
    } else {
      showCustomSnackBarWidget(errorMessage, Get.context!,
          snackBarType: SnackBarType.error);
    }
  } else {
    showCustomSnackBarWidget(errorMessage, Get.context!,
        snackBarType: SnackBarType.error);
  }
}

Future<void> googleLogin(BuildContext context, String? fromPage,
    VoidCallback? onLoginSuccess) async {
  SocialLoginModel socialLogin = SocialLoginModel();

  try {
    await Provider.of<GoogleSignInController>(context, listen: false).login();
    String? id, token, email, medium, name;
    if (context.mounted) {}
    if (Provider.of<GoogleSignInController>(Get.context!, listen: false)
        .googleAccount !=
        null) {
      id = Provider.of<GoogleSignInController>(Get.context!, listen: false)
          .googleAccount!
          .id;
      email = Provider.of<GoogleSignInController>(Get.context!, listen: false)
          .googleAccount!
          .email;
      token = Provider.of<GoogleSignInController>(Get.context!, listen: false)
          .accessToken;
      name = Provider.of<GoogleSignInController>(Get.context!, listen: false)
          .googleAccount!
          .displayName;
      medium = 'google';
      log('eemail =>$email token =>$token');

      socialLogin.email = email;
      socialLogin.medium = medium;
      socialLogin.token = token;
      socialLogin.uniqueId = id;
      socialLogin.name = name;

      await Provider.of<AuthController>(Get.context!, listen: false)
          .socialLogin(socialLogin, route, fromPage, onLoginSuccess);
    }
  } catch (er) {
    if (kDebugMode) debugPrint('access token error is : $er');
  }
}

Future<void> facebookLogin(BuildContext context, String? fromPage,
    VoidCallback? onLoginSuccess) async {
  SocialLoginModel socialLogin = SocialLoginModel();

  try {
    await Provider.of<FacebookLoginController>(context, listen: false).login();
    String? id, token, email, medium, name;
    if (Provider.of<FacebookLoginController>(Get.context!, listen: false)
        .userData !=
        null) {
      id = Provider.of<FacebookLoginController>(Get.context!, listen: false)
          .userData?['id'];
      email = Provider.of<FacebookLoginController>(Get.context!, listen: false)
          .userData?['email'];
      token = Provider.of<FacebookLoginController>(Get.context!, listen: false)
          .result
          .accessToken
          ?.tokenString;
      name = Provider.of<FacebookLoginController>(Get.context!, listen: false)
          .userData?['name'] ??
          '';
      medium = 'facebook';
      socialLogin.email = email;
      socialLogin.medium = medium;
      socialLogin.token = token;
      socialLogin.uniqueId = id;
      await Provider.of<AuthController>(Get.context!, listen: false)
          .socialLogin(socialLogin, route, fromPage, onLoginSuccess);
    }
  } catch (er) {
    if (kDebugMode) debugPrint('access token error is : $er');
  }
}

Future<void> appleLogin(BuildContext context, String? fromPage,
    VoidCallback? onLoginSuccess) async {
  SocialLoginModel socialLogin = SocialLoginModel();
  try {
    String? id, token, email, medium;
    final credential = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName
    ]);

    id = credential.authorizationCode; // backend uses this as 'code' in Apple token exchange
    email = await Provider.of<AuthController>(Get.context!, listen: false)
        .onConfigurationAppleEmail(credential);

    token = credential.identityToken;
    medium = 'apple';
    socialLogin.email = email;
    socialLogin.medium = medium;
    socialLogin.token = token;
    socialLogin.uniqueId = id;
    socialLogin.name = credential.givenName ?? '';
    await Provider.of<AuthController>(Get.context!, listen: false)
        .socialLogin(socialLogin, route, fromPage, onLoginSuccess);

    log('''
================ APPLE SIGN IN CREDENTIALS (JSON) ================
{
  "userIdentifier": "${credential.userIdentifier}",
  "email": "${credential.email}",
  "givenName": "${credential.givenName}",
  "familyName": "${credential.familyName}",
  "identityToken": "${credential.identityToken}",
  "authorizationCode": "${credential.authorizationCode}"
}
==================================================================
''');
  } catch (er) {
    if (kDebugMode) debugPrint('access token error is : $er');
  }
}

class SocialLoginButtonWidget extends StatelessWidget {
  final String? text;
  final String image;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final SocialLoginOption? option;
  const SocialLoginButtonWidget(
      {super.key,
        this.text,
        required this.image,
        this.color,
        this.padding,
        this.option});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.all(text == null
              ? Dimensions.paddingSizeSmall
              : Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.08),
        shape: text == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: text == null ? null : BorderRadius.circular(30),
        border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: text == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Image.asset(
            image,
            color: color,
            height: ResponsiveHelper.isTab(context) ? 24 : 20,
            width: ResponsiveHelper.isTab(context) ? 24 : 20,
          ),
          if (text != null) ...[
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Flexible(
              child: Text(
                text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}