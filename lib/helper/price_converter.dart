import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:provider/provider.dart';
import 'package:syriapharmacy/features/splash/domain/models/config_model.dart';
import 'package:syriapharmacy/features/storefront/controllers/storefront_controller.dart';
import 'package:syriapharmacy/features/storefront/domain/models/storefront_country.dart';
import 'package:syriapharmacy/features/storefront/storefront_config.dart';
import 'package:syriapharmacy/features/storefront/storefront_money.dart';

class PriceConverter {
  /// The storefront the customer is on when it trades in its own currency (GCC-05, J-05); null while storefronts are off and on the default
  /// storefront, which keep the platform's money (and the currency the customer chose in the settings).
  static StorefrontCountry? _storefrontOfOwnCurrency(BuildContext context) {
    if (!StorefrontConfig.enabled) {
      return null;
    }

    final StorefrontCountry storefront =
        Provider.of<StorefrontController>(context, listen: false).current;

    return StorefrontMoney.writesPricesOf(storefront, enabled: true)
        ? storefront
        : null;
  }

  /// The mark of [currencyCode] in the server's currency list, or null when the server sent none.
  static String? _symbolOf(ConfigModel? configModel, String currencyCode) {
    for (final CurrencyList currency
        in configModel?.currencyList ?? const <CurrencyList>[]) {
      if (currency.code == currencyCode) {
        return currency.symbol;
      }
    }

    return null;
  }

  /// The currency code of the storefront the customer is on when that storefront trades in its own currency, else null: the code the
  /// customer chose in the settings applies (`SplashController.myCurrency`), as it always has.
  static String? ownCurrencyCode(BuildContext context) =>
      _storefrontOfOwnCurrency(context)?.currency;

  /// The mark of that currency (the symbol of the server's list, the code when the server sent none), else null.
  static String? ownCurrencySymbol(BuildContext context) {
    final StorefrontCountry? storefront = _storefrontOfOwnCurrency(context);
    if (storefront == null) {
      return null;
    }

    final String? symbol = _symbolOf(
        Provider.of<SplashController>(context, listen: false).configModel,
        storefront.currency);

    return symbol == null || symbol.trim().isEmpty
        ? storefront.currency
        : symbol;
  }

  /// The currency code to send with an order, a payment or an analytics event: the storefront's own currency when it has one, else the
  /// currency the customer chose in the settings (which may be null before the config arrives).
  static String? currencyCodeToSend(BuildContext context) =>
      ownCurrencyCode(context) ??
      Provider.of<SplashController>(context, listen: false).myCurrency?.code;

  /// The mark to write beside an amount the customer types or reads outside the price helpers: the storefront's own, else the one of
  /// the currency chosen in the settings (null before the config arrives).
  static String? currencySymbolToShow(BuildContext context) =>
      ownCurrencySymbol(context) ??
      Provider.of<SplashController>(context, listen: false).myCurrency?.symbol;

  /// The price written in the currency of the storefront the customer is on, when that storefront trades in its own currency
  /// (GCC-05, J-05); null while storefronts are off and on the default storefront, which keep the platform's money below.
  static String? _priceOfOwnCurrency(BuildContext context, double? price,
      {bool withSymbol = true}) {
    final StorefrontCountry? storefront = _storefrontOfOwnCurrency(context);
    if (storefront == null) {
      return null;
    }

    if (!withSymbol) {
      return StorefrontMoney.formatWithoutSymbol(price,
          currencyCode: storefront.currency);
    }

    final ConfigModel? configModel =
        Provider.of<SplashController>(context, listen: false).configModel;

    return StorefrontMoney.format(price,
        currencyCode: storefront.currency,
        symbol: _symbolOf(configModel, storefront.currency),
        symbolOnRight: configModel?.currencySymbolPosition == 'right');
  }

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
    final String? ownCurrencyPrice = _priceOfOwnCurrency(context, price);
    if (ownCurrencyPrice != null) {
      return ownCurrencyPrice;
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
    final String? ownCurrencyPrice = _priceOfOwnCurrency(context, price);
    if (ownCurrencyPrice != null) {
      return ownCurrencyPrice;
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
    final String? ownCurrencyPrice =
        _priceOfOwnCurrency(context, price, withSymbol: false);
    if (ownCurrencyPrice != null) {
      return ownCurrencyPrice;
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
