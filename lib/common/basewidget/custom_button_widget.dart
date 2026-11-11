import 'package:flutter/material.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CustomButton extends StatefulWidget {
  final Function()? onTap;
  final String? buttonText;
  final bool isBuy;
  final bool isBorder;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? loadingColor;
  final double? radius;
  final double? fontSize;
  final String? leftIcon;
  final double? borderWidth;
  final bool isLoading;
  final double buttonHeight;

  const CustomButton({
    super.key,
    this.onTap,
    required this.buttonText,
    this.isBuy = false,
    this.isBorder = false,
    this.backgroundColor,
    this.radius,
    this.textColor,
    this.fontSize,
    this.leftIcon,
    this.borderColor,
    this.loadingColor = Colors.white,
    this.borderWidth,
    this.isLoading = false,
    this.buttonHeight = 45,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double defaultRadius = widget.radius ??
        (widget.isBorder ? Dimensions.paddingSizeExtraSmall : 30.0);

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null && !widget.isLoading) {
          _controller.reverse();
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null && !widget.isLoading) {
          _controller.forward();
        }
      },
      onTapCancel: () {
        if (widget.onTap != null && !widget.isLoading) {
          _controller.forward();
        }
      },
      child: ScaleTransition(
        scale: _controller,
        child: TextButton(
          onPressed: widget.isLoading ? null : widget.onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
          child: Container(
            height: widget.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: widget.isBorder
                  ? Border.all(
                      color:
                          widget.borderColor ?? Theme.of(context).primaryColor,
                      width: widget.borderWidth ?? 1)
                  : null,
              color: widget.onTap == null
                  ? Theme.of(context).disabledColor
                  : widget.backgroundColor ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: widget.isBuy && widget.onTap != null
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: widget.isLoading
                ? Center(
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              widget.loadingColor!),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(getTranslated('loading', context)!,
                          style: textBold.copyWith(color: widget.loadingColor)),
                    ],
                  ))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.leftIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: SizedBox(
                            width: 30,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeExtraSmall),
                              child: Image.asset(widget.leftIcon!),
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          widget.buttonText ?? "",
                          style: titilliumSemiBold.copyWith(
                            fontSize: widget.fontSize ?? 16,
                            color: widget.textColor ??
                                (Provider.of<ThemeController>(context,
                                            listen: false)
                                        .darkTheme
                                    ? Colors.white
                                    : Theme.of(context).highlightColor),
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
