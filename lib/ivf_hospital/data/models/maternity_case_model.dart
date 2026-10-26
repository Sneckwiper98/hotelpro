import 'dart:convert';

/// Maternity, Labour, Delivery & Newborn Management Model
class MaternityCaseModel {
  final String caseId;
  final String patientUhid;
  final String patientName;
  final DateTime lmp;
  final DateTime edd;
  final int gravida;
  final int para;
  final bool isIvfConception;
  final String highRiskCondition; // 'Low Risk', 'GDM', 'Preeclampsia', 'Previous LSCS', 'Twin Gestation'
  final String? wardBed; // e.g. 'Maternity Ward - Bed 102'
  final DateTime? admissionDate;
  final DateTime? labourStartTime;
  final double? cervicalDilationCm;
  final int? fetalHeartRateBpm;
  final DateTime? deliveryDate;
  final String deliveryType; // 'Normal Vaginal', 'Elective LSCS', 'Emergency LSCS', 'Assisted Vacuum'
  final String attendingObstetrician;
  final String attendingPediatrician;
  final String? babyGender; // 'Female', 'Male', 'Twins'
  final double? birthWeightKg;
  final int? apgar1Min;
  final int? apgar5Min;
  final bool vaccineBcgGiven;
  final bool vaccineOpv0Given;
  final bool vaccineHepBGiven;
  final String caseStatus; // 'Antenatal Care', 'In Labour', 'Delivered & Postnatal', 'Discharged'

  MaternityCaseModel({
    required this.caseId,
    required this.patientUhid,
    required this.patientName,
    required this.lmp,
    required this.edd,
    this.gravida = 1,
    this.para = 0,
    this.isIvfConception = true,
    this.highRiskCondition = 'Low Risk',
    this.wardBed,
    this.admissionDate,
    this.labourStartTime,
    this.cervicalDilationCm,
    this.fetalHeartRateBpm,
    this.deliveryDate,
    this.deliveryType = 'Normal Vaginal',
    this.attendingObstetrician = 'Dr. Sunita Deshmukh (MD, DGO, Obstetrician)',
    this.attendingPediatrician = 'Dr. Anand Verma (MD, Pediatrics / Neonatologist)',
    this.babyGender,
    this.birthWeightKg,
    this.apgar1Min,
    this.apgar5Min,
    this.vaccineBcgGiven = false,
    this.vaccineOpv0Given = false,
    this.vaccineHepBGiven = false,
    this.caseStatus = 'Antenatal Care',
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'patientUhid': patientUhid,
      'patientName': patientName,
      'lmp': lmp.toIso8601String(),
      'edd': edd.toIso8601String(),
      'gravida': gravida,
      'para': para,
      'isIvfConception': isIvfConception,
      'highRiskCondition': highRiskCondition,
      'wardBed': wardBed,
      'admissionDate': admissionDate?.toIso8601String(),
      'labourStartTime': labourStartTime?.toIso8601String(),
      'cervicalDilationCm': cervicalDilationCm,
      'fetalHeartRateBpm': fetalHeartRateBpm,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'deliveryType': deliveryType,
      'attendingObstetrician': attendingObstetrician,
      'attendingPediatrician': attendingPediatrician,
      'babyGender': babyGender,
      'birthWeightKg': birthWeightKg,
      'apgar1Min': apgar1Min,
      'apgar5Min': apgar5Min,
      'vaccineBcgGiven': vaccineBcgGiven,
      'vaccineOpv0Given': vaccineOpv0Given,
      'vaccineHepBGiven': vaccineHepBGiven,
      'caseStatus': caseStatus,
    };
  }

  factory MaternityCaseModel.fromMap(Map<String, dynamic> map) {
    return MaternityCaseModel(
      caseId: map['caseId'] ?? '',
      patientUhid: map['patientUhid'] ?? '',
      patientName: map['patientName'] ?? '',
      lmp: map['lmp'] != null ? DateTime.parse(map['lmp']) : DateTime.now(),
      edd: map['edd'] != null ? DateTime.parse(map['edd']) : DateTime.now().add(const Duration(days: 280)),
      gravida: map['gravida'] ?? 1,
      para: map['para'] ?? 0,
      isIvfConception: map['isIvfConception'] ?? true,
      highRiskCondition: map['highRiskCondition'] ?? 'Low Risk',
      wardBed: map['wardBed'],
      admissionDate: map['admissionDate'] != null ? DateTime.parse(map['admissionDate']) : null,
      labourStartTime: map['labourStartTime'] != null ? DateTime.parse(map['labourStartTime']) : null,
      cervicalDilationCm: map['cervicalDilationCm'] != null ? (map['cervicalDilationCm'] as num).toDouble() : null,
      fetalHeartRateBpm: map['fetalHeartRateBpm'],
      deliveryDate: map['deliveryDate'] != null ? DateTime.parse(map['deliveryDate']) : null,
      deliveryType: map['deliveryType'] ?? 'Normal Vaginal',
      attendingObstetrician: map['attendingObstetrician'] ?? '',
      attendingPediatrician: map['attendingPediatrician'] ?? '',
      babyGender: map['babyGender'],
      birthWeightKg: map['birthWeightKg'] != null ? (map['birthWeightKg'] as num).toDouble() : null,
      apgar1Min: map['apgar1Min'],
      apgar5Min: map['apgar5Min'],
      vaccineBcgGiven: map['vaccineBcgGiven'] ?? false,
      vaccineOpv0Given: map['vaccineOpv0Given'] ?? false,
      vaccineHepBGiven: map['vaccineHepBGiven'] ?? false,
      caseStatus: map['caseStatus'] ?? 'Antenatal Care',
    );
  }

  String toJson() => json.encode(toMap());

  factory MaternityCaseModel.fromJson(String source) =>
      MaternityCaseModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
