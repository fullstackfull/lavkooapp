  import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_view_all.dart';
  import 'package:syriapharmacy/core/animations/app_animations.dart';
  import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
  import 'package:syriapharmacy/features/splash/domain/models/business_pages_model.dart';
  import 'package:syriapharmacy/helper/route_healper.dart';
  import 'package:syriapharmacy/utill/app_constants.dart';
  import 'package:syriapharmacy/features/more/widgets/logout_confirm_bottom_sheet_widget.dart';
  import 'package:syriapharmacy/localization/language_constrants.dart';
  import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
  import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
  import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
  import 'package:syriapharmacy/utill/custom_themes.dart';
  import 'package:syriapharmacy/utill/dimensions.dart';
  import 'package:syriapharmacy/utill/images.dart';
  import 'package:syriapharmacy/features/more/widgets/profile_info_section_widget.dart';
  import 'package:syriapharmacy/features/more/widgets/more_horizontal_section_widget.dart';
  import 'package:provider/provider.dart';
  import 'package:syriapharmacy/features/more/widgets/title_button_widget.dart';

  class MoreScreen extends StatefulWidget {
    const MoreScreen({super.key});
    @override
    State<MoreScreen> createState() => _MoreScreenState();
  }

  class _MoreScreenState extends State<MoreScreen> {
    String? version;
    bool singleVendor = false;

    @override
    void initState() {
      if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
        version = Provider.of<SplashController>(context, listen: false)
                .configModel!
                .softwareVersion ??
            'version';
        Provider.of<ProfileController>(context, listen: false)
            .getUserInfo(context);
      }
      singleVendor = Provider.of<SplashController>(context, listen: false)
              .configModel
              ?.businessMode ==
          "single";

      super.initState();
    }

    @override
    Widget build(BuildContext context) {
      // var authController = Provider.of<AuthController>(context, listen: false);

      return Scaffold(
        body: CustomScrollView(slivers: [
          // Tall enough for what the header actually holds, plus whatever the
          // device gives to its status bar. It was a flat 180 against content
          // that needs 164 more than the inset, which is why this screen has
          // been drawing an overflow stripe across the profile card.
          Builder(builder: (context) {
            final double headerHeight =
                164 + MediaQuery.paddingOf(context).top;
            return SliverAppBar(
                floating: false,
                elevation: 0,
                expandedHeight: headerHeight,
                pinned: true,
                centerTitle: false,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).cardColor,
                collapsedHeight: headerHeight,
                flexibleSpace: const ProfileInfoSectionWidget());
          }),
          SliverToBoxAdapter(
              child: Container(
            decoration:
                BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
            child: Consumer<AuthController>(builder: (ctx, authController, _) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeSmall),
                            child: Center(child: MoreHorizontalSection()))
                        .animateSectionEntrance(index: 0),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                Dimensions.paddingSizeDefault,
                                Dimensions.paddingSizeDefault,
                                Dimensions.paddingSizeDefault,
                                0),
                            child: Text(getTranslated('general', context) ?? '',
                                style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeExtraLarge,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color)),
                          ),
                          Consumer<SplashController>(
                              builder: (context, splashController, _) {
                            final isDark =
                                Provider.of<ThemeController>(context).darkTheme;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall,
                                    vertical: Dimensions.paddingSizeExtraSmall),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.withOpacity(0.08),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                          color: isDark
                                              ? Colors.black.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.03),
                                          blurRadius: 15,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 6))
                                    ],
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Theme.of(context).cardColor),
                                child: Column(children: [
                                  MenuButtonWidget(
                                    image: Images.trackOrderIcon,
                                    title: getTranslated('TRACK_ORDER', context),
                                    onTap: () {
                                      RouterHelper.getGuestTrackOrderRoute(
                                          action: RouteAction.push);
                                    },
                                  ),
                                  if (authController.isLoggedIn())
                                    MenuButtonWidget(
                                      image: Images.shoppingImage,
                                      title: getTranslated('orders', context),
                                      onTap: () {
                                        RouterHelper.getOrderScreenRoute(
                                            action: RouteAction.push);
                                      },
                                    ),
                                  if (authController.isLoggedIn())
                                    MenuButtonWidget(
                                      image: Images.user,
                                      title: getTranslated('profile', context),
                                      onTap: () {
                                        RouterHelper.getProfileScreen1Route(
                                            action: RouteAction.push);
                                      },
                                    ),
                                  MenuButtonWidget(
                                    image: Images.address,
                                    title: getTranslated('addresses', context),
                                    onTap: () {
                                      RouterHelper.getAddressListScreen(
                                          action: RouteAction.push);
                                    },
                                  ),
                                  MenuButtonWidget(
                                    image: Images.coupon,
                                    title: getTranslated('coupons', context),
                                    onTap: () {
                                      RouterHelper.getCouponListScreenRoute();
                                    },
                                  ),
                                  if (authController.isLoggedIn())
                                    if (splashController
                                            .configModel?.refEarningStatus ==
                                        "1")
                                      MenuButtonWidget(
                                        image: Images.refIcon,
                                        title: getTranslated(
                                            'refer_and_earn', context),
                                        isProfile: true,
                                        onTap: () {
                                          RouterHelper.getReferAndEarnRoute(
                                              action: RouteAction.push);
                                        },
                                      ),
                                  MenuButtonWidget(
                                    image: Images.category,
                                    title: getTranslated('CATEGORY', context),
                                    onTap: () {
                                      RouterHelper.getCategoryScreenRoute(
                                          action: RouteAction.push);
                                    },
                                  ),
                                  if (authController.isLoggedIn())
                                    MenuButtonWidget(
                                      image: Images.restockIcon,
                                      title: getTranslated(
                                          'restock_requests', context),
                                      onTap: () {
                                        RouterHelper.getRestockListRoute(
                                            action: RouteAction.push);
                                      },
                                    ),
                                  if (splashController.configModel!.activeTheme !=
                                          "default" &&
                                      authController.isLoggedIn())
                                    MenuButtonWidget(
                                      image: Images.compare,
                                      title: getTranslated(
                                          'compare_products', context),
                                      onTap: () {
                                        RouterHelper
                                            .getCompareProductScreenRoute();
                                      },
                                    ),
                                  MenuButtonWidget(
                                    image: Images.notification,
                                    title: getTranslated(
                                      'notification',
                                      context,
                                    ),
                                    isNotification: true,
                                    onTap: () {
                                      RouterHelper.getNotificationRoute(
                                          action: RouteAction.push);
                                    },
                                  ),
                                  MenuButtonWidget(
                                    image: Images.settings,
                                    title: getTranslated('settings', context),
                                    onTap: () {
                                      RouterHelper.getSettingsRoute(
                                          action: RouteAction.push);
                                    },
                                  ),
                                  MenuButtonWidget(
                                    image: Images.preference,
                                    title:
                                        getTranslated('becomeMerchant', context),
                                    onTap: () {
                                      RouterHelper.getBecomeMerchantRoute(
                                          action: RouteAction.push);
                                    },
                                  ),
                                  if (splashController
                                          .configModel?.blogUrl?.isNotEmpty ??
                                      false)
                                    MenuButtonWidget(
                                        image: Images.blogIcon,
                                        title: getTranslated('blog', context),
                                        onTap: () {
                                          RouterHelper.getBlogScreenRoute(
                                              action: RouteAction.push,
                                              url: splashController
                                                      .configModel?.blogUrl ??
                                                  '');
                                        }),
                                ]),
                              ),
                            );
                          }),
                        ]).animateSectionEntrance(index: 1),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  Dimensions.paddingSizeDefault,
                                  Dimensions.paddingSizeDefault,
                                  Dimensions.paddingSizeDefault,
                                  0),
                              child: Text(
                                  getTranslated('help_and_support', context) ??
                                      '',
                                  style: textBold.copyWith(
                                      fontSize: Dimensions.fontSizeExtraLarge,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color))),
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeSmall,
                                      vertical: Dimensions.paddingSizeExtraSmall),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: (Theme.of(context).brightness ==
                                                Brightness.dark)
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey.withOpacity(0.08),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                            color: (Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark)
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.black.withOpacity(0.03),
                                            blurRadius: 15,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 6))
                                      ],
                                      color: (Theme.of(context).brightness ==
                                              Brightness.dark)
                                          ? Colors.white.withOpacity(0.04)
                                          : Theme.of(context).cardColor),
                                  child: Consumer<SplashController>(
                                      builder: (context, splashController, _) {
                                    return Column(children: [
                                      singleVendor
                                          ? const SizedBox()
                                          : MenuButtonWidget(
                                              image: Images.chats,
                                              title:
                                                  getTranslated('inbox', context),
                                              onTap: () {
                                                RouterHelper.getInboxScreenRoute(
                                                    action: RouteAction.push);
                                              },
                                            ),
                                      MenuButtonWidget(
                                        image: Images.callIcon,
                                        title:
                                            getTranslated('contact_us', context),
                                        onTap: () {
                                          RouterHelper.getContactUsScreenRoute();
                                        },
                                      ),
                                      MenuButtonWidget(
                                        image: Images.preference,
                                        title: getTranslated(
                                            'support_ticket', context),
                                        onTap: () {
                                          RouterHelper.getSupportTicketRoute(
                                              action: RouteAction.push);
                                        },
                                      ),
                                      if (splashController.defaultBusinessPages !=
                                              null &&
                                          splashController.defaultBusinessPages!
                                              .isNotEmpty) ...[
                                        if (getPageBySlug(
                                                'terms-and-conditions',
                                                splashController
                                                    .defaultBusinessPages) !=
                                            null)
                                          MenuButtonWidget(
                                              image: Images.termCondition,
                                              title: getTranslated(
                                                  'terms_condition', context),
                                              onTap: () =>
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: getPageBySlug(
                                                          'terms-and-conditions',
                                                          splashController
                                                              .defaultBusinessPages)!)),
                                        if (getPageBySlug(
                                                'privacy-policy',
                                                splashController
                                                    .defaultBusinessPages) !=
                                            null)
                                          MenuButtonWidget(
                                              image: Images.privacyPolicy,
                                              title: getTranslated(
                                                  'privacy_policy', context),
                                              onTap: () =>
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: getPageBySlug(
                                                          'privacy-policy',
                                                          splashController
                                                              .defaultBusinessPages)!)),
                                        if (getPageBySlug(
                                                'refund-policy',
                                                splashController
                                                    .defaultBusinessPages) !=
                                            null)
                                          MenuButtonWidget(
                                              image: Images.termCondition,
                                              title: getTranslated(
                                                  'refund_policy', context),
                                              onTap: () =>
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: getPageBySlug(
                                                          'refund-policy',
                                                          splashController
                                                              .defaultBusinessPages)!)),
                                        if (getPageBySlug(
                                                'return-policy',
                                                splashController
                                                    .defaultBusinessPages) !=
                                            null)
                                          MenuButtonWidget(
                                              image: Images.termCondition,
                                              title: getTranslated(
                                                  'return_policy', context),
                                              onTap: () =>
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: getPageBySlug(
                                                          'return-policy',
                                                          splashController
                                                              .defaultBusinessPages)!)),
                                        if (getPageBySlug(
                                                'cancellation-policy',
                                                splashController
                                                    .defaultBusinessPages) !=
                                            null)
                                          MenuButtonWidget(
                                              image: Images.termCondition,
                                              title: getTranslated(
                                                  'cancellation_policy', context),
                                              onTap: () =>
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: getPageBySlug(
                                                          'cancellation-policy',
                                                          splashController
                                                              .defaultBusinessPages)!)),
                                        if (getPageBySlug(
                                                'shipping-policy',
                                                splashController
                                                    .defaultBusinessPages) !=
                                            null)
                                          MenuButtonWidget(
                                              image: Images.termCondition,
                                              title: getTranslated(
                                                  'shipping_policy', context),
                                              onTap: () =>
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: getPageBySlug(
                                                          'shipping-policy',
                                                          splashController
                                                              .defaultBusinessPages)!)),
                                      ],
                                      MenuButtonWidget(
                                        image: Images.faq,
                                        title: getTranslated('faq', context),
                                        onTap: () {
                                          RouterHelper.getFaqRoute(
                                              action: RouteAction.push);
                                        },
                                      ),
                                      if (getPageBySlug(
                                              'about-us',
                                              splashController
                                                  .defaultBusinessPages) !=
                                          null)
                                        MenuButtonWidget(
                                            image: Images.user,
                                            title: getTranslated(
                                                'about_us', context),
                                            onTap: () =>
                                                RouterHelper.getHtmlViewRoute(
                                                    page: getPageBySlug(
                                                        'about-us',
                                                        splashController
                                                            .defaultBusinessPages)!)),
                                      if (splashController.businessPages !=
                                              null &&
                                          splashController
                                              .businessPages!.isNotEmpty)
                                        ListView.builder(
                                            itemCount: splashController
                                                .businessPages?.length,
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              // return MenuButtonWidget(
                                              //   image: Images.termCondition,
                                              //   title: splashController
                                              //       .businessPages?[index].title,
                                              //   onTap: () {
                                              //     RouterHelper.getHtmlViewRoute(
                                              //         page: splashController
                                              //             .businessPages![index]);
                                              //   },
                                              // );
                                              return MenuButtonWidget(
                                                image: Images.termCondition,
                                                // title: splashController
                                                //     .businessPages?[index].title,
                                                title: getTranslated(
                                                    'delete_account', context),
                                                onTap: () {
                                                  RouterHelper.getHtmlViewRoute(
                                                      page: splashController
                                                          .businessPages![index]);
                                                },
                                              );
                                            })
                                    ]);
                                  }))),
                        ]).animateSectionEntrance(index: 2),
                    Column(children: [
                      if (authController.isLoggedIn())
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Image.asset(Images.logOut,
                                  color: Theme.of(context).primaryColor,
                                  width: 22,
                                  height: 22),
                              title: Text(
                                getTranslated('sign_out', context)!,
                                style: textBold.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              trailing: Icon(forwardChevron(context),
                                  size: 14,
                                  color: Theme.of(context).primaryColor),
                              onTap: () {
                                showModalBottomSheet(
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (_) =>
                                      const LogoutCustomBottomSheetWidget(),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Image.asset(Images.logOut,
                                  color: Theme.of(context).primaryColor,
                                  width: 22,
                                  height: 22),
                              title: Text(
                                getTranslated('sign_in', context)!,
                                style: textBold.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              trailing: Icon(forwardChevron(context),
                                  size: 14,
                                  color: Theme.of(context).primaryColor),
                              onTap: () {
                                RouterHelper.getLoginRoute(
                                    action: RouteAction.push,
                                    fromPage:
                                        '${RouterHelper.dashboardScreen}?page=more');
                              },
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeDefault),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${getTranslated('version', context)} ${AppConstants.appVersion}',
                                style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context).hintColor),
                              ),
                            ]),
                      ),
                    ]).animateSectionEntrance(index: 3),
                    const SizedBox(height: 100),
                  ]);
            }),
          )),
        ]).animateScreenEntrance(),
      );
    }

    BusinessPageModel? getPageBySlug(
        String slug, List<BusinessPageModel>? pagesList) {
      BusinessPageModel? pageModel;
      if (pagesList != null && pagesList.isNotEmpty) {
        for (var page in pagesList) {
          if (page.slug == slug) {
            pageModel = page;
          }
        }
      }
      return pageModel;
    }
  }
