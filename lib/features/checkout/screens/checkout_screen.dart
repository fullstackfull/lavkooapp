import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/cart/domain/models/cart_model.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/checkout/widgets/checkout_condition_checkbox.dart';
import 'package:syriapharmacy/features/checkout/widgets/order_place_bottomsheet_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:syriapharmacy/features/profile/controllers/profile_contrroller.dart';
import 'package:syriapharmacy/features/shipping/controllers/shipping_controller.dart';
import 'package:syriapharmacy/helper/cart_healper.dart';
import 'package:syriapharmacy/helper/debounce_helper.dart';
import 'package:syriapharmacy/helper/price_converter.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/main.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/cart/controllers/cart_controller.dart';
import 'package:syriapharmacy/features/coupon/controllers/coupon_controller.dart';
import 'package:syriapharmacy/features/splash/controllers/splash_controller.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/common/basewidget/amount_widget.dart';
import 'package:syriapharmacy/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_button_widget.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/common/basewidget/custom_textfield_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/choose_payment_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/coupon_apply_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/shipping_details_widget.dart';
import 'package:syriapharmacy/features/checkout/widgets/wallet_payment_widget.dart';
import 'package:provider/provider.dart';

import '../../../services/meta_tracking_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartModel> cartList;
  final bool fromProductDetails;
  final double totalOrderAmount;
  final double shippingFee;
  final double discount;
  final double tax;
  final int? sellerId;
  final bool onlyDigital;
  final bool hasPhysical;
  final int quantity;

  const CheckoutScreen(
      {super.key,
        required this.cartList,
        this.fromProductDetails = false,
        required this.discount,
        required this.tax,
        required this.totalOrderAmount,
        required this.shippingFee,
        this.sellerId,
        this.onlyDigital = false,
        required this.quantity,
        required this.hasPhysical});

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
  GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();

  final FocusNode _orderNoteNode = FocusNode();
  double _order = 0;
  double _tax = 0;
  late bool _billingAddress;
  double? _couponDiscount;
  double? _referralDiscount;

  DebounceHelper debounceHelper = DebounceHelper(milliseconds: 500);
  SplashController splashController =
  Provider.of<SplashController>(Get.context!, listen: false);

  @override
  void initState() {
    super.initState();
    Provider.of<AddressController>(context, listen: false).getAddressList();
    Provider.of<CheckoutController>(context, listen: false)
        .getReferralAmount('0');
    Provider.of<CouponController>(context, listen: false)
        .removePrevCouponData();
    Provider.of<CartController>(context, listen: false).getCartData(context);
    Provider.of<CheckoutController>(context, listen: false)
        .resetPaymentMethod();
    // The payment list comes from the admin panel and the app caches the config, so it is re-read here.
    // Without this, a gateway switched off in the admin panel keeps appearing on the payment sheet
    // until the cache happens to expire, and the customer picks a method the server will refuse.
    splashController.refreshPaymentMethods();
    Provider.of<ShippingController>(context, listen: false)
        .getChosenShippingMethod(context);
    if (splashController.configModel != null &&
        splashController.configModel!.offlinePayment != null) {
      Provider.of<CheckoutController>(context, listen: false)
          .getOfflinePaymentList();
    }

    if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<CouponController>(context, listen: false)
          .getAvailableCouponList();
    }

    if (Provider.of<CheckoutController>(context, listen: false).isAcceptTerms) {
      Provider.of<CheckoutController>(context, listen: false)
          .toggleTermsCheck(isUpdate: false);
    }

    _billingAddress = Provider.of<SplashController>(Get.context!, listen: false)
        .configModel!
        .billingInputByCustomer ==
        1;
    Provider.of<CheckoutController>(context, listen: false).clearData();

    if (splashController.configModel?.systemTaxIncludeStatus != 1) {
      _tax = widget.tax;
    }
  }

  @override
  Widget build(BuildContext context) {
    _order = widget.totalOrderAmount + widget.discount;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      bottomNavigationBar:
      Consumer<AddressController>(builder: (context, locationProvider, _) {
        return Consumer<CheckoutController>(
            builder: (context, orderProvider, child) {
              return Consumer<CouponController>(
                  builder: (context, couponProvider, _) {
                    if (splashController.configModel?.systemTaxIncludeStatus != 1) {
                      _tax = CartHelper().calculateVatTax(
                          Provider.of<CartController>(context, listen: false).cartList);
                    }
                    return Consumer<CartController>(
                        builder: (context, cartProvider, _) {
                          return Consumer<ProfileController>(
                              builder: (context, profileProvider, _) {
                                return orderProvider.isLoading
                                    ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator())
                                    ])
                                    : Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    Dimensions.paddingSizeDefault,
                                    Dimensions.paddingSizeDefault,
                                    Dimensions.paddingSizeDefault,
                                    Dimensions.paddingSizeLarge,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, -5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CheckoutConditionCheckBox(),
                                      const SizedBox(height: Dimensions.paddingSizeSmall),
                                      //// الزر تبع المتابعة بالحجز ====================
                                      CustomButton(
                                        onTap: (orderProvider.isLoading ||
                                            !orderProvider.isAcceptTerms)
                                            ? null
                                            : () async {
                                          if (orderProvider.addressIndex == null &&
                                              widget.hasPhysical) {
                                            RouterHelper.getSavedAddressListRoute(
                                                fromGuest:
                                                !Provider.of<AuthController>(
                                                    context,
                                                    listen: false)
                                                    .isLoggedIn());
                                            showCustomSnackBarWidget(
                                                getTranslated(
                                                    'select_a_shipping_address',
                                                    context),
                                                Get.context!,
                                                snackBarType: SnackBarType.warning);
                                          } else if ((orderProvider
                                              .billingAddressIndex ==
                                              null &&
                                              !widget.hasPhysical &&
                                              !_billingAddress)) {
                                            showCustomSnackBarWidget(
                                                getTranslated(
                                                    'you_cant_place_order_of_digital_product_without_billing_address',
                                                    context),
                                                Get.context!,
                                                snackBarType: SnackBarType.warning);
                                          } else if ((orderProvider
                                              .billingAddressIndex ==
                                              null &&
                                              !widget.hasPhysical &&
                                              !orderProvider.sameAsBilling &&
                                              _billingAddress) ||
                                              (orderProvider.billingAddressIndex ==
                                                  null &&
                                                  _billingAddress &&
                                                  !orderProvider.sameAsBilling)) {
                                            RouterHelper
                                                .getSavedBillingAddressListRoute(
                                                fromGuest: !Provider.of<
                                                    AuthController>(
                                                    context,
                                                    listen: false)
                                                    .isLoggedIn());
                                            showCustomSnackBarWidget(
                                                getTranslated(
                                                    'select_a_billing_address',
                                                    context),
                                                Get.context!,
                                                snackBarType: SnackBarType.warning);
                                          } else {
                                            if (!orderProvider
                                                .isCheckCreateAccount ||
                                                (orderProvider
                                                    .isCheckCreateAccount &&
                                                    (passwordFormKey.currentState
                                                        ?.validate() ??
                                                        false))) {
                                              String orderNote = orderProvider
                                                  .orderNoteController.text
                                                  .trim();
                                              String couponCode =
                                              couponProvider.discount != null &&
                                                  couponProvider.discount !=
                                                      0
                                                  ? couponProvider.couponCode
                                                  : '';
                                              String couponCodeAmount =
                                              couponProvider.discount != null &&
                                                  couponProvider.discount !=
                                                      0
                                                  ? couponProvider.discount
                                                  .toString()
                                                  : '0';

                                              String addressId =
                                              orderProvider.addressIndex != null
                                                  ? locationProvider
                                                  .addressList![
                                              orderProvider
                                                  .addressIndex!]
                                                  .id
                                                  .toString()
                                                  : '';

                                              String billingAddressId =
                                              (_billingAddress)
                                                  ? !orderProvider.sameAsBilling
                                                  ? locationProvider
                                                  .addressList![
                                              orderProvider
                                                  .billingAddressIndex!]
                                                  .id
                                                  .toString()
                                                  : locationProvider
                                                  .addressList![
                                              orderProvider
                                                  .addressIndex!]
                                                  .id
                                                  .toString()
                                                  : '';

                                              if (orderProvider
                                                  .paymentMethodIndex !=
                                                  -1) {
                                                orderProvider.digitalPaymentPlaceOrder(
                                                    orderNote: orderNote,
                                                    customerId: Provider.of<
                                                        AuthController>(
                                                        context,
                                                        listen: false)
                                                        .isLoggedIn()
                                                        ? profileProvider
                                                        .userInfoModel?.id
                                                        .toString()
                                                        : Provider.of<
                                                        AuthController>(
                                                        context,
                                                        listen: false)
                                                        .getGuestToken(),
                                                    addressId: addressId,
                                                    billingAddressId:
                                                    billingAddressId,
                                                    couponCode: couponCode,
                                                    couponDiscount:
                                                    couponCodeAmount,
                                                    paymentMethod: orderProvider
                                                        .selectedDigitalPaymentMethodName);
                                              } else if (orderProvider
                                                  .isCODChecked &&
                                                  !widget.onlyDigital) {
                                                orderProvider.placeOrder(
                                                    callback: _callback,
                                                    addressID: addressId,
                                                    couponCode: couponCode,
                                                    couponAmount: couponCodeAmount,
                                                    billingAddressId:
                                                    billingAddressId,
                                                    orderNote: orderNote);
                                              } else if (orderProvider
                                                  .isOfflineChecked) {
                                                // Navigator.of(context).push(MaterialPageRoute(builder: (_)=> OfflinePaymentScreen(payableAmount: _order + widget.shippingFee - widget.discount - (_referralDiscount ?? 0) - _couponDiscount! + _tax, callback: _callback)));
                                                RouterHelper
                                                    .getOfflinePaymentScreen(
                                                    payableAmount: (_order +
                                                        widget.shippingFee -
                                                        widget.discount -
                                                        (_referralDiscount ??
                                                            0) -
                                                        _couponDiscount! +
                                                        _tax),
                                                    callback: _callback);
                                              } else if (orderProvider
                                                  .isWalletChecked) {
                                                showAnimatedDialog(
                                                    context,
                                                    WalletPaymentWidget(
                                                        currentBalance:
                                                        profileProvider
                                                            .balance ??
                                                            0,
                                                        orderAmount: _order +
                                                            widget.shippingFee -
                                                            widget.discount -
                                                            (_referralDiscount ??
                                                                0) -
                                                            _couponDiscount! +
                                                            _tax,
                                                        onTap: () {
                                                          if (profileProvider
                                                              .balance! <
                                                              (_order +
                                                                  widget
                                                                      .shippingFee -
                                                                  widget.discount -
                                                                  (_referralDiscount ??
                                                                      0) -
                                                                  _couponDiscount! +
                                                                  _tax)) {
                                                            showCustomSnackBarWidget(
                                                                getTranslated(
                                                                    'insufficient_balance',
                                                                    context),
                                                                context,
                                                                snackBarType:
                                                                SnackBarType
                                                                    .warning);
                                                          } else {
                                                            Navigator.pop(context);
                                                            orderProvider.placeOrder(
                                                                callback: _callback,
                                                                wallet: true,
                                                                addressID:
                                                                addressId,
                                                                couponCode:
                                                                couponCode,
                                                                couponAmount:
                                                                couponCodeAmount,
                                                                billingAddressId:
                                                                billingAddressId,
                                                                orderNote:
                                                                orderNote);
                                                          }
                                                        }),
                                                    dismissible: false,
                                                    willFlip: true);
                                              } else {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                  Colors.transparent,
                                                  builder: (c) {
                                                    return PaymentMethodBottomSheetWidget(
                                                        onlyDigital:
                                                        widget.onlyDigital);
                                                  },
                                                );
                                              }
                                            }
                                          }
                                        },
                                        buttonText:
                                        '${getTranslated('proceed', context)}',
                                      )
                                    ],
                                  ),
                                );
                              });
                        });
                  });
            });
      }),
      appBar: CustomAppBar(title: getTranslated('checkout', context)),
      body: Consumer<AuthController>(builder: (context, authProvider, _) {
        return Consumer<CheckoutController>(
            builder: (context, orderProvider, _) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(0),
                      children: [
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: Dimensions.paddingSizeDefault),
                          child: ShippingDetailsWidget(
                            hasPhysical: widget.hasPhysical,
                            billingAddress: _billingAddress,
                            passwordFormKey: passwordFormKey,
                          ),
                        ),
                        if (Provider.of<AuthController>(context, listen: false)
                            .isLoggedIn())
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: Dimensions.paddingSizeSmall),
                            child: CouponApplyWidget(
                              couponController: _controller,
                              orderAmount: _order,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child:
                          ChoosePaymentWidget(onlyDigital: widget.onlyDigital),
                        ),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeExtraSmall),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.08),
                                width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.receipt_long_rounded,
                                          color: Theme.of(context).primaryColor,
                                          size: 20),
                                    ),
                                    const SizedBox(
                                        width: Dimensions.paddingSizeSmall),
                                    Text(
                                      getTranslated('order_summary', context) ?? '',
                                      style: textBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault),
                                child: Consumer<CheckoutController>(
                                  builder: (context, checkoutController, child) {
                                    _couponDiscount =
                                        Provider.of<CouponController>(context)
                                            .discount ??
                                            0;
                                    _referralDiscount =
                                        Provider.of<CheckoutController>(context)
                                            .referralAmount
                                            ?.amount ??
                                            0;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        widget.quantity > 1
                                            ? AmountWidget(
                                          title:
                                          '${getTranslated('sub_total', context)} ${' (${widget.quantity} ${getTranslated('items', context)}) '}',
                                          amount: PriceConverter.convertPrice(
                                              context, _order),
                                        )
                                            : AmountWidget(
                                          title:
                                          '${getTranslated('sub_total', context)} ${'(${widget.quantity} ${getTranslated('item', context)})'}',
                                          amount: PriceConverter.convertPrice(
                                              context, _order),
                                        ),
                                        AmountWidget(
                                          title: getTranslated(
                                              'shipping_fee', context),
                                          amount: PriceConverter.convertPrice(
                                              context, widget.shippingFee),
                                        ),
                                        AmountWidget(
                                          title: getTranslated('discount', context),
                                          amount: PriceConverter.convertPrice(
                                              context, widget.discount),
                                        ),
                                        AmountWidget(
                                          title: getTranslated(
                                              'coupon_voucher', context),
                                          amount: PriceConverter.convertPrice(
                                              context, _couponDiscount),
                                        ),
                                        if (splashController.configModel
                                            ?.systemTaxIncludeStatus !=
                                            1)
                                          AmountWidget(
                                            title: getTranslated('tax', context),
                                            amount: PriceConverter.convertPrice(
                                                context, _tax),
                                          ),
                                        if ((_referralDiscount ?? 0) > 0)
                                          AmountWidget(
                                            title: getTranslated(
                                                'referral_discount', context),
                                            amount: PriceConverter.convertPrice(
                                                context, _referralDiscount),
                                          ),
                                        const Divider(
                                            height: Dimensions.paddingSizeDefault,
                                            thickness: 0.5),
                                        Container(
                                          padding: const EdgeInsets.all(
                                              Dimensions.paddingSizeSmall),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.1),
                                                width: 1),
                                          ),
                                          child: AmountWidget(
                                            fontSize: Dimensions.fontSizeLarge,
                                            isTitleBlack: true,
                                            title:
                                            '${getTranslated('total_payable', context)} ${Provider.of<SplashController>(Get.context!, listen: false).configModel?.systemTaxIncludeStatus == 1 ? getTranslated('inc_vat_tax', context) : ''} ',
                                            amount: PriceConverter.convertPrice(
                                              context,
                                              (_order +
                                                  widget.shippingFee -
                                                  (_referralDiscount ?? 0) -
                                                  widget.discount -
                                                  _couponDiscount! +
                                                  _tax),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeExtraSmall),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.08),
                                width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.note_alt_outlined,
                                          color: Theme.of(context).primaryColor,
                                          size: 20),
                                    ),
                                    const SizedBox(
                                        width: Dimensions.paddingSizeSmall),
                                    Text(
                                      '${getTranslated('order_note', context)}',
                                      style: textBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeDefault),
                                child: CustomTextFieldWidget(
                                  hintText: getTranslated('enter_note', context),
                                  inputType: TextInputType.multiline,
                                  inputAction: TextInputAction.done,
                                  maxLines: 3,
                                  focusNode: _orderNoteNode,
                                  controller: orderProvider.orderNoteController,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                      ],
                    ),
                  ),
                ],
              );
            });
      }),
    );
  }

  void _callback(bool isSuccess, String message, String orderID,
      bool createAccount) async {
    if (isSuccess) {
      // ✅ Meta Tracking: Purchase event
      String? orderId = Provider.of<CheckoutController>(context, listen: false)
          .getFirstOrderId(orderID);
      if (orderId != null) {
        MetaTrackingService().logPurchase(
          orderId: orderId,
          amount: widget.totalOrderAmount + widget.shippingFee - widget.discount + widget.tax,
          currency: Provider.of<SplashController>(context, listen: false)
              .myCurrency?.code ?? 'SYP',
          items: widget.cartList.map((cart) => {
            'product_id': cart.productId?.toString(),
            'product_name': cart.name,
            'quantity': cart.quantity,
            'price': cart.price,
          }).toList(),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        bool isLoggedIn =
        Provider.of<AuthController>(context, listen: false).isLoggedIn();

        if (isLoggedIn && orderId != null) {
          RouterHelper.getOrderScreenRoute(
              isBackButtonExist: true,
              action: RouteAction.push,
              fromPlaceOrder: true);
        } else {
          RouterHelper.getDashboardRoute(
              action: RouteAction.pushReplacement, page: 'home');
        }

        Future.delayed(Duration(milliseconds: 300), () {
          showModalBottomSheet(
            isDismissible: false,
            enableDrag: false,
            context: Get.context!,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: OrderPlaceBottomSheetWidget(
                  orderID: orderID,
                  icon: Icons.check,
                  title: getTranslated(
                    createAccount
                        ? 'order_placed_Account_Created'
                        : 'order_placed',
                    Get.context!,
                  ),
                  description: getTranslated('your_order_placed', Get.context!),
                  isFailed: false,
                ),
              );
            },
          );
        });
      });
    } else {
      showCustomSnackBarWidget(message, context,
          snackBarType: SnackBarType.error);
    }
  }
}