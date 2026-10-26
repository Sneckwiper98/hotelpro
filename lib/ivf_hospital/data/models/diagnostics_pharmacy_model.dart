// Laboratory, Radiology, Pharmacy & Bed Master Models

class LabInvestigationModel {
  final String orderId;
  final String patientUhid;
  final String patientName;
  final String testCategory; // 'HORMONES', 'SEMEN ANALYSIS', 'HEMATOLOGY', 'USG RADIOLOGY'
  final String testName; // e.g. 'Serum AMH', 'Semen Analysis WHO 6th', 'Beta-hCG', 'Pelvic USG'
  final String resultValue;
  final String normalRange;
  final String unit;
  final String status; // 'COMPLETED', 'SAMPLE COLLECTED', 'PENDING'
  final DateTime orderDate;
  final String? pathologistNotes;

  LabInvestigationModel({
    required this.orderId,
    required this.patientUhid,
    required this.patientName,
    required this.testCategory,
    required this.testName,
    required this.resultValue,
    required this.normalRange,
    required this.unit,
    this.status = 'COMPLETED',
    DateTime? orderDate,
    this.pathologistNotes,
  }) : orderDate = orderDate ?? DateTime.now();
}

class PharmacyItemModel {
  final String medicineId;
  final String brandName;
  final String composition;
  final String category; // 'IVF Injections', 'Luteal Support', 'Antibiotics', 'Vitamins'
  final String batchNumber;
  final DateTime expiryDate;
  int currentStock;
  final int reorderLevel;
  final double mrpUnit;

  PharmacyItemModel({
    required this.medicineId,
    required this.brandName,
    required this.composition,
    required this.category,
    required this.batchNumber,
    required this.expiryDate,
    required this.currentStock,
    this.reorderLevel = 10,
    required this.mrpUnit,
  });
}

class BedOccupancyModel {
  final String bedId;
  final String wardName; // 'Maternity Deluxe', 'IVF Recovery Day Care', 'General Ward', 'NICU'
  final String bedNumber;
  final String category;
  bool isOccupied;
  String? occupiedByPatientName;
  String? occupiedByUhid;
  double dailyCharge;

  BedOccupancyModel({
    required this.bedId,
    required this.wardName,
    required this.bedNumber,
    required this.category,
    this.isOccupied = false,
    this.occupiedByPatientName,
    this.occupiedByUhid,
    this.dailyCharge = 2500.0,
  });

  String? get patientName => occupiedByPatientName;
  String? get patientUhid => occupiedByUhid;
  double get dailyCharges => dailyCharge;
}
