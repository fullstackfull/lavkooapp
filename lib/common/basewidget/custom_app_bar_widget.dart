import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool isBackButtonExist;
  final bool showActionButton;
  final Function()? onBackPressed;
  final bool centerTitle;
  final double? fontSize;
  final bool showResetIcon;
  final Widget? reset;
  final bool showLogo;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.isBackButtonExist = true,
    this.onBackPressed,
    this.centerTitle = true,
    this.showActionButton = true,
    this.fontSize,
    this.showResetIcon = false,
    this.reset,
    this.showLogo = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0),
      child: AppBar(
        actions: showResetIcon ? [reset!] : [],
        backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
        toolbarHeight: 56,
        iconTheme: IconThemeData(
            color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color),
        automaticallyImplyLeading: false,
        title: Text(
          title ?? '',
          style: textBold.copyWith(
            fontSize: fontSize ?? Dimensions.fontSizeExtraLarge,
            color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: centerTitle,
        excludeHeaderSemantics: true,
        titleSpacing: isBackButtonExist ? 0 : Dimensions.paddingSizeDefault,
        elevation: 0,
        clipBehavior: Clip.none,
        shadowColor: Theme.of(context).primaryColor.withValues(alpha: .05),
        leadingWidth: isBackButtonExist ? 56 : 120,
        leading: isBackButtonExist
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor != null
                      ? Colors.white.withValues(alpha: 0.15)
                      : Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: textColor ??
                        Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => onBackPressed != null
                      ? onBackPressed!()
                      : Navigator.pop(context),
                ),
              )
            : (showLogo)
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: Dimensions.paddingSizeDefault),
                    child:
                        SizedBox(child: Image.asset(Images.logoWithNameImage)),
                  )
                : Builder(
                    builder: (context) {
                      final drawer = ZoomDrawer.of(context);
                      if (drawer != null) {
                        return IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          onPressed: () => drawer.toggle(),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
      ),
    );
  }

  @override
  Size get preferredSize => Size(MediaQuery.of(Get.context!).size.width, 50);
}
