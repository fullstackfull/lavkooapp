import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';
import 'package:syriapharmacy/features/address/domain/models/address_model.dart';
import 'package:syriapharmacy/features/address/domain/services/address_service_interface.dart';
import 'package:syriapharmacy/features/address/controllers/address_controller.dart';
import 'package:syriapharmacy/features/address/domain/models/label_model.dart';

/// What the app saves when a Saudi address is built from the central catalogue
/// (J-14): the region and the city BY ID, the district and the National Address.
///
/// Two rules decide every case here.
///
/// **Ids are the keys and names never are.** A courier's coverage, a warehouse
/// and a marketplace are mapped to a city by its id, so an address that kept the
/// city only as text could be checked against none of them. The text is kept
/// beside the ids and never replaced by them, because the platform's own `soft`
/// mode stores both -- and `zip` is never derived from the National Address.
///
/// **A store that cannot keep these must see the request it has always seen.**
/// An address with none of them sends none of them: not a null, not a zero, and
/// not an empty string.
void main() {
  group('what the body carries', () {
    test('an address built from the catalogue carries the two ids, the district and the National Address', () {
      final Map<String, dynamic> body = AddressModel(
        contactPersonName: 'A customer',
        address: 'A street',
        city: 'Riyadh',
        country: 'SA',
        phone: '+966500000000',
        regionId: 1,
        cityId: 21,
        district: 'Al Olaya',
        nationalAddress: 'RRRD2929',
      ).toJson();

      expect(body['region_id'], 1);
      expect(body['city_id'], 21);
      expect(body['district'], 'Al Olaya');
      expect(body['national_address'], 'RRRD2929');
      expect(body['city'], 'Riyadh', reason: 'the free text is kept beside the ids, not replaced by them');
    });

    test('an address with none of them carries none of them, not even as a null', () {
      final Map<String, dynamic> body = AddressModel(
        contactPersonName: 'A customer',
        address: 'A street',
        city: 'Riyadh',
        country: 'SA',
      ).toJson();

      for (final String key in <String>['region_id', 'city_id', 'district', 'national_address']) {
        expect(body.containsKey(key), isFalse,
            reason: '$key: a store whose address migrations have not run must see the request it always saw');
      }
    });

    test('the zip is never the National Address and the National Address is never the zip', () {
      final Map<String, dynamic> body = AddressModel(zip: '12345', nationalAddress: 'RRRD2929').toJson();

      expect(body['zip'], '12345');
      expect(body['national_address'], 'RRRD2929');
    });
  });

  group('what the app reads back', () {
    test('the two ids are read whether the server writes them as numbers or as text', () {
      final AddressModel asNumbers = AddressModel.fromJson(<String, dynamic>{'region_id': 3, 'city_id': 44});
      final AddressModel asText = AddressModel.fromJson(<String, dynamic>{'region_id': '3', 'city_id': ' 44 '});

      expect(<int?>[asNumbers.regionId, asNumbers.cityId], <int>[3, 44]);
      expect(<int?>[asText.regionId, asText.cityId], <int>[3, 44]);
    });

    test('nought, a negative and anything that is not a number are NO id', () {
      for (final Object? written in <Object?>[0, -1, '0', '-2', '', 'Riyadh', null, <String>[]]) {
        final AddressModel address = AddressModel.fromJson(<String, dynamic>{'region_id': written, 'city_id': written});

        expect(address.regionId, isNull, reason: 'region: $written');
        expect(address.cityId, isNull,
            reason: 'city: $written -- an address kept with an unusable id would match no coverage, and pretending it '
                'had one would hide that');
      }
    });

    test('a district or a National Address with nothing in it is nothing at all', () {
      final AddressModel address = AddressModel.fromJson(<String, dynamic>{'district': '   ', 'national_address': ''});

      expect(address.district, isNull);
      expect(address.nationalAddress, isNull);
    });

    test('a saved address round-trips through the body unchanged', () {
      final Map<String, dynamic> body = AddressModel(regionId: 1, cityId: 21, district: 'Al Olaya', nationalAddress: 'RRRD2929').toJson();
      final AddressModel read = AddressModel.fromJson(body);

      expect(<Object?>[read.regionId, read.cityId, read.district, read.nationalAddress],
          <Object?>[1, 21, 'Al Olaya', 'RRRD2929']);
    });
  });

  group('the form the controller offers', () {
    late _CatalogService service;
    late AddressController controller;

    setUp(() {
      service = _CatalogService();
      controller = AddressController(addressServiceInterface: service);
    });

    test('offers nothing while the catalogue has no rows, so the form is the one it always was', () async {
      await controller.loadAddressRegions();

      expect(controller.addressCatalogIsOffered, isFalse);
      expect(controller.addressRegions, isEmpty);
    });

    test('a chosen region loads its cities, and nothing else', () async {
      service.regions = _riyadhAndMakkah();
      service.citiesByRegion = <int, List<AddressCityModel>>{
        1: <AddressCityModel>[_city(id: 21, regionId: 1, name: 'Riyadh')],
        2: <AddressCityModel>[_city(id: 31, regionId: 2, name: 'Jeddah')],
      };

      await controller.loadAddressRegions();
      await controller.chooseAddressRegion(controller.addressRegions.first);

      expect(service.askedForRegions, <int>[1]);
      expect(controller.addressCities.map((AddressCityModel city) => city.id), <int>[21]);
    });

    test('changing the region forgets the city, so a city of the region just left is never saved against the new one',
        () async {
      service.regions = _riyadhAndMakkah();
      service.citiesByRegion = <int, List<AddressCityModel>>{
        1: <AddressCityModel>[_city(id: 21, regionId: 1, name: 'Riyadh')],
        2: <AddressCityModel>[_city(id: 31, regionId: 2, name: 'Jeddah')],
      };

      await controller.loadAddressRegions();
      await controller.chooseAddressRegion(controller.addressRegions.first);
      controller.chooseAddressCity(controller.addressCities.first);
      expect(controller.chosenCity?.id, 21);

      await controller.chooseAddressRegion(controller.addressRegions.last);

      expect(controller.chosenCity, isNull);
      expect(controller.chosenRegion?.id, 2);
      expect(controller.addressCities.map((AddressCityModel city) => city.id), <int>[31]);
    });

    test('a form opened on an address it is editing starts on the region and the city that address holds', () async {
      service.regions = _riyadhAndMakkah();
      service.citiesByRegion = <int, List<AddressCityModel>>{
        2: <AddressCityModel>[_city(id: 31, regionId: 2, name: 'Jeddah')],
      };

      await controller.loadAddressRegions();
      await controller.seedAddressCatalogChoice(
          AddressModel(regionId: 2, cityId: 31, district: 'Al Hamra', nationalAddress: 'JEDA1234'));

      expect(controller.chosenRegion?.id, 2);
      expect(controller.chosenCity?.id, 31);
      expect(controller.addressDistrict, 'Al Hamra');
      expect(controller.nationalAddress, 'JEDA1234');
    });

    test('a city the catalogue no longer offers is left unchosen rather than guessed at', () async {
      service.regions = _riyadhAndMakkah();
      service.citiesByRegion = <int, List<AddressCityModel>>{
        2: <AddressCityModel>[_city(id: 31, regionId: 2, name: 'Jeddah')],
      };

      await controller.loadAddressRegions();
      await controller.seedAddressCatalogChoice(AddressModel(regionId: 2, cityId: 999));

      expect(controller.chosenRegion?.id, 2, reason: 'the region is still in the catalogue');
      expect(controller.chosenCity, isNull, reason: 'the city is not, so it has to be chosen again');
    });

    test('a region the catalogue no longer offers leaves both unchosen', () async {
      service.regions = _riyadhAndMakkah();

      await controller.loadAddressRegions();
      await controller.seedAddressCatalogChoice(AddressModel(regionId: 777, cityId: 31));

      expect(controller.chosenRegion, isNull);
      expect(controller.chosenCity, isNull);
      expect(service.askedForRegions, isEmpty, reason: 'and no cities were asked for');
    });

    test('a new form forgets what the previous one chose', () async {
      service.regions = _riyadhAndMakkah();
      service.citiesByRegion = <int, List<AddressCityModel>>{
        1: <AddressCityModel>[_city(id: 21, regionId: 1, name: 'Riyadh')],
      };

      await controller.loadAddressRegions();
      await controller.chooseAddressRegion(controller.addressRegions.first);
      controller.chooseAddressCity(controller.addressCities.first);
      controller.writeAddressDistrict('Al Olaya');
      controller.writeNationalAddress('RRRD2929');

      controller.forgetAddressCatalogChoice();

      expect(<Object?>[
        controller.chosenRegion,
        controller.chosenCity,
        controller.addressDistrict,
        controller.nationalAddress,
      ], <Object?>[null, null, null, null]);
      expect(controller.addressCities, isEmpty);
    });

    test('a district typed and then cleared is nothing, not a district whose name is blank', () {
      controller.writeAddressDistrict('Al Olaya');
      controller.writeAddressDistrict('   ');

      expect(controller.addressDistrict, isNull);
    });
  });
}

List<AddressRegionModel> _riyadhAndMakkah() => <AddressRegionModel>[
      const AddressRegionModel(id: 1, code: '01', nameAr: 'الرياض', nameEn: 'Riyadh', name: 'Riyadh'),
      const AddressRegionModel(id: 2, code: '02', nameAr: 'مكة المكرمة', nameEn: 'Makkah', name: 'Makkah'),
    ];

AddressCityModel _city({required int id, required int regionId, required String name}) =>
    AddressCityModel(id: id, regionId: regionId, nameAr: name, nameEn: name, name: name);

/// A service that answers the catalogue from a script and records which regions
/// were asked for. Nothing else of the address service is used by these tests.
class _CatalogService implements AddressServiceInterface {
  List<AddressRegionModel> regions = const <AddressRegionModel>[];
  Map<int, List<AddressCityModel>> citiesByRegion = const <int, List<AddressCityModel>>{};
  final List<int> askedForRegions = <int>[];

  @override
  Future<List<AddressRegionModel>> getAddressRegions() async => regions;

  @override
  Future<List<AddressCityModel>> getAddressCities({int? regionId}) async {
    if (regionId != null) {
      askedForRegions.add(regionId);
    }

    return citiesByRegion[regionId] ?? const <AddressCityModel>[];
  }

  @override
  Future<dynamic> getList({bool fromRemove = false, bool isShipping = false, bool isBilling = false, bool all = false}) =>
      throw UnimplementedError();

  @override
  Future<dynamic> add(AddressModel addressModel) => throw UnimplementedError();

  @override
  Future<dynamic> update(Map<String, dynamic> body, int addressId) => throw UnimplementedError();

  @override
  Future<dynamic> delete(int id) => throw UnimplementedError();

  @override
  List<LabelAsModel> getAddressType() => throw UnimplementedError();

  @override
  Future<dynamic> getDeliveryRestrictedCountryList() => throw UnimplementedError();

  @override
  Future<dynamic> getDeliveryRestrictedZipList() => throw UnimplementedError();

  @override
  Future<dynamic> getDeliveryRestrictedZipBySearch(String zipcode) => throw UnimplementedError();

  @override
  Future<dynamic> getDeliveryRestrictedCountryBySearch(String country) => throw UnimplementedError();
}
