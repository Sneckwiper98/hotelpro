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
}
