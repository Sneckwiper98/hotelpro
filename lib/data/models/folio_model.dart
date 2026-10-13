import '../../config/app_constants.dart';

class FolioTransactionModel {
  final String id;
  final String folioId;
  final FolioCategory category;
  final String description;
  final double amount;
  final double taxAmount;
  final bool isCredit; // true = payment made, false = charge billed
  final PaymentMethod? paymentMethod;
  final String? referenceId;
  final DateTime timestamp;

  const FolioTransactionModel({
    required this.id,
    required this.folioId,
    required this.category,
    required this.description,
    required this.amount,
    this.taxAmount = 0.0,
    required this.isCredit,
    this.paymentMethod,
    this.referenceId,
    required this.timestamp,
  });

  double get netAmount => isCredit ? -amount : (amount + taxAmount);

  factory FolioTransactionModel.fromJson(Map<String, dynamic> json) => FolioTransactionModel(
    id: json['id'] as String,
    folioId: json['folio_id'] as String? ?? '',
    category: FolioCategory.fromCode(json['category'] as String? ?? 'room_charge'),
    description: json['description'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
    isCredit: json['is_credit'] as bool? ?? false,
    paymentMethod: json['payment_method'] != null
        ? PaymentMethod.fromCode(json['payment_method'].toString())
        : null,
    referenceId: json['reference_id'] as String?,
    timestamp: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'folio_id': folioId,
    'category': category.code,
    'description': description,
    'amount': amount,
    'tax_amount': taxAmount,
    'is_credit': isCredit,
    'payment_method': paymentMethod?.code,
    'reference_id': referenceId,
    'created_at': timestamp.toIso8601String(),
  };
}

class FolioModel {
  final String id;
  final String reservationId;
  final String folioNumber; // e.g. "FOL-2026-8812"
  final String status; // 'open', 'settled', 'cancelled'
  final String roomNumber;
  final String guestName;
  final List<FolioTransactionModel> transactions;

  const FolioModel({
    required this.id,
    required this.reservationId,
    required this.folioNumber,
    this.status = 'open',
    required this.roomNumber,
    required this.guestName,
    required this.transactions,
  });

  double get totalCharges {
    return transactions
        .where((t) => !t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount + t.taxAmount);
  }

  double get totalTaxes {
    return transactions
        .where((t) => !t.isCredit)
        .fold(0.0, (sum, t) => sum + t.taxAmount);
  }

  double get totalPaid {
    return transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balanceDue => totalCharges - totalPaid;

  FolioModel copyWith({
    String? status,
    List<FolioTransactionModel>? transactions,
  }) {
    return FolioModel(
      id: id,
      reservationId: reservationId,
      folioNumber: folioNumber,
      status: status ?? this.status,
      roomNumber: roomNumber,
      guestName: guestName,
      transactions: transactions ?? this.transactions,
    );
  }

  factory FolioModel.fromJson(Map<String, dynamic> json, {List<FolioTransactionModel>? txns}) {
    return FolioModel(
      id: json['id'] as String,
      reservationId: json['reservation_id'] as String? ?? '',
      folioNumber: json['folio_number'] as String? ?? 'FOL-001',
      status: json['status'] as String? ?? 'open',
      roomNumber: json['room_number'] as String? ?? '',
      guestName: json['guest_name'] as String? ?? 'Guest',
      transactions: txns ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reservation_id': reservationId,
    'folio_number': folioNumber,
    'status': status,
    'room_number': roomNumber,
    'guest_name': guestName,
    'total_charges': totalCharges,
    'total_paid': totalPaid,
    'balance_due': balanceDue,
  };
}

