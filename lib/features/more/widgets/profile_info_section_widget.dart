import 'package:syriapharmacy/theme/dark_theme.dart';
import 'package:syriapharmacy/theme/light_theme.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/helper/route_healper.dart';

class ProfileInfoSectionWidget extends StatelessWidget {
  const ProfileInfoSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, profile, _) {
        bool isGuestMode =
            !Provider.of<AuthController>(context, listen: false).isLoggedIn();
        final isDark = Provider.of<ThemeController>(context).darkTheme;
        final userName = isGuestMode
            ? 'Guest'
            : '${profile.userInfoModel?.fName ?? ''} ${profile.userInfoModel?.lName ?? ''}'
                .trim();

        final primaryColor = Theme.of(context).primaryColor;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          // The status bar's own height, not a guess at it: 45 was too much on
          // a short inset and too little on a tall one.
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            MediaQuery.paddingOf(context).top + 12,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Title + Settings/Inbox/Theme Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TopIconButton(
                    icon: Icons.arrow_back_ios,
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  // Text(
                  //   getTranslated('more', context) ?? 'More',
                  //   style: textBold.copyWith(
                  //     fontSize: Dimensions.fontSizeOverLarge,
                  //     color: Theme.of(context).textTheme.bodyLarge?.color,
                  //   ),
                  // ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ThemeSwitcher.withTheme(
                        builder: (ctx, switcher, theme) {
                          final isDarkNow = theme.brightness == Brightness.dark;
                          return GestureDetector(
                            onTapDown: (details) {
                              Provider.of<ThemeController>(ctx, listen: false)
                                  .toggleThemeSilent();
                              switcher.changeTheme(
                                theme: isDarkNow
                                    ? light(
                                        primaryColor:
                                            Provider.of<ThemeController>(ctx,
                                                    listen: false)
                                                .selectedPrimaryColor,
                                        secondaryColor:
                                            Provider.of<ThemeController>(ctx,
                                                    listen: false)
                                                .selectedSecondaryColor,
                                      )
                                    : dark(
                                        primaryColor:
                                            Provider.of<ThemeController>(ctx,
                                                    listen: false)
                                                .selectedPrimaryColor,
                                        secondaryColor:
                                            Provider.of<ThemeController>(ctx,
                                                    listen: false)
                                                .selectedSecondaryColor,
                                      ),
                                offset: details.globalPosition,
                              );
                            },
                            child: AbsorbPointer(
                              child: _TopIconButton(
                                icon: isDarkNow
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                onTap: () {},
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _TopIconButton(
                        icon: Icons.inbox_outlined,
                        onTap: () => RouterHelper.getInboxScreenRoute(
                            action: RouteAction.push),
                      ),
                      const SizedBox(width: 8),
                      _TopIconButton(
                        icon: Icons.settings_outlined,
                        onTap: () => RouterHelper.getSettingsRoute(
                            action: RouteAction.push),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Profile Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    InkWell(
                      onTap: () {
                        if (isGuestMode) {
                          showModalBottomSheet(
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (_) => NotLoggedInBottomSheetWidget(
                              fromPage: RouterHelper.profileScreen1,
                            ),
                          );
                        } else {
                          if (profile.userInfoModel != null) {
                            RouterHelper.getProfileScreen1Route(
                                action: RouteAction.push);
                          }
                        }
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.12),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: ClipOval(
                          child: Provider.of<AuthController>(context,
                                      listen: false)
                                  .isLoggedIn()
                              ? CustomImageWidget(
                                  image: profile
                                          .userInfoModel?.imageFullUrl?.path ??
                                      '',
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  placeholder: Images.guestProfile,
                                )
                              : Image.asset(Images.guestProfile),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name & Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isGuestMode
                                      ? (getTranslated('guest', context) ??
                                          'Guest')
                                      : userName,
                                  style: textBold.copyWith(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isGuestMode) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () =>
                                      RouterHelper.getProfileScreen1Route(
                                          action: RouteAction.push),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_activity_outlined,
                                          size: 13,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          getTranslated(
                                                  'my_activity', context) ??
                                              'My Activity',
                                          style: textMedium.copyWith(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall +
                                                    1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGuestMode
                                ? (getTranslated(
                                        'welcome_to_shoppe', context) ??
                                    'Welcome to Shoppe')
                                : (profile.userInfoModel?.email ??
                                    profile.userInfoModel?.phone ??
                                    ''),
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        // decoration: BoxDecoration(
        //   shape: BoxShape.circle,
        //   color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        //   border: Border.all(
        //     color: isDark
        //         ? Colors.white.withOpacity(0.05)
        //         : Colors.black.withOpacity(0.05),
        //     width: 1,
        //   ),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.02),
        //       blurRadius: 6,
        //       offset: const Offset(0, 2),
        //     ),
        //   ],
        // ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
    );
  }
}
