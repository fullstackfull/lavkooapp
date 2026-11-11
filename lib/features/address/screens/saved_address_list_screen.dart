import 'package:flutter/material.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/address/widgets/address_shimmer.dart';
import 'package:syriapharmacy/features/checkout/controllers/checkout_controller.dart';
import 'package:syriapharmacy/helper/route_healper.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:syriapharmacy/utill/dimensions.dart';
import 'package:syriapharmacy/utill/images.dart';
import 'package:syriapharmacy/common/basewidget/custom_app_bar_widget.dart';
import 'package:syriapharmacy/common/basewidget/no_internet_screen_widget.dart';
import 'package:syriapharmacy/features/address/widgets/address_type_widget.dart';
import 'package:provider/provider.dart';

class SavedAddressListScreen extends StatefulWidget {
  final bool fromGuest;
  const SavedAddressListScreen({super.key, this.fromGuest = false});

  @override
  State<SavedAddressListScreen> createState() => _SavedAddressListScreenState();
}

class _SavedAddressListScreenState extends State<SavedAddressListScreen> {
  @override
  void initState() {
    Provider.of<AddressController>(context, listen: false).getAddressList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () => RouterHelper.getAddNewAddressRoute(isBilling: false),
          backgroundColor: Theme.of(context).textTheme.bodyMedium?.color,
          child: Icon(Icons.add, color: Theme.of(context).highlightColor)),
      appBar: CustomAppBar(
          title: widget.fromGuest
              ? getTranslated('ADDRESS_LIST', context)
              : getTranslated('SHIPPING_ADDRESS_LIST', context)),
      body: SafeArea(child: Consumer<AddressController>(
    builder: (context, locationProvider, child) {
      return locationProvider.addressList != null
          ? locationProvider.addressList!.isNotEmpty
          ? ListView.builder(
        // ⬇️ شيلنا NeverScrollableScrollPhysics و shrinkWrap
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: locationProvider.addressList?.length,
        itemBuilder: (context, index) {
          return InkWell(
              onTap: () {
                Provider.of<CheckoutController>(context, listen: false)
                    .setAddressIndex(index);
                Navigator.pop(context);
              },
              child: Container(
                  margin: const EdgeInsets.only(
                      top: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).highlightColor,
                      border: index ==
                          Provider.of<CheckoutController>(context)
                              .addressIndex
                          ? Border.all(
                          width: 2,
                          color: Theme.of(context).primaryColor)
                          : null),
                  child: AddressTypeWidget(
                      address:
                      locationProvider.addressList?[index])));
        },
      )
          : Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 3),
          child: Center(
              child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(
                      bottom: Dimensions.paddingSizeLarge),
                  child: const NoInternetOrDataScreenWidget(
                      isNoInternet: false,
                      message: 'no_address_found',
                      icon: Images.noAddress))))
          : const AddressShimmerWidget();
    },
    )),
    );
  }
}
