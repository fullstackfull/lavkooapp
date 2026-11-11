import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/contact_us/controllers/contact_us_controller.dart';
import 'package:syriapharmacy/features/contact_us/domain/models/contact_us_body.dart';
import 'package:syriapharmacy/helper/velidate_check.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  final GlobalKey<FormState> contactFormKey = GlobalKey<FormState>();

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          centerTitle: true, title: '${getTranslated('contact_us', context)}'),
      body: Consumer<AuthController>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Illustration & Banner Card
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: Dimensions.homePagePadding),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslated('get_in_touch', context) ??
                                  "Get in Touch",
                              style: textBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraLarge,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              getTranslated('contact_us_subtitle', context) ??
                                  "We would love to hear from you. Send us a message and we will respond as soon as possible.",
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        Images.contactUsBg,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Form Container Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.homePagePadding),
                  child: Container(
                    padding:
                        const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusLarge),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: contactFormKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextFieldWidget(
                            prefixIcon: Images.user,
                            controller: fullNameController,
                            required: true,
                            labelText: getTranslated('full_name', context),
                            hintText: getTranslated('enter_full_name', context),
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                                    value, 'name_is_required'),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          CustomTextFieldWidget(
                            hintText: getTranslated('email', context),
                            prefixIcon: Images.email,
                            required: true,
                            labelText: getTranslated('email', context),
                            controller: emailController,
                            validator: (value) =>
                                ValidateCheck.validateEmail(value),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          CustomTextFieldWidget(
                            hintText:
                                getTranslated('enter_mobile_number', context),
                            labelText:
                                getTranslated('enter_mobile_number', context),
                            controller: phoneController,
                            required: true,
                            showCodePicker: true,
                            countryDialCode: authProvider.countryDialCode,
                            onCountryChanged: (CountryCode countryCode) {
                              authProvider.countryDialCode =
                                  countryCode.dialCode!;
                              authProvider
                                  .setCountryCode(countryCode.dialCode!);
                            },
                            isAmount: true,
                            inputAction: TextInputAction.next,
                            inputType: TextInputType.phone,
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                                    value, 'phone_is_required'),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          CustomTextFieldWidget(
                            required: true,
                            labelText: getTranslated('subject', context),
                            hintText: getTranslated('subject', context),
                            controller: subjectController,
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                                    value, 'subject_is_required'),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          CustomTextFieldWidget(
                            maxLines: 5,
                            required: true,
                            controller: messageController,
                            labelText: getTranslated('message', context),
                            hintText: getTranslated('message', context),
                            validator: (value) =>
                                ValidateCheck.validateEmptyText(
                                    value, 'message_is_required'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeOverLarge),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<ContactUsController>(
        builder: (context, profileProvider, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            child: CustomButton(
              isLoading: profileProvider.isLoading,
              buttonText: getTranslated('send_request', context),
              onTap: () {
                if (contactFormKey.currentState?.validate() ?? false) {
                  String name = fullNameController.text.trim();
                  String email = emailController.text.trim();
                  String phone = phoneController.text.trim();
                  String subject = subjectController.text.trim();
                  String message = messageController.text.trim();

                  ContactUsBody contactUsBody = ContactUsBody(
                      name: name,
                      email: email,
                      phone: phone,
                      subject: subject,
                      message: message);

                  profileProvider.contactUs(contactUsBody).then((isSuccess) {
                    if (isSuccess) {
                      Navigator.of(Get.context!).pop();
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}
