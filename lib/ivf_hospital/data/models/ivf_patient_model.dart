import 'dart:convert';

/// Master Patient & Couple Profile Model
class IvfPatientModel {
  final String uhid;
  final String femaleName;
  final int femaleAge;
  final String femaleBloodGroup;
  final String phone;
  final String? email;
  final String address;
  final String? malePartnerName;
  final int? maleAge;
  final String? maleBloodGroup;
  final String? malePhone;
  final int yearsOfMarriage;
  final String clinicalCategory; // 'IVF', 'INFERTILITY', 'GYNECOLOGY', 'MATERNITY'
  final String infertilityType; // 'Primary Infertility', 'Secondary Infertility', 'N/A'
  final int infertilityDurationYears;
  final String? lmpDate;
  final String obstetricGpla; // e.g. 'G2 P1 L1 A0'
  final String attendingDoctor;
  final String? medicalHistory;
  final String? allergies;
  final DateTime registrationDate;
  final String status; // 'Active Treatment', 'Follow-up', 'Delivered', 'Completed'

  IvfPatientModel({
    required this.uhid,
    required this.femaleName,
    required this.femaleAge,
    required this.femaleBloodGroup,
    required this.phone,
    this.email,
    required this.address,
    this.malePartnerName,
    this.maleAge,
    this.maleBloodGroup,
    this.malePhone,
    this.yearsOfMarriage = 0,
    required this.clinicalCategory,
    this.infertilityType = 'N/A',
    this.infertilityDurationYears = 0,
    this.lmpDate,
    this.obstetricGpla = 'G0 P0 L0 A0',
    required this.attendingDoctor,
    this.medicalHistory,
    this.allergies,
    DateTime? registrationDate,
    this.status = 'Active Treatment',
  }) : registrationDate = registrationDate ?? DateTime.now();

  String get femalePhone => phone;
  String get cycleStatus => status;

  Map<String, dynamic> toMap() {
    return {
      'uhid': uhid,
      'femaleName': femaleName,
      'femaleAge': femaleAge,
      'femaleBloodGroup': femaleBloodGroup,
      'phone': phone,
      'email': email,
      'address': address,
      'malePartnerName': malePartnerName,
      'maleAge': maleAge,
      'maleBloodGroup': maleBloodGroup,
      'malePhone': malePhone,
      'yearsOfMarriage': yearsOfMarriage,
      'clinicalCategory': clinicalCategory,
      'infertilityType': infertilityType,
      'infertilityDurationYears': infertilityDurationYears,
      'lmpDate': lmpDate,
      'obstetricGpla': obstetricGpla,
      'attendingDoctor': attendingDoctor,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'registrationDate': registrationDate.toIso8601String(),
      'status': status,
    };
  }

  factory IvfPatientModel.fromMap(Map<String, dynamic> map) {
    return IvfPatientModel(
      uhid: map['uhid'] ?? '',
      femaleName: map['femaleName'] ?? '',
      femaleAge: map['femaleAge'] ?? 0,
      femaleBloodGroup: map['femaleBloodGroup'] ?? 'B+',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'] ?? '',
      malePartnerName: map['malePartnerName'],
      maleAge: map['maleAge'],
      maleBloodGroup: map['maleBloodGroup'],
      malePhone: map['malePhone'],
      yearsOfMarriage: map['yearsOfMarriage'] ?? 0,
      clinicalCategory: map['clinicalCategory'] ?? 'IVF',
      infertilityType: map['infertilityType'] ?? 'N/A',
      infertilityDurationYears: map['infertilityDurationYears'] ?? 0,
      lmpDate: map['lmpDate'],
      obstetricGpla: map['obstetricGpla'] ?? 'G0 P0 L0 A0',
      attendingDoctor: map['attendingDoctor'] ?? 'Dr. Ananya Sharma (MS, OB-GYN, IVF Spec.)',
      medicalHistory: map['medicalHistory'],
      allergies: map['allergies'],
      registrationDate: map['registrationDate'] != null ? DateTime.parse(map['registrationDate']) : DateTime.now(),
      status: map['status'] ?? 'Active Treatment',
    );
  }

  String toJson() => json.encode(toMap());

  factory IvfPatientModel.fromJson(String source) =>
      IvfPatientModel.fromMap(json.decode(source) as Map<String, dynamic>);

  factory IvfPatientModel.empty() {
    return IvfPatientModel(
      uhid: 'N/A',
      femaleName: 'No Patient Selected',
      femaleAge: 0,
      femaleBloodGroup: 'O+',
      phone: '',
      address: '',
      clinicalCategory: 'IVF',
      attendingDoctor: 'Specialist',
    );
  }
}
