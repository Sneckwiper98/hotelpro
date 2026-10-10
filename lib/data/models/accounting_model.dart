import 'dart:convert';
import 'dart:typed_data';

// =============================================================================
// Purchase Models (Supplier Invoices & Materials)
// =============================================================================

class PurchaseItem {
  final String id;
  final String name;
  final String category; // Grocery, Dairy, Beverages, Housekeeping, Linen, Maintenance
  final double quantity;
  final String unit; // Kg, Ltr, Pcs, Box, Pack, Can
  final double unitPrice;
  final double taxPercent; // 0, 5, 12, 18, 28

  const PurchaseItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.taxPercent = 5.0,
  });

  double get subTotal => quantity * unitPrice;
  double get taxAmount => subTotal * (taxPercent / 100.0);
  double get totalAmount => subTotal + taxAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'taxPercent': taxPercent,
  };

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    id: json['id'] as String? ?? 'ITEM-${DateTime.now().millisecondsSinceEpoch}',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    unit: json['unit'] as String? ?? 'Pcs',
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 5.0,
  );
}

class PurchaseEntry {
  final String id;
  final String branchId;
  final String invoiceNumber;
  final String vendorName;
  final String vendorGstin;
  final String vendorPhone;
  final DateTime purchaseDate;
  final String department; // Kitchen, Housekeeping, Maintenance, Front Office, Bar & F&B
  final List<PurchaseItem> items;
  final String paymentStatus; // Paid, Pending, Partial
  final String paymentMode; // Cash, Bank Transfer / NEFT, UPI, Cheque, Credit
  final String notes;
  final DateTime createdAt;

  const PurchaseEntry({
    required this.id,
    required this.branchId,
    required this.invoiceNumber,
    required this.vendorName,
    required this.vendorGstin,
    required this.vendorPhone,
    required this.purchaseDate,
    required this.department,
    required this.items,
    this.paymentStatus = 'Paid',
    this.paymentMode = 'Bank Transfer / NEFT',
    this.notes = '',
    required this.createdAt,
  });

  double get subTotal => items.fold(0.0, (sum, item) => sum + item.subTotal);
  double get totalTax => items.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get grandTotal => items.fold(0.0, (sum, item) => sum + item.totalAmount);

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': branchId,
    'invoiceNumber': invoiceNumber,
    'vendorName': vendorName,
    'vendorGstin': vendorGstin,
    'vendorPhone': vendorPhone,
    'purchaseDate': purchaseDate.toIso8601String(),
    'department': department,
    'items': items.map((i) => i.toJson()).toList(),
    'paymentStatus': paymentStatus,
    'paymentMode': paymentMode,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PurchaseEntry.fromJson(Map<String, dynamic> json) => PurchaseEntry(
    id: json['id'] as String? ?? '',
    branchId: json['branch_id'] ?? json['branchId'] ?? '',
    invoiceNumber: json['invoice_number'] ?? json['invoiceNumber'] ?? '',
    vendorName: json['vendor_name'] ?? json['vendorName'] ?? '',
    vendorGstin: json['vendor_gstin'] ?? json['vendorGstin'] ?? '',
    vendorPhone: json['vendor_phone'] ?? json['vendorPhone'] ?? '',
    purchaseDate: DateTime.tryParse((json['purchase_date'] ?? json['purchaseDate']) as String? ?? '') ?? DateTime.now(),
    department: json['department'] as String? ?? 'General',
    items: ((json['items'] as List?) ?? [])
        .map((i) => PurchaseItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'Paid',
    paymentMode: json['payment_mode'] ?? json['paymentMode'] ?? 'Bank Transfer / NEFT',
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt']) as String? ?? '') ?? DateTime.now(),
  );

  PurchaseEntry copyWith({
    String? id,
    String? branchId,
    String? invoiceNumber,
    String? vendorName,
    String? vendorGstin,
    String? vendorPhone,
    DateTime? purchaseDate,
    String? department,
    List<PurchaseItem>? items,
    String? paymentStatus,
    String? paymentMode,
    String? notes,
    DateTime? createdAt,
  }) {
    return PurchaseEntry(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      vendorName: vendorName ?? this.vendorName,
      vendorGstin: vendorGstin ?? this.vendorGstin,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      department: department ?? this.department,
      items: items ?? this.items,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// =============================================================================
// Expense Models (Operating Outlays with Bill Copy Upload)
// =============================================================================

class ExpenseEntry {
  final String id;
  final String branchId;
  final String voucherNo;
  final DateTime date;
  final String category; // Kitchen & Provisions, Electricity & Utilities, Staff Salaries & Welfare, Repairs & Maintenance, Laundry & Linen, Generator & Diesel, Software & Internet, Marketing, Miscellaneous
  final String paidTo;
  final String description;
  final double amount;
  final double taxAmount;
  final String paymentMode; // Cash, Bank, UPI, Cheque
  final String referenceNo; // UTR / Txn ID / Cheque No
  final String status; // Approved, Paid, Pending
  final String recordedBy;
  final String? billAttachmentPath;
  final Uint8List? billAttachmentBytes;
  final String? billAttachmentName;
  final DateTime createdAt;

  const ExpenseEntry({
    required this.id,
    required this.branchId,
    required this.voucherNo,
    required this.date,
    required this.category,
    required this.paidTo,
    required this.description,
    required this.amount,
    this.taxAmount = 0.0,
    this.paymentMode = 'Cash',
    this.referenceNo = '',
    this.status = 'Approved',
    this.recordedBy = 'Accounts Dept',
    this.billAttachmentPath,
    this.billAttachmentBytes,
    this.billAttachmentName,
    required this.createdAt,
  });

  bool get hasBillCopy => (billAttachmentBytes != null && billAttachmentBytes!.isNotEmpty) ||
      (billAttachmentPath != null && billAttachmentPath!.isNotEmpty);

  double get netAmount => amount + taxAmount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': branchId,
    'voucherNo': voucherNo,
    'date': date.toIso8601String(),
    'category': category,
    'paidTo': paidTo,
    'description': description,
    'amount': amount,
    'taxAmount': taxAmount,
    'paymentMode': paymentMode,
    'referenceNo': referenceNo,
    'status': status,
    'recordedBy': recordedBy,
    'billAttachmentPath': billAttachmentPath,
    'billAttachmentName': billAttachmentName,
    'billAttachmentBase64': billAttachmentBytes != null ? base64Encode(billAttachmentBytes!) : null,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    final b64 = json['billAttachmentBase64'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {}
    }

    return ExpenseEntry(
      id: json['id'] as String? ?? '',
      branchId: json['branch_id'] ?? json['branchId'] ?? '',
      voucherNo: json['voucher_number'] ?? json['voucherNo'] ?? '',
      date: DateTime.tryParse((json['expense_date'] ?? json['date']) as String? ?? '') ?? DateTime.now(),
      category: json['category'] as String? ?? 'Miscellaneous',
      paidTo: json['paid_to'] ?? json['paidTo'] ?? '',
      description: json['description'] as String? ?? '',
      amount: ((json['amount']) as num?)?.toDouble() ?? 0.0,
      taxAmount: ((json['tax_amount'] ?? json['taxAmount']) as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode'] ?? json['paymentMode'] ?? 'Cash',
      referenceNo: json['reference_number'] ?? json['referenceNo'] ?? '',
      status: json['status'] as String? ?? 'Approved',
      recordedBy: json['recorded_by'] ?? json['recordedBy'] ?? 'Accounts Dept',
      billAttachmentPath: json['billAttachmentPath'] as String?,
      billAttachmentBytes: bytes,
      billAttachmentName: json['billAttachmentName'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt']) as String? ?? '') ?? DateTime.now(),
    );
  }

  ExpenseEntry copyWith({
    String? id,
    String? branchId,
    String? voucherNo,
    DateTime? date,
    String? category,
    String? paidTo,
    String? description,
    double? amount,
    double? taxAmount,
    String? paymentMode,
    String? referenceNo,
    String? status,
    String? recordedBy,
    String? billAttachmentPath,
    Uint8List? billAttachmentBytes,
    String? billAttachmentName,
    DateTime? createdAt,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      voucherNo: voucherNo ?? this.voucherNo,
      date: date ?? this.date,
      category: category ?? this.category,
      paidTo: paidTo ?? this.paidTo,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNo: referenceNo ?? this.referenceNo,
      status: status ?? this.status,
      recordedBy: recordedBy ?? this.recordedBy,
      billAttachmentPath: billAttachmentPath ?? this.billAttachmentPath,
      billAttachmentBytes: billAttachmentBytes ?? this.billAttachmentBytes,
      billAttachmentName: billAttachmentName ?? this.billAttachmentName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// =============================================================================
// Balance Sheet & Financial Statements Models
// =============================================================================

class FinancialLineItem {
  final String code;
  final String title;
  final double amount;
  final String? note;
  final bool isHeader;

  const FinancialLineItem({
    required this.code,
    required this.title,
    required this.amount,
    this.note,
    this.isHeader = false,
  });
}

class BalanceSheetData {
  final String branchId;
  final String branchName;
  final DateTime asOfDate;
  final String financialYear;

  // Assets
  final List<FinancialLineItem> currentAssets;
  final List<FinancialLineItem> fixedAssets;

  // Liabilities
  final List<FinancialLineItem> currentLiabilities;
  final List<FinancialLineItem> longTermLiabilities;

  // Equity & Retained Earnings
  final List<FinancialLineItem> equityItems;

  const BalanceSheetData({
    required this.branchId,
    required this.branchName,
    required this.asOfDate,
    required this.financialYear,
    required this.currentAssets,
    required this.fixedAssets,
    required this.currentLiabilities,
    required this.longTermLiabilities,
    required this.equityItems,
  });

  double get totalCurrentAssets => currentAssets.fold(0.0, (s, i) => s + i.amount);
  double get totalFixedAssets => fixedAssets.fold(0.0, (s, i) => s + i.amount);
  double get totalAssets => totalCurrentAssets + totalFixedAssets;

  double get totalCurrentLiabilities => currentLiabilities.fold(0.0, (s, i) => s + i.amount);
  double get totalLongTermLiabilities => longTermLiabilities.fold(0.0, (s, i) => s + i.amount);
  double get totalLiabilities => totalCurrentLiabilities + totalLongTermLiabilities;

  double get totalEquity => equityItems.fold(0.0, (s, i) => s + i.amount);
  double get totalLiabilitiesAndEquity => totalLiabilities + totalEquity;

  bool get isBalanced => (totalAssets - totalLiabilitiesAndEquity).abs() < 1.0;
}
