// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:syriapharmacy/common/basewidget/custom_asset_image_widget.dart';
// import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
// import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
// import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
// import 'package:syriapharmacy/features/checkout/widgets/create_account_widget.dart';
// import 'package:syriapharmacy/helper/route_healper.dart';
// import 'package:syriapharmacy/localization/language_constrants.dart';
// import 'package:syriapharmacy/utill/custom_themes.dart';
// import 'package:syriapharmacy/utill/dimensions.dart';
// import 'package:syriapharmacy/utill/images.dart';
// import 'package:provider/provider.dart';
//
// class ShippingDetailsWidget extends StatefulWidget {
//   final bool hasPhysical;
//   final bool billingAddress;
//   final GlobalKey<FormState> passwordFormKey;
//
//   const ShippingDetailsWidget(
//       {super.key,
//       required this.hasPhysical,
//       required this.billingAddress,
//       required this.passwordFormKey});
//
//   @override
//   State<ShippingDetailsWidget> createState() => _ShippingDetailsWidgetState();
// }
//
// class _ShippingDetailsWidgetState extends State<ShippingDetailsWidget> {
//   @override
//   Widget build(BuildContext context) {
//     bool isGuestMode =
//         !Provider.of<AuthController>(context, listen: false).isLoggedIn();
//     return Consumer<CheckoutController>(
//         builder: (context, shippingProvider, _) {
//       if (shippingProvider.sameAsBilling && !widget.hasPhysical) {
//         shippingProvider.setSameAsBilling(isUpdate: false);
//       }
//
//       return Consumer<AddressController>(
//         builder: (context, locationProvider, _) {
//           return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (widget.hasPhysical)
//                   Container(
//                     margin: const EdgeInsets.symmetric(
//                         horizontal: Dimensions.paddingSizeDefault,
//                         vertical: Dimensions.paddingSizeExtraSmall),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                           color: Theme.of(context)
//                               .primaryColor
//                               .withValues(alpha: 0.08),
//                           width: 1.2),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withValues(alpha: 0.03),
//                           blurRadius: 15,
//                           offset: const Offset(0, 5),
//                         )
//                       ],
//                     ),
//                     child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(
//                                 Dimensions.paddingSizeDefault),
//                             child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Expanded(
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           padding: const EdgeInsets.all(8),
//                                           decoration: BoxDecoration(
//                                             color: Theme.of(context)
//                                                 .primaryColor
//                                                 .withValues(alpha: 0.08),
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: CustomAssetImageWidget(
//                                               Images.deliveryTo,
//                                               height: 20,
//                                               width: 20,
//                                               color: Theme.of(context)
//                                                   .primaryColor),
//                                         ),
//                                         const SizedBox(
//                                             width: Dimensions.paddingSizeSmall),
//                                         Text(
//                                           '${getTranslated('delivery_to', context)}',
//                                           style: textBold.copyWith(
//                                             fontSize: Dimensions.fontSizeLarge,
//                                             color: Theme.of(context)
//                                                 .textTheme
//                                                 .bodyLarge
//                                                 ?.color,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   InkWell(
//                                     onTap: () {
//                                       RouterHelper.getSavedAddressListRoute(
//                                           fromGuest: isGuestMode);
//                                     },
//                                     borderRadius: BorderRadius.circular(30),
//                                     child: Container(
//                                       padding: const EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         color: Theme.of(context)
//                                             .primaryColor
//                                             .withValues(alpha: 0.08),
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Image.asset(Images.edit,
//                                           scale: 3,
//                                           color:
//                                               Theme.of(context).primaryColor),
//                                     ),
//                                   ),
//                                 ]),
//                           ),
//                           const Divider(height: 1, thickness: 0.5),
//                           if (shippingProvider.addressIndex != null &&
//                               locationProvider.addressList != null &&
//                               locationProvider.addressList!.isNotEmpty)
//                             Container(
//                               margin: const EdgeInsets.all(
//                                   Dimensions.paddingSizeDefault),
//                               padding: const EdgeInsets.all(
//                                   Dimensions.paddingSizeDefault),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(16),
//                                 color: Theme.of(context)
//                                     .primaryColor
//                                     .withValues(alpha: 0.03),
//                                 border: Border.all(
//                                     color: Theme.of(context)
//                                         .primaryColor
//                                         .withValues(alpha: 0.05),
//                                     width: 1.2),
//                               ),
//                               child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Icon(Icons.person_outline_rounded,
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                             size: 18),
//                                         const SizedBox(
//                                             width: Dimensions
//                                                 .paddingSizeExtraSmall),
//                                         Expanded(
//                                           child: Text(
//                                             locationProvider
//                                                     .addressList![
//                                                         shippingProvider
//                                                             .addressIndex!]
//                                                     .contactPersonName ??
//                                                 '',
//                                             style: textBold.copyWith(
//                                                 fontSize:
//                                                     Dimensions.fontSizeDefault,
//                                                 color: Theme.of(context)
//                                                     .textTheme
//                                                     .bodyLarge
//                                                     ?.color),
//                                             maxLines: 1,
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(
//                                         height: Dimensions.paddingSizeSmall),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.phone_outlined,
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                             size: 18),
//                                         const SizedBox(
//                                             width: Dimensions
//                                                 .paddingSizeExtraSmall),
//                                         Expanded(
//                                           child: Text(
//                                             locationProvider
//                                                     .addressList![
//                                                         shippingProvider
//                                                             .addressIndex!]
//                                                     .phone ??
//                                                 '',
//                                             style: textMedium.copyWith(
//                                                 fontSize:
//                                                     Dimensions.fontSizeDefault,
//                                                 color: Theme.of(context)
//                                                     .textTheme
//                                                     .bodyLarge
//                                                     ?.color),
//                                             maxLines: 1,
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const Divider(
//                                         height: Dimensions.paddingSizeLarge,
//                                         thickness: 0.5),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.location_on_outlined,
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                             size: 18),
//                                         const SizedBox(
//                                             width: Dimensions
//                                                 .paddingSizeExtraSmall),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 8, vertical: 2),
//                                           decoration: BoxDecoration(
//                                             color: Theme.of(context)
//                                                 .primaryColor
//                                                 .withValues(alpha: 0.1),
//                                             borderRadius:
//                                                 BorderRadius.circular(6),
//                                           ),
//                                           child: Text(
//                                             locationProvider
//                                                     .addressList![
//                                                         shippingProvider
//                                                             .addressIndex!]
//                                                     .addressType ??
//                                                 '',
//                                             style: textBold.copyWith(
//                                                 fontSize:
//                                                     Dimensions.fontSizeSmall,
//                                                 color: Theme.of(context)
//                                                     .primaryColor),
//                                           ),
//                                         ),
//                                         const SizedBox(
//                                             width: Dimensions.paddingSizeSmall),
//                                         Expanded(
//                                           child: Text(
//                                             locationProvider
//                                                     .addressList![
//                                                         shippingProvider
//                                                             .addressIndex!]
//                                                     .address ??
//                                                 '',
//                                             style: textRegular.copyWith(
//                                                 fontSize:
//                                                     Dimensions.fontSizeDefault,
//                                                 color: Theme.of(context)
//                                                     .textTheme
//                                                     .bodyLarge
//                                                     ?.color,
//                                                 overflow:
//                                                     TextOverflow.ellipsis),
//                                             maxLines: 2,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ]),
//                             )
//                           else
//                             Padding(
//                               padding: const EdgeInsets.all(
//                                   Dimensions.paddingSizeDefault),
//                               child: InkWell(
//                                 onTap: () {
//                                   RouterHelper.getSavedAddressListRoute(
//                                       fromGuest: isGuestMode);
//                                 },
//                                 borderRadius: BorderRadius.circular(16),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(
//                                       Dimensions.paddingSizeLarge),
//                                   decoration: BoxDecoration(
//                                     color: Theme.of(context)
//                                         .primaryColor
//                                         .withValues(alpha: 0.02),
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(
//                                       color: Theme.of(context)
//                                           .primaryColor
//                                           .withValues(alpha: 0.25),
//                                       width: 1.5,
//                                       style: BorderStyle.solid,
//                                     ),
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.add_circle_outline_rounded,
//                                         color: Theme.of(context).primaryColor,
//                                         size: 24,
//                                       ),
//                                       const SizedBox(
//                                         width: Dimensions.paddingSizeSmall,
//                                       ),
//                                       Flexible(
//                                         child: FittedBox(
//                                           fit: BoxFit.scaleDown,
//                                           child: Text(
//                                             getTranslated(
//                                               'please_set_your_delivery_info',
//                                               context,
//                                             ) ??
//                                                 '',
//                                             style: textBold.copyWith(
//                                               color: Theme.of(context).primaryColor,
//                                               fontSize: Dimensions.fontSizeDefault,
//                                             ),
//                                             maxLines: 1,
//                                             softWrap: false,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   )
//                                 ),
//                               ),
//                             ),
//                         ]),
//                   )
//                       .animate()
//                       .fadeIn(duration: 350.ms)
//                       .slideX(begin: -0.05, end: 0, curve: Curves.easeOutQuad),
//                 SizedBox(
//                     height:
//                         widget.hasPhysical ? Dimensions.paddingSizeSmall : 0),
//                 isGuestMode
//                     ? (widget.hasPhysical
//                         ? CreateAccountWidget(formKey: widget.passwordFormKey)
//                         : const SizedBox())
//                     : const SizedBox(),
//                 isGuestMode
//                     ? const SizedBox(height: Dimensions.paddingSizeSmall)
//                     : const SizedBox(),
//                 if (widget.billingAddress || shippingProvider.sameAsBilling)
//                   Container(
//                     margin: const EdgeInsets.symmetric(
//                         horizontal: Dimensions.paddingSizeDefault,
//                         vertical: Dimensions.paddingSizeExtraSmall),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                           color: Theme.of(context)
//                               .primaryColor
//                               .withValues(alpha: 0.08),
//                           width: 1.2),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withValues(alpha: 0.03),
//                           blurRadius: 15,
//                           offset: const Offset(0, 5),
//                         )
//                       ],
//                     ),
//                     child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(
//                                 Dimensions.paddingSizeDefault),
//                             child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Expanded(
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           padding: const EdgeInsets.all(8),
//                                           decoration: BoxDecoration(
//                                             color: Theme.of(context)
//                                                 .primaryColor
//                                                 .withValues(alpha: 0.08),
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: CustomAssetImageWidget(
//                                               Images.billingTo,
//                                               height: 20,
//                                               width: 20,
//                                               color: Theme.of(context)
//                                                   .primaryColor),
//                                         ),
//                                         const SizedBox(
//                                             width: Dimensions.paddingSizeSmall),
//                                         Text(
//                                           '${getTranslated('billing_to', context)}',
//                                           style: textBold.copyWith(
//                                             fontSize: Dimensions.fontSizeLarge,
//                                             color: Theme.of(context)
//                                                 .textTheme
//                                                 .bodyLarge
//                                                 ?.color,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   if (widget.hasPhysical &&
//                                       widget.billingAddress)
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 10, vertical: 6),
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(12),
//                                         color: Theme.of(context)
//                                             .primaryColor
//                                             .withValues(alpha: 0.05),
//                                       ),
//                                       child: InkWell(
//                                         highlightColor: Colors.transparent,
//                                         focusColor: Colors.transparent,
//                                         splashColor: Colors.transparent,
//                                         onTap: () =>
//                                             shippingProvider.setSameAsBilling(),
//                                         child: Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.end,
//                                             children: [
//                                               AnimatedContainer(
//                                                 duration: const Duration(
//                                                     milliseconds: 200),
//                                                 width: 18,
//                                                 height: 18,
//                                                 alignment: Alignment.center,
//                                                 decoration: BoxDecoration(
//                                                   border: Border.all(
//                                                       color: Theme.of(context)
//                                                           .primaryColor,
//                                                       width: 1.5),
//                                                   borderRadius:
//                                                       BorderRadius.circular(4),
//                                                   color: shippingProvider
//                                                           .sameAsBilling
//                                                       ? Theme.of(context)
//                                                           .primaryColor
//                                                       : Colors.transparent,
//                                                 ),
//                                                 child: Icon(
//                                                   CupertinoIcons.checkmark_alt,
//                                                   size: 14,
//                                                   color: shippingProvider
//                                                           .sameAsBilling
//                                                       ? Colors.white
//                                                       : Colors.transparent,
//                                                 ),
//                                               ),
//                                               const SizedBox(
//                                                   width: Dimensions
//                                                       .paddingSizeExtraSmall),
//                                               Text(
//                                                 getTranslated(
//                                                     'same_as_delivery',
//                                                     context)!,
//                                                 style: textMedium.copyWith(
//                                                     fontSize: Dimensions
//                                                         .fontSizeSmall,
//                                                     color: Theme.of(context)
//                                                         .textTheme
//                                                         .bodyLarge
//                                                         ?.color),
//                                               )
//                                             ]),
//                                       ),
//                                     ),
//                                   if (!shippingProvider.sameAsBilling) ...[
//                                     const SizedBox(
//                                         width: Dimensions.paddingSizeSmall),
//                                     InkWell(
//                                       onTap: () => RouterHelper
//                                           .getSavedBillingAddressListRoute(
//                                               fromGuest: isGuestMode),
//                                       borderRadius: BorderRadius.circular(30),
//                                       child: Container(
//                                         padding: const EdgeInsets.all(8),
//                                         decoration: BoxDecoration(
//                                           color: Theme.of(context)
//                                               .primaryColor
//                                               .withValues(alpha: 0.08),
//                                           shape: BoxShape.circle,
//                                         ),
//                                         child: Image.asset(Images.edit,
//                                             scale: 3,
//                                             color:
//                                                 Theme.of(context).primaryColor),
//                                       ),
//                                     ),
//                                   ],
//                                 ]),
//                           ),
//                           if (!shippingProvider.sameAsBilling) ...[
//                             const Divider(height: 1, thickness: 0.5),
//                             if (shippingProvider.billingAddressIndex != null &&
//                                 (locationProvider.addressList?.isNotEmpty ??
//                                     false))
//                               Container(
//                                 margin: const EdgeInsets.all(
//                                     Dimensions.paddingSizeDefault),
//                                 padding: const EdgeInsets.all(
//                                     Dimensions.paddingSizeDefault),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(16),
//                                   color: Theme.of(context)
//                                       .primaryColor
//                                       .withValues(alpha: 0.03),
//                                   border: Border.all(
//                                       color: Theme.of(context)
//                                           .primaryColor
//                                           .withValues(alpha: 0.05),
//                                       width: 1.2),
//                                 ),
//                                 child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Expanded(
//                                             child: Row(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Text(
//                                                   '${getTranslated('name', context)} : ',
//                                                   style: textMedium.copyWith(
//                                                       fontSize: Dimensions
//                                                           .fontSizeDefault,
//                                                       color: Theme.of(context)
//                                                           .textTheme
//                                                           .bodySmall
//                                                           ?.color),
//                                                 ),
//                                                 Expanded(
//                                                   child: Text(
//                                                     locationProvider
//                                                             .addressList![
//                                                                 shippingProvider
//                                                                     .billingAddressIndex!]
//                                                             .contactPersonName ??
//                                                         '',
//                                                     style: textBold.copyWith(
//                                                         fontSize: Dimensions
//                                                             .fontSizeDefault,
//                                                         color: Theme.of(context)
//                                                             .textTheme
//                                                             .bodyLarge
//                                                             ?.color,
//                                                         overflow: TextOverflow
//                                                             .ellipsis),
//                                                     maxLines: 1,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           Expanded(
//                                             child: Row(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Text(
//                                                   '${getTranslated('phone', context)} : ',
//                                                   style: textMedium.copyWith(
//                                                       fontSize: Dimensions
//                                                           .fontSizeDefault,
//                                                       color: Theme.of(context)
//                                                           .textTheme
//                                                           .bodySmall
//                                                           ?.color),
//                                                 ),
//                                                 Expanded(
//                                                   child: Text(
//                                                     locationProvider
//                                                             .addressList![
//                                                                 shippingProvider
//                                                                     .billingAddressIndex!]
//                                                             .phone ??
//                                                         '',
//                                                     style: textBold.copyWith(
//                                                         fontSize: Dimensions
//                                                             .fontSizeDefault,
//                                                         color: Theme.of(context)
//                                                             .textTheme
//                                                             .bodyLarge
//                                                             ?.color,
//                                                         overflow: TextOverflow
//                                                             .ellipsis),
//                                                     maxLines: 1,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const Divider(
//                                           height: Dimensions.paddingSizeLarge,
//                                           thickness: 0.5),
//                                       Row(
//                                         children: [
//                                           Icon(Icons.location_on_outlined,
//                                               color: Theme.of(context)
//                                                   .primaryColor,
//                                               size: 18),
//                                           const SizedBox(
//                                               width: Dimensions
//                                                   .paddingSizeExtraSmall),
//                                           Container(
//                                             padding: const EdgeInsets.symmetric(
//                                                 horizontal: 8, vertical: 2),
//                                             decoration: BoxDecoration(
//                                               color: Theme.of(context)
//                                                   .primaryColor
//                                                   .withValues(alpha: 0.1),
//                                               borderRadius:
//                                                   BorderRadius.circular(6),
//                                             ),
//                                             child: Text(
//                                               locationProvider
//                                                       .addressList![shippingProvider
//                                                           .billingAddressIndex!]
//                                                       .addressType ??
//                                                   '',
//                                               style: textBold.copyWith(
//                                                   fontSize:
//                                                       Dimensions.fontSizeSmall,
//                                                   color: Theme.of(context)
//                                                       .primaryColor),
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                               width:
//                                                   Dimensions.paddingSizeSmall),
//                                           Expanded(
//                                             child: Text(
//                                               locationProvider
//                                                       .addressList![shippingProvider
//                                                           .billingAddressIndex!]
//                                                       .address ??
//                                                   '',
//                                               style: textRegular.copyWith(
//                                                   fontSize: Dimensions
//                                                       .fontSizeDefault,
//                                                   color: Theme.of(context)
//                                                       .textTheme
//                                                       .bodyLarge
//                                                       ?.color,
//                                                   overflow:
//                                                       TextOverflow.ellipsis),
//                                               maxLines: 2,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ]),
//                               )
//                             else
//                               Padding(
//                                 padding: const EdgeInsets.all(
//                                     Dimensions.paddingSizeDefault),
//                                 child: InkWell(
//                                   onTap: () => RouterHelper
//                                       .getSavedBillingAddressListRoute(
//                                           fromGuest: isGuestMode),
//                                   borderRadius: BorderRadius.circular(16),
//                                   child: Container(
//                                     padding: const EdgeInsets.all(
//                                         Dimensions.paddingSizeLarge),
//                                     decoration: BoxDecoration(
//                                       color: Theme.of(context)
//                                           .primaryColor
//                                           .withValues(alpha: 0.02),
//                                       borderRadius: BorderRadius.circular(16),
//                                       border: Border.all(
//                                         color: Theme.of(context)
//                                             .primaryColor
//                                             .withValues(alpha: 0.25),
//                                         width: 1.5,
//                                         style: BorderStyle.solid,
//                                       ),
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Icon(Icons.add_circle_outline_rounded,
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                             size: 24),
//                                         const SizedBox(
//                                             width: Dimensions.paddingSizeSmall),
//                                         Text(
//                                           getTranslated(
//                                                   'please_set_your_billing_info',
//                                                   context) ??
//                                               '',
//                                           style: textBold.copyWith(
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                             fontSize:
//                                                 Dimensions.fontSizeDefault,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ]),
//                   )
//                       .animate()
//                       .fadeIn(duration: 350.ms)
//                       .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
//                 isGuestMode
//                     ? (!widget.hasPhysical
//                         ? CreateAccountWidget(formKey: widget.passwordFormKey)
//                         : const SizedBox())
//                     : const SizedBox(),
//               ]);
//         },
//       );
//     });
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syriapharmacy/common/basewidget/custom_asset_image_widget.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/auth/controllers/auth_controller.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/features/checkout/widgets/create_account_widget.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:provider/provider.dart';

class ShippingDetailsWidget extends StatefulWidget {
  final bool hasPhysical;
  final bool billingAddress;
  final GlobalKey<FormState> passwordFormKey;

  const ShippingDetailsWidget({
    super.key,
    required this.hasPhysical,
    required this.billingAddress,
    required this.passwordFormKey,
  });

  @override
  State<ShippingDetailsWidget> createState() =>
      _ShippingDetailsWidgetState();
}

class _ShippingDetailsWidgetState extends State<ShippingDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isGuestMode =
    !Provider.of<AuthController>(
      context,
      listen: false,
    ).isLoggedIn();

    return Consumer<CheckoutController>(
      builder: (context, shippingProvider, _) {
        return Consumer<AddressController>(
          builder: (context, locationProvider, _) {
            // ============================================================
            // DELIVERY ADDRESS
            // ============================================================

            final int? deliveryIndex =
                shippingProvider.addressIndex;

            final bool hasDeliveryAddress =
                deliveryIndex != null &&
                    locationProvider.addressList != null &&
                    locationProvider.addressList!.isNotEmpty &&
                    deliveryIndex >= 0 &&
                    deliveryIndex <
                        locationProvider.addressList!.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========================================================
                // DELIVERY ADDRESS
                // ========================================================

                if (widget.hasPhysical)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.08),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // DELIVERY HEADER
                        // ==================================================

                        Padding(
                          padding: const EdgeInsets.all(
                            Dimensions.paddingSizeDefault,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
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
                                      child: CustomAssetImageWidget(
                                        Images.deliveryTo,
                                        height: 20,
                                        width: 20,
                                        color: Theme.of(context)
                                            .primaryColor,
                                      ),
                                    ),

                                    const SizedBox(
                                      width:
                                      Dimensions.paddingSizeSmall,
                                    ),

                                    Text(
                                      getTranslated(
                                        'delivery_to',
                                        context,
                                      ) ??
                                          '',
                                      style: textBold.copyWith(
                                        fontSize:
                                        Dimensions.fontSizeLarge,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ==================================================
                              // EDIT DELIVERY ADDRESS
                              // ==================================================

                              InkWell(
                                onTap: () {
                                  RouterHelper
                                      .getSavedAddressListRoute(
                                    fromGuest: isGuestMode,
                                  );
                                },
                                borderRadius:
                                BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    Images.edit,
                                    scale: 3,
                                    color: Theme.of(context)
                                        .primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 0.5,
                        ),

                        // ==================================================
                        // DELIVERY ADDRESS EXISTS
                        // ==================================================

                        if (hasDeliveryAddress)
                          Container(
                            margin: const EdgeInsets.all(
                              Dimensions.paddingSizeDefault,
                            ),
                            padding: const EdgeInsets.all(
                              Dimensions.paddingSizeDefault,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(16),
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.03),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.05),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                // ==========================================
                                // NAME
                                // ==========================================

                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color: Theme.of(context)
                                          .primaryColor,
                                      size: 18,
                                    ),

                                    const SizedBox(
                                      width: Dimensions
                                          .paddingSizeExtraSmall,
                                    ),

                                    Expanded(
                                      child: Text(
                                        locationProvider
                                            .addressList![
                                        deliveryIndex!]
                                            .contactPersonName ??
                                            '',
                                        style: textBold.copyWith(
                                          fontSize: Dimensions
                                              .fontSizeDefault,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height:
                                  Dimensions.paddingSizeSmall,
                                ),

                                // ==========================================
                                // PHONE
                                // ==========================================

                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      color: Theme.of(context)
                                          .primaryColor,
                                      size: 18,
                                    ),

                                    const SizedBox(
                                      width: Dimensions
                                          .paddingSizeExtraSmall,
                                    ),

                                    Expanded(
                                      child: Text(
                                        locationProvider
                                            .addressList![
                                        deliveryIndex]
                                            .phone ??
                                            '',
                                        style: textMedium.copyWith(
                                          fontSize: Dimensions
                                              .fontSizeDefault,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(
                                  height:
                                  Dimensions.paddingSizeLarge,
                                  thickness: 0.5,
                                ),

                                // ==========================================
                                // ADDRESS
                                // ==========================================

                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: Theme.of(context)
                                          .primaryColor,
                                      size: 18,
                                    ),

                                    const SizedBox(
                                      width: Dimensions
                                          .paddingSizeExtraSmall,
                                    ),

                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        locationProvider
                                            .addressList![
                                        deliveryIndex]
                                            .addressType ??
                                            '',
                                        style: textBold.copyWith(
                                          fontSize: Dimensions
                                              .fontSizeSmall,
                                          color: Theme.of(context)
                                              .primaryColor,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: Dimensions
                                          .paddingSizeSmall,
                                    ),

                                    Expanded(
                                      child: Text(
                                        locationProvider
                                            .addressList![
                                        deliveryIndex]
                                            .address ??
                                            '',
                                        style: textRegular.copyWith(
                                          fontSize: Dimensions
                                              .fontSizeDefault,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )

                        // ==================================================
                        // NO DELIVERY ADDRESS
                        // ==================================================

                        else
                          Padding(
                            padding: const EdgeInsets.all(
                              Dimensions.paddingSizeDefault,
                            ),
                            child: InkWell(
                              onTap: () {
                                RouterHelper
                                    .getSavedAddressListRoute(
                                  fromGuest: isGuestMode,
                                );
                              },
                              borderRadius:
                              BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeLarge,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.02),
                                  borderRadius:
                                  BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons
                                          .add_circle_outline_rounded,
                                      color: Theme.of(context)
                                          .primaryColor,
                                      size: 24,
                                    ),

                                    const SizedBox(
                                      width: Dimensions
                                          .paddingSizeSmall,
                                    ),

                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          getTranslated(
                                            'please_set_your_delivery_info',
                                            context,
                                          ) ??
                                              '',
                                          style: textBold.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor,
                                            fontSize: Dimensions
                                                .fontSizeDefault,
                                          ),
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideX(
                    begin: -0.05,
                    end: 0,
                    curve: Curves.easeOutQuad,
                  ),

                // ========================================================
                // SPACE
                // ========================================================

                // SizedBox(
                //   height: widget.hasPhysical
                //       ? Dimensions.paddingSizeSmall
                //       : 0,
                // ),

                // ========================================================
                // GUEST ACCOUNT
                // ========================================================

                isGuestMode
                    ? (widget.hasPhysical
                    ? CreateAccountWidget(
                  formKey: widget.passwordFormKey,
                )
                    : const SizedBox())
                    : const SizedBox(),

                isGuestMode
                    ? const SizedBox(
                  height: Dimensions.paddingSizeSmall,
                )
                    : const SizedBox(),

                // ========================================================
                // BILLING ADDRESS
                //
                // IMPORTANT:
                // Billing is now ALWAYS the same as Delivery.
                // There is NO independent billing address.
                // ========================================================

                // if (widget.billingAddress ||
                //     shippingProvider.sameAsBilling)
                //   Container(
                //     margin: const EdgeInsets.symmetric(
                //       horizontal: Dimensions.paddingSizeDefault,
                //       vertical: Dimensions.paddingSizeExtraSmall,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Theme.of(context).cardColor,
                //       borderRadius: BorderRadius.circular(20),
                //       border: Border.all(
                //         color: Theme.of(context)
                //             .primaryColor
                //             .withValues(alpha: 0.08),
                //         width: 1.2,
                //       ),
                //       boxShadow: [
                //         BoxShadow(
                //           color:
                //           Colors.black.withValues(alpha: 0.03),
                //           blurRadius: 15,
                //           offset: const Offset(0, 5),
                //         ),
                //       ],
                //     ),
                //     child: Column(
                //       crossAxisAlignment:
                //       CrossAxisAlignment.start,
                //       children: [
                //         // ==================================================
                //         // BILLING HEADER
                //         // ==================================================
                //
                //         Padding(
                //           padding: const EdgeInsets.all(
                //             Dimensions.paddingSizeDefault,
                //           ),
                //           child: Row(
                //             mainAxisAlignment:
                //             MainAxisAlignment.start,
                //             crossAxisAlignment:
                //             CrossAxisAlignment.center,
                //             children: [
                //               Expanded(
                //                 child: Row(
                //                   children: [
                //                     Container(
                //                       padding:
                //                       const EdgeInsets.all(8),
                //                       decoration: BoxDecoration(
                //                         color: Theme.of(context)
                //                             .primaryColor
                //                             .withValues(alpha: 0.08),
                //                         shape: BoxShape.circle,
                //                       ),
                //                       child:
                //                       CustomAssetImageWidget(
                //                         Images.billingTo,
                //                         height: 20,
                //                         width: 20,
                //                         color: Theme.of(context)
                //                             .primaryColor,
                //                       ),
                //                     ),
                //
                //                     const SizedBox(
                //                       width: Dimensions
                //                           .paddingSizeSmall,
                //                     ),
                //
                //                     Text(
                //                       getTranslated(
                //                         'billing_to',
                //                         context,
                //                       ) ??
                //                           '',
                //                       style: textBold.copyWith(
                //                         fontSize: Dimensions
                //                             .fontSizeLarge,
                //                         color: Theme.of(context)
                //                             .textTheme
                //                             .bodyLarge
                //                             ?.color,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //
                //               // ==================================================
                //               // SAME AS DELIVERY CHECKBOX
                //               //
                //               // ALWAYS ENABLED
                //               // NO onTap
                //               // ==================================================
                //
                //               Container(
                //                 padding:
                //                 const EdgeInsets.symmetric(
                //                   horizontal: 10,
                //                   vertical: 6,
                //                 ),
                //                 decoration: BoxDecoration(
                //                   borderRadius:
                //                   BorderRadius.circular(12),
                //                   color: Theme.of(context)
                //                       .primaryColor
                //                       .withValues(alpha: 0.05),
                //                 ),
                //                 child: Row(
                //                   mainAxisAlignment:
                //                   MainAxisAlignment.end,
                //                   children: [
                //                     // ==========================================
                //                     // ALWAYS CHECKED
                //                     // ==========================================
                //
                //                     Container(
                //                       width: 18,
                //                       height: 18,
                //                       alignment:
                //                       Alignment.center,
                //                       decoration: BoxDecoration(
                //                         border: Border.all(
                //                           color: Theme.of(context)
                //                               .primaryColor,
                //                           width: 1.5,
                //                         ),
                //                         borderRadius:
                //                         BorderRadius.circular(4),
                //                         color: Theme.of(context)
                //                             .primaryColor,
                //                       ),
                //                       child: const Icon(
                //                         CupertinoIcons
                //                             .checkmark_alt,
                //                         size: 14,
                //                         color: Colors.white,
                //                       ),
                //                     ),
                //
                //                     const SizedBox(
                //                       width: Dimensions
                //                           .paddingSizeExtraSmall,
                //                     ),
                //
                //                     Text(
                //                       getTranslated(
                //                         'same_as_delivery',
                //                         context,
                //                       ) ??
                //                           '',
                //                       style: textMedium.copyWith(
                //                         fontSize: Dimensions
                //                             .fontSizeSmall,
                //                         color: Theme.of(context)
                //                             .textTheme
                //                             .bodyLarge
                //                             ?.color,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //
                //         const Divider(
                //           height: 1,
                //           thickness: 0.5,
                //         ),
                //
                //         // ==================================================
                //         // BILLING ADDRESS
                //         //
                //         // VERY IMPORTANT:
                //         // We use deliveryIndex here.
                //         //
                //         // So Billing = Delivery.
                //         // ==================================================
                //
                //         if (hasDeliveryAddress)
                //           Container(
                //             margin: const EdgeInsets.all(
                //               Dimensions.paddingSizeDefault,
                //             ),
                //             padding: const EdgeInsets.all(
                //               Dimensions.paddingSizeDefault,
                //             ),
                //             decoration: BoxDecoration(
                //               borderRadius:
                //               BorderRadius.circular(16),
                //               color: Theme.of(context)
                //                   .primaryColor
                //                   .withValues(alpha: 0.03),
                //               border: Border.all(
                //                 color: Theme.of(context)
                //                     .primaryColor
                //                     .withValues(alpha: 0.05),
                //                 width: 1.2,
                //               ),
                //             ),
                //             child: Column(
                //               crossAxisAlignment:
                //               CrossAxisAlignment.start,
                //               children: [
                //                 // ==========================================
                //                 // NAME + PHONE
                //                 // ==========================================
                //
                //                 Row(
                //                   children: [
                //                     // NAME
                //                     Expanded(
                //                       child: Row(
                //                         mainAxisSize:
                //                         MainAxisSize.min,
                //                         children: [
                //                           Text(
                //                             '${getTranslated('name', context)} : ',
                //                             style:
                //                             textMedium.copyWith(
                //                               fontSize: Dimensions
                //                                   .fontSizeDefault,
                //                               color: Theme.of(context)
                //                                   .textTheme
                //                                   .bodySmall
                //                                   ?.color,
                //                             ),
                //                           ),
                //
                //                           Expanded(
                //                             child: Text(
                //                               locationProvider
                //                                   .addressList![
                //                               deliveryIndex!]
                //                                   .contactPersonName ??
                //                                   '',
                //                               style:
                //                               textBold.copyWith(
                //                                 fontSize: Dimensions
                //                                     .fontSizeDefault,
                //                                 color: Theme.of(context)
                //                                     .textTheme
                //                                     .bodyLarge
                //                                     ?.color,
                //                                 overflow: TextOverflow
                //                                     .ellipsis,
                //                               ),
                //                               maxLines: 1,
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //
                //                     const SizedBox(
                //                       width:
                //                       Dimensions.paddingSizeSmall,
                //                     ),
                //
                //                     // PHONE
                //                     Expanded(
                //                       child: Row(
                //                         mainAxisSize:
                //                         MainAxisSize.min,
                //                         children: [
                //                           Text(
                //                             '${getTranslated('phone', context)} : ',
                //                             style:
                //                             textMedium.copyWith(
                //                               fontSize: Dimensions
                //                                   .fontSizeDefault,
                //                               color: Theme.of(context)
                //                                   .textTheme
                //                                   .bodySmall
                //                                   ?.color,
                //                             ),
                //                           ),
                //
                //                           Expanded(
                //                             child: Text(
                //                               locationProvider
                //                                   .addressList![
                //                               deliveryIndex]
                //                                   .phone ??
                //                                   '',
                //                               style:
                //                               textBold.copyWith(
                //                                 fontSize: Dimensions
                //                                     .fontSizeDefault,
                //                                 color: Theme.of(context)
                //                                     .textTheme
                //                                     .bodyLarge
                //                                     ?.color,
                //                                 overflow: TextOverflow
                //                                     .ellipsis,
                //                               ),
                //                               maxLines: 1,
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //
                //                 const Divider(
                //                   height:
                //                   Dimensions.paddingSizeLarge,
                //                   thickness: 0.5,
                //                 ),
                //
                //                 // ==========================================
                //                 // BILLING ADDRESS
                //                 // SAME DELIVERY ADDRESS
                //                 // ==========================================
                //
                //                 Row(
                //                   children: [
                //                     Icon(
                //                       Icons.location_on_outlined,
                //                       color: Theme.of(context)
                //                           .primaryColor,
                //                       size: 18,
                //                     ),
                //
                //                     const SizedBox(
                //                       width: Dimensions
                //                           .paddingSizeExtraSmall,
                //                     ),
                //
                //                     Container(
                //                       padding:
                //                       const EdgeInsets.symmetric(
                //                         horizontal: 8,
                //                         vertical: 2,
                //                       ),
                //                       decoration: BoxDecoration(
                //                         color: Theme.of(context)
                //                             .primaryColor
                //                             .withValues(alpha: 0.1),
                //                         borderRadius:
                //                         BorderRadius.circular(6),
                //                       ),
                //                       child: Text(
                //                         locationProvider
                //                             .addressList![
                //                         deliveryIndex]
                //                             .addressType ??
                //                             '',
                //                         style: textBold.copyWith(
                //                           fontSize: Dimensions
                //                               .fontSizeSmall,
                //                           color: Theme.of(context)
                //                               .primaryColor,
                //                         ),
                //                       ),
                //                     ),
                //
                //                     const SizedBox(
                //                       width: Dimensions
                //                           .paddingSizeSmall,
                //                     ),
                //
                //                     Expanded(
                //                       child: Text(
                //                         locationProvider
                //                             .addressList![
                //                         deliveryIndex]
                //                             .address ??
                //                             '',
                //                         style: textRegular.copyWith(
                //                           fontSize: Dimensions
                //                               .fontSizeDefault,
                //                           color: Theme.of(context)
                //                               .textTheme
                //                               .bodyLarge
                //                               ?.color,
                //                           overflow:
                //                           TextOverflow.ellipsis,
                //                         ),
                //                         maxLines: 2,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ],
                //             ),
                //           )
                //
                //         // ==================================================
                //         // NO DELIVERY ADDRESS
                //         // ==================================================
                //
                //         else
                //           Padding(
                //             padding: const EdgeInsets.all(
                //               Dimensions.paddingSizeDefault,
                //             ),
                //             child: Container(
                //               padding: const EdgeInsets.all(
                //                 Dimensions.paddingSizeLarge,
                //               ),
                //               decoration: BoxDecoration(
                //                 color: Theme.of(context)
                //                     .primaryColor
                //                     .withValues(alpha: 0.02),
                //                 borderRadius:
                //                 BorderRadius.circular(16),
                //                 border: Border.all(
                //                   color: Theme.of(context)
                //                       .primaryColor
                //                       .withValues(alpha: 0.15),
                //                   width: 1.2,
                //                 ),
                //               ),
                //               child: Row(
                //                 mainAxisAlignment:
                //                 MainAxisAlignment.center,
                //                 children: [
                //                   Icon(
                //                     Icons
                //                         .info_outline_rounded,
                //                     color: Theme.of(context)
                //                         .primaryColor,
                //                     size: 22,
                //                   ),
                //
                //                   const SizedBox(
                //                     width: Dimensions
                //                         .paddingSizeSmall,
                //                   ),
                //
                //                   Flexible(
                //                     child: Text(
                //                       getTranslated(
                //                         'please_set_your_delivery_info',
                //                         context,
                //                       ) ??
                //                           '',
                //                       style: textMedium.copyWith(
                //                         color: Theme.of(context)
                //                             .primaryColor,
                //                         fontSize: Dimensions
                //                             .fontSizeDefault,
                //                       ),
                //                       textAlign: TextAlign.center,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //       ],
                //     ),
                //   )
                //       .animate()
                //       .fadeIn(duration: 350.ms)
                //       .slideX(
                //     begin: 0.05,
                //     end: 0,
                //     curve: Curves.easeOutQuad,
                //   ),

                // ========================================================
                // GUEST ACCOUNT - DIGITAL
                // ========================================================

                isGuestMode
                    ? (!widget.hasPhysical
                    ? CreateAccountWidget(
                  formKey: widget.passwordFormKey,
                )
                    : const SizedBox())
                    : const SizedBox(),
              ],
            );
          },
        );
      },
    );
  }
}