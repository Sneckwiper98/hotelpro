import 'dart:convert';

/// Hospital Billing, IVF Package & GST Invoice Model
class IvfBillingModel {
  final String invoiceNumber;
  final String patientUhid;
  final String patientName;
  final String category; // 'IVF Package', 'OPD Consultation', 'Maternity Delivery IPD', 'Diagnostics / Lab', 'Pharmacy'
  final String serviceDescription;
  final double baseTaxable;
  final double cgstAmount;
  final double sgstAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final String paymentMode; // 'Cash', 'UPI', 'POS Card', 'Bank NEFT'
  final String status; // 'PAID', 'PARTIAL', 'DUE'
  final DateTime invoiceDate;

  IvfBillingModel({
    required this.invoiceNumber,
    required this.patientUhid,
    required this.patientName,
    required this.category,
    required this.serviceDescription,
    required this.baseTaxable,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    double? balanceDue,
    this.paymentMode = 'UPI',
    this.status = 'PAID',
    DateTime? invoiceDate,
  })  : balanceDue = balanceDue ?? (totalAmount - paidAmount),
        invoiceDate = invoiceDate ?? DateTime.now();

  double get taxableAmount => baseTaxable;
  double get totalGst => cgstAmount + sgstAmount;

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'patientUhid': patientUhid,
      'patientName': patientName,
      'category': category,
      'serviceDescription': serviceDescription,
      'baseTaxable': baseTaxable,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceDue': balanceDue,
      'paymentMode': paymentMode,
      'status': status,
      'invoiceDate': invoiceDate.toIso8601String(),
    };
  }

  factory IvfBillingModel.fromMap(Map<String, dynamic> map) {
    return IvfBillingModel(
      invoiceNumber: map['invoiceNumber'] ?? '',
      patientUhid: map['patientUhid'] ?? '',
      patientName: map['patientName'] ?? '',
      category: map['category'] ?? 'IVF Package',
      serviceDescription: map['serviceDescription'] ?? '',
      baseTaxable: (map['baseTaxable'] ?? 0.0).toDouble(),
      cgstAmount: (map['cgstAmount'] ?? 0.0).toDouble(),
      sgstAmount: (map['sgstAmount'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      balanceDue: (map['balanceDue'] ?? 0.0).toDouble(),
      paymentMode: map['paymentMode'] ?? 'UPI',
      status: map['status'] ?? 'PAID',
      invoiceDate: map['invoiceDate'] != null ? DateTime.parse(map['invoiceDate']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory IvfBillingModel.fromJson(String source) =>
      IvfBillingModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
