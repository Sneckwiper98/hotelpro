import 'package:flutter/material.dart';

enum ErpInvoiceType {
  roomStay('Room Stay Folio', '🏨', Color(0xFF1B4F72)),
  restaurantPos('Restaurant Dining', '🍽️', Color(0xFFD35400)),
  onlineDelivery('Online Food Delivery', '🛵', Color(0xFF27AE60));

  final String label;
  final String icon;
  final Color color;
  const ErpInvoiceType(this.label, this.icon, this.color);
}

enum ErpInvoiceStatus {
  paid('PAID', Color(0xFF1E8449), Color(0xFFD4EFDF)),
  pending('PENDING', Color(0xFFB7950B), Color(0xFFFCF3CF)),
  credit('BTC / CREDIT', Color(0xFF2E86C1), Color(0xFFD4E6F1)),
  cancelled('CANCELLED', Color(0xFFC0392B), Color(0xFFFADBD8));

  final String label;
  final Color textColor;
  final Color bgColor;
  const ErpInvoiceStatus(this.label, this.textColor, this.bgColor);
}

class ErpInvoiceRecord {
  final String invoiceNumber;
  final ErpInvoiceType type;
  final String customerName;
  final String customerPhone;
  final String? customerGstin;
  final String? customerAddress;
  final DateTime date;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double totalAmount;
  final String paymentMode; // Cash, UPI, Credit Card, Razorpay, Room Bill BTC
  final ErpInvoiceStatus status;
  final String? referenceId; // Folio id or POS order id
  final List<ErpInvoiceLineItem> items;

  const ErpInvoiceRecord({
    required this.invoiceNumber,
    required this.type,
    required this.customerName,
    required this.customerPhone,
    this.customerGstin,
    this.customerAddress,
    required this.date,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalAmount,
    required this.paymentMode,
    required this.status,
    this.referenceId,
    this.items = const [],
  });

  ErpInvoiceRecord copyWith({
    ErpInvoiceStatus? status,
    String? paymentMode,
  }) {
    return ErpInvoiceRecord(
      invoiceNumber: invoiceNumber,
      type: type,
      customerName: customerName,
      customerPhone: customerPhone,
      customerGstin: customerGstin,
      customerAddress: customerAddress,
      date: date,
      taxableAmount: taxableAmount,
      cgst: cgst,
      sgst: sgst,
      totalAmount: totalAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      referenceId: referenceId,
      items: items,
    );
  }
}

class ErpInvoiceLineItem {
  final String description;
  final String hsnSacCode;
  final int quantity;
  final double unitRate;
  final double amount;
  final double gstRate;

  const ErpInvoiceLineItem({
    required this.description,
    this.hsnSacCode = '996331',
    required this.quantity,
    required this.unitRate,
    required this.amount,
    this.gstRate = 5.0,
  });
}
