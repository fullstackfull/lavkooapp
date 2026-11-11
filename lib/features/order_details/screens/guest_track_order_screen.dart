import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:syriapharmacy/features/order_details/controllers/order_details_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/helper/country_code_helper.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/helper/velidate_check.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class GuestTrackOrderScreen extends StatefulWidget {
  final String? orderId;
  final String? phone;
  const GuestTrackOrderScreen({super.key, this.orderId, this.phone});

  @override
  State<GuestTrackOrderScreen> createState() => _GuestTrackOrderScreenState();
}

class _GuestTrackOrderScreenState extends State<GuestTrackOrderScreen> {
  String? countryCode;

  TextEditingController orderIdController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      orderIdController.text = widget.orderId ?? '';
    }

    if (widget.phone != null) {
      String countryCodee =
          CountryCodeHelper.getCountryCode(widget.phone ?? '')!;
      countryCode = countryCodee;

      String phoneNumberOnly = CountryCodeHelper.extractPhoneNumber(
          countryCode!, widget.phone ?? '');
      phoneNumberController.text = phoneNumberOnly;
    } else {
      final ConfigModel configModel =
          Provider.of<SplashController>(context, listen: false).configModel!;
      countryCode ??=
          CountryCode.fromCountryCode(configModel.countryCode!).dialCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double widthSize = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if (widget.phone != null) {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushReplacement, page: 'home');
        } else {
          return;
        }
      },
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor),
              onPressed: () {
                if (widget.phone != null) {
                  RouterHelper.getDashboardRoute(
                      action: RouteAction.pushReplacement, page: 'home');
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          body: Consumer<OrderDetailsController>(
              builder: (context, orderTrackingProvider, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraLarge),
                child: Form(
                  key: formKey,
                  child: ListView(
                      physics: const ClampingScrollPhysics(),
                      children: [
                        const SizedBox(height: Dimensions.paddingSizeOverLarge),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset('assets/lottie/truck.json',
                                  height: widthSize * 0.4),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          Dimensions.paddingSizeDefault),
                                  child: Text(
                                    getTranslated(
                                        'track_your_order_from_here', context)!,
                                    style: textMedium.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                        fontSize: Dimensions.fontSizeLarge),
                                    textAlign: TextAlign.center,
                                  )),
                            ]),
                        const SizedBox(
                            height: Dimensions.paddingSizeThirtyFive),
                        Container(
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeDefault),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.08),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTranslated('order_details', context) ??
                                    'Order Details',
                                style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              CustomTextFieldWidget(
                                controller: orderIdController,
                                prefixIcon: Images.orderIdIcon,
                                prefixColor: Theme.of(context).primaryColor,
                                isAmount: true,
                                inputType: TextInputType.phone,
                                hintText:
                                    getTranslated('enter_order_id', context),
                                labelText: getTranslated('order_id', context),
                                labelTextStyle: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                required: true,
                                showLabelText: false,
                                validator: (value) =>
                                    ValidateCheck.validateEmptyText(
                                        value, 'order_id_is_required'),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              CustomTextFieldWidget(
                                countryDialCode: countryCode,
                                showCodePicker: true,
                                inputType: TextInputType.phone,
                                prefixColor: Theme.of(context).primaryColor,
                                controller: phoneNumberController,
                                inputAction: TextInputAction.done,
                                hintText:
                                    '${getTranslated('enter_phone_number', context)}',
                                required: true,
                                labelText:
                                    '${getTranslated('phone_number', context)}',
                                labelTextStyle: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                showLabelText: false,
                                validator: (value) =>
                                    ValidateCheck.validateEmptyText(
                                        value, 'phone_number_is_required'),
                                onCountryChanged: (CountryCode value) {
                                  countryCode = value.dialCode;
                                },
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraOverLarge),
                              CustomButton(
                                isLoading: orderTrackingProvider.searching,
                                buttonText:
                                    '${getTranslated('track_order', context)}',
                                onTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  String orderId =
                                      orderIdController.text.trim();
                                  String phone = countryCode! +
                                      phoneNumberController.text.trim();

                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    await orderTrackingProvider
                                        .trackOrder(
                                      orderId: orderId,
                                      phoneNumber: phone,
                                      isUpdate: true,
                                    )
                                        .then((value) async {
                                      if (value.response?.statusCode == 200) {
                                        await orderTrackingProvider
                                            .getTrackOrderDetailsId(
                                                orderId: orderId);

                                        if (context.mounted) {
                                          RouterHelper.getTrackingResultRoute(
                                            action: RouteAction.push,
                                            orderID: orderId,
                                          );
                                          orderIdController.text = '';
                                          phoneNumberController.text = '';
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ]),
                ),
              ),
            );
          })),
    );
  }
}
