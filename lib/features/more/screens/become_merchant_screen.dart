import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

class BecomeMerchantScreen extends StatefulWidget {
  const BecomeMerchantScreen({super.key});

  @override
  State<BecomeMerchantScreen> createState() => _BecomeMerchantScreenState();
}

class _BecomeMerchantScreenState extends State<BecomeMerchantScreen> {
  Future<void> _launchAppOrStore({
    required BuildContext context,
    required String? appUrlScheme,
    required String? packageName,
    required String fallbackUrl,
  }) async {
    // Try launching custom scheme first (like syriavendor://)
    if (appUrlScheme != null && appUrlScheme.isNotEmpty) {
      final Uri schemeUri = Uri.parse(appUrlScheme);
      try {
        if (await canLaunchUrl(schemeUri)) {
          await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    // Try launching package name directly using Android Intent format
    if (packageName != null && packageName.isNotEmpty) {
      final Uri intentUri = Uri.parse(
        'intent:#Intent;package=$packageName;end',);
          // "intent://#Intent;package=$packageName;scheme=${appUrlScheme?.replaceAll('://', '') ?? 'syriavendor'};end");
      try {
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    // Fallback to store/web URL
    final Uri fallbackUri = Uri.parse(fallbackUrl);
    try {
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showCustomSnackBar(
              getTranslated('could_not_launch_url', context) ??
                  'Could not launch URL',
              context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackBar(e.toString(), context);
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showCustomSnackBar(
              getTranslated('could_not_launch_url', context) ??
                  'Could not launch URL',
              context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackBar(e.toString(), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final splashController = Provider.of<SplashController>(context, listen: false);
    final config = splashController.configModel;

    final String websiteUrl = 'https://lavkoo.com/vendor/auth/registration/index';
    final String androidUrl = config?.vendorAppVersionControl?.forAndroid?.link ??
        'https://play.google.com/store/apps/details?id=com.syriapharmacy.vendor';
    final String iosUrl = config?.vendorAppVersionControl?.forIos?.link ?? '';
    final String androidPackage = 'com.lavkoocosmeticsmanager.app';
    final String appScheme = 'lavkooseller://';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF4F6FA),
      body: Column(
        children: [
          CustomAppBar(
            title: getTranslated('becomeMerchant', context) ?? 'Become a Merchant',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Professional Header Banner Card
                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    theme.primaryColor.withValues(alpha: 0.18),
                                    theme.primaryColor.withValues(alpha: 0.04),
                                  ]
                                : [
                                    theme.primaryColor.withValues(alpha: 0.12),
                                    theme.primaryColor.withValues(alpha: 0.02),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: isDark ? 0.05 : 0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: theme.primaryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    getTranslated('becomeMerchant', context) ?? 'Become a Merchant',
                                    style: robotoBold.copyWith(
                                      fontSize: 22,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              getTranslated('become_merchant_desc', context) ??
                                  'Join the largest beauty and pharmacy platform in Syria and expand your sales today.',
                              style: textRegular.copyWith(
                                fontSize: 15,
                                height: 1.6,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Why Sell With Us Section
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'لماذا تبيع معنا؟'
                            : 'Why Sell With Us?',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 14),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.trending_up_rounded,
                            title: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'زيادة مبيعاتك'
                                : 'Boost Sales',
                            desc: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'الوصول لآلاف العملاء يومياً'
                                : 'Reach thousands daily',
                          ),
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.percent_rounded,
                            title: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'عمولة منخفضة'
                                : 'Low Commission',
                            desc: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'أعلى ربحية لمنتجاتك'
                                : 'Max profit margins',
                          ),
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.dashboard_customize_rounded,
                            title: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'لوحة تحكم ذكية'
                                : 'Smart Dashboard',
                            desc: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'إدارة سهلة لمتجرك'
                                : 'Manage shop easily',
                          ),
                          _buildFeatureCard(
                            context: context,
                            icon: Icons.support_agent_rounded,
                            title: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'دعم مستمر'
                                : '24/7 Support',
                            desc: Localizations.localeOf(context).languageCode == 'ar'
                                ? 'فريق دعم تقني وبشري'
                                : 'Help at every step',
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Registration Methods (Quick Links)
                      Text(
                        getTranslated('quick_links', context) ??
                            (Localizations.localeOf(context).languageCode == 'ar'
                                ? 'طرق التسجيل والتحميل'
                                : 'Registration & Download'),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Option 1: Web Portal
                      _buildOptionCard(
                        context: context,
                        icon: Icons.language_rounded,
                        title: getTranslated('register_website', context) ??
                            (Localizations.localeOf(context).languageCode == 'ar'
                                ? 'لوحة التحكم الإلكترونية'
                                : 'Vendor Web Dashboard'),
                        subtitle: websiteUrl,
                        description: Localizations.localeOf(context).languageCode == 'ar'
                            ? 'سجل كتاجر من خلال المتصفح لرفع المنتجات وإدارتها بالكامل.'
                            : 'Register as a merchant through your web browser to upload products.',
                        buttonText: getTranslated('visit_website', context) ??
                            (Localizations.localeOf(context).languageCode == 'ar'
                                ? 'فتح لوحة التحكم'
                                : 'Open Dashboard'),
                        color: Colors.blue,
                        onTap: () => _openUrl(context, websiteUrl),
                      ),
                      const SizedBox(height: 16),

                      // Option 2: Android App
                      if (androidUrl.isNotEmpty) ...[
                        _buildOptionCard(
                          context: context,
                          icon: Icons.android_rounded,
                          title: getTranslated('vendor_app_android', context) ??
                              (Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'تطبيق البائع للأندرويد'
                                  : 'Vendor App (Android)'),
                          subtitle: androidUrl,
                          description: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'أدر متجرك، تابع الطلبات والعملاء مباشرة من هاتفك.'
                              : 'Manage orders, customers, and chat directly from your device.',
                          buttonText: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'تحميل أو فتح التطبيق'
                              : 'Open or Download App',
                          color: Colors.green,
                          onTap: () => _launchAppOrStore(
                            context: context,
                            appUrlScheme: appScheme,
                            packageName: androidPackage,
                            fallbackUrl: androidUrl,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Option 3: iOS App
                      if (iosUrl.isNotEmpty) ...[
                        _buildOptionCard(
                          context: context,
                          icon: Icons.apple_rounded,
                          title: getTranslated('vendor_app_ios', context) ??
                              (Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'تطبيق البائع للـ iOS'
                                  : 'Vendor App (iOS)'),
                          subtitle: iosUrl,
                          description: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'تطبيق مخصص لأجهزة الآيفون لإدارة متجرك بكفاءة وسهولة.'
                              : 'Exclusive iOS app to monitor and run your store on the go.',
                          buttonText: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'تحميل أو فتح التطبيق'
                              : 'Open or Download App',
                          color: Colors.grey,
                          onTap: () => _launchAppOrStore(
                            context: context,
                            appUrlScheme: appScheme,
                            packageName: '',
                            fallbackUrl: iosUrl,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: textRegular.copyWith(
              fontSize: 11,
              color: theme.hintColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: theme.primaryColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonText,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
