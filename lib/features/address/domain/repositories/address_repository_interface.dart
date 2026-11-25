import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/features/address/domain/models/label_model.dart';
import 'package:syriapharmacy/interface/repo_interface.dart';

abstract class AddressRepoInterface<T>
    implements RepositoryInterface<AddressModel> {
  List<LabelAsModel> getAddressType();

  Future<dynamic> getDeliveryRestrictedCountryList();

  Future<dynamic> getDeliveryRestrictedZipList();

  Future<dynamic> getDeliveryRestrictedZipBySearch(String zipcode);

  Future<dynamic> getDeliveryRestrictedCountryBySearch(String country);

  /// The central address catalogue (J-14). Both answer an empty list on a store
  /// whose address masters have not been imported, and on a build with the
  /// catalogue switched off, so a caller never has to ask whether to ask.
  Future<List<AddressRegionModel>> getAddressRegions();

  /// The cities of a region, or the whole catalogue when no region is named.
  /// [query] narrows by name and [limit] bounds the answer, both as the server's
  /// own parameters.
  Future<List<AddressCityModel>> getAddressCities({int? regionId, String? query, int? limit});
}
