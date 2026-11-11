import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/dynamic_theme/widgets/theme_view_all.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/theme/custom_theme_colors.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class TitleRowWidget extends StatelessWidget {
  final String? title;
  final Function? icon;
  final Function? onTap;
  final Duration? eventDuration;
  final bool? isDetailsPage;
  final bool isFlash;
  final Color? titleColor;
  final bool isBackExist;
  const TitleRowWidget(
      {super.key,
      required this.title,
      this.icon,
      this.onTap,
      this.eventDuration,
      this.isDetailsPage,
      this.isFlash = false,
      this.titleColor,
      this.isBackExist = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The approved section header: a heavy baseline title with a plain
          // violet «الكل ←» link — no chip, no circle.
          Expanded(
            child: Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tajawalBlack.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
                color:
                    titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          if (onTap != null)
            InkWell(
              onTap: onTap as VoidCallback?,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getTranslated('VIEW_ALL', context) ?? 'See All',
                      style: textBold.copyWith(
                        color: BrandColors.primary,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      // "Onwards" is leftwards in Arabic. A fixed arrow points
                      // back on every rail of an RTL storefront.
                      forwardChevron(context),
                      color: BrandColors.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TimerBox extends StatelessWidget {
  final int? time;
  final bool isBorder;
  final String? day;
  final bool? isDetailsPage;

  const TimerBox(
      {super.key,
      required this.time,
      this.isBorder = false,
      this.day,
      this.isDetailsPage = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        border: isBorder
            ? Border.all(
                width: 2, color: Theme.of(context).textTheme.bodyMedium!.color!)
            : null,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isDetailsPage != null &&
                        Provider.of<ThemeController>(context, listen: false)
                            .darkTheme)
                    ? Theme.of(context).primaryColor.withValues(alpha: .12)
                    : (isDetailsPage != null &&
                            !Provider.of<ThemeController>(context,
                                    listen: false)
                                .darkTheme)
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                time! < 10 ? '0$time' : time.toString(),
                style: textBold.copyWith(
                  color: (isDetailsPage ?? false)
                      ? Colors.white
                      : isBorder
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeExtraSmall,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: Text(day!,
                  style: textBold.copyWith(
                    color: isDetailsPage != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : isBorder
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Colors.white.withValues(alpha: .5),
                    fontSize: Dimensions.fontSizeExtraSmall,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashDealBar extends StatelessWidget {
  final String title;
  final Duration? eventDuration;
  final VoidCallback? onTap;
  final bool? isDetailsPage;
  final bool isBackExist;

  /// True when the bar sits inside a section that already paints the flash
  /// gradient behind it — the bar goes transparent instead of doubling it.
  final bool embedded;

  const FlashDealBar({
    super.key,
    required this.title,
    this.eventDuration,
    this.onTap,
    this.isDetailsPage,
    this.isBackExist = false,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    int? days, hours, minutes, seconds;
    if (eventDuration != null) {
      days = eventDuration!.inDays;
      hours = eventDuration!.inHours % 24;
      minutes = eventDuration!.inMinutes % 60;
      seconds = eventDuration!.inSeconds % 60;
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: isBackExist
            ? Dimensions.paddingSizeExtraSmall
            : Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      // The approved flash strip: blue → magenta gradient with dark countdown chips.
      decoration: embedded
          ? null
          : const BoxDecoration(
              borderRadius:
                  BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall)),
              gradient: BrandGradients.flash,
            ),
      child: Row(
        children: [
          if (isBackExist)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚡ $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tajawalBlack.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (eventDuration != null) ...[
            if ((days ?? 0) > 0) ...[
              _FigmaTimerBox(time: days ?? 0),
              const SizedBox(width: 4),
            ],
            _FigmaTimerBox(time: hours ?? 0),
            const SizedBox(width: 4),
            _FigmaTimerBox(time: minutes ?? 0),
            const SizedBox(width: 4),
            _FigmaTimerBox(time: seconds ?? 0),
          ] else ...[
            const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: Dimensions.paddingSizeExtraSmall),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    getTranslated('all_offers', context) ?? '',
                    style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: Colors.white),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FigmaTimerBox extends StatelessWidget {
  final int time;
  const _FigmaTimerBox({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandColors.ink.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time < 10 ? '0$time' : time.toString(),
        style: textBold.copyWith(
          color: Colors.white,
          fontSize: Dimensions.fontSizeDefault,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
