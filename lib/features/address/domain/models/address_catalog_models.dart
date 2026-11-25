/// The central address catalogue of the platform: the regions and cities an
/// address is built from, by their ids (J-14).
///
/// The platform's one rule about addresses is that **ids are the keys and names
/// never are**. A courier's coverage, a warehouse and a marketplace are all
/// mapped to a city by its id, so an address that keeps the city as text cannot
/// be checked against any of them. This is the app's side of that: a region and
/// a city as the server numbers them, with both names carried for display and
/// neither used to match anything.
///
/// Both names arrive on every row, and `name` is the one the server already
/// chose for the language of the request. The app shows `name` and keeps the
/// other two so that a form can label a row in the other language without
/// asking again.
class AddressRegionModel {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;

  /// The name in the language the request asked for, chosen by the server.
  final String name;

  const AddressRegionModel({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.name,
  });

  /// One row of `GET /api/v1/address/regions`, or null when it carries no id:
  /// a row the app cannot name by its id is a row it must not offer, because
  /// choosing it would save an address that matches no coverage.
  static AddressRegionModel? fromJson(Object? row) {
    if (row is! Map) {
      return null;
    }

    final int? id = _id(row['id']);

    if (id == null) {
      return null;
    }

    final String nameAr = _text(row['name_ar']);
    final String nameEn = _text(row['name_en']);

    return AddressRegionModel(
      id: id,
      code: _text(row['code']),
      nameAr: nameAr,
      nameEn: nameEn,
      name: _text(row['name']).isEmpty ? (nameEn.isEmpty ? nameAr : nameEn) : _text(row['name']),
    );
  }

  /// Every readable row of the answer, in the order the server sent them.
  ///
  /// The server's order is the order a person expects to read -- it sorts the
  /// catalogue -- so the app never re-sorts it. A row that cannot be read is
  /// dropped rather than making the whole list fail: a catalogue with one bad
  /// row is still a catalogue, and refusing all of it would leave the customer
  /// with no form at all.
  static List<AddressRegionModel> listFrom(Object? body) {
    final Object? rows = body is Map ? body['regions'] : null;

    if (rows is! List) {
      return const <AddressRegionModel>[];
    }

    return rows.map(AddressRegionModel.fromJson).whereType<AddressRegionModel>().toList();
  }
}

/// A city of the catalogue, which is what a courier's coverage is keyed by.
class AddressCityModel {
  final int id;
  final int regionId;
  final String nameAr;
  final String nameEn;
  final String name;

  const AddressCityModel({
    required this.id,
    required this.regionId,
    required this.nameAr,
    required this.nameEn,
    required this.name,
  });

  static AddressCityModel? fromJson(Object? row) {
    if (row is! Map) {
      return null;
    }

    final int? id = _id(row['id']);

    if (id == null) {
      return null;
    }

    final String nameAr = _text(row['name_ar']);
    final String nameEn = _text(row['name_en']);

    return AddressCityModel(
      id: id,
      regionId: _id(row['region_id']) ?? 0,
      nameAr: nameAr,
      nameEn: nameEn,
      name: _text(row['name']).isEmpty ? (nameEn.isEmpty ? nameAr : nameEn) : _text(row['name']),
    );
  }

  static List<AddressCityModel> listFrom(Object? body) {
    final Object? rows = body is Map ? body['cities'] : null;

    if (rows is! List) {
      return const <AddressCityModel>[];
    }

    return rows.map(AddressCityModel.fromJson).whereType<AddressCityModel>().toList();
  }
}

/// An id as the server writes it, whether as a number or as text, or null when
/// it is neither.
int? _id(Object? value) {
  if (value is int) {
    return value > 0 ? value : null;
  }
  if (value is num) {
    return value > 0 ? value.toInt() : null;
  }

  final int? parsed = value is String ? int.tryParse(value.trim()) : null;

  return parsed != null && parsed > 0 ? parsed : null;
}

String _text(Object? value) => value is String ? value.trim() : '';
