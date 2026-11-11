import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_view_all.dart';
import 'package:syriapharmacy/common/basewidget/custom_asset_image_widget.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/notification/controllers/notification_controller.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/localization/controllers/localization_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class MenuButtonWidget extends StatelessWidget {
  final String image;
  final String? title;
  final Widget? navigateTo;
  final bool isNotification;
  final bool isProfile;
  final Function? onTap;
  const MenuButtonWidget(
      {super.key,
      required this.image,
      required this.title,
      this.navigateTo,
      this.isNotification = false,
      this.isProfile = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLtr =
        Provider.of<LocalizationController>(context, listen: false).isLtr;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        InkWell(
          onTap: onTap != null ? () => onTap!() : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeSmall + 2,
            ),
            child: Row(
              children: [
                // Premium colored background container for Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    // color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: CustomAssetImageWidget(
                    image,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Title
                Expanded(
                  child: Text(
                    title ?? '',
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),

                // Trailing (notification count, profile count, or chevron)
                if (isNotification &&
                    Provider.of<AuthController>(context, listen: false)
                        .isLoggedIn())
                  Consumer<NotificationController>(
                    builder: (context, notificationController, _) {
                      final count = notificationController
                              .notificationModel?.newNotificationItem ??
                          0;
                      if (count == 0) {
                        return Icon(
                          // Was inverted: LTR drew a left chevron and RTL a
                          // right one, so every row pointed back in both
                          // languages. One helper decides this app-wide.
                          forwardChevron(context),
                          color: Theme.of(context).hintColor.withOpacity(0.6),
                          size: 22,
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: textRegular.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      );
                    },
                  )
                else if (isProfile)
                  Consumer<ProfileController>(
                    builder: (context, profileProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          profileProvider.userInfoModel?.referCount
                                  .toString() ??
                              '0',
                          style: textRegular.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Icon(forwardChevron(context))
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).hintColor.withOpacity(0.08),
          indent: 52,
        ),
      ],
    );
  }
}
