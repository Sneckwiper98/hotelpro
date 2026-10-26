import 'dart:convert';

/// Whitelabel Configuration Model for IVFPro 360 Enterprise
/// Enables selling this software to any IVF / Maternity Hospital
class HospitalConfigModel {
  String hospitalName;
  String tagline;
  String technologyPartner;
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
  String artClinicRegNumber; // ART Act 2021 Registration No
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

  HospitalConfigModel({
    this.hospitalName = 'Shri Radhakrishna Hospital & Infertility Centre',
    this.tagline = 'Gynecology • Infertility • IVF • Maternity',
    this.technologyPartner = 'iSecure System Pvt. Ltd.',
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
  });

  Map<String, dynamic> toMap() {
    return {
      'hospitalName': hospitalName,
      'tagline': tagline,
      'technologyPartner': technologyPartner,
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
    };
  }

  factory HospitalConfigModel.fromMap(Map<String, dynamic> map) {
    return HospitalConfigModel(
      hospitalName: map['hospitalName'] ?? 'Shri Radhakrishna Hospital & Infertility Centre',
      tagline: map['tagline'] ?? 'Gynecology • Infertility • IVF • Maternity',
      technologyPartner: map['technologyPartner'] ?? 'iSecure System Pvt. Ltd.',
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
    );
  }

  String toJson() => json.encode(toMap());

  factory HospitalConfigModel.fromJson(String source) =>
      HospitalConfigModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
