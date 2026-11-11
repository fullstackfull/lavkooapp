import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syriapharmacy/common/basewidget/custom_asset_image_widget.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:provider/provider.dart';

class ChoosePaymentWidget extends StatelessWidget {
  final bool onlyDigital;
  const ChoosePaymentWidget({super.key, required this.onlyDigital});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(builder: (context, orderProvider, _) {
      return Consumer<SplashController>(builder: (context, configProvider, _) {
        final bool hasPaymentSelected = orderProvider.isCODChecked ||
            orderProvider.isOfflineChecked ||
            orderProvider.isWalletChecked ||
            (orderProvider.paymentMethodIndex != -1);

        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: CustomAssetImageWidget(
                              Images.paymentMethodSelectIcon,
                              height: 20,
                              width: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            '${getTranslated('payment_method', context)}',
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => PaymentMethodBottomSheetWidget(
                            onlyDigital: onlyDigital),
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(Images.edit,
                            scale: 3, color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              if (hasPaymentSelected)
                Container(
                  margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.03),
                    border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.05),
                        width: 1.2),
                  ),
                  child: (orderProvider.paymentMethodIndex != -1)
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        Colors.black.withValues(alpha: 0.05)),
                              ),
                              width: 50,
                              height: 35,
                              child: CustomImageWidget(
                                image:
                                    '${configProvider.configModel?.paymentMethodImagePath}/${configProvider.configModel!.paymentMethods![orderProvider.paymentMethodIndex].additionalDatas!.gatewayImage ?? ''}',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Text(
                                configProvider
                                        .configModel!
                                        .paymentMethods![
                                            orderProvider.paymentMethodIndex]
                                        .additionalDatas!
                                        .gatewayTitle ??
                                    '',
                                style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                orderProvider.isWalletChecked
                                    ? Icons.account_balance_wallet_outlined
                                    : orderProvider.isOfflineChecked
                                        ? Icons.receipt_long_outlined
                                        : Icons.payments_outlined,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Text(
                                orderProvider.isCODChecked
                                    ? (getTranslated(
                                            'cash_on_delivery', context) ??
                                        '')
                                    : orderProvider.isOfflineChecked
                                        ? (getTranslated(
                                                'offline_payment', context) ??
                                            '')
                                        : orderProvider.isWalletChecked
                                            ? (getTranslated('wallet_payment',
                                                    context) ??
                                                '')
                                            : '',
                                style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                            ),
                          ],
                        ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: InkWell(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => PaymentMethodBottomSheetWidget(
                          onlyDigital: onlyDigital),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.25),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: Theme.of(context).primaryColor, size: 24),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            getTranslated('add_payment_method', context) ?? '',
                            style: textBold.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 350.ms)
            .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
      });
    });
  }
}
