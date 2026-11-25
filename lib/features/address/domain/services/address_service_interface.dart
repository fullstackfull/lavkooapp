import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/features/address/domain/models/label_model.dart';

abstract class AddressServiceInterface {
  Future<dynamic> getList(
      {bool fromRemove = false,
      bool isShipping = false,
      bool isBilling = false,
      bool all = false});

  Future<dynamic> add(AddressModel addressModel);

  Future<dynamic> update(Map<String, dynamic> body, int addressId);

  Future<dynamic> delete(int id);

  List<LabelAsModel> getAddressType();

  Future<dynamic> getDeliveryRestrictedCountryList();

  Future<dynamic> getDeliveryRestrictedZipList();

  Future<dynamic> getDeliveryRestrictedZipBySearch(String zipcode);

  Future<dynamic> getDeliveryRestrictedCountryBySearch(String country);

  /// The regions of the central address catalogue, or none at all (J-14). None
  /// is what a build without the switch, a store whose catalogue has not been
  /// imported, a refusal and a timeout all give, so a caller never has to tell
  /// them apart to draw a form.
  Future<List<AddressRegionModel>> getAddressRegions();

  /// The cities of one region, under the same rule.
  Future<List<AddressCityModel>> getAddressCities({int? regionId});
}
