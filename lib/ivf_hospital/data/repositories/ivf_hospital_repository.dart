import 'package:flutter/material.dart';
import '../models/hospital_config_model.dart';
import '../models/ivf_patient_model.dart';
import '../models/ivf_cycle_model.dart';
import '../models/maternity_case_model.dart';
import '../models/ivf_billing_model.dart';
import '../models/diagnostics_pharmacy_model.dart';
import '../services/supabase_service.dart';

/// Central Clinical Repository & State Management for IVFPro 360 Enterprise
class IvfHospitalRepository extends ChangeNotifier {
  HospitalConfigModel _config = HospitalConfigModel();
  final List<IvfPatientModel> _patients = [];
  final List<IvfCycleModel> _ivfCycles = [];
  final List<MaternityCaseModel> _maternityCases = [];
  final List<IvfBillingModel> _invoices = [];
  final List<LabInvestigationModel> _labInvestigations = [];
  final List<PharmacyItemModel> _pharmacyItems = [];
  final List<BedOccupancyModel> _beds = [];

  bool _isLoading = false;

  HospitalConfigModel get config => _config;
  List<IvfPatientModel> get patients => List.unmodifiable(_patients);
  List<IvfCycleModel> get ivfCycles => List.unmodifiable(_ivfCycles);
  List<MaternityCaseModel> get maternityCases => List.unmodifiable(_maternityCases);
  List<IvfBillingModel> get invoices => List.unmodifiable(_invoices);
  List<LabInvestigationModel> get labInvestigations => List.unmodifiable(_labInvestigations);
  List<PharmacyItemModel> get pharmacyItems => List.unmodifiable(_pharmacyItems);
  List<BedOccupancyModel> get beds => List.unmodifiable(_beds);
  bool get isLoading => _isLoading;

  IvfHospitalRepository() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load Whitelabel Hospital Config
    await SupabaseService.instance.loadConfig();
    _config = SupabaseService.instance.config;

    // 2. Pre-seed clinical dataset based on Shri Radhakrishna Hospital specs
    _seedClinicalRecords();

    _isLoading = false;
    notifyListeners();
  }

  void _seedClinicalRecords() {
    // Seed Patients (Couples & Women)
    _patients.addAll([
      IvfPatientModel(
        uhid: 'SRH-P-1001',
        femaleName: 'Snehal Deshmukh',
        femaleAge: 29,
        femaleBloodGroup: 'B+',
        phone: '+91 98221 44550',
        email: 'snehal.d@gmail.com',
        address: 'Plot 42, Civil Lines, Nagpur',
        malePartnerName: 'Rohan Deshmukh',
        maleAge: 32,
        maleBloodGroup: 'O+',
        malePhone: '+91 98221 44551',
        yearsOfMarriage: 5,
        clinicalCategory: 'IVF',
        infertilityType: 'Primary Infertility',
        infertilityDurationYears: 4,
        obstetricGpla: 'G0 P0 L0 A0',
        attendingDoctor: 'Dr. Ananya Sharma (MS, OB-GYN, IVF Specialist)',
        medicalHistory: 'Bilateral tubal block diagnosed on Laparoscopy; AMH 2.8 ng/mL',
        status: 'Active Treatment',
      ),
      IvfPatientModel(
        uhid: 'SRH-P-1002',
        femaleName: 'Priyanka Kulkarni',
        femaleAge: 31,
        femaleBloodGroup: 'A+',
        phone: '+91 97650 33221',
        email: 'priyanka.k@rediffmail.com',
        address: 'Shankar Nagar, Nagpur',
        malePartnerName: 'Abhishek Kulkarni',
        maleAge: 34,
        maleBloodGroup: 'A+',
        malePhone: '+91 97650 33222',
        yearsOfMarriage: 6,
        clinicalCategory: 'MATERNITY',
        infertilityType: 'Secondary Infertility',
        infertilityDurationYears: 3,
        lmpDate: '15-Feb-2026',
        obstetricGpla: 'G2 P1 L1 A0',
        attendingDoctor: 'Dr. Sunita Deshmukh (MD, DGO, Obstetrician)',
        medicalHistory: 'Conceived via IVF FET cycle #2; Uneventful ANC course',
        status: 'Delivered & Postnatal',
      ),
      IvfPatientModel(
        uhid: 'SRH-P-1003',
        femaleName: 'Kavita Chawla',
        femaleAge: 33,
        femaleBloodGroup: 'AB+',
        phone: '+91 94220 88990',
        address: 'Wardha Road, Nagpur',
        malePartnerName: 'Rajesh Chawla',
        maleAge: 36,
        maleBloodGroup: 'B+',
        yearsOfMarriage: 7,
        clinicalCategory: 'IVF',
        infertilityType: 'Primary Infertility',
        infertilityDurationYears: 5,
        obstetricGpla: 'G0 P0 L0 A0',
        attendingDoctor: 'Dr. Ananya Sharma (MS, IVF Specialist)',
        medicalHistory: 'Severe Male Factor (Oligoasthenoteratozoospermia) - ICSI indicated',
        status: 'Active Treatment',
      ),
      IvfPatientModel(
        uhid: 'SRH-P-1004',
        femaleName: 'Meera Tiwari',
        femaleAge: 27,
        femaleBloodGroup: 'O+',
        phone: '+91 93700 11223',
        address: 'Dharampeth, Nagpur',
        malePartnerName: 'Vikas Tiwari',
        maleAge: 29,
        yearsOfMarriage: 3,
        clinicalCategory: 'GYNECOLOGY',
        infertilityType: 'N/A',
        infertilityDurationYears: 0,
        obstetricGpla: 'G0 P0 L0 A0',
        attendingDoctor: 'Dr. Sunita Deshmukh (MD, DGO)',
        medicalHistory: 'Severe PCOS with Oligomenorrhea (Cycles 45-60 days)',
        status: 'Follow-up',
      ),
    ]);

    // Seed IVF Cycles
    _ivfCycles.addAll([
      IvfCycleModel(
        cycleId: 'IVF-2026-001',
        patientUhid: 'SRH-P-1001',
        patientName: 'Snehal Deshmukh',
        cycleType: 'ICSI',
        protocol: 'Antagonist Protocol',
        startDate: DateTime.now().subtract(const Duration(days: 22)),
        stimulationDays: 11,
        stimulationMedications: 'Inj. Gonal-F 225 IU + Menopur 75 IU + Cetrotide 0.25mg',
        rightOvaryFollicles: '19mm, 18mm, 16mm, 15mm',
        leftOvaryFollicles: '20mm, 17mm, 16mm',
        endometrialThicknessMm: 9.6,
        triggerDate: DateTime.now().subtract(const Duration(days: 10)),
        triggerMedicine: 'Inj. Ovitrelle 250 mcg Recombinant hCG',
        opuDate: DateTime.now().subtract(const Duration(days: 8)),
        totalOocytesRetrieved: 14,
        m2Oocytes: 11,
        m1Oocytes: 2,
        gvOocytes: 1,
        semenSampleType: 'Fresh Partner (Normozoospermic)',
        fertilization2pnCount: 9,
        day3CleavageCount: 8,
        day5BlastocystCount: 5,
        blastocystGrading: 'Grade 4AA (x2), 4AB (x2), 3BB (x1)',
        embryoTransferDate: DateTime.now().subtract(const Duration(days: 3)),
        transferType: 'Fresh Transfer',
        embryosTransferredCount: 1,
        embryosFrozenCount: 4,
        cryoStorageLocation: 'Cryo Tank 1 • Canister 2 • Straw #9021',
        betaHcgValue: 485.5,
        cycleOutcome: 'Positive (Pregnant)',
        attendingDoctor: 'Dr. Ananya Sharma',
        attendingEmbryologist: 'Dr. Rajesh Patel',
      ),
      IvfCycleModel(
        cycleId: 'IVF-2026-002',
        patientUhid: 'SRH-P-1003',
        patientName: 'Kavita Chawla',
        cycleType: 'ICSI',
        protocol: 'Antagonist Protocol',
        startDate: DateTime.now().subtract(const Duration(days: 8)),
        stimulationDays: 8,
        stimulationMedications: 'Inj. Rekovelle 12 mcg + Menopur 150 IU',
        rightOvaryFollicles: '16mm, 15mm, 13mm, 12mm',
        leftOvaryFollicles: '15mm, 14mm, 12mm',
        endometrialThicknessMm: 8.4,
        totalOocytesRetrieved: 0,
        cycleOutcome: 'Stimulation in Progress',
        attendingDoctor: 'Dr. Ananya Sharma',
        attendingEmbryologist: 'Dr. Rajesh Patel',
      ),
    ]);

    // Seed Maternity & Delivery
    _maternityCases.addAll([
      MaternityCaseModel(
        caseId: 'MAT-2026-081',
        patientUhid: 'SRH-P-1002',
        patientName: 'Priyanka Kulkarni',
        lmp: DateTime.now().subtract(const Duration(days: 275)),
        edd: DateTime.now().add(const Duration(days: 5)),
        gravida: 2,
        para: 1,
        isIvfConception: true,
        highRiskCondition: 'Previous LSCS + IVF Conception',
        wardBed: 'Maternity Deluxe Room - Bed 201',
        admissionDate: DateTime.now().subtract(const Duration(days: 2)),
        labourStartTime: DateTime.now().subtract(const Duration(hours: 30)),
        cervicalDilationCm: 10.0,
        fetalHeartRateBpm: 142,
        deliveryDate: DateTime.now().subtract(const Duration(hours: 18)),
        deliveryType: 'Elective LSCS',
        babyGender: 'Female',
        birthWeightKg: 3.15,
        apgar1Min: 8,
        apgar5Min: 9,
        vaccineBcgGiven: true,
        vaccineOpv0Given: true,
        vaccineHepBGiven: true,
        caseStatus: 'Delivered & Postnatal',
      ),
    ]);

    // Seed Billing & Packages
    _invoices.addAll([
      IvfBillingModel(
        invoiceNumber: 'SRH-INV-2026-101',
        patientUhid: 'SRH-P-1001',
        patientName: 'Snehal Deshmukh',
        category: 'IVF Package',
        serviceDescription: 'Complete ICSI Cycle Package (OPU + Embryology + Blastocyst + Fresh ET)',
        baseTaxable: 140000.0,
        cgstAmount: 0.0, // Healthcare clinical procedures GST exempt
        sgstAmount: 0.0,
        totalAmount: 140000.0,
        paidAmount: 140000.0,
        balanceDue: 0.0,
        paymentMode: 'UPI (PhonePe)',
        status: 'PAID',
        invoiceDate: DateTime.now().subtract(const Duration(days: 22)),
      ),
      IvfBillingModel(
        invoiceNumber: 'SRH-INV-2026-102',
        patientUhid: 'SRH-P-1002',
        patientName: 'Priyanka Kulkarni',
        category: 'Maternity Delivery IPD',
        serviceDescription: 'LSCS Delivery Package + 3 Days Deluxe Room + Pediatric Care',
        baseTaxable: 55000.0,
        totalAmount: 55000.0,
        paidAmount: 55000.0,
        balanceDue: 0.0,
        paymentMode: 'Credit Card POS',
        status: 'PAID',
        invoiceDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      IvfBillingModel(
        invoiceNumber: 'SRH-INV-2026-103',
        patientUhid: 'SRH-P-1003',
        patientName: 'Kavita Chawla',
        category: 'IVF Package',
        serviceDescription: 'Advance Deposit - ICSI Treatment Package (1st Installment)',
        baseTaxable: 75000.0,
        totalAmount: 75000.0,
        paidAmount: 50000.0,
        balanceDue: 25000.0,
        paymentMode: 'Bank NEFT',
        status: 'PARTIAL',
        invoiceDate: DateTime.now().subtract(const Duration(days: 8)),
      ),
      IvfBillingModel(
        invoiceNumber: 'SRH-INV-2026-104',
        patientUhid: 'SRH-P-1004',
        patientName: 'Meera Tiwari',
        category: 'OPD Consultation',
        serviceDescription: 'Gynecology Consultation & Pelvic USG Scan',
        baseTaxable: 1500.0,
        totalAmount: 1500.0,
        paidAmount: 1500.0,
        balanceDue: 0.0,
        paymentMode: 'Cash Counter',
        status: 'PAID',
        invoiceDate: DateTime.now(),
      ),
    ]);

    // Seed Diagnostics
    _labInvestigations.addAll([
      LabInvestigationModel(
        orderId: 'LAB-2026-501',
        patientUhid: 'SRH-P-1001',
        patientName: 'Snehal Deshmukh',
        testCategory: 'HORMONES',
        testName: 'Serum Beta-hCG (14 Days Post-ET)',
        resultValue: '485.5',
        normalRange: '> 25.0 indicates positive clinical pregnancy',
        unit: 'mIU/mL',
        pathologistNotes: 'Excellent doubling confirmed. Advised 1st USG sac scan in 2 weeks.',
      ),
      LabInvestigationModel(
        orderId: 'LAB-2026-502',
        patientUhid: 'SRH-P-1001',
        patientName: 'Snehal Deshmukh',
        testCategory: 'HORMONES',
        testName: 'Serum AMH (Anti-Mullerian Hormone)',
        resultValue: '2.84',
        normalRange: '1.5 - 4.0 (Normal Ovarian Reserve)',
        unit: 'ng/mL',
      ),
      LabInvestigationModel(
        orderId: 'LAB-2026-503',
        patientUhid: 'SRH-P-1003',
        patientName: 'Kavita Chawla (Husband: Rajesh Chawla)',
        testCategory: 'SEMEN ANALYSIS',
        testName: 'Semen Analysis (WHO 6th Edition)',
        resultValue: 'Concentration: 6.2 M/mL | Total Motility: 24% | Morphology: 1% Normal',
        normalRange: '> 16 M/mL, > 42% Motility, > 4% Normal Morphology',
        unit: 'M/mL',
        pathologistNotes: 'Oligoasthenoteratozoospermia (OAT) confirmed. ICSI recommended.',
      ),
    ]);

    // Seed Pharmacy Items
    _pharmacyItems.addAll([
      PharmacyItemModel(
        medicineId: 'MED-101',
        brandName: 'Gonal-F 300 IU / 0.5 mL Pen',
        composition: 'Recombinant Follitropin Alfa (r-FSH)',
        category: 'IVF Injections',
        batchNumber: 'BA058190',
        expiryDate: DateTime(2027, 8, 30),
        currentStock: 48,
        mrpUnit: 6450.0,
      ),
      PharmacyItemModel(
        medicineId: 'MED-102',
        brandName: 'Menopur 75 IU Inj.',
        composition: 'Highly Purified Menotrophin (HP-HMG)',
        category: 'IVF Injections',
        batchNumber: 'MN2024A',
        expiryDate: DateTime(2027, 5, 15),
        currentStock: 65,
        mrpUnit: 1420.0,
      ),
      PharmacyItemModel(
        medicineId: 'MED-103',
        brandName: 'Cetrotide 0.25 mg Inj.',
        composition: 'Cetrorelix Acetate (GnRH Antagonist)',
        category: 'IVF Injections',
        batchNumber: 'CT88129',
        expiryDate: DateTime(2027, 4, 20),
        currentStock: 35,
        mrpUnit: 2150.0,
      ),
      PharmacyItemModel(
        medicineId: 'MED-104',
        brandName: 'Ovitrelle 250 mcg Prefilled Syringe',
        composition: 'Choriogonadotropin Alfa (Recombinant hCG Trigger)',
        category: 'IVF Injections',
        batchNumber: 'OV99201',
        expiryDate: DateTime(2027, 10, 10),
        currentStock: 22,
        mrpUnit: 2850.0,
      ),
      PharmacyItemModel(
        medicineId: 'MED-105',
        brandName: 'Susten 400 mg Soft Gelatin Capsule',
        composition: 'Natural Micronized Progesterone',
        category: 'Luteal Support',
        batchNumber: 'SN44120',
        expiryDate: DateTime(2028, 1, 15),
        currentStock: 180,
        mrpUnit: 695.0,
      ),
    ]);

    // Seed Beds & Wards
    _beds.addAll([
      BedOccupancyModel(
        bedId: 'BED-101',
        wardName: 'IVF Recovery Day Care',
        bedNumber: 'Bed 1 (OPU Recovery)',
        category: 'Day Care',
        isOccupied: false,
        dailyCharge: 1500.0,
      ),
      BedOccupancyModel(
        bedId: 'BED-102',
        wardName: 'IVF Recovery Day Care',
        bedNumber: 'Bed 2 (ET Rest Room)',
        category: 'Day Care',
        isOccupied: true,
        occupiedByPatientName: 'Snehal Deshmukh',
        occupiedByUhid: 'SRH-P-1001',
        dailyCharge: 1500.0,
      ),
      BedOccupancyModel(
        bedId: 'BED-201',
        wardName: 'Maternity Deluxe Room',
        bedNumber: 'Room 201',
        category: 'Deluxe AC',
        isOccupied: true,
        occupiedByPatientName: 'Priyanka Kulkarni (Mother & Baby)',
        occupiedByUhid: 'SRH-P-1002',
        dailyCharge: 4500.0,
      ),
      BedOccupancyModel(
        bedId: 'BED-202',
        wardName: 'Maternity Deluxe Room',
        bedNumber: 'Room 202',
        category: 'Deluxe AC',
        isOccupied: false,
        dailyCharge: 4500.0,
      ),
      BedOccupancyModel(
        bedId: 'BED-301',
        wardName: 'Labour & Delivery Suite',
        bedNumber: 'LDR Bed 1',
        category: 'Labour OT',
        isOccupied: false,
        dailyCharge: 3500.0,
      ),
    ]);
  }

  // --- Clinical Actions ---

  Future<void> addPatient(IvfPatientModel patient) async {
    _patients.insert(0, patient);
    notifyListeners();
    await SupabaseService.instance.syncRecordToTable(
      tableName: 'patients',
      record: patient.toMap(),
    );
  }

  Future<void> addIvfCycle(IvfCycleModel cycle) async {
    _ivfCycles.insert(0, cycle);
    notifyListeners();
    await SupabaseService.instance.syncRecordToTable(
      tableName: 'ivf_cycles',
      record: cycle.toMap(),
    );
  }

  Future<void> updateIvfCycle(IvfCycleModel cycle) async {
    final idx = _ivfCycles.indexWhere((c) => c.cycleId == cycle.cycleId);
    if (idx != -1) {
      _ivfCycles[idx] = cycle;
      notifyListeners();
      await SupabaseService.instance.syncRecordToTable(
        tableName: 'ivf_cycles',
        record: cycle.toMap(),
      );
    }
  }

  Future<void> addMaternityCase(MaternityCaseModel matCase) async {
    _maternityCases.insert(0, matCase);
    notifyListeners();
    await SupabaseService.instance.syncRecordToTable(
      tableName: 'maternity_cases',
      record: matCase.toMap(),
    );
  }

  Future<void> addBillingInvoice(IvfBillingModel invoice) async {
    _invoices.insert(0, invoice);
    notifyListeners();
    await SupabaseService.instance.syncRecordToTable(
      tableName: 'billing_invoices',
      record: invoice.toMap(),
    );
  }

  Future<void> updateHospitalConfig(HospitalConfigModel newConfig) async {
    _config = newConfig;
    await SupabaseService.instance.saveConfig(newConfig);
    notifyListeners();
  }

  Future<void> switchBranch(String branchId) async {
    _config.activeBranchId = branchId;
    await SupabaseService.instance.saveConfig(_config);
    notifyListeners();
  }
}
