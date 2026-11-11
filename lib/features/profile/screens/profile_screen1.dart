import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_loader_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/auth/domain/models/signup_model.dart';
import 'package:syriapharmacy/features/auth/enums/from_page.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/profile/domain/models/profile_model.dart';
import 'package:syriapharmacy/features/profile/widgets/delete_account_bottom_sheet_widget.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/helper/image_size_checker.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';

class ProfileScreen1 extends StatefulWidget {
  final bool formVerification;
  const ProfileScreen1({super.key, this.formVerification = false});

  @override
  State<ProfileScreen1> createState() => _ProfileScreen1State();
}

class _ProfileScreen1State extends State<ProfileScreen1> {
  final FocusNode _fNameFocus = FocusNode();
  final FocusNode _lNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isMailChanged = false;
  bool isPhoneChanged = false;

  File? file;
  final picker = ImagePicker();

  void _choose() async {
    final pickedFile = await ImageValidationHelper.validateAndPickImage(
        source: ImageSource.gallery, context: context);

    if (pickedFile != null) {
      setState(() {
        file = File(pickedFile.path);
      });
    }
  }

  final phoneToolTipKey = GlobalKey<State<Tooltip>>();
  final emailToolTipKey = GlobalKey<State<Tooltip>>();

  Future<void> _updateUserAccount() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String phoneNumber = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (Provider.of<ProfileController>(context, listen: false)
                .userInfoModel!
                .fName ==
            _firstNameController.text &&
        Provider.of<ProfileController>(context, listen: false)
                .userInfoModel!
                .lName ==
            _lastNameController.text &&
        Provider.of<ProfileController>(context, listen: false)
                .userInfoModel!
                .phone ==
            _phoneController.text &&
        Provider.of<ProfileController>(context, listen: false)
                .userInfoModel!
                .email ==
            _emailController.text &&
        file == null &&
        _passwordController.text.isEmpty &&
        _confirmPasswordController.text.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('change_something_to_update', context), context,
          snackBarType: SnackBarType.warning);
    } else if (firstName.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('first_name_is_required', context), context,
          snackBarType: SnackBarType.warning);
    } else if (lastName.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('last_name_is_required', context), context,
          snackBarType: SnackBarType.warning);
    } else if (email.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('email_is_required', context), context,
          snackBarType: SnackBarType.warning);
    } else if (phoneNumber.isEmpty) {
      showCustomSnackBarWidget(
          getTranslated('phone_must_be_required', context), context,
          snackBarType: SnackBarType.warning);
    } else if ((password.isNotEmpty && password.length < 8) ||
        (confirmPassword.isNotEmpty && confirmPassword.length < 8)) {
      showCustomSnackBarWidget(
          getTranslated('minimum_password_is_8_character', context), context,
          snackBarType: SnackBarType.warning);
    } else if (password != confirmPassword) {
      showCustomSnackBarWidget(
          getTranslated('confirm_password_not_matched', context), context,
          snackBarType: SnackBarType.warning);
    } else {
      ProfileModel updateUserInfoModel =
          Provider.of<ProfileController>(context, listen: false).userInfoModel!;
      updateUserInfoModel.method = 'put';
      updateUserInfoModel.fName = _firstNameController.text;
      updateUserInfoModel.lName = _lastNameController.text;
      updateUserInfoModel.phone = _phoneController.text;
      updateUserInfoModel.email = _emailController.text;
      String pass = _passwordController.text;

      await Provider.of<ProfileController>(context, listen: false)
          .updateUserInfo(
        updateUserInfoModel,
        pass,
        file,
        Provider.of<AuthController>(context, listen: false).getUserToken(),
      )
          .then((response) {
        if (response.isSuccess) {
          Provider.of<ProfileController>(Get.context!, listen: false)
              .getUserInfo(Get.context!);
          showCustomSnackBarWidget(
              getTranslated('profile_info_updated_successfully', Get.context!),
              Get.context!,
              snackBarType: SnackBarType.success);
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(() {});
        } else {
          showCustomSnackBarWidget(response.message ?? '', Get.context!,
              snackBarType: SnackBarType.error);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashProvider =
        Provider.of<SplashController>(context, listen: false);
    final config = splashProvider.configModel;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.formVerification) {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        } else {
          return;
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('profile', context),
          backgroundColor: Theme.of(context).primaryColor,
          textColor: Colors.white,
          onBackPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              RouterHelper.getDashboardRoute(
                  action: RouteAction.pushNamedAndRemoveUntil);
            }
          },
        ),
        body: Consumer<AuthController>(builder: (context, authController, _) {
          return Consumer<ProfileController>(builder: (context, profile, _) {
            _firstNameController.text = profile.userInfoModel?.fName ?? '';
            _lastNameController.text = profile.userInfoModel?.lName ?? '';
            _emailController.text = profile.userInfoModel?.email ?? '';
            _phoneController.text = profile.userInfoModel?.phone ?? '';
            return profile.userInfoModel != null
                ? Column(children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Gradient background banner with rounded bottom corners
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),

                        // Profile Avatar stacked over the banner
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 110,
                                  width: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.2),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: ClipOval(
                                    child: file == null
                                        ? CustomImageWidget(
                                            image: profile.userInfoModel
                                                    ?.imageFullUrl?.path ??
                                                '',
                                            height: 102,
                                            width: 102,
                                            fit: BoxFit.cover,
                                            placeholder: Images.guestProfile,
                                          )
                                        : Image.file(
                                            file!,
                                            width: 102,
                                            height: 102,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: InkWell(
                                    onTap: _choose,
                                    borderRadius: BorderRadius.circular(100),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animateSectionEntrance(index: 0),

                    const SizedBox(height: 50), // Spacing for stacked avatar

                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        children: [
                          // Section 1: Personal Info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, left: 4, right: 4),
                                child: Text(
                                  getTranslated('personal_info', context) ??
                                      'Personal Info',
                                  style: textBold.copyWith(
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    CustomTextFieldWidget(
                                      labelText:
                                          getTranslated('first_name', context),
                                      inputType: TextInputType.name,
                                      focusNode: _fNameFocus,
                                      nextFocus: _lNameFocus,
                                      hintText:
                                          profile.userInfoModel?.fName ?? '',
                                      controller: _firstNameController,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextFieldWidget(
                                      labelText:
                                          getTranslated('last_name', context),
                                      inputType: TextInputType.name,
                                      focusNode: _lNameFocus,
                                      nextFocus: _emailFocus,
                                      hintText: profile.userInfoModel?.lName,
                                      controller: _lastNameController,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextFieldWidget(
                                      isEnabled:
                                          config?.customerVerification?.email ==
                                                  0 ||
                                              profile.userInfoModel
                                                      ?.emailVerifiedAt ==
                                                  null,
                                      labelText:
                                          getTranslated('email', context),
                                      inputType: TextInputType.emailAddress,
                                      focusNode: _emailFocus,
                                      nextFocus: _phoneFocus,
                                      hintText:
                                          profile.userInfoModel?.email ?? '',
                                      controller: _emailController,
                                      isToolTipSuffix: (isMailChanged ||
                                              (config?.customerVerification
                                                      ?.email ==
                                                  0))
                                          ? false
                                          : true,
                                      suffixIcon: (isMailChanged ||
                                              (config?.customerVerification
                                                      ?.email ==
                                                  0))
                                          ? null
                                          : (config?.customerVerification
                                                          ?.email ==
                                                      1 &&
                                                  profile.userInfoModel
                                                          ?.emailVerifiedAt ==
                                                      null)
                                              ? Images.notVerifiedSvg
                                              : Images.verifiedSvg,
                                      toolTipMessage: (config
                                                      ?.customerVerification
                                                      ?.email ==
                                                  1 &&
                                              profile.userInfoModel
                                                      ?.emailVerifiedAt ==
                                                  null)
                                          ? getTranslated(
                                              'email_not_verified', context)!
                                          : '',
                                      toolTipKey: emailToolTipKey,
                                      suffixOnTap: () {
                                        if (profile.userInfoModel
                                                ?.emailVerifiedAt ==
                                            null) {
                                          SignUpModel signUpModel = SignUpModel(
                                            email: _emailController.text.trim(),
                                          );
                                          authController.sendVerificationCode(
                                              config!, signUpModel,
                                              type: 'email',
                                              fromPage: FromPage.profile);
                                        }
                                      },
                                      onChanged: (value) {
                                        if (profile.userInfoModel?.email !=
                                            value) {
                                          setState(() => isMailChanged = true);
                                        } else if (isMailChanged &&
                                            profile.userInfoModel?.email ==
                                                value) {
                                          setState(() => isMailChanged = false);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextFieldWidget(
                                      isEnabled:
                                          config?.customerVerification?.phone ==
                                                  0 ||
                                              profile.userInfoModel
                                                      ?.isPhoneVerified ==
                                                  0,
                                      labelText:
                                          getTranslated('phone', context),
                                      inputType: TextInputType.phone,
                                      focusNode: _phoneFocus,
                                      hintText:
                                          profile.userInfoModel?.phone ?? "",
                                      nextFocus: _addressFocus,
                                      controller: _phoneController,
                                      toolTipKey: phoneToolTipKey,
                                      isToolTipSuffix: (isPhoneChanged ||
                                              (config?.customerVerification
                                                      ?.phone ==
                                                  0))
                                          ? false
                                          : true,
                                      toolTipMessage: (profile.userInfoModel
                                                      ?.isPhoneVerified ==
                                                  0 &&
                                              config?.customerVerification
                                                      ?.phone ==
                                                  1)
                                          ? getTranslated(
                                              'phone_number_not_verified',
                                              context)!
                                          : '',
                                      suffixIcon: (isPhoneChanged ||
                                              (config?.customerVerification
                                                      ?.phone ==
                                                  0))
                                          ? null
                                          : config?.customerVerification
                                                          ?.phone ==
                                                      1 &&
                                                  profile.userInfoModel
                                                          ?.isPhoneVerified ==
                                                      0
                                              ? Images.notVerifiedSvg
                                              : Images.verifiedSvg,
                                      suffixOnTap: () {
                                        if (profile.userInfoModel
                                                ?.isPhoneVerified ==
                                            0) {
                                          final configModel =
                                              Provider.of<SplashController>(
                                                      context,
                                                      listen: false)
                                                  .configModel;
                                          SignUpModel signUpModel = SignUpModel(
                                            phone: _phoneController.text.trim(),
                                          );
                                          authController.sendVerificationCode(
                                              configModel!, signUpModel,
                                              type: 'phone',
                                              fromPage: FromPage.profile);
                                        }
                                      },
                                      isAmount: true,
                                      onChanged: (value) {
                                        if (profile.userInfoModel?.phone !=
                                            value) {
                                          setState(() => isPhoneChanged = true);
                                        } else if (isPhoneChanged &&
                                            profile.userInfoModel?.phone ==
                                                value) {
                                          setState(
                                              () => isPhoneChanged = false);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animateSectionEntrance(index: 1),

                          const SizedBox(height: 24),

                          // Section 2: Security & Password
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, left: 4, right: 4),
                                child: Text(
                                  getTranslated('password', context) ??
                                      'Security',
                                  style: textBold.copyWith(
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.08),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    CustomTextFieldWidget(
                                        isPassword: true,
                                        labelText:
                                            getTranslated('password', context),
                                        hintText: getTranslated(
                                            'enter_7_plus_character', context),
                                        controller: _passwordController,
                                        focusNode: _passwordFocus,
                                        nextFocus: _confirmPasswordFocus,
                                        inputAction: TextInputAction.next),
                                    const SizedBox(height: 16),
                                    CustomTextFieldWidget(
                                        labelText: getTranslated(
                                            'confirm_password', context),
                                        hintText: getTranslated(
                                            'enter_7_plus_character', context),
                                        isPassword: true,
                                        controller: _confirmPasswordController,
                                        focusNode: _confirmPasswordFocus,
                                        inputAction: TextInputAction.done),
                                  ],
                                ),
                              ),
                            ],
                          ).animateSectionEntrance(index: 2),
                          const SizedBox(height: 30),

                          // Redesigned Bottom Update Button (inside scroll)
                          !profile.isLoading
                              ? Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _updateUserAccount,
                                      borderRadius: BorderRadius.circular(18),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        alignment: Alignment.center,
                                        child: Text(
                                          getTranslated(
                                                  'update_profile', context) ??
                                              'Update Profile',
                                          style: textBold.copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor),
                                  ),
                                ),

                          const SizedBox(height: 16),

                          // Delete Account Button (inside scroll)
                          InkWell(
                            onTap: () => showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (_) => DeleteAccountBottomSheet(
                                  customerId: profile.userID),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withValues(alpha: 0.3)),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      color: Theme.of(context).colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    getTranslated('delete_account', context) ??
                                        'Delete Account',
                                    style: textBold.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ])
                : CustomLoaderWidget(height: MediaQuery.sizeOf(context).height);
          });
        }),
      ),
    );
  }
}
