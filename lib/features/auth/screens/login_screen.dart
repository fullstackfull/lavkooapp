import 'package:syriapharmacy/core/animations/app_animations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/auth/domain/models/user_log_data.dart';
import 'package:syriapharmacy/features/auth/enums/from_page.dart';
import 'package:syriapharmacy/features/auth/widgets/only_social_login_widget.dart';
import 'package:syriapharmacy/features/auth/widgets/social_login_widget.dart';
import 'package:syriapharmacy/features/home/screens/aster_theme_home_screen.dart';
import 'package:syriapharmacy/features/home/screens/home_screens.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/helper/number_checker_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final bool fromLogout;
  final bool showBackButton;
  final String? fromPage;
  final VoidCallback? onLoginSuccess;
  const LoginScreen(
      {super.key,
      this.fromLogout = false,
      this.fromPage,
      this.onLoginSuccess,
      this.showBackButton = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _emailNumberFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  TextEditingController? _emailPhoneController;
  TextEditingController? _passwordController;
  GlobalKey<FormState>? _formKeyLogin;
  String? countryCode;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    _emailPhoneController = TextEditingController();
    _passwordController = TextEditingController();

    final ConfigModel configModel =
        Provider.of<SplashController>(context, listen: false).configModel!;
    final AuthController authController =
        Provider.of<AuthController>(context, listen: false);

    authController.setIsLoading = false;
    authController.setIsPhoneVerificationButttonLoading = false;
    UserLogData? userData = authController.getUserData();
    authController.toggleIsNumberLoginScreenText(value: false, isUpdate: false);

    countryCode =
        CountryCode.fromCountryCode(configModel.countryCode!).dialCode;

    if (userData != null) {
      if (userData.email != null) {
        _emailPhoneController?.text = userData.email ?? '';
      } else if (userData.phoneNumber != null) {
        authController.toggleIsNumberLoginScreenText(isUpdate: false);
        countryCode = userData.countryCode ?? '';
        _emailPhoneController?.text = userData.phoneNumber ?? '';
      }
      _passwordController!.text = userData.password ?? '';
    }
  }

  @override
  void dispose() {
    _emailPhoneController!.dispose();
    _passwordController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final size = MediaQuery.of(context).size;
    final configModel =
        Provider.of<SplashController>(context, listen: false).configModel!;
    final LocalizationController localizationProvider =
        Provider.of<LocalizationController>(context, listen: false);

    if (configModel.customerLogin!.loginOption!.manualLogin == 0 &&
        configModel.customerLogin!.loginOption!.otpLogin == 0) {
      return OnlySocialLoginWidget(
          fromLogout: widget.fromLogout,
          fromPage: widget.fromPage,
          onLoginSuccess: widget.onLoginSuccess);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (widget.fromLogout) {
            final authController =
                Provider.of<AuthController>(context, listen: false);
            if (!authController.isLoading) {
              RouterHelper.getDashboardRoute(
                  action: RouteAction.pushNamedAndRemoveUntil);
            }
          } else {
            Navigator.pop(context);
          }
        }
        return;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Stack(
              children: [
                // Soft elegant mesh gradients for background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.06),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating blurred glow circles in background
                Positioned(
                  top: -size.height * 0.15,
                  right: -size.width * 0.1,
                  child: Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.height * 0.1,
                  left: -size.width * 0.1,
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Main Content
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    (configModel.customerLogin?.loginOption?.manualLogin == 0 &&
                            configModel.customerLogin?.loginOption?.otpLogin ==
                                0)
                        ? OnlySocialLoginWidget(
                            fromPage: widget.fromPage,
                            onLoginSuccess: widget.onLoginSuccess)
                        : SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + (widget.showBackButton ? 0 : 0),
                                bottom:
                                    MediaQuery.of(context).padding.bottom + 10,
                                left: Dimensions.paddingSizeLarge,
                                right: Dimensions.paddingSizeLarge,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      Images.logoSplash,
                                      height: 175,
                                      width: 350,
                                      fit: BoxFit.contain,
                                    ).animateSectionEntrance(index: 0),
                              const SizedBox(height: 8),
                                    Container(
                                      width: width > 700 ? 500 : width,
                                      padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeExtraLarge),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .cardColor
                                            .withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          ),
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.02),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Consumer<AuthController>(
                                        builder:
                                            (context, authProvider, child) =>
                                                Form(
                                          key: _formKeyLogin,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Heading "Login" & Welcome Back subtitle
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      getTranslated('sign_in',
                                                              context) ??
                                                          'Login',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'IBM_Plex_Sans_Arabic',
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          getTranslated(
                                                                  'welcome_back',
                                                                  context) ??
                                                              'Good to see you back!',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'IBM_Plex_Sans_Arabic',
                                                            fontSize: 14,
                                                            color: Theme.of(
                                                                    context)
                                                                .hintColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Icon(
                                                            Icons
                                                                .favorite_rounded,
                                                            size: 14,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 28),

                                              Selector<AuthController, bool>(
                                                selector: (context,
                                                        authProvider) =>
                                                    authProvider
                                                        .isNumberLoginScreenText,
                                                builder:
                                                    (_, isNumberLogin, ___) {
                                                  return CustomTextFieldWidget(
                                                    countryDialCode:
                                                        isNumberLogin
                                                            ? countryCode
                                                            : null,
                                                    showCodePicker:
                                                        isNumberLogin,
                                                    onCountryChanged:
                                                        (CountryCode value) {
                                                      countryCode =
                                                          value.dialCode;
                                                    },
                                                    onChanged: (String text) {
                                                      final numberRegExp =
                                                          RegExp(
                                                              r'^[+]?[0-9]+$');

                                                      if (text.isEmpty &&
                                                          isNumberLogin) {
                                                        authProvider
                                                            .toggleIsNumberLoginScreenText();
                                                      }
                                                      if (text.startsWith(
                                                              numberRegExp) &&
                                                          !isNumberLogin) {
                                                        authProvider
                                                            .toggleIsNumberLoginScreenText();
                                                      }

                                                      final emailRegExp =
                                                          RegExp(r'@');

                                                      if (text.contains(
                                                              emailRegExp) &&
                                                          isNumberLogin) {
                                                        authProvider
                                                            .toggleIsNumberLoginScreenText();
                                                      }
                                                    },
                                                    isShowBorder: true,
                                                    borderRadius: 16,
                                                    borderColor:
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.12),
                                                    focusNode:
                                                        _emailNumberFocus,
                                                    nextFocus: _passwordFocus,
                                                    controller:
                                                        _emailPhoneController,
                                                    inputType:
                                                        TextInputType.name,
                                                    labelText: getTranslated(
                                                        'email/phone', context),
                                                    required: true,
                                                  );
                                                },
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),

                                              CustomTextFieldWidget(
                                                hintText: getTranslated(
                                                    'password_hint', context),
                                                labelText: getTranslated(
                                                    'password', context),
                                                isShowBorder: true,
                                                borderRadius: 16,
                                                borderColor: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.12),
                                                required: true,
                                                isPassword: true,
                                                showLabelText: false,
                                                focusNode: _passwordFocus,
                                                controller: _passwordController,
                                                inputAction:
                                                    TextInputAction.done,
                                                prefixIcon: Images.lockSvg,
                                                prefixColor: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              const SizedBox(height: 20),

                                              // for remember me section
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    InkWell(
                                                      onTap: () => authProvider
                                                          .toggleRememberMe(),
                                                      child: Row(children: [
                                                        Container(
                                                          width: 18,
                                                          height: 18,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: authProvider
                                                                    .isActiveRememberMe
                                                                ? Theme.of(
                                                                        context)
                                                                    .primaryColor
                                                                : Theme.of(
                                                                        context)
                                                                    .cardColor,
                                                            border: Border.all(
                                                              color: authProvider.isActiveRememberMe
                                                                  ? Theme.of(
                                                                          context)
                                                                      .primaryColor
                                                                  : Theme.of(
                                                                          context)
                                                                      .primaryColor
                                                                      .withValues(
                                                                          alpha:
                                                                              0.3),
                                                              width: 1.5,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          child: authProvider
                                                                  .isActiveRememberMe
                                                              ? const Icon(
                                                                  Icons
                                                                      .done_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 13)
                                                              : const SizedBox
                                                                  .shrink(),
                                                        ),
                                                        const SizedBox(
                                                            width: Dimensions
                                                                .paddingSizeSmall),
                                                        Text(
                                                          getTranslated(
                                                              'remember',
                                                              context)!,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .displayMedium!
                                                              .copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                                color: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyLarge
                                                                    ?.color,
                                                              ),
                                                        ),
                                                      ]),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        RouterHelper
                                                            .getForgetPasswordScreenRoute();
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 6.0,
                                                                horizontal:
                                                                    8.0),
                                                        child: Text(
                                                          localizationProvider
                                                                  .isLtr
                                                              ? "${getTranslated('forget_password', context)!}?"
                                                              : "${getTranslated('forget_password', context)!}؟",
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .displayMedium!
                                                              .copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ]),

                                              if (authProvider
                                                  .loginErrorMessage!
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CircleAvatar(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                          radius: 4),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          authProvider
                                                                  .loginErrorMessage ??
                                                              "",
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .displayMedium!
                                                              .copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeSmall,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .error,
                                                              ),
                                                        ),
                                                      ),
                                                    ]),
                                              ],
                                              const SizedBox(height: 24),

                                              CustomButton(
                                                buttonText: getTranslated(
                                                    'sign_in', context),
                                                isLoading:
                                                    authProvider.isLoading,
                                                radius: 16,
                                                onTap: () async {
                                                  String password =
                                                      _passwordController!.text
                                                          .trim();

                                                  if (_emailPhoneController!
                                                      .text.isEmpty) {
                                                    showCustomSnackBarWidget(
                                                        getTranslated(
                                                            'enter_email_or_phone',
                                                            context),
                                                        context,
                                                        snackBarType:
                                                            SnackBarType
                                                                .warning);
                                                  } else if (password.isEmpty) {
                                                    showCustomSnackBarWidget(
                                                        getTranslated(
                                                            'enter_password',
                                                            context),
                                                        context,
                                                        snackBarType:
                                                            SnackBarType
                                                                .warning);
                                                  } else if (password.length <
                                                      6) {
                                                    showCustomSnackBarWidget(
                                                        getTranslated(
                                                            'password_should_be',
                                                            context),
                                                        context,
                                                        snackBarType:
                                                            SnackBarType
                                                                .warning);
                                                  } else {
                                                    String userInput =
                                                        _emailPhoneController!
                                                            .text
                                                            .trim();
                                                    bool isNumber =
                                                        NumberCheckerHelper
                                                            .isNumber(
                                                                userInput);

                                                    if (isNumber) {
                                                      userInput = countryCode! +
                                                          userInput;
                                                    }

                                                    String type = isNumber
                                                        ? 'phone'
                                                        : 'email';

                                                    await authProvider
                                                        .login(
                                                            userInput,
                                                            password,
                                                            type,
                                                            FromPage.login,
                                                            toNavigateScreen:
                                                                widget.fromPage,
                                                            onLoginSuccess: widget
                                                                .onLoginSuccess)
                                                        .then((status) async {
                                                      if (status.isSuccess) {
                                                        if (authProvider
                                                            .isActiveRememberMe) {
                                                          authProvider
                                                              .saveUserEmailAndPassword(
                                                                  UserLogData(
                                                            countryCode:
                                                                countryCode,
                                                            phoneNumber:
                                                                isNumber
                                                                    ? userInput
                                                                    : null,
                                                            email: isNumber
                                                                ? null
                                                                : userInput,
                                                            password: password,
                                                          ));
                                                        } else {
                                                          // authProvider.clearUserLogData();
                                                        }
                                                        if (widget.fromPage ==
                                                                '/dashboard' &&
                                                            !widget
                                                                .showBackButton) {
                                                          Navigator.of(
                                                                  Get.context!)
                                                              .pop();
                                                          if (Provider.of<SplashController>(
                                                                      Get
                                                                          .context!,
                                                                      listen:
                                                                          false)
                                                                  .configModel!
                                                                  .activeTheme ==
                                                              "theme_aster") {
                                                            AsterThemeHomeScreen
                                                                .loadData(
                                                                    false);
                                                          } else {
                                                            HomePage.loadData(
                                                                false);
                                                          }
                                                        }
                                                        authProvider.navigateToHome(
                                                            widget.fromPage,
                                                            widget
                                                                .onLoginSuccess);
                                                      }
                                                    });
                                                  }
                                                },
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),

                                              if (configModel.customerLogin
                                                      ?.loginOption?.otpLogin ==
                                                  null)
                                                Row(
                                                  children: [
                                                    Expanded(
                                                        child: Divider(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.12))),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                                    Text(
                                                      getTranslated(
                                                          'OR', context)!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displayMedium!
                                                          .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeDefault,
                                                              color: Theme.of(
                                                                      context)
                                                                  .hintColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                                    Expanded(
                                                        child: Divider(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.12))),
                                                  ],
                                                ),

                                              if (configModel.customerLogin
                                                      ?.loginOption?.otpLogin ==
                                                  1) ...[
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeDefault),
                                                InkWell(
                                                  onTap: () => RouterHelper
                                                      .getOtpLoginRoute(
                                                          toNavigateScreen:
                                                              widget.fromPage,
                                                          onLoginSuccess: widget
                                                              .onLoginSuccess),
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          getTranslated(
                                                              'sign_in_with',
                                                              context)!,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .displayMedium!
                                                              .copyWith(
                                                                fontSize: Dimensions
                                                                    .fontSizeDefault,
                                                                color: Theme.of(
                                                                        context)
                                                                    .hintColor,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                            width: Dimensions
                                                                .paddingSizeSmall),
                                                        Text(
                                                          getTranslated(
                                                              'otp', context)!,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .displaySmall!
                                                                  .copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeDefault,
                                                                    decoration:
                                                                        TextDecoration
                                                                            .underline,
                                                                    decorationColor:
                                                                        Theme.of(context)
                                                                            .primaryColor,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                                  ),
                                                        ),
                                                      ]),
                                                ),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeLarge),
                                              ],

                                              if ((configModel
                                                          .customerLogin
                                                          ?.loginOption
                                                          ?.socialMediaLogin ==
                                                      1) &&
                                                  configModel
                                                          .customerLogin
                                                          ?.loginOption
                                                          ?.otpLogin !=
                                                      1)
                                                Row(
                                                  children: [
                                                    Expanded(
                                                        child: Divider(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.12))),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                                    Text(
                                                      getTranslated(
                                                          'or_sign_in_with',
                                                          context)!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displayMedium!
                                                          .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeDefault,
                                                              color: Theme.of(
                                                                      context)
                                                                  .hintColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                                    Expanded(
                                                        child: Divider(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.12))),
                                                  ],
                                                ),

                                              if (configModel
                                                      .customerLogin
                                                      ?.loginOption
                                                      ?.socialMediaLogin ==
                                                  1) ...[
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeSmall),
                                                Center(
                                                    child: SocialLoginWidget(
                                                        fromPage:
                                                            widget.fromPage,
                                                        onLoginSuccess: widget
                                                            .onLoginSuccess)),
                                                const SizedBox(
                                                    height: Dimensions
                                                        .paddingSizeLarge),
                                              ],

                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      getTranslated(
                                                          'create_an_account',
                                                          context)!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displayMedium!
                                                          .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color,
                                                          ),
                                                    ),
                                                    const SizedBox(
                                                        width: Dimensions
                                                            .paddingSizeSmall),
                                                    InkWell(
                                                      onTap: () {
                                                        RouterHelper.getAuthScreenRoute(
                                                            fromLogout: widget
                                                                .fromLogout,
                                                            fromPage:
                                                                widget.fromPage,
                                                            onLoginSuccess: widget
                                                                .onLoginSuccess);
                                                      },
                                                      child: Text(
                                                        getTranslated(
                                                            'signup_here',
                                                            context)!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall!
                                                            .copyWith(
                                                              fontSize: Dimensions
                                                                  .fontSizeDefault,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                              decorationColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                            ),
                                                      ),
                                                    ),
                                                  ]),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),

                                              Center(
                                                child: InkWell(
                                                  onTap: () => {
                                                    if (!authProvider
                                                            .isLoading &&
                                                        widget.showBackButton)
                                                      {
                                                        authProvider
                                                            .getGuestIdUrl(),
                                                        RouterHelper.getDashboardRoute(
                                                            page: 'home',
                                                            action: RouteAction
                                                                .pushReplacement)
                                                      },
                                                    if (!widget.showBackButton)
                                                      {
                                                        Navigator.of(context)
                                                            .pop(),
                                                      }
                                                  },
                                                  child: RichText(
                                                      text: TextSpan(children: [
                                                    TextSpan(
                                                      text:
                                                          '${getTranslated('continue_as', context)} ',
                                                      style: titilliumRegular
                                                          .copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(context)
                                                            .hintColor,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: getTranslated(
                                                          'guest', context),
                                                      style: titilliumRegular
                                                          .copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ])),
                                                ),
                                              ),
                                            ],
                                          ).animateSectionEntrance(index: 1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),

                // Floating circular back button
                if (widget.showBackButton)
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: MediaQuery.of(context).padding.top +
                        Dimensions.paddingSizeDefault,
                    start: Dimensions.paddingSizeLarge,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          if (widget.fromLogout) {
                            RouterHelper.getDashboardRoute(
                                action: RouteAction.pushNamedAndRemoveUntil);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ),

                // Close pull-down handle & button for bottom sheet / non-back button mode
                if (!widget.showBackButton)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          height: 5,
                          width: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                Dimensions.radiusExtraLarge),
                            color: Theme.of(context)
                                .disabledColor
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16, top: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .cardColor
                                    .withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 18,
                                    color: Theme.of(context).primaryColor),
                                onPressed: () {
                                  if (widget.fromLogout) {
                                    RouterHelper.getDashboardRoute(
                                        action: RouteAction
                                            .pushNamedAndRemoveUntil);
                                  } else {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
