import '../../config/app_constants.dart';

class GuestModel {
  final String id;
  final String organizationId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final VipTier vipTier;
  final String idType; // Passport, Aadhaar, Driving License
  final String idNumber;
  final String? idDocumentUrl;
  final String dietaryPreferences;
  final String specialRequests;
  final int totalStays;

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
  });

  String get fullName => '$firstName $lastName'.trim();

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
  };
}
