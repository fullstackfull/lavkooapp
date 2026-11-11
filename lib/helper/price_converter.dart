import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:provider/provider.dart';

class PriceConverter {
  // static String convertPrice(BuildContext context, double? price,
  //     {double? discount, String? discountType}) {
  //   if (discount != null && discountType != null) {
  //     if (discountType == 'amount' || discountType == 'flat') {
  //       price = price! - discount;
  //     } else if (discountType == 'percent' || discountType == 'percentage') {
  //       price = price! - ((discount / 100) * price);
  //     }
  //   }
  //   final splashController =
  //       Provider.of<SplashController>(context, listen: false);
  //   final isNewMode = false; // splashController.isNewPricingMode; (Temporarily disabled)
  //   if (isNewMode && price != null) {
  //     if (price > 100.0) {
  //       price = (price / 100.0).truncateToDouble();
  //     }
  //   }
  //
  //   final configModel = splashController.configModel;
  //   if (configModel == null ||
  //       splashController.myCurrency == null ||
  //       splashController.usdCurrency == null) {
  //     return price?.toStringAsFixed(1) ?? '0.0';
  //   }
  //   bool singleCurrency = false; // configModel.currencyModel == 'single_currency';
  //   bool inRight = configModel.currencySymbolPosition == 'right';
  //
  //   try {
  //     return '${inRight ? '' : splashController.myCurrency!.symbol}'
  //         '${(singleCurrency ? price : price! * splashController.myCurrency!.exchangeRate! * (1 / splashController.usdCurrency!.exchangeRate!))!.toStringAsFixed(configModel.decimalPointSettings ?? 1).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
  //         '${inRight ? splashController.myCurrency!.symbol : ''}';
  //   } catch (e) {
  //     return price.toString();
  //   }
  // }
  static String convertPrice(BuildContext context, double? price,
      {double? discount, String? discountType}) {
    if (discount != null && discountType != null) {
      if (discountType == 'amount' || discountType == 'flat') {
        price = price! - discount;
      } else if (discountType == 'percent' || discountType == 'percentage') {
        price = price! - ((discount / 100) * price);
      }
    }
    final splashController =
    Provider.of<SplashController>(context, listen: false);
    final isNewMode = false; // splashController.isNewPricingMode; (Temporarily disabled)
    if (isNewMode && price != null) {
      if (price > 100.0) {
        price = (price / 100.0).truncateToDouble();
      }
    }

    final configModel = splashController.configModel;
    if (configModel == null ||
        splashController.myCurrency == null ||
        splashController.usdCurrency == null) {
      return price?.toStringAsFixed(0) ?? '0';
    }
    bool singleCurrency = false; // configModel.currencyModel == 'single_currency';
    bool inRight = configModel.currencySymbolPosition == 'right';

    try {
      final double finalPrice = singleCurrency
          ? price!
          : price! *
          splashController.myCurrency!.exchangeRate! *
          (1 / splashController.usdCurrency!.exchangeRate!);

      final String formattedPrice = finalPrice
          .toStringAsFixed(0)
          .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

      return '${inRight ? '' : splashController.myCurrency!.symbol}'
          '$formattedPrice'
          '${inRight ? splashController.myCurrency!.symbol : ''}';
    } catch (e) {
      return price.toString();
    }
  }
  static double? convertWithDiscount(BuildContext context, double? price,
      double? discount, String? discountType) {
    if (discountType == 'amount' || discountType == 'flat') {
      price = price! - discount!;
    } else if (discountType == 'percent' || discountType == 'percentage') {
      price = price! - ((discount! / 100) * price);
    }
    return price;
  }

  static double calculation(
      double amount, double discount, String type, int quantity) {
    double calculatedAmount = 0;
    if (type == 'amount' || type == 'flat') {
      calculatedAmount = discount * quantity;
    } else if (type == 'percent' || type == 'percentage') {
      calculatedAmount = (discount / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(BuildContext context, double? price,
      double? discount, String? discountType) {
    final configModel =
        Provider.of<SplashController>(context, listen: false).configModel;
    if (configModel == null) {
      return '-${discount?.toStringAsFixed(1) ?? '0.0'} %';
    }
    return '-${(discountType == 'percent' || discountType == 'percentage') ? '${discount?.toStringAsFixed(configModel.decimalPointSettings ?? 1)} %' : convertPrice(context, discount)}';
  }

  static String getUnitCurrency(BuildContext context, double? price) {
    final splashController =
        Provider.of<SplashController>(context, listen: false);
    final isNewMode = false; // splashController.isNewPricingMode; (Temporarily disabled)
    if (isNewMode && price != null) {
      if (price > 100.0) {
        price = (price / 100.0).truncateToDouble();
      }
    }

    final configModel = splashController.configModel;
    if (configModel == null || splashController.myCurrency == null) {
      return price?.toStringAsFixed(1) ?? '0.0';
    }
    bool singleCurrency = false; // configModel.currencyModel == 'single_currency';
    bool inRight = configModel.currencySymbolPosition == 'right';

    return '${inRight ? '' : splashController.myCurrency!.symbol}'
        '${(singleCurrency ? price : price!)!.toStringAsFixed(configModel.decimalPointSettings ?? 1).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
        '${inRight ? splashController.myCurrency!.symbol : ''}';
  }

  static String convertPriceWithoutSymbol(BuildContext context, double? price,
      {double? discount, String? discountType}) {
    if (discount != null && discountType != null) {
      if (discountType == 'amount' || discountType == 'flat') {
        price = price! - discount;
      } else if (discountType == 'percent' || discountType == 'percentage') {
        price = price! - ((discount / 100) * price);
      }
    }
    final splashProvider =
        Provider.of<SplashController>(context, listen: false);
    final isNewMode = false; // splashProvider.isNewPricingMode; (Temporarily disabled)
    if (isNewMode && price != null) {
      if (price > 100.0) {
        price = (price / 100.0).truncateToDouble();
      }
    }

    final configModel = splashProvider.configModel;
    if (configModel == null ||
        splashProvider.myCurrency == null ||
        splashProvider.usdCurrency == null) {
      return price?.toStringAsFixed(1) ?? '0.0';
    }
    bool singleCurrency = false; // configModel.currencyModel == 'single_currency';

    return (singleCurrency
            ? price
            : price! *
                splashProvider.myCurrency!.exchangeRate! *
                (1 / splashProvider.usdCurrency!.exchangeRate!))!
        .toStringAsFixed(configModel.decimalPointSettings ?? 1);
  }

  static String longToShortPrice(double amount,
      {bool withDecimalPoint = true}) {
    int decimalPoint = withDecimalPoint ? 2 : 0;

    if (amount.abs() >= 1e12) {
      return '${(amount / 1e12).toStringAsFixed(decimalPoint)}T';
    } else if (amount.abs() >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(decimalPoint)}B';
    } else if (amount.abs() >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(decimalPoint)}M';
    } else if (amount.abs() >= 1e3) {
      return '${(amount / 1e3).toStringAsFixed(decimalPoint)}K';
    } else {
      return amount.toStringAsFixed(decimalPoint);
    }
  }
}
