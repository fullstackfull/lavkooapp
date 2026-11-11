import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/features/onboarding/concentric_transition/page_view.dart';
import 'package:syriapharmacy/features/onboarding/widgets/card_planet.dart';
import 'package:syriapharmacy/utill/images.dart';

class OnBoardingScreen extends StatefulWidget {
  final Color indicatorColor;
  final Color selectedIndicatorColor;
  const OnBoardingScreen({
    super.key,
    this.indicatorColor = Colors.grey,
    this.selectedIndicatorColor = Colors.black,
  });

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  Widget build(BuildContext context) {
    final data = [
      CardPlanetData(
        title:
        getTranslated('onboarding_title_1', context) ?? 'A World of Beauty',
        subtitle: getTranslated('onboarding_subtitle_1', context) ??
            'Discover a wide selection of premium cosmetics and makeup from the world\'s top brands.',
        image: Image.asset(Images.onBoarding1)
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 600.ms)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
            begin: -8, end: 8, duration: 1800.ms, curve: Curves.easeInOut),
        backgroundColor: const Color(0xFFFFFFFF), // white
        titleColor: const Color(0xFF063523), // elegant purple
        subtitleColor: const Color(0xFF555555), // dark grey
      ),
      CardPlanetData(
        title:
        getTranslated('onboarding_title_2', context) ?? 'Premium Skin Care',
        subtitle: getTranslated('onboarding_subtitle_2', context) ??
            'Pamper your skin with natural and safe care products for a lasting glow and radiance.',
        image: Image.asset(Images.onBoarding2)
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 600.ms)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
            begin: -8, end: 8, duration: 1800.ms, curve: Curves.easeInOut),
        backgroundColor: const Color(0xFF063523), // rich purple
        titleColor: const Color(0xFFFFFFFF),
        subtitleColor: const Color(0xFFD6EBE0), // light purple
      ),
      CardPlanetData(
        title: getTranslated('onboarding_title_3', context) ??
            'Fast & Safe Delivery',
        subtitle: getTranslated('onboarding_subtitle_3', context) ??
            'Order whatever you need and we will deliver it to your doorstep quickly and safely.',
        image: Image.asset(Images.onBoarding3)
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 600.ms)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
            begin: -8, end: 8, duration: 1800.ms, curve: Curves.easeInOut),
        backgroundColor: const Color(0xFFFFFFFF), // white
        titleColor: Theme.of(context).primaryColor, // app primary color
        subtitleColor: const Color(0xFF555555), // dark grey
      ),
    ];

    return Scaffold(
      body: ConcentricPageView(
        colors: data.map((e) => e.backgroundColor).toList(),
        itemCount: data.length,
        itemBuilder: (int index) {
          return CardPlanet(data: data[index]);
        },
        onFinish: () {
          Provider.of<SplashController>(context, listen: false).disableIntro();
          Provider.of<AuthController>(context, listen: false).getGuestIdUrl();
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushNamedAndRemoveUntil);
        },
      ),
    );
  }
}
