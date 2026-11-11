import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/dynamic_theme/controllers/dynamic_theme_controller.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer_registry.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/features/dynamic_theme/screens/dynamic_home_view.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// A page the merchant composed, on a screen of its own.
///
/// The builder could make an Offers page, the API could serve it, and the app could not open it:
/// it fetched `home` and `header` and nothing else, so every page a merchant made after those was
/// a page nobody could reach. This is the screen that reaches them — one screen for all of them,
/// because a composed page is a list of sections and the renderers already know how to draw those.
///
/// It owns a Scaffold because it IS a screen, unlike the home content which is embedded inside the
/// app's own home. Everything below the app bar is the merchant's.
class ExperiencePageScreen extends StatefulWidget {
  const ExperiencePageScreen({super.key, required this.slug, this.title});

  /// The page's address, which is what both clients ask for.
  final String slug;

  /// What to put in the app bar until the page says otherwise.
  final String? title;

  @override
  State<ExperiencePageScreen> createState() => _ExperiencePageScreenState();
}

class _ExperiencePageScreenState extends State<ExperiencePageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DynamicThemeController>().loadPage(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicThemeController>(
      builder: (context, controller, _) {
        final payload = controller.page(widget.slug);

        // A language switch (or any purge) can empty the held page while this screen is open;
        // with nothing in flight and no recorded failure, ask again — loadPage dedupes, so an
        // extra call is free.
        if (payload == null &&
            !controller.isPageLoading(widget.slug) &&
            !controller.pageFailed(widget.slug)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<DynamicThemeController>().loadPage(widget.slug);
          });
        }
        final registry = context.read<SectionRendererRegistry>();

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? _titleFrom(widget.slug)),
            elevation: 0,
          ),
          body: _body(context, controller, payload, registry),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    DynamicThemeController controller,
    payload,
    SectionRendererRegistry registry,
  ) {
    if (payload == null) {
      // Failed is not "still arriving": a spinner over a dead request spins forever and tells
      // the shopper nothing. Say it did not load, and offer the retry.
      if (controller.pageFailed(widget.slug) && !controller.isPageLoading(widget.slug)) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getTranslated('this_page_could_not_be_loaded', context) ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                OutlinedButton(
                  onPressed: () => controller.retryPage(widget.slug),
                  child: Text(getTranslated('try_again', context) ?? ''),
                ),
              ],
            ),
          ),
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    if (payload.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
          child: Text(
            getTranslated('this_page_has_no_content_yet', context) ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ThemeStyle(
      tokens: payload.tokens,
      fallback: Theme.of(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in payload.sections)
              SectionBoundary(
                key: ValueKey(section.uuid),
                section: section,
                registry: registry,
              ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
      ),
    );
  }

  /// A readable name from a slug, for the moment before the page has told us its own.
  String _titleFrom(String slug) =>
      slug.replaceAll('-', ' ').replaceAll('_', ' ');
}
