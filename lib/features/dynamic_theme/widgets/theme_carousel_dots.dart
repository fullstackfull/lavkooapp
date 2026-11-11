import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/engine/theme_style.dart';

/// Where you are in a slideshow, and how much of it is left.
///
/// A carousel with no indicator reads as a single image: shoppers do not swipe what they cannot see
/// more of, so the merchant's second and third slides are never opened. The active dot is a pill
/// rather than a larger circle — the width difference survives a small screen and a colour-blind
/// reader, which a tint alone does not.
class ThemeCarouselDots extends StatelessWidget {
  const ThemeCarouselDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.onImage = false,
  });

  final int count;
  final int activeIndex;

  /// Drawn over a photograph: white pills with a soft shadow instead of theme tints, because a
  /// primary-coloured dot disappears on a primary-coloured banner.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();

    final style = ThemeStyle.of(context);

    return Semantics(
      // The dots are decoration; the slide itself is what a screen reader should read.
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: index == activeIndex ? 18 : 6,
              decoration: BoxDecoration(
                color: onImage
                    ? Colors.white.withValues(alpha: index == activeIndex ? .95 : .55)
                    : index == activeIndex
                        ? style.primary
                        : style.mutedText.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(3),
                boxShadow: onImage
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
