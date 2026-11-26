import 'package:flutter/material.dart';
import 'package:syriapharmacy/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:syriapharmacy/features/address/address_catalog_config.dart';
import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/features/address/domain/models/label_model.dart';
import 'package:syriapharmacy/features/address/domain/models/restricted_zip_model.dart';
import 'package:syriapharmacy/features/address/domain/services/address_service_interface.dart';
import 'package:syriapharmacy/helper/api_checker.dart';
import 'package:syriapharmacy/main.dart';

class AddressController with ChangeNotifier {
  final AddressServiceInterface addressServiceInterface;
  AddressController({required this.addressServiceInterface});

  List<String> _restrictedCountryList = [];
  List<String> get restrictedCountryList => _restrictedCountryList;
  List<RestrictedZipModel> _restrictedZipList = [];
  List<RestrictedZipModel> get restrictedZipList => _restrictedZipList;
  final List<String> _zipNameList = [];
  List<String> get zipNameList => _zipNameList;
  final TextEditingController _searchZipController = TextEditingController();
  TextEditingController get searchZipController => _searchZipController;
  final TextEditingController _searchCountryController =
      TextEditingController();
  TextEditingController get searchCountryController => _searchCountryController;
  List<AddressModel>? _addressList;
  List<AddressModel>? get addressList => _addressList;

  List<AddressRegionModel> _addressRegions = const <AddressRegionModel>[];
  List<AddressCityModel> _addressCities = const <AddressCityModel>[];
  AddressRegionModel? _chosenRegion;
  AddressCityModel? _chosenCity;

  /// The regions of the central catalogue, empty until they have been read and
  /// on every build that does not ask for them (J-14).
  List<AddressRegionModel> get addressRegions => _addressRegions;

  /// The cities of the chosen region, empty while no region is chosen.
  List<AddressCityModel> get addressCities => _addressCities;

  AddressRegionModel? get chosenRegion => _chosenRegion;

  AddressCityModel? get chosenCity => _chosenCity;

  /// Whether a form should offer the catalogue at all: this build knows how to,
  /// and the store has rows to offer. A store whose catalogue has not been
  /// imported answers an empty list, and then the form is the one it always was
  /// rather than two empty pickers nobody can get past.
  bool get addressCatalogIsOffered =>
      AddressCatalogConfig.enabled && _addressRegions.isNotEmpty;

  /// Reads the regions once per form. It never throws and never shows an error:
  /// a catalogue that cannot be read is a catalogue with no rows, and the form
  /// falls back to the free text it has always had.
  ///
  /// The build switch is NOT consulted a second time here. It lives in the one
  /// place that makes the request, which answers an empty list without making
  /// one while it is off, so a build that does not ask for the catalogue gets no
  /// rows and [addressCatalogIsOffered] is false either way. Asking twice would
  /// also make this unreachable in a test, which is the usual price of a second
  /// copy of a rule.
  Future<void> loadAddressRegions() async {
    if (_addressRegions.isNotEmpty) {
      return;
    }

    _addressRegions = await addressServiceInterface.getAddressRegions();
    notifyListeners();
  }

  /// Chooses a region and reads its cities. The city is forgotten first, because
  /// a city of the region just left would be saved against the new one.
  Future<void> chooseAddressRegion(AddressRegionModel? region) async {
    _chosenRegion = region;
    _chosenCity = null;
    _addressCities = const <AddressCityModel>[];
    notifyListeners();

    if (region == null) {
      return;
    }

    final List<AddressCityModel> cities =
        await addressServiceInterface.getAddressCities(regionId: region.id);

    // The region may have been changed again while this was in flight; the answer of a region
    // nobody is looking at any more is dropped rather than drawn under the one they are.
    if (_chosenRegion?.id == region.id) {
      _addressCities = cities;
      notifyListeners();
    }
  }

  void chooseAddressCity(AddressCityModel? city) {
    _chosenCity = city;
    notifyListeners();
  }

  /// Opens a form on the address it is editing: the region and the city it
  /// already holds, found in the catalogue BY ID.
  ///
  /// Without this, editing the phone number of an address that already has a
  /// region and a city would meet two empty pickers and have to choose them
  /// again -- and a form that saved while they were empty would send no ids at
  /// all, which the server reads as a legacy edit and would quietly leave the
  /// address matching no coverage.
  ///
  /// An id that is not in the catalogue is left unchosen rather than guessed at:
  /// a city that has been withdrawn from the catalogue must be chosen again, and
  /// the form says so by being empty and required.
  Future<void> seedAddressCatalogChoice(AddressModel? existing) async {
    final int? regionId = existing?.regionId;
    final int? cityId = existing?.cityId;

    _addressDistrict = _something(existing?.district);
    _nationalAddress = _something(existing?.nationalAddress);

    if (regionId == null || _chosenRegion != null) {
      return;
    }

    final AddressRegionModel? region = _addressRegions
        .where((AddressRegionModel row) => row.id == regionId)
        .firstOrNull;

    if (region == null) {
      return;
    }

    await chooseAddressRegion(region);

    if (cityId == null) {
      return;
    }

    final AddressCityModel? city = _addressCities
        .where((AddressCityModel row) => row.id == cityId)
        .firstOrNull;

    if (city != null) {
      chooseAddressCity(city);
    }
  }

  String? _addressDistrict;
  String? _nationalAddress;

  String? get addressDistrict => _addressDistrict;

  String? get nationalAddress => _nationalAddress;

  /// Kept WITHOUT notifying, both of them: these two are typed, and rebuilding
  /// the form on every keystroke would fight the field the person is typing in.
  /// Nothing on the screen reads them back; the save does, once.
  void writeAddressDistrict(String? value) =>
      _addressDistrict = _something(value);

  void writeNationalAddress(String? value) =>
      _nationalAddress = _something(value);

  /// Forgets what a form chose, so that the next form does not open on it.
  void forgetAddressCatalogChoice() {
    _chosenRegion = null;
    _chosenCity = null;
    _addressCities = const <AddressCityModel>[];
    _addressDistrict = null;
    _nationalAddress = null;
  }

  /// Text with nothing in it is nothing at all, so an untouched field is not
  /// saved as a district whose name is blank.
  static String? _something(String? value) {
    final String text = value?.trim() ?? '';

    return text.isEmpty ? null : text;
  }

  Future<void> getRestrictedDeliveryCountryList() async {
    ApiResponseModel apiResponse =
        await addressServiceInterface.getDeliveryRestrictedCountryList();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _restrictedCountryList = [];
      apiResponse.response!.data
          .forEach((address) => _restrictedCountryList.add(address));
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future<void> getRestrictedDeliveryZipList() async {
    ApiResponseModel apiResponse =
        await addressServiceInterface.getDeliveryRestrictedZipList();
    if (apiResponse.response != null &&
        apiResponse.response?.statusCode == 200) {
      _restrictedZipList = [];
      apiResponse.response!.data.forEach((address) =>
          _restrictedZipList.add(RestrictedZipModel.fromJson(address)));
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future<void> getDeliveryRestrictedZipBySearch(String searchName) async {
    _restrictedZipList = [];
    ApiResponseModel response = await addressServiceInterface
        .getDeliveryRestrictedZipBySearch(searchName);
    if (response.response!.statusCode == 200) {
      _restrictedZipList = [];
      response.response!.data.forEach((address) {
        _restrictedZipList.add(RestrictedZipModel.fromJson(address));
      });
    } else {
      ApiChecker.checkApi(response);
    }
    notifyListeners();
  }

  Future<void> getDeliveryRestrictedCountryBySearch(String searchName) async {
    _restrictedCountryList = [];
    ApiResponseModel response = await addressServiceInterface
        .getDeliveryRestrictedCountryBySearch(searchName);
    if (response.response!.statusCode == 200) {
      _restrictedCountryList = [];
      response.response!.data
          .forEach((address) => _restrictedCountryList.add(address));
    } else {
      ApiChecker.checkApi(response);
    }
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<AddressModel>?> getAddressList(
      {bool fromRemove = false,
      bool isShipping = false,
      bool isBilling = false,
      bool all = false}) async {
    _addressList = null;
    _addressList = await addressServiceInterface.getList(
        isShipping: isShipping,
        isBilling: isBilling,
        fromRemove: fromRemove,
        all: all);
    notifyListeners();
    return _addressList;
  }

  Future<void> deleteAddress(int id) async {
    ApiResponseModel apiResponse = await addressServiceInterface.delete(id);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(
          apiResponse.response!.data['message'], Get.context!,
          snackBarType: SnackBarType.success);
      getAddressList(fromRemove: true);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future<ApiResponseModel> addAddress(AddressModel addressModel) async {
    _isLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await addressServiceInterface.add(addressModel);
    _isLoading = false;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      showCustomSnackBarWidget(
          apiResponse.response!.data["message"], Get.context!,
          snackBarType: SnackBarType.success);
      getAddressList();
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<void> updateAddress(BuildContext context,
      {required AddressModel addressModel, int? addressId}) async {
    _isLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await addressServiceInterface.update(addressModel.toJson(), addressId!);
    _isLoading = false;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Navigator.pop(Get.context!);
      getAddressList();
      showCustomSnackBarWidget(
          apiResponse.response!.data["message"], Get.context!,
          snackBarType: SnackBarType.success);
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
  }

  void setZip(String zip) {
    _searchZipController.text = zip;
    notifyListeners();
  }

  void setCountry(String country) {
    _searchCountryController.text = country;
    notifyListeners();
  }

  List<LabelAsModel> addressTypeList = [];
  int _selectAddressIndex = 0;

  int get selectAddressIndex => _selectAddressIndex;

  void updateAddressIndex(int index, bool notify) {
    _selectAddressIndex = index;
    if (notify) {
      notifyListeners();
    }
  }

  Future<List<LabelAsModel>> getAddressType() async {
    if (addressTypeList.isEmpty) {
      addressTypeList = [];
      addressTypeList = addressServiceInterface.getAddressType();
    }
    return addressTypeList;
  }

  void resetAddressList({bool isUpdate = true}) {
    _addressList = [];
    if (isUpdate) {
      notifyListeners();
    }
  }
}
