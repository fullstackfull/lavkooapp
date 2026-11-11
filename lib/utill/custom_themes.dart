import 'package:flutter/material.dart';
import 'package:syriapharmacy/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

const titilliumRegular = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontWeight: FontWeight.w400,
  fontSize: 12,
);
const titleRegular = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontWeight: FontWeight.w500,
  fontSize: 14,
);
const titleHeader = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontWeight: FontWeight.w600,
  fontSize: 16,
);
const titilliumSemiBold = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

const titilliumBold = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontSize: 14,
  fontWeight: FontWeight.w700,
);
const titilliumItalic = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontSize: 14,
  fontWeight: FontWeight.w400,
  fontStyle: FontStyle.italic,
);

const textRegular = TextStyle(
  fontFamily: 'IBM_Plex_Sans_Arabic',
  fontWeight: FontWeight.w400,
  fontSize: 14,
);

const textMedium = TextStyle(
    fontFamily: 'IBM_Plex_Sans_Arabic',
    fontSize: 14,
    fontWeight: FontWeight.w500);
const textBold = TextStyle(
    fontFamily: 'IBM_Plex_Sans_Arabic',
    fontSize: 14,
    fontWeight: FontWeight.w600);

// Direction B: Tajawal carries prices, CTAs and headlines; IBM Plex stays the body voice.
const robotoBold = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 14,
  fontWeight: FontWeight.w700,
);

const tajawalHeavy = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 16,
  fontWeight: FontWeight.w800,
);

const tajawalBlack = TextStyle(
  fontFamily: 'Tajawal',
  fontSize: 16,
  fontWeight: FontWeight.w900,
);

class ThemeShadow {
  static List<BoxShadow> getShadow(BuildContext context) {
    List<BoxShadow> boxShadow = [
      BoxShadow(
          color: Provider.of<ThemeController>(context, listen: false).darkTheme
              ? Colors.black26
              : Theme.of(context).primaryColor.withValues(alpha: .075),
          blurRadius: 5,
          spreadRadius: 1,
          offset: const Offset(1, 1))
    ];
    return boxShadow;
  }
}
