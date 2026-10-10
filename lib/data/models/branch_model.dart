class BranchModel {
  final String id;
  final String organizationId;
  final String name;
  final String code;
  final int starRating; // 3 or 5
  final String city;
  final String state;
  final String address;
  final String phone;
  final String email;
  final String currency;
  final String taxIdentifier; // GSTIN / VAT
  final String checkInTime;
  final String checkOutTime;
  final List<String> amenities;
  final int totalRooms;

  const BranchModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.starRating,
    required this.city,
    required this.state,
    required this.address,
    required this.phone,
    required this.email,
    this.currency = 'INR',
    required this.taxIdentifier,
    this.checkInTime = '14:00',
    this.checkOutTime = '11:00',
    required this.amenities,
    required this.totalRooms,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'name': name,
    'code': code,
    'star_rating': starRating,
    'city': city,
    'state': state,
    'address': address,
    'phone': phone,
    'email': email,
    'currency': currency,
    'tax_identifier': taxIdentifier,
    'check_in_time': checkInTime,
    'check_out_time': checkOutTime,
    'amenities': amenities,
    'total_rooms': totalRooms,
  };

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String? ?? '',
    name: json['name'] as String,
    code: json['code'] as String,
    starRating: (json['star_rating'] as num?)?.toInt() ?? 5,
    city: json['city'] as String,
    state: json['state'] as String,
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    currency: json['currency'] as String? ?? 'INR',
    taxIdentifier: json['tax_identifier'] as String? ?? '',
    checkInTime: json['check_in_time'] as String? ?? '14:00',
    checkOutTime: json['check_out_time'] as String? ?? '11:00',
    amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    totalRooms: (json['total_rooms'] as num?)?.toInt() ?? 0,
  );

  BranchModel copyWith({
    String? name,
    String? code,
    int? starRating,
    String? city,
    String? state,
    String? address,
    String? phone,
    String? email,
    String? currency,
    String? taxIdentifier,
    String? checkInTime,
    String? checkOutTime,
    List<String>? amenities,
    int? totalRooms,
  }) {
    return BranchModel(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      code: code ?? this.code,
      starRating: starRating ?? this.starRating,
      city: city ?? this.city,
      state: state ?? this.state,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      taxIdentifier: taxIdentifier ?? this.taxIdentifier,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      amenities: amenities ?? this.amenities,
      totalRooms: totalRooms ?? this.totalRooms,
    );
  }
}
