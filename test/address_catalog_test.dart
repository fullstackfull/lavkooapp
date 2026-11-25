import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syriapharmacy/features/address/address_catalog_config.dart';
import 'package:syriapharmacy/features/address/domain/models/address_catalog_models.dart';

/// The central address catalogue the platform keys coverage by (J-14).
///
/// The platform's one rule about addresses is that **ids are the keys and names never are**: a courier's coverage, a warehouse and a
/// marketplace are mapped to a city by its id, so an address that keeps its city as text can be checked against none of them. These read
/// the catalogue the way the app must: a row without a usable id is not offered, because choosing it would save an address that matches no
/// coverage, and everything else is kept in the order the server sent.
void main() {
  group('the regions the server sends', () {
    test('are read with their ids, their codes and both names', () {
      final List<AddressRegionModel> regions = AddressRegionModel.listFrom(jsonDecode(
        '{"regions":[{"id":1,"code":"01","name_ar":"الرياض","name_en":"Riyadh","name":"Riyadh"},'
        '{"id":2,"code":"02","name_ar":"مكة المكرمة","name_en":"Makkah","name":"Makkah"}]}',
      ));

      expect(regions.length, 2);
      expect(regions.first.id, 1);
      expect(regions.first.code, '01');
      expect(regions.first.nameAr, 'الرياض');
      expect(regions.first.nameEn, 'Riyadh');
      expect(regions.first.name, 'Riyadh', reason: 'the server already chose the name for the language of the request');
    });

    test('keep the order the server chose, because it sorted the catalogue', () {
      final List<AddressRegionModel> regions = AddressRegionModel.listFrom(jsonDecode(
        '{"regions":[{"id":9,"name_en":"Tabuk"},{"id":1,"name_en":"Riyadh"},{"id":5,"name_en":"Asir"}]}',
      ));

      expect(regions.map((AddressRegionModel region) => region.id).toList(), <int>[9, 1, 5]);
    });

    test('drop a row with no usable id rather than offering a region nothing can be matched by', () {
      final List<AddressRegionModel> regions = AddressRegionModel.listFrom(jsonDecode(
        '{"regions":[{"id":1,"name_en":"Riyadh"},{"name_en":"No id"},{"id":0,"name_en":"Zero"},'
        '{"id":-3,"name_en":"Negative"},{"id":"4","name_en":"As text"},"not a row",null]}',
      ));

      expect(
        regions.map((AddressRegionModel region) => region.id).toList(),
        <int>[1, 4],
        reason: 'an id written as text is an id; nought, a negative and a missing one are not',
      );
    });

    test('fall back to a name the row does carry when the server named none', () {
      final List<AddressRegionModel> regions = AddressRegionModel.listFrom(jsonDecode(
        '{"regions":[{"id":1,"name_ar":"الرياض","name_en":"Riyadh"},{"id":2,"name_ar":"جازان"}]}',
      ));

      expect(regions.first.name, 'Riyadh');
      expect(regions.last.name, 'جازان', reason: 'a row with only the Arabic name is shown in Arabic rather than blank');
    });

    test('are none when the answer is not a catalogue at all, and nothing throws', () {
      for (final String body in <String>['{}', '{"regions":null}', '{"regions":"none"}', '[]', 'null', '"text"', '7']) {
        expect(AddressRegionModel.listFrom(jsonDecode(body)), isEmpty, reason: body);
      }
    });
  });

  group('the cities the server sends', () {
    test('are read with their ids and the region they belong to', () {
      final List<AddressCityModel> cities = AddressCityModel.listFrom(jsonDecode(
        '{"cities":[{"id":41125,"region_id":1,"name_ar":"الرياض","name_en":"Riyadh","name":"Riyadh"},'
        '{"id":50001,"region_id":5,"name_ar":"أبها","name_en":"Abha","name":"Abha"}]}',
      ));

      expect(cities.length, 2);
      expect(cities.first.id, 41125);
      expect(cities.first.regionId, 1);
      expect(cities.last.nameAr, 'أبها');
    });

    test('keep a city whose region the server did not name, because the city id is the key', () {
      final List<AddressCityModel> cities =
          AddressCityModel.listFrom(jsonDecode('{"cities":[{"id":41125,"name_en":"Riyadh"}]}'));

      expect(cities.single.id, 41125);
      expect(cities.single.regionId, 0, reason: 'nought means the server named no region, and the city is still usable');
    });

    test('drop a row with no usable id', () {
      final List<AddressCityModel> cities = AddressCityModel.listFrom(jsonDecode(
        '{"cities":[{"id":41125,"name_en":"Riyadh"},{"region_id":1,"name_en":"No id"},{"id":"50001","name_en":"As text"}]}',
      ));

      expect(cities.map((AddressCityModel city) => city.id).toList(), <int>[41125, 50001]);
    });

    test('are none when the answer carries no cities', () {
      for (final String body in <String>['{}', '{"cities":{}}', '{"regions":[]}', 'null']) {
        expect(AddressCityModel.listFrom(jsonDecode(body)), isEmpty, reason: body);
      }
    });
  });

  /// The switch is a compile-time constant, so each of these holds in one build
  /// and is skipped in the other -- the way every other flag of this app is
  /// tested. The readers above are run in both builds and do not depend on it:
  /// a row with no usable id is dropped either way.
  group('the switch', () {
    test(
      'is off in a build that did not ask for the catalogue, which is every build that ships',
      () => expect(
        AddressCatalogConfig.enabled,
        isFalse,
        reason: 'the catalogue ships dark: the address form is the one this app has always had until a build asks for it',
      ),
      skip: AddressCatalogConfig.enabled ? 'this build asked for the catalogue' : null,
    );

    test(
      'is on in a build made with the dart-define, and only then',
      () => expect(AddressCatalogConfig.enabled, isTrue),
      skip: AddressCatalogConfig.enabled ? null : 'this build did not ask for the catalogue',
    );
  });
}
