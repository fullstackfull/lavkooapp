import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/custom_image_widget.dart';
import 'package:syriapharmacy/features/splash/domain/models/business_pages_model.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syriapharmacy/features/more/widgets/html_policy_widget.dart';
import 'package:syriapharmacy/features/more/widgets/html_about_us_widget.dart';

class HtmlViewScreen extends StatelessWidget {
  final BusinessPageModel? page;
  const HtmlViewScreen({super.key, required this.page});
  @override
  Widget build(BuildContext context) {
    final isAboutUs = page?.slug == 'about-us';
    final useNewDesign = page != null;

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    Theme.of(context).primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              if (!useNewDesign) CustomAppBar(title: page?.title ?? ''),
              Expanded(
                child: SingleChildScrollView(
                  padding: useNewDesign
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (useNewDesign) ...[
                        // Custom App Bar for New Screens
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 18,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    page?.title ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isAboutUs)
                          HtmlAboutUsWidget(
                            htmlString: page?.description ?? '',
                            title: page?.title ?? '',
                          )
                        else
                          HtmlPolicyWidget(
                            htmlString: page?.description ?? '',
                            title: page?.title ?? '',
                          ),
                      ] else ...[
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSmall),
                          child: SizedBox(
                            height: 70,
                            width: double.infinity,
                            child: CustomImageWidget(
                              fit: BoxFit.cover,
                              image: page?.bannerFullUrl?.path ?? "",
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        HtmlWidget(
                          page?.description ?? '',
                          onTapUrl: (String url) {
                            return launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          },
                          textStyle: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
