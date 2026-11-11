import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/features/auth/widgets/sign_up_widget.dart';
import 'package:syriapharmacy/core/animations/app_animations.dart';

class AuthScreen extends StatefulWidget {
  final bool fromLogout;
  final String? fromPage;
  final VoidCallback? onLoginSuccess;
  final String? referCode;
  const AuthScreen(
      {super.key,
      this.fromLogout = false,
      this.fromPage,
      this.onLoginSuccess,
      this.referCode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  bool scrolled = false;
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (widget.referCode != null) {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        } else {
          Navigator.pop(context);
        }
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                          bottom: MediaQuery.of(context).padding.bottom + 10,
                          left: Dimensions.paddingSizeTwelve,
                          right: Dimensions.paddingSizeTwelve,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeTwelve,
                                  vertical: Dimensions.paddingSizeExtraLarge,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .cardColor
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Heading "Sign Up" & subtitle
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            getTranslated('sign_up', context) ??
                                                'Sign Up',
                                            style: TextStyle(
                                              fontFamily:
                                                  'IBM_Plex_Sans_Arabic',
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
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
                                                        'create_an_account',
                                                        context) ??
                                                    'Create an account to continue',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'IBM_Plex_Sans_Arabic',
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .hintColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 28),

                                    SignUpWidget(
                                        fromLogout: widget.fromLogout,
                                        fromPage: widget.fromPage,
                                        onLoginSuccess: widget.onLoginSuccess,
                                        referCode: widget.referCode),
                                  ],
                                ).animateSectionEntrance(index: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating circular back button
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: MediaQuery.of(context).padding.top +
                      Dimensions.paddingSizeDefault,
                  start: Dimensions.paddingSizeLarge,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.9),
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
                        if (widget.referCode != null) {
                          RouterHelper.getDashboardRoute(
                              action: RouteAction.pushNamedAndRemoveUntil);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
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
