import 'dart:convert';

/// IVF & Assisted Reproductive Technology (ART) Treatment Cycle Model
class IvfCycleModel {
  final String cycleId;
  final String patientUhid;
  final String patientName;
  final String cycleType; // 'IVF', 'ICSI', 'FET', 'IUI', 'Egg Freezing'
  final String protocol; // 'Antagonist Protocol', 'Long Agonist Protocol', 'Mild Stimulation', 'Natural Cycle'
  final DateTime startDate;
  int stimulationDays;
  String stimulationMedications; // e.g. 'Rec-FSH 225 IU + HMG 75 IU'
  String rightOvaryFollicles; // e.g. '18mm, 17mm, 15mm, 14mm'
  String leftOvaryFollicles; // e.g. '19mm, 16mm, 15mm'
  double endometrialThicknessMm;
  DateTime? triggerDate;
  String triggerMedicine; // 'Inj. Ovitrelle 250mcg / Decapeptyl'
  DateTime? opuDate;
  int totalOocytesRetrieved;
  int m2Oocytes;
  int m1Oocytes;
  int gvOocytes;
  String semenSampleType; // 'Fresh Partner', 'Frozen Partner', 'Donor Sperm'
  int fertilization2pnCount;
  int day3CleavageCount;
  int day5BlastocystCount;
  String blastocystGrading; // e.g. '4AA, 4AB, 3BB'
  DateTime? embryoTransferDate;
  String transferType; // 'Fresh Transfer', 'FET - Frozen Embryo Transfer'
  int embryosTransferredCount;
  int embryosFrozenCount;
  String cryoStorageLocation; // e.g. 'Tank-2, Canister-4, Straw #8821'
  double? betaHcgValue; // mIU/mL
  String cycleOutcome; // 'Stimulation', 'OPU Done', 'Culturing', 'FET Scheduled', 'Positive (Pregnant)', 'Negative'
  String attendingDoctor;
  String attendingEmbryologist;

  IvfCycleModel({
    required this.cycleId,
    required this.patientUhid,
    required this.patientName,
    this.cycleType = 'ICSI',
    this.protocol = 'Antagonist Protocol',
    required this.startDate,
    this.stimulationDays = 10,
    this.stimulationMedications = 'Inj. Gonal-F 225 IU + Menopur 75 IU',
    this.rightOvaryFollicles = '19mm, 18mm, 16mm, 14mm',
    this.leftOvaryFollicles = '20mm, 17mm, 16mm, 15mm',
    this.endometrialThicknessMm = 9.4,
    this.triggerDate,
    this.triggerMedicine = 'Inj. Ovitrelle 250 mcg hCG',
    this.opuDate,
    this.totalOocytesRetrieved = 14,
    this.m2Oocytes = 11,
    this.m1Oocytes = 2,
    this.gvOocytes = 1,
    this.semenSampleType = 'Fresh Partner',
    this.fertilization2pnCount = 9,
    this.day3CleavageCount = 8,
    this.day5BlastocystCount = 5,
    this.blastocystGrading = '4AA, 4AB, 4BB, 3BB, 3BC',
    this.embryoTransferDate,
    this.transferType = 'FET - Frozen Embryo Transfer',
    this.embryosTransferredCount = 1,
    this.embryosFrozenCount = 4,
    this.cryoStorageLocation = 'Cryo Tank 2 • Canister 3 • Goblet Green #412',
    this.betaHcgValue,
    this.cycleOutcome = 'Positive (Pregnant)',
    this.attendingDoctor = 'Dr. Ananya Sharma (MS, IVF Specialist)',
    this.attendingEmbryologist = 'Dr. Rajesh Patel (Chief Embryologist)',
  });

  Map<String, dynamic> toMap() {
    return {
      'cycleId': cycleId,
      'patientUhid': patientUhid,
      'patientName': patientName,
      'cycleType': cycleType,
      'protocol': protocol,
      'startDate': startDate.toIso8601String(),
      'stimulationDays': stimulationDays,
      'stimulationMedications': stimulationMedications,
      'rightOvaryFollicles': rightOvaryFollicles,
      'leftOvaryFollicles': leftOvaryFollicles,
      'endometrialThicknessMm': endometrialThicknessMm,
      'triggerDate': triggerDate?.toIso8601String(),
      'triggerMedicine': triggerMedicine,
      'opuDate': opuDate?.toIso8601String(),
      'totalOocytesRetrieved': totalOocytesRetrieved,
      'm2Oocytes': m2Oocytes,
      'm1Oocytes': m1Oocytes,
      'gvOocytes': gvOocytes,
      'semenSampleType': semenSampleType,
      'fertilization2pnCount': fertilization2pnCount,
      'day3CleavageCount': day3CleavageCount,
      'day5BlastocystCount': day5BlastocystCount,
      'blastocystGrading': blastocystGrading,
      'embryoTransferDate': embryoTransferDate?.toIso8601String(),
      'transferType': transferType,
      'embryosTransferredCount': embryosTransferredCount,
      'embryosFrozenCount': embryosFrozenCount,
      'cryoStorageLocation': cryoStorageLocation,
      'betaHcgValue': betaHcgValue,
      'cycleOutcome': cycleOutcome,
      'attendingDoctor': attendingDoctor,
      'attendingEmbryologist': attendingEmbryologist,
    };
  }

  factory IvfCycleModel.fromMap(Map<String, dynamic> map) {
    return IvfCycleModel(
      cycleId: map['cycleId'] ?? '',
      patientUhid: map['patientUhid'] ?? '',
      patientName: map['patientName'] ?? '',
      cycleType: map['cycleType'] ?? 'ICSI',
      protocol: map['protocol'] ?? 'Antagonist Protocol',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      stimulationDays: map['stimulationDays'] ?? 0,
      stimulationMedications: map['stimulationMedications'] ?? '',
      rightOvaryFollicles: map['rightOvaryFollicles'] ?? '',
      leftOvaryFollicles: map['leftOvaryFollicles'] ?? '',
      endometrialThicknessMm: (map['endometrialThicknessMm'] ?? 0.0).toDouble(),
      triggerDate: map['triggerDate'] != null ? DateTime.parse(map['triggerDate']) : null,
      triggerMedicine: map['triggerMedicine'] ?? '',
      opuDate: map['opuDate'] != null ? DateTime.parse(map['opuDate']) : null,
      totalOocytesRetrieved: map['totalOocytesRetrieved'] ?? 0,
      m2Oocytes: map['m2Oocytes'] ?? 0,
      m1Oocytes: map['m1Oocytes'] ?? 0,
      gvOocytes: map['gvOocytes'] ?? 0,
      semenSampleType: map['semenSampleType'] ?? 'Fresh Partner',
      fertilization2pnCount: map['fertilization2pnCount'] ?? 0,
      day3CleavageCount: map['day3CleavageCount'] ?? 0,
      day5BlastocystCount: map['day5BlastocystCount'] ?? 0,
      blastocystGrading: map['blastocystGrading'] ?? '',
      embryoTransferDate: map['embryoTransferDate'] != null ? DateTime.parse(map['embryoTransferDate']) : null,
      transferType: map['transferType'] ?? 'FET',
      embryosTransferredCount: map['embryosTransferredCount'] ?? 0,
      embryosFrozenCount: map['embryosFrozenCount'] ?? 0,
      cryoStorageLocation: map['cryoStorageLocation'] ?? '',
      betaHcgValue: map['betaHcgValue'] != null ? (map['betaHcgValue'] as num).toDouble() : null,
      cycleOutcome: map['cycleOutcome'] ?? 'Ongoing',
      attendingDoctor: map['attendingDoctor'] ?? '',
      attendingEmbryologist: map['attendingEmbryologist'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory IvfCycleModel.fromJson(String source) =>
      IvfCycleModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
