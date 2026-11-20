import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/utill/update_target.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(
              color: Theme.of(context).primaryColor,
              Images.update,
              width: MediaQuery.of(context).size.height * 0.4,
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              getTranslated('update', context)!,
              style: robotoBold.copyWith(
                  fontSize: MediaQuery.of(context).size.height * 0.023,
                  color: Theme.of(context).primaryColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              getTranslated('your_app_is_deprecated', context)!,
              style: textRegular.copyWith(
                  fontSize: MediaQuery.of(context).size.height * 0.0175,
                  color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            CustomButton(
                buttonText: getTranslated('update_now', context)!,
                onTap: () async {
                  final List<String> targets = UpdateTarget.candidates(
                    control: Provider.of<SplashController>(context,
                            listen: false)
                        .configModel
                        ?.userAppVersionControl,
                    isIos: defaultTargetPlatform == TargetPlatform.iOS,
                  );

                  for (final String target in targets) {
                    if (await canLaunchUrlString(target)) {
                      await launchUrlString(target,
                          mode: LaunchMode.externalApplication);
                      return;
                    }
                  }

                  if (context.mounted) {
                    showCustomSnackBarWidget(
                        '${getTranslated('can_not_launch', context)!}  ${targets.join(', ')}',
                        context,
                        snackBarType: SnackBarType.error);
                  }
                }),
          ]),
        ),
      ),
    );
  }
}
