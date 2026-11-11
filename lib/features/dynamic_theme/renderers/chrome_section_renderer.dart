import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/section_renderer.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_action_resolver.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';
import 'package:syriapharmacy/utill/dimensions.dart';

/// The announcement bar: a thin message strip the merchant can put above everything.
///
/// Not wrapped in the section shell, deliberately. The shell exists to give content sections
/// consistent padding and a heading; a bar that adopted either would stop being a bar.
class AnnouncementSectionRenderer extends SectionRenderer {
  const AnnouncementSectionRenderer();

  static const ThemeActionResolver _actions = ThemeActionResolver();

  @override
  List<String> get types => const ['announcement_bar'];

  @override
  bool canRender(ThemeSectionSchema section) =>
      section.settings.string('text') != null;

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) {
    final style = ThemeStyle.of(context);
    final settings = section.settings;
    final action = settings.action;

    final bar = Container(
      width: double.infinity,
      color: style.color(settings.string('background')) ?? style.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeEight,
      ),
      child: Text(
        settings.string('text')!,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: style.color(settings.string('text_color')) ?? Colors.white,
          fontSize: Dimensions.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (!_actions.isNavigable(action)) return bar;

    return InkWell(onTap: () => _actions.go(context, action), child: bar);
  }
}

/// Deliberate empty space between two sections.
///
/// The smallest possible renderer, and worth having: without it a merchant who wants breathing
/// room has to fake it by padding a neighbouring section, which then behaves differently the next
/// time that section is moved.
class SpacerSectionRenderer extends SectionRenderer {
  const SpacerSectionRenderer();

  @override
  List<String> get types => const ['spacer'];

  @override
  Widget? build(BuildContext context, ThemeSectionSchema section) {
    final height = section.settings.integer('height', 24).clamp(0, 200).toDouble();
    if (height == 0) return null;

    return Container(
      height: height,
      color: ThemeStyle.of(context).color(section.settings.string('background')),
    );
  }
}
