import '../../config/app_constants.dart';

class GuestModel {
  final String id;
  final String organizationId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final VipTier vipTier;
  final String idType; // Passport, Aadhaar, Driving License, Voter ID
  final String idNumber;
  final String? idDocumentUrl;
  final String dietaryPreferences;
  final String specialRequests;
  final int totalStays;

  // Indian Hospitality & Government Statutory Compliance
  final String nationality;
  final String stateOfResidence;
  final String cityOfResidence;
  final String? companyName;
  final String? gstin;

  // FRRO / Bureau of Immigration Form C (Foreigner Registration)
  final String? passportNumber;
  final DateTime? passportExpiryDate;
  final String? visaNumber;
  final String? visaType; // Tourist, Business, Conference, Medical, e-Visa
  final DateTime? visaExpiryDate;
  final String? portOfArrival;
  final DateTime? dateOfArrivalInIndia;
  final DateTime? proposedDepartureDate;

  const GuestModel({
    required this.id,
    required this.organizationId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.vipTier = VipTier.regular,
    this.idType = 'Passport',
    required this.idNumber,
    this.idDocumentUrl,
    this.dietaryPreferences = 'None',
    this.specialRequests = 'High floor, Non-smoking',
    this.totalStays = 1,
    this.nationality = 'Indian',
    this.stateOfResidence = 'Maharashtra',
    this.cityOfResidence = 'Mumbai',
    this.companyName,
    this.gstin,
    this.passportNumber,
    this.passportExpiryDate,
    this.visaNumber,
    this.visaType,
    this.visaExpiryDate,
    this.portOfArrival,
    this.dateOfArrivalInIndia,
    this.proposedDepartureDate,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Complies with UIDAI Aadhaar Act 2016 regulations (masking first 8 digits)
  String get maskedIdNumber {
    final clean = idNumber.replaceAll(' ', '').replaceAll('-', '');
    if (idType.toLowerCase().contains('aadhaar') && clean.length == 12) {
      return 'XXXX-XXXX-${clean.substring(8)}';
    }
    return idNumber;
  }

  /// Whether foreigner registration under Foreigners Act 1946 / Form C is mandated
  bool get isForeigner =>
      nationality.trim().isNotEmpty &&
      nationality.toLowerCase() != 'indian' &&
      nationality.toLowerCase() != 'india';

  factory GuestModel.fromJson(Map<String, dynamic> json) => GuestModel(
    id: json['id'] as String,
    organizationId: json['organization_id'] as String? ?? '',
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String,
    vipTier: VipTier.fromCode(json['vip_tier'] as String? ?? 'regular'),
    idType: json['id_type'] as String? ?? 'Passport',
    idNumber: json['id_number'] as String? ?? '',
    idDocumentUrl: json['id_document_url'] as String?,
    dietaryPreferences: json['dietary_preferences'] as String? ?? 'None',
    specialRequests: json['special_requests'] as String? ?? '',
    totalStays: (json['total_stays'] as num?)?.toInt() ?? 1,
    nationality: json['nationality'] as String? ?? 'Indian',
    stateOfResidence: json['state_of_residence'] as String? ?? 'Maharashtra',
    cityOfResidence: json['city_of_residence'] as String? ?? 'Mumbai',
    companyName: json['company_name'] as String?,
    gstin: json['gstin'] as String?,
    passportNumber: json['passport_number'] as String?,
    passportExpiryDate: json['passport_expiry_date'] != null
        ? DateTime.tryParse(json['passport_expiry_date'] as String)
        : null,
    visaNumber: json['visa_number'] as String?,
    visaType: json['visa_type'] as String?,
    visaExpiryDate: json['visa_expiry_date'] != null
        ? DateTime.tryParse(json['visa_expiry_date'] as String)
        : null,
    portOfArrival: json['port_of_arrival'] as String?,
    dateOfArrivalInIndia: json['date_of_arrival_in_india'] != null
        ? DateTime.tryParse(json['date_of_arrival_in_india'] as String)
        : null,
    proposedDepartureDate: json['proposed_departure_date'] != null
        ? DateTime.tryParse(json['proposed_departure_date'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'vip_tier': vipTier.code,
    'id_type': idType,
    'id_number': idNumber,
    'id_document_url': idDocumentUrl,
    'dietary_preferences': dietaryPreferences,
    'special_requests': specialRequests,
    'total_stays': totalStays,
    'nationality': nationality,
    'state_of_residence': stateOfResidence,
    'city_of_residence': cityOfResidence,
    'company_name': companyName,
    'gstin': gstin,
    'passport_number': passportNumber,
    'passport_expiry_date': passportExpiryDate?.toIso8601String(),
    'visa_number': visaNumber,
    'visa_type': visaType,
    'visa_expiry_date': visaExpiryDate?.toIso8601String(),
    'port_of_arrival': portOfArrival,
    'date_of_arrival_in_india': dateOfArrivalInIndia?.toIso8601String(),
    'proposed_departure_date': proposedDepartureDate?.toIso8601String(),
  };

  Map<String, dynamic> toSupabaseJson() => {
    'id': id,
    'organization_id': organizationId.isNotEmpty ? organizationId : 'org-taj-imperial',
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'vip_tier': vipTier.code,
    'id_type': idType,
    'id_number': idNumber,
    'dietary_preferences': dietaryPreferences,
    'special_requests': specialRequests,
    'total_stays': totalStays,
    'nationality': nationality,
    'state_of_residence': stateOfResidence,
    'city_of_residence': cityOfResidence,
    'company_name': companyName,
    'gstin': gstin,
    'passport_number': passportNumber,
    'visa_number': visaNumber,
    'port_of_arrival': portOfArrival,
  };
}
