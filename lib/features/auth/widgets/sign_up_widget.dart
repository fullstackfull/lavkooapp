import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/auth/domain/models/register_model.dart';
import 'package:syriapharmacy/features/auth/widgets/condition_check_box_widget.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/helper/velidate_check.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class SignUpWidget extends StatefulWidget {
  final bool fromLogout;
  final String? fromPage;
  final VoidCallback? onLoginSuccess;
  final String? referCode;
  const SignUpWidget(
      {super.key,
      required this.fromLogout,
      this.fromPage,
      this.onLoginSuccess,
      this.referCode});

  @override
  SignUpWidgetState createState() => SignUpWidgetState();
}

class SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _referController = TextEditingController();

  final FocusNode _fNameFocus = FocusNode();
  final FocusNode _lNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _referFocus = FocusNode();

  RegisterModel register = RegisterModel();
  final GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();

  Future<void> route(bool isRoute, String? token, String? tempToken,
      String? errorMessage) async {
    var splashController =
        Provider.of<SplashController>(context, listen: false);
    var authController = Provider.of<AuthController>(context, listen: false);
    var profileController =
        Provider.of<ProfileController>(context, listen: false);
    String phone =
        authController.countryDialCode + _phoneController.text.trim();
    if (isRoute) {
      if (splashController.configModel!.emailVerification!) {
        authController
            .sendOtpToEmail(_emailController.text.toString(), tempToken!)
            .then((value) async {
          if (value.response?.statusCode == 200) {
            authController.updateEmail(_emailController.text.toString());
            // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>
            //     VerificationScreen(tempToken,'',_emailController.text.toString())), (route) => false);
          }
        });
      } else if (splashController.configModel!.phoneVerification!) {
        authController.sendOtpToPhone(phone, tempToken!).then((value) async {
          if (value.isSuccess) {
            authController.updatePhone(phone);
            // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>
            //     VerificationScreen(tempToken,phone,'')), (route) => false);
          }
        });
      } else {
        await profileController.getUserInfo(context);

        _emailController.clear();
        _passwordController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _phoneController.clear();
        _confirmPasswordController.clear();
        _referController.clear();
      }
    } else {
      showCustomSnackBarWidget(errorMessage, context,
          snackBarType: SnackBarType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    Provider.of<AuthController>(context, listen: false).setCountryCode(
        CountryCode.fromCountryCode(
                Provider.of<SplashController>(context, listen: false)
                    .configModel!
                    .countryCode!)
            .dialCode!,
        notify: false);

    if (widget.referCode != null) {
      _referController.text = widget.referCode ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config =
        Provider.of<SplashController>(context, listen: false).configModel;
    return Column(children: [
      Consumer<AuthController>(builder: (context, authProvider, _) {
        return Consumer<SplashController>(
            builder: (context, splashProvider, _) {
          return Form(
            key: signUpFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // First Name
                CustomTextFieldWidget(
                  hintText: getTranslated('first_name', context),
                  labelText: getTranslated('first_name', context),
                  labelTextStyle: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                  inputType: TextInputType.name,
                  required: true,
                  isShowBorder: true,
                  borderRadius: 16,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  focusNode: _fNameFocus,
                  nextFocus: _lNameFocus,
                  prefixIcon: Images.username,
                  capitalization: TextCapitalization.words,
                  controller: _firstNameController,
                  validator: (value) => ValidateCheck.validateEmptyText(
                      value, "first_name_field_is_required"),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Last Name
                CustomTextFieldWidget(
                  hintText: getTranslated('last_name', context),
                  labelText: getTranslated('last_name', context),
                  labelTextStyle: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                  focusNode: _lNameFocus,
                  prefixIcon: Images.username,
                  nextFocus: _emailFocus,
                  required: true,
                  isShowBorder: true,
                  borderRadius: 16,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  capitalization: TextCapitalization.words,
                  controller: _lastNameController,
                  validator: (value) => ValidateCheck.validateEmptyText(
                      value, "last_name_field_is_required"),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Email Field
                CustomTextFieldWidget(
                  hintText: getTranslated('enter_your_email', context),
                  labelText: getTranslated('enter_your_email', context),
                  labelTextStyle: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                  focusNode: _emailFocus,
                  nextFocus: _phoneFocus,
                  required: true,
                  isShowBorder: true,
                  borderRadius: 16,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  inputType: TextInputType.emailAddress,
                  controller: _emailController,
                  prefixIcon: Images.email,
                  validator: (value) => ValidateCheck.validateEmail(value),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Mobile Phone Field
                CustomTextFieldWidget(
                  hintText: getTranslated('enter_mobile_number', context),
                  labelText: getTranslated('enter_mobile_number', context),
                  labelTextStyle: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  nextFocus: _passwordFocus,
                  required: true,
                  showCodePicker: true,
                  isShowBorder: true,
                  borderRadius: 16,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  countryDialCode: authProvider.countryDialCode,
                  onCountryChanged: (CountryCode countryCode) {
                    _phoneFocus.requestFocus();
                    authProvider.countryDialCode = countryCode.dialCode!;
                    authProvider.setCountryCode(countryCode.dialCode!);
                  },
                  isAmount: true,
                  validator: (value) => ValidateCheck.validatePhoneNoText(value,
                      authProvider.countryDialCode, "phone_must_be_required"),
                  inputAction: TextInputAction.next,
                  inputType: TextInputType.phone,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Password Field
                CustomTextFieldWidget(
                  hintText: getTranslated('minimum_password_length', context),
                  labelText: getTranslated('password', context),
                  labelTextStyle: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  isPassword: true,
                  required: true,
                  isShowBorder: true,
                  borderRadius: 16,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  nextFocus: _confirmPasswordFocus,
                  inputAction: TextInputAction.next,
                  validator: (value) => ValidateCheck.validatePassword(
                      value, "password_must_be_required"),
                  prefixIcon: Images.pass,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Confirm Password Field
                CustomTextFieldWidget(
                  isPassword: true,
                  required: true,
                  isShowBorder: true,
                  borderRadius: 16,
                  borderColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  hintText: getTranslated('re_enter_password', context),
                  labelText: getTranslated('re_enter_password', context),
                  labelTextStyle: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  inputAction: TextInputAction.done,
                  validator: (value) => ValidateCheck.validateConfirmPassword(
                      value, _passwordController.text.trim()),
                  prefixIcon: Images.pass,
                ),

                // Referral Code Field
                if (splashProvider.configModel?.refEarningStatus != null &&
                    splashProvider.configModel?.refEarningStatus == "1") ...[
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  CustomTextFieldWidget(
                    hintText: getTranslated('enter_refer_code', context),
                    labelText: getTranslated('referral_code', context),
                    labelTextStyle: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyLarge!.color),
                    controller: _referController,
                    focusNode: _referFocus,
                    isShowBorder: true,
                    borderRadius: 16,
                    borderColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.12),
                    prefixIcon: Images.referImage,
                    prefixColor: Theme.of(context).primaryColor,
                    inputAction: TextInputAction.done,
                  ),
                ],

                const SizedBox(height: Dimensions.paddingSizeLarge),
                const ConditionCheckBox(),
                const SizedBox(height: 24),

                CustomButton(
                  isLoading: authProvider.isLoading,
                  radius: 16,
                  onTap: authProvider.isAcceptTerms
                      ? () {
                          String firstName = _firstNameController.text.trim();
                          String lastName = _lastNameController.text.trim();
                          String email = _emailController.text.trim();
                          String phoneNumber = authProvider.countryDialCode +
                              _phoneController.text.trim();
                          String password = _passwordController.text.trim();

                          if (signUpFormKey.currentState?.validate() ?? false) {
                            register.fName = firstName;
                            register.lName = lastName;
                            register.email = email;
                            register.phone = phoneNumber;
                            register.password = password;
                            register.referCode = _referController.text.trim();
                            authProvider.registration(register, route, config!,
                                widget.fromPage, widget.onLoginSuccess);
                          }
                        }
                      : null,
                  buttonText: getTranslated('sign_up', context),
                ),

                if (!authProvider.isLoading) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getTranslated('already_have_account', context) ??
                            "Already have an account?",
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          authProvider.getGuestIdUrl();
                          Navigator.pop(context);
                        },
                        child: Text(
                          getTranslated('sign_in', context) ?? "Sign In",
                          style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        });
      }),
    ]);
  }
}
