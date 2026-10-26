import 'dart:convert';

/// Hospital Branch Model for Multi-Branch IVF & Maternity Groups
class HospitalBranchModel {
  final String branchId;
  final String branchName;
  final String address;
  final String city;
  final String phone;
  final String inChargeDoctor;
  final String artClinicRegNumber;
  final bool isMainBranch;

  HospitalBranchModel({
    required this.branchId,
    required this.branchName,
    required this.address,
    required this.city,
    required this.phone,
    required this.inChargeDoctor,
    required this.artClinicRegNumber,
    this.isMainBranch = false,
  });

  String get doctorInCharge => inChargeDoctor;

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'address': address,
      'city': city,
      'phone': phone,
      'inChargeDoctor': inChargeDoctor,
      'artClinicRegNumber': artClinicRegNumber,
      'isMainBranch': isMainBranch,
    };
  }

  factory HospitalBranchModel.fromMap(Map<String, dynamic> map) {
    return HospitalBranchModel(
      branchId: map['branchId'] ?? 'BR-01',
      branchName: map['branchName'] ?? 'Main Hospital & IVF Center',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      phone: map['phone'] ?? '',
      inChargeDoctor: map['inChargeDoctor'] ?? 'Dr. Sunita Rao, MD',
      artClinicRegNumber: map['artClinicRegNumber'] ?? '',
      isMainBranch: map['isMainBranch'] ?? false,
    );
  }
}

/// Whitelabel Configuration Model for IVFPro 360 Enterprise
/// Enables selling this software to any IVF / Maternity Hospital with Multi-Branch & Custom Logo
class HospitalConfigModel {
  String hospitalName;
  String tagline;
  String technologyPartner;
  String logoPathOrUrl; // Custom Logo URL, Path, or Preset
  String address;
  String city;
  String state;
  String stateCode;
  String pincode;
  String phone;
  String emergencyHelpline;
  String email;
  String website;
  String gstin;
  String pan;
  String artClinicRegNumber; // National ART Act 2021 Registration No
  String clinicalEstRegNumber;
  String currencySymbol;
  String invoicePrefix;
  String patientIdPrefix;
  String ivfCyclePrefix;
  String supabaseUrl;
  String supabaseAnonKey;
  bool isCloudSyncEnabled;
  String licenseKey;
  String licenseStatus; // 'ACTIVE', 'TRIAL', 'EXPIRED'

  // Multi-Branch Architecture
  String _activeBranchId;
  String get activeBranchId => _activeBranchId.isEmpty ? 'BR-01' : _activeBranchId;
  set activeBranchId(String val) => _activeBranchId = val;

  static List<HospitalBranchModel> get defaultBranches => [
    HospitalBranchModel(
      branchId: 'BR-01',
      branchName: 'Central Nagpur Main Campus & IVF Center',
      address: 'Station Road, Opp. Civil Hospital',
      city: 'Nagpur',
      phone: '+91 712 2554433',
      inChargeDoctor: 'Dr. Sunita Rao, MD (OBGYN, IVF Specialist)',
      artClinicRegNumber: 'ART/MH/NAG/2024/0089',
      isMainBranch: true,
    ),
    HospitalBranchModel(
      branchId: 'BR-02',
      branchName: 'Dharampeth Satellite Clinic & DayCare',
      address: 'Plot 42, West High Court Road, Dharampeth',
      city: 'Nagpur',
      phone: '+91 712 2598811',
      inChargeDoctor: 'Dr. Rajesh Deshmukh, MS (OBGYN)',
      artClinicRegNumber: 'ART/MH/NAG/2024/0089-B2',
      isMainBranch: false,
    ),
    HospitalBranchModel(
      branchId: 'BR-03',
      branchName: 'Wardha Road Fertility Care Branch',
      address: 'Near Metro Pillar 118, Somalwada, Wardha Road',
      city: 'Nagpur',
      phone: '+91 712 2671122',
      inChargeDoctor: 'Dr. Anjali Mehta, DNB, ART Specialist',
      artClinicRegNumber: 'ART/MH/NAG/2024/0089-B3',
      isMainBranch: false,
    ),
  ];

  List<HospitalBranchModel> _branches;
  List<HospitalBranchModel> get branches =>
      _branches.isNotEmpty ? _branches : defaultBranches;
  set branches(List<HospitalBranchModel>? val) {
    if (val != null && val.isNotEmpty) {
      _branches = val;
    } else {
      _branches = defaultBranches;
    }
  }

  HospitalConfigModel({
    this.hospitalName = 'Shri Radhakrishna Hospital & Infertility Centre',
    this.tagline = 'Gynecology • Infertility • IVF • Maternity',
    this.technologyPartner = 'iSecure System Pvt. Ltd.',
    this.logoPathOrUrl = 'preset:fertility_lotus', // Default built-in medical IVF emblem
    this.address = 'Station Road, Opp. Civil Hospital',
    this.city = 'Nagpur',
    this.state = 'Maharashtra',
    this.stateCode = '27',
    this.pincode = '440001',
    this.phone = '+91 712 2554433',
    this.emergencyHelpline = '+91 98220 12345',
    this.email = 'care@radhakrishnahospital.in',
    this.website = 'www.radhakrishnahospital.in',
    this.gstin = '27AABCS1482K1Z5',
    this.pan = 'AABCS1482K',
    this.artClinicRegNumber = 'ART/MH/NAG/2024/0089',
    this.clinicalEstRegNumber = 'CEA/MH/2022/4119',
    this.currencySymbol = '₹',
    this.invoicePrefix = 'SRH-INV-',
    this.patientIdPrefix = 'SRH-P-',
    this.ivfCyclePrefix = 'IVF-2026-',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.isCloudSyncEnabled = false,
    this.licenseKey = 'ISECURE-IVFPRO-ENT-2026-COMMERCIAL',
    this.licenseStatus = 'ACTIVE',
    String? activeBranchId,
    List<HospitalBranchModel>? branches,
  })  : _activeBranchId = activeBranchId ?? 'BR-01',
        _branches = (branches != null && branches.isNotEmpty)
            ? branches
            : defaultBranches;

  HospitalBranchModel get activeBranch {
    final list = branches;
    return list.firstWhere(
      (b) => b.branchId == activeBranchId,
      orElse: () => list.first,
    );
  }

  String get hospitalLogoUrl => logoPathOrUrl;

  Map<String, dynamic> toMap() {
    return {
      'hospitalName': hospitalName,
      'tagline': tagline,
      'technologyPartner': technologyPartner,
      'logoPathOrUrl': logoPathOrUrl,
      'address': address,
      'city': city,
      'state': state,
      'stateCode': stateCode,
      'pincode': pincode,
      'phone': phone,
      'emergencyHelpline': emergencyHelpline,
      'email': email,
      'website': website,
      'gstin': gstin,
      'pan': pan,
      'artClinicRegNumber': artClinicRegNumber,
      'clinicalEstRegNumber': clinicalEstRegNumber,
      'currencySymbol': currencySymbol,
      'invoicePrefix': invoicePrefix,
      'patientIdPrefix': patientIdPrefix,
      'ivfCyclePrefix': ivfCyclePrefix,
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
      'isCloudSyncEnabled': isCloudSyncEnabled,
      'licenseKey': licenseKey,
      'licenseStatus': licenseStatus,
      'activeBranchId': activeBranchId,
      'branches': branches.map((b) => b.toMap()).toList(),
    };
  }

  factory HospitalConfigModel.fromMap(Map<String, dynamic> map) {
    return HospitalConfigModel(
      hospitalName: map['hospitalName'] ?? 'Shri Radhakrishna Hospital & Infertility Centre',
      tagline: map['tagline'] ?? 'Gynecology • Infertility • IVF • Maternity',
      technologyPartner: map['technologyPartner'] ?? 'iSecure System Pvt. Ltd.',
      logoPathOrUrl: map['logoPathOrUrl'] ?? 'preset:fertility_lotus',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      stateCode: map['stateCode'] ?? '27',
      pincode: map['pincode'] ?? '',
      phone: map['phone'] ?? '',
      emergencyHelpline: map['emergencyHelpline'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      gstin: map['gstin'] ?? '',
      pan: map['pan'] ?? '',
      artClinicRegNumber: map['artClinicRegNumber'] ?? '',
      clinicalEstRegNumber: map['clinicalEstRegNumber'] ?? '',
      currencySymbol: map['currencySymbol'] ?? '₹',
      invoicePrefix: map['invoicePrefix'] ?? 'SRH-INV-',
      patientIdPrefix: map['patientIdPrefix'] ?? 'SRH-P-',
      ivfCyclePrefix: map['ivfCyclePrefix'] ?? 'IVF-2026-',
      supabaseUrl: map['supabaseUrl'] ?? '',
      supabaseAnonKey: map['supabaseAnonKey'] ?? '',
      isCloudSyncEnabled: map['isCloudSyncEnabled'] ?? false,
      licenseKey: map['licenseKey'] ?? '',
      licenseStatus: map['licenseStatus'] ?? 'ACTIVE',
      activeBranchId: map['activeBranchId']?.toString() ?? 'BR-01',
      branches: (map['branches'] != null && map['branches'] is List && (map['branches'] as List).isNotEmpty)
          ? (map['branches'] as List)
              .where((b) => b != null)
              .map((b) => HospitalBranchModel.fromMap(Map<String, dynamic>.from(b as Map)))
              .toList()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory HospitalConfigModel.fromJson(String source) =>
      HospitalConfigModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
