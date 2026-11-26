/// A saved address.
///
/// It carries the free-text fields it always carried AND, for a Saudi address
/// built from the central catalogue, the four structured ones: the region and
/// the city as ids, the district, and the National Address (J-14).
///
/// **The ids are the keys and the names never are.** A courier's coverage, a
/// warehouse and a marketplace are all mapped to a city by its id, so an address
/// that keeps only the city as text cannot be checked against any of them. The
/// text is kept beside the ids and not replaced by them, because the platform's
/// `unified_address_mode` has a `soft` state in which both are stored and
/// nothing is lost either way, and because `zip` is never derived from the
/// National Address.
///
/// All four are null on an address that has none, and a null is left out of the
/// body rather than sent as one: a server that cannot store these must see the
/// request it has always seen.
class AddressModel {
  int? id;
  String? contactPersonName;
  String? addressType;
  String? address;
  String? city;
  String? zip;
  String? phone;
  String? createdAt;
  String? updatedAt;
  String? state;
  String? country;
  String? latitude;
  String? longitude;
  bool? isBilling;
  String? guestId;
  String? email;

  /// The region of the central catalogue, by its id.
  int? regionId;

  /// The city of the central catalogue, by its id. This is what coverage is keyed by.
  int? cityId;
  String? district;
  String? nationalAddress;
  AddressModel({
    this.id,
    this.contactPersonName,
    this.addressType,
    this.address,
    this.city,
    this.zip,
    this.phone,
    this.createdAt,
    this.updatedAt,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.isBilling,
    this.guestId,
    this.email,
    this.regionId,
    this.cityId,
    this.district,
    this.nationalAddress,
  });

  AddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    contactPersonName = json['contact_person_name'];
    addressType = json['address_type'];
    address = json['address'];
    city = json['city'];
    zip = json['zip'];
    phone = json['phone'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    state = json['state'];
    country = json['country'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    isBilling = json['is_billing'] ?? false;
    email = json['email'];
    regionId = _identifier(json['region_id']);
    cityId = _identifier(json['city_id']);
    district = _text(json['district']);
    nationalAddress = _text(json['national_address']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['contact_person_name'] = contactPersonName;
    data['address_type'] = addressType;
    data['address'] = address;
    data['city'] = city;
    data['zip'] = zip;
    data['phone'] = phone;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['state'] = state;
    data['country'] = country;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['is_billing'] = isBilling;
    data['guest_id'] = guestId;
    data['email'] = email;
    // Left out entirely when there is none, rather than sent as a null: a store whose address
    // migrations have not run must see exactly the request it has always seen.
    if (regionId != null) data['region_id'] = regionId;
    if (cityId != null) data['city_id'] = cityId;
    if (district != null) data['district'] = district;
    if (nationalAddress != null) data['national_address'] = nationalAddress;
    return data;
  }

  /// An id as the server writes it, whether as a number or as text. Nought, a
  /// negative and anything that is not a number are no id: an address that kept
  /// one of those could not be matched against any coverage, and pretending it
  /// had an id would hide that.
  static int? _identifier(Object? value) {
    final int? parsed = value is int
        ? value
        : value is num
            ? value.toInt()
            : value is String
                ? int.tryParse(value.trim())
                : null;

    return parsed != null && parsed > 0 ? parsed : null;
  }

  /// Text with nothing in it is nothing at all, so that an empty district does
  /// not read as a district whose name is blank.
  static String? _text(Object? value) {
    final String text = value is String ? value.trim() : '';

    return text.isEmpty ? null : text;
  }
}
