import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/accounting_model.dart';
import '../models/guest_model.dart';
import '../models/invoice_model.dart';

/// 🇮🇳 TallyPrime / Tally ERP 9 XML Accounting Engine & Indian Statutory Compliance Service
///
/// Features:
/// 1. Tally XML Vouchers Export: Sales, Receipts, Purchases, and Chart of Accounts Masters
/// 2. Government GST Returns: GSTR-1 (Table 4 B2B, Table 7 B2CS, Table 12 HSN, Table 13 Docs)
/// 3. GSTR-3B Tax Liability & Eligible Input Tax Credit (ITC) calculator
/// 4. Ministry of Corporate Affairs (MCA) Rule 11(g) Audit Trail logger
/// 5. Bureau of Immigration / FRRO Form C Foreigner Registration exporter
/// 6. Indian Rupee Number to Words converter (Lakhs & Crores)
class TallyAccountingService {
  static final TallyAccountingService instance = TallyAccountingService._internal();
  TallyAccountingService._internal();

  // ── Indian State Codes Reference (GST Standard) ───────────────────────────
  static const Map<String, String> indianGstStateCodes = {
    '01': 'Jammu and Kashmir',
    '02': 'Himachal Pradesh',
    '03': 'Punjab',
    '04': 'Chandigarh',
    '05': 'Uttarakhand',
    '06': 'Haryana',
    '07': 'Delhi',
    '08': 'Rajasthan',
    '09': 'Uttar Pradesh',
    '10': 'Bihar',
    '11': 'Sikkim',
    '12': 'Arunachal Pradesh',
    '13': 'Nagaland',
    '14': 'Manipur',
    '15': 'Mizoram',
    '16': 'Tripura',
    '17': 'Meghalaya',
    '18': 'Assam',
    '19': 'West Bengal',
    '20': 'Jharkhand',
    '21': 'Odisha',
    '22': 'Chhattisgarh',
    '23': 'Madhya Pradesh',
    '24': 'Gujarat',
    '26': 'Dadra and Nagar Haveli and Daman and Diu',
    '27': 'Maharashtra',
    '28': 'Andhra Pradesh',
    '29': 'Karnataka',
    '30': 'Goa',
    '31': 'Lakshadweep',
    '32': 'Kerala',
    '33': 'Tamil Nadu',
    '34': 'Puducherry',
    '35': 'Andaman and Nicobar Islands',
    '36': 'Telangana',
    '37': 'Andhra Pradesh (New)',
    '38': 'Ladakh',
    '97': 'Other Territory',
  };

  // ── MCA Rule 11(g) Audit Trail In-Memory Store ────────────────────────────
  static final List<McaAuditTrailEntry> _auditTrail = [
    McaAuditTrailEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      voucherNo: 'INV-RM-1024',
      action: 'CREATED',
      userId: 'rpatil.fd',
      userRole: 'Front Desk Lead',
      details: 'Tax Invoice created for Rajesh Singhania (Singhania Steels). Taxable: ₹18,500, CGST: ₹1665, SGST: ₹1665.',
      checksum: _computeChecksum('INV-RM-1024|CREATED|18500|rpatil.fd'),
    ),
    McaAuditTrailEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      voucherNo: 'INV-POS-4401',
      action: 'CREATED',
      userId: 'waiter.kunal',
      userRole: 'POS Captain',
      details: 'Restaurant GST invoice generated for Pooja Verma. Taxable: ₹2,450, CGST: ₹61.25, SGST: ₹61.25.',
      checksum: _computeChecksum('INV-POS-4401|CREATED|2450|waiter.kunal'),
    ),
    McaAuditTrailEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      voucherNo: 'PUR-2026-089',
      action: 'CREATED',
      userId: 'accounts.sharma',
      userRole: 'Senior Accountant',
      details: 'Purchase bill recorded from Metro Wholesale for Dairy & Grocery. Taxable: ₹45,200, ITC: ₹2,260.',
      checksum: _computeChecksum('PUR-2026-089|CREATED|45200|accounts.sharma'),
    ),
  ];

  static List<McaAuditTrailEntry> get auditTrail => List.unmodifiable(_auditTrail);

  static void logAudit({
    required String voucherNo,
    required String action,
    required String userId,
    required String userRole,
    required String details,
  }) {
    final entry = McaAuditTrailEntry(
      timestamp: DateTime.now(),
      voucherNo: voucherNo,
      action: action,
      userId: userId,
      userRole: userRole,
      details: details,
      checksum: _computeChecksum('$voucherNo|$action|$userId|${DateTime.now().millisecondsSinceEpoch}'),
    );
    _auditTrail.insert(0, entry);
  }

  static String _computeChecksum(String data) {
    int hash = 0xcbf29ce484222325;
    final bytes = utf8.encode(data);
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  // ===========================================================================
  // 1. TALLYPRIME / TALLY ERP 9 XML EXPORTERS
  // ===========================================================================

  /// Generates TallyPrime / Tally ERP 9 standard XML envelope for Sales Vouchers
  static String generateSalesVouchersXml({
    required List<ErpInvoiceRecord> invoices,
    required String companyName,
  }) {
    final buffer = StringBuffer();
    final dateFmt = DateFormat('yyyyMMdd');

    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>Vouchers</REPORTNAME>');
    buffer.writeln('        <STATICVARIABLES>');
    buffer.writeln('          <SVCURRENTCOMPANY>${_escapeXml(companyName)}</SVCURRENTCOMPANY>');
    buffer.writeln('        </STATICVARIABLES>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final inv in invoices) {
      final dateStr = dateFmt.format(inv.date);
      final partyLedger = inv.customerName.trim().isNotEmpty ? inv.customerName.trim() : 'Sundry Debtors - Hotel Guests';
      final salesLedger = _getSalesLedgerName(inv.type);
      final isInterState = inv.isInterState;
      final narration = 'Being Tax Invoice #${inv.invoiceNumber} for ${inv.type.label}. POS: ${inv.placeOfSupply}. Status: ${inv.status.label}. Mode: ${inv.paymentMode}';

      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <VOUCHER VCHTYPE="Sales" ACTION="Create" OBJVIEW="Accounting Voucher View">');
      buffer.writeln('            <DATE>$dateStr</DATE>');
      buffer.writeln('            <VOUCHERTYPENAME>Sales</VOUCHERTYPENAME>');
      buffer.writeln('            <VOUCHERNUMBER>${_escapeXml(inv.invoiceNumber)}</VOUCHERNUMBER>');
      buffer.writeln('            <REFERENCE>${_escapeXml(inv.referenceId ?? inv.invoiceNumber)}</REFERENCE>');
      buffer.writeln('            <PARTYLEDGERNAME>${_escapeXml(partyLedger)}</PARTYLEDGERNAME>');
      buffer.writeln('            <NARRATION>${_escapeXml(narration)}</NARRATION>');
      buffer.writeln('            <STATENAME>${_escapeXml(inv.placeOfSupply)}</STATENAME>');
      buffer.writeln('            <ISINVOICE>Yes</ISINVOICE>');
      if (inv.customerGstin != null && inv.customerGstin!.isNotEmpty) {
        buffer.writeln('            <PARTYGSTIN>${_escapeXml(inv.customerGstin!)}</PARTYGSTIN>');
      }

      // Ledger Entry 1: Party / Debtor (Debit - represented as negative in Tally Sales)
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(partyLedger)}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>-${inv.totalAmount.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

      // Ledger Entry 2: Sales Account (Credit)
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(salesLedger)}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${inv.taxableAmount.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

      // Tax Ledger Entries: CGST + SGST or IGST
      if (isInterState || inv.igst > 0) {
        final igstAmt = inv.igst > 0 ? inv.igst : (inv.cgst + inv.sgst);
        buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
        buffer.writeln('              <LEDGERNAME>Output IGST</LEDGERNAME>');
        buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
        buffer.writeln('              <AMOUNT>${igstAmt.toStringAsFixed(2)}</AMOUNT>');
        buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
      } else {
        if (inv.cgst > 0) {
          buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
          buffer.writeln('              <LEDGERNAME>Output CGST</LEDGERNAME>');
          buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
          buffer.writeln('              <AMOUNT>${inv.cgst.toStringAsFixed(2)}</AMOUNT>');
          buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
        }
        if (inv.sgst > 0) {
          buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
          buffer.writeln('              <LEDGERNAME>Output SGST</LEDGERNAME>');
          buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
          buffer.writeln('              <AMOUNT>${inv.sgst.toStringAsFixed(2)}</AMOUNT>');
          buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
        }
      }

      buffer.writeln('          </VOUCHER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  /// Generates Tally XML for Receipt Vouchers (Settled invoices / payments received)
  static String generateReceiptVouchersXml({
    required List<ErpInvoiceRecord> invoices,
    required String companyName,
  }) {
    final buffer = StringBuffer();
    final dateFmt = DateFormat('yyyyMMdd');
    final paidInvoices = invoices.where((i) => i.status == ErpInvoiceStatus.paid).toList();

    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>Vouchers</REPORTNAME>');
    buffer.writeln('        <STATICVARIABLES>');
    buffer.writeln('          <SVCURRENTCOMPANY>${_escapeXml(companyName)}</SVCURRENTCOMPANY>');
    buffer.writeln('        </STATICVARIABLES>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final inv in paidInvoices) {
      final dateStr = dateFmt.format(inv.date);
      final partyLedger = inv.customerName.trim().isNotEmpty ? inv.customerName.trim() : 'Sundry Debtors - Hotel Guests';
      final bankOrCash = _getPaymentLedger(inv.paymentMode);
      final narration = 'Settlement of Bill #${inv.invoiceNumber} via ${inv.paymentMode}';

      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <VOUCHER VCHTYPE="Receipt" ACTION="Create" OBJVIEW="Accounting Voucher View">');
      buffer.writeln('            <DATE>$dateStr</DATE>');
      buffer.writeln('            <VOUCHERTYPENAME>Receipt</VOUCHERTYPENAME>');
      buffer.writeln('            <VOUCHERNUMBER>REC-${_escapeXml(inv.invoiceNumber)}</VOUCHERNUMBER>');
      buffer.writeln('            <PARTYLEDGERNAME>${_escapeXml(partyLedger)}</PARTYLEDGERNAME>');
      buffer.writeln('            <NARRATION>${_escapeXml(narration)}</NARRATION>');

      // Debit Bank/Cash Account
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(bankOrCash)}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>-${inv.totalAmount.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

      // Credit Party Account
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(partyLedger)}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${inv.totalAmount.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

      buffer.writeln('          </VOUCHER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  /// Generates Tally XML for Purchase Entries (Material & Vendor Invoices)
  static String generatePurchaseVouchersXml({
    required List<PurchaseEntry> purchases,
    required String companyName,
  }) {
    final buffer = StringBuffer();
    final dateFmt = DateFormat('yyyyMMdd');

    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>Vouchers</REPORTNAME>');
    buffer.writeln('        <STATICVARIABLES>');
    buffer.writeln('          <SVCURRENTCOMPANY>${_escapeXml(companyName)}</SVCURRENTCOMPANY>');
    buffer.writeln('        </STATICVARIABLES>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    for (final p in purchases) {
      final dateStr = dateFmt.format(p.purchaseDate);
      final vendorLedger = p.vendorName.trim().isNotEmpty ? p.vendorName.trim() : 'Sundry Creditors - Hotel Suppliers';
      final purchaseLedger = _getPurchaseLedgerName(p.department);
      final halfTax = p.totalTax / 2.0;

      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Accounting Voucher View">');
      buffer.writeln('            <DATE>$dateStr</DATE>');
      buffer.writeln('            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>');
      buffer.writeln('            <VOUCHERNUMBER>${_escapeXml(p.invoiceNumber)}</VOUCHERNUMBER>');
      buffer.writeln('            <PARTYLEDGERNAME>${_escapeXml(vendorLedger)}</PARTYLEDGERNAME>');
      buffer.writeln('            <NARRATION>Purchase Invoice #${_escapeXml(p.invoiceNumber)} from ${_escapeXml(p.vendorName)} (${p.department}). Status: ${p.paymentStatus}</NARRATION>');
      if (p.vendorGstin.isNotEmpty) {
        buffer.writeln('            <PARTYGSTIN>${_escapeXml(p.vendorGstin)}</PARTYGSTIN>');
      }

      // Credit Vendor (Total Grand Amount)
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(vendorLedger)}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${p.grandTotal.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

      // Debit Purchase Account (Taxable SubTotal)
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>${_escapeXml(purchaseLedger)}</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>-${p.subTotal.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

      // Debit Input CGST (ITC)
      if (halfTax > 0) {
        buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
        buffer.writeln('              <LEDGERNAME>Input CGST</LEDGERNAME>');
        buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
        buffer.writeln('              <AMOUNT>-${halfTax.toStringAsFixed(2)}</AMOUNT>');
        buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

        // Debit Input SGST (ITC)
        buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
        buffer.writeln('              <LEDGERNAME>Input SGST</LEDGERNAME>');
        buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
        buffer.writeln('              <AMOUNT>-${halfTax.toStringAsFixed(2)}</AMOUNT>');
        buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
      }

      buffer.writeln('          </VOUCHER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  /// Generates 1-Click Master Chart of Accounts XML to pre-populate all hotel accounts in Tally
  static String generateChartOfAccountsMasterXml({required String companyName}) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>All Masters</REPORTNAME>');
    buffer.writeln('        <STATICVARIABLES>');
    buffer.writeln('          <SVCURRENTCOMPANY>${_escapeXml(companyName)}</SVCURRENTCOMPANY>');
    buffer.writeln('        </STATICVARIABLES>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');

    // Hotel Standard Ledgers Definition
    final ledgers = [
      // Revenue / Sales Accounts
      {'name': 'Room Sales Account', 'parent': 'Sales Accounts'},
      {'name': 'Restaurant Food Sales A/c', 'parent': 'Sales Accounts'},
      {'name': 'Banquet & Events Revenue', 'parent': 'Sales Accounts'},
      {'name': 'Online Food Delivery Sales', 'parent': 'Sales Accounts'},

      // Tax Ledgers (Duties & Taxes)
      {'name': 'Output CGST', 'parent': 'Duties & Taxes'},
      {'name': 'Output SGST', 'parent': 'Duties & Taxes'},
      {'name': 'Output IGST', 'parent': 'Duties & Taxes'},
      {'name': 'Input CGST', 'parent': 'Duties & Taxes'},
      {'name': 'Input SGST', 'parent': 'Duties & Taxes'},
      {'name': 'Input IGST', 'parent': 'Duties & Taxes'},

      // Direct / Indirect Expense Ledgers
      {'name': 'Kitchen Grocery & Food Purchases', 'parent': 'Direct Expenses'},
      {'name': 'Beverages & Soft Drinks Purchases', 'parent': 'Direct Expenses'},
      {'name': 'Housekeeping & Toiletries Purchases', 'parent': 'Direct Expenses'},
      {'name': 'Linen & Laundry Purchases', 'parent': 'Direct Expenses'},
      {'name': 'Hotel Electricity & Power Charges', 'parent': 'Indirect Expenses'},
      {'name': 'Staff Salaries & Wages', 'parent': 'Indirect Expenses'},
      {'name': 'Repairs & Property Maintenance', 'parent': 'Indirect Expenses'},
      {'name': 'Generator Diesel & Fuel Expense', 'parent': 'Indirect Expenses'},

      // Banks & Cash Ledgers
      {'name': 'Cash in Hand (Front Office)', 'parent': 'Cash-in-Hand'},
      {'name': 'Cash in Hand (Restaurant POS)', 'parent': 'Cash-in-Hand'},
      {'name': 'HDFC Hotel Current Account', 'parent': 'Bank Accounts'},
      {'name': 'UPI QR Collections Clearing A/c', 'parent': 'Bank Accounts'},
      {'name': 'Razorpay Payment Gateway A/c', 'parent': 'Bank Accounts'},

      // Groups / Debtors & Creditors
      {'name': 'Sundry Debtors - Hotel Guests', 'parent': 'Sundry Debtors'},
      {'name': 'Sundry Creditors - Hotel Suppliers', 'parent': 'Sundry Creditors'},
    ];

    for (final l in ledgers) {
      buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
      buffer.writeln('          <LEDGER NAME="${_escapeXml(l['name']!)}" ACTION="Create">');
      buffer.writeln('            <NAME>${_escapeXml(l['name']!)}</NAME>');
      buffer.writeln('            <PARENT>${_escapeXml(l['parent']!)}</PARENT>');
      buffer.writeln('            <ISBILLWISEON>Yes</ISBILLWISEON>');
      buffer.writeln('            <AFFECTSSTOCK>No</AFFECTSSTOCK>');
      buffer.writeln('          </LEDGER>');
      buffer.writeln('        </TALLYMESSAGE>');
    }

    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    return buffer.toString();
  }

  // ===========================================================================
  // 2. GSTR-1 TAX RETURN EXPORTERS (GOVERNMENT SPEC)
  // ===========================================================================

  /// GSTR-1 Table 4: B2B Invoices (Registered Buyers with GSTIN)
  static String generateGstr1B2bCsv({required List<ErpInvoiceRecord> invoices}) {
    final b2b = invoices.where((i) => i.isB2B).toList();
    final buffer = StringBuffer();
    final dateFmt = DateFormat('dd-MMM-yyyy');

    buffer.writeln('GSTIN/UIN of Recipient,Receiver Name,Invoice Number,Invoice date,Invoice Value,Place Of Supply,Reverse Charge,Applicable % of Tax Rate,Invoice Type,E-Commerce GSTIN,Rate,Taxable Value,Cess Amount');

    for (final inv in b2b) {
      final rate = inv.taxableAmount > 0 ? ((inv.totalGst / inv.taxableAmount) * 100).round() : 12;
      buffer.writeln([
        inv.customerGstin ?? '',
        _escapeCsv(inv.customerName),
        _escapeCsv(inv.invoiceNumber),
        dateFmt.format(inv.date),
        inv.totalAmount.toStringAsFixed(2),
        inv.placeOfSupply,
        inv.isReverseCharge ? 'Y' : 'N',
        '', // Applicable % of tax rate (regular)
        'Regular',
        '', // E-Commerce GSTIN
        rate,
        inv.taxableAmount.toStringAsFixed(2),
        '0.00',
      ].join(','));
    }

    return buffer.toString();
  }

  /// GSTR-1 Table 7: B2C Small Invoices (Unregistered Consumers)
  static String generateGstr1B2csCsv({required List<ErpInvoiceRecord> invoices}) {
    final b2cs = invoices.where((i) => !i.isB2B).toList();
    final buffer = StringBuffer();

    buffer.writeln('Type,Place of Supply,Applicable % of Tax Rate,Rate,Taxable Value,Cess Amount,E-Commerce GSTIN');

    // Group B2CS by POS and Tax Rate
    final groups = <String, double>{};
    final rateMap = <String, int>{};

    for (final inv in b2cs) {
      final rate = inv.taxableAmount > 0 ? ((inv.totalGst / inv.taxableAmount) * 100).round() : 5;
      final key = '${inv.placeOfSupply}|$rate';
      groups[key] = (groups[key] ?? 0.0) + inv.taxableAmount;
      rateMap[key] = rate;
    }

    for (final entry in groups.entries) {
      final parts = entry.key.split('|');
      final pos = parts[0];
      final rate = rateMap[entry.key] ?? 5;
      buffer.writeln([
        'OE', // Other than E-commerce
        pos,
        '',
        rate,
        entry.value.toStringAsFixed(2),
        '0.00',
        '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// GSTR-1 Table 12: HSN/SAC Summary of Outward Supplies
  static String generateGstr1HsnCsv({required List<ErpInvoiceRecord> invoices}) {
    final buffer = StringBuffer();
    buffer.writeln('HSN,Description,UQC,Total Quantity,Total Value,Taxable Value,Integrated Tax Amount,Central Tax Amount,State/UT Tax Amount,Cess Amount');

    // Aggregate by HSN Code
    final hsnMap = <String, Map<String, dynamic>>{};

    for (final inv in invoices) {
      for (final item in inv.items) {
        final hsn = item.hsnSacCode;
        if (!hsnMap.containsKey(hsn)) {
          hsnMap[hsn] = {
            'description': item.description,
            'qty': 0,
            'taxable': 0.0,
            'cgst': 0.0,
            'sgst': 0.0,
            'igst': 0.0,
          };
        }
        final record = hsnMap[hsn]!;
        record['qty'] = (record['qty'] as int) + item.quantity;
        record['taxable'] = (record['taxable'] as double) + item.amount;
        final itemTax = item.amount * (item.gstRate / 100.0);
        if (inv.isInterState) {
          record['igst'] = (record['igst'] as double) + itemTax;
        } else {
          record['cgst'] = (record['cgst'] as double) + (itemTax / 2.0);
          record['sgst'] = (record['sgst'] as double) + (itemTax / 2.0);
        }
      }
    }

    for (final entry in hsnMap.entries) {
      final hsn = entry.key;
      final data = entry.value;
      final totalTax = (data['cgst'] as double) + (data['sgst'] as double) + (data['igst'] as double);
      final totalVal = (data['taxable'] as double) + totalTax;

      buffer.writeln([
        hsn,
        _escapeCsv(_getHsnDescription(hsn)),
        'OTH-OTHERS',
        data['qty'],
        totalVal.toStringAsFixed(2),
        (data['taxable'] as double).toStringAsFixed(2),
        (data['igst'] as double).toStringAsFixed(2),
        (data['cgst'] as double).toStringAsFixed(2),
        (data['sgst'] as double).toStringAsFixed(2),
        '0.00',
      ].join(','));
    }

    return buffer.toString();
  }

  /// GSTR-1 Table 13: Summary of Documents Issued during tax period
  static String generateGstr1DocsCsv({required List<ErpInvoiceRecord> invoices}) {
    final buffer = StringBuffer();
    buffer.writeln('Nature of Document,Sr. No. From,Sr. No. To,Total Number,Cancelled');

    if (invoices.isEmpty) {
      buffer.writeln('Invoices for outward supply,N/A,N/A,0,0');
      return buffer.toString();
    }

    final firstNo = invoices.first.invoiceNumber;
    final lastNo = invoices.last.invoiceNumber;
    final total = invoices.length;
    final cancelled = invoices.where((i) => i.status == ErpInvoiceStatus.cancelled).length;

    buffer.writeln([
      'Invoices for outward supply',
      firstNo,
      lastNo,
      total,
      cancelled,
    ].join(','));

    return buffer.toString();
  }

  // ===========================================================================
  // 3. GSTR-3B STATUTORY TAX LIABILITY CALCULATOR
  // ===========================================================================

  static Gstr3bSummary calculateGstr3b({
    required List<ErpInvoiceRecord> invoices,
    required List<PurchaseEntry> purchases,
    required List<ExpenseEntry> expenses,
  }) {
    double outwardTaxable = 0.0;
    double outwardCgst = 0.0;
    double outwardSgst = 0.0;
    double outwardIgst = 0.0;

    for (final inv in invoices) {
      if (inv.status == ErpInvoiceStatus.cancelled) continue;
      outwardTaxable += inv.taxableAmount;
      outwardCgst += inv.cgst;
      outwardSgst += inv.sgst;
      outwardIgst += inv.igst;
    }

    // Input Tax Credit (ITC) from Purchases
    double itcCgst = 0.0;
    double itcSgst = 0.0;
    double itcIgst = 0.0;

    for (final p in purchases) {
      final halfTax = p.totalTax / 2.0;
      itcCgst += halfTax;
      itcSgst += halfTax;
    }

    // Input Tax Credit (ITC) from Operating Expenses (eligible commercial expenses)
    for (final e in expenses) {
      if (e.taxAmount > 0) {
        itcCgst += e.taxAmount / 2.0;
        itcSgst += e.taxAmount / 2.0;
      }
    }

    final netCgstPayable = (outwardCgst - itcCgst).clamp(0.0, double.infinity);
    final netSgstPayable = (outwardSgst - itcSgst).clamp(0.0, double.infinity);
    final netIgstPayable = (outwardIgst - itcIgst).clamp(0.0, double.infinity);
    final netCashTaxPayable = netCgstPayable + netSgstPayable + netIgstPayable;

    return Gstr3bSummary(
      outwardTaxable: outwardTaxable,
      outwardCgst: outwardCgst,
      outwardSgst: outwardSgst,
      outwardIgst: outwardIgst,
      totalOutwardTax: outwardCgst + outwardSgst + outwardIgst,
      itcCgst: itcCgst,
      itcSgst: itcSgst,
      itcIgst: itcIgst,
      totalEligibleItc: itcCgst + itcSgst + itcIgst,
      netCgstPayable: netCgstPayable,
      netSgstPayable: netSgstPayable,
      netIgstPayable: netIgstPayable,
      netCashTaxPayable: netCashTaxPayable,
    );
  }

  // ===========================================================================
  // 4. STATUTORY FORM C (BUREAU OF IMMIGRATION / FRRO COMPLIANCE)
  // ===========================================================================

  /// Foreigners Registration under Rule 14 of Foreigners Registration Rules, 1992
  static String generateFormCCsv({required List<GuestModel> guests}) {
    final buffer = StringBuffer();
    final dateFmt = DateFormat('dd/MM/yyyy');

    buffer.writeln('Guest Name,Nationality,Passport Number,Passport Expiry,Visa Number,Visa Type,Visa Expiry,Port of Arrival,Arrival Date in India,Phone,Proposed Departure');

    final foreigners = guests.where((g) => g.isForeigner).toList();

    for (final g in foreigners) {
      buffer.writeln([
        _escapeCsv(g.fullName),
        g.nationality,
        g.passportNumber ?? g.idNumber,
        g.passportExpiryDate != null ? dateFmt.format(g.passportExpiryDate!) : '',
        g.visaNumber ?? '',
        g.visaType ?? 'Tourist',
        g.visaExpiryDate != null ? dateFmt.format(g.visaExpiryDate!) : '',
        _escapeCsv(g.portOfArrival ?? 'Mumbai International Airport (BOM)'),
        g.dateOfArrivalInIndia != null ? dateFmt.format(g.dateOfArrivalInIndia!) : '',
        g.phone,
        g.proposedDepartureDate != null ? dateFmt.format(g.proposedDepartureDate!) : '',
      ].join(','));
    }

    return buffer.toString();
  }

  // ===========================================================================
  // 5. INDIAN RUPEE AMOUNT TO WORDS CONVERTER (Lakhs & Crores)
  // ===========================================================================

  /// Converts a numeric amount into standard Indian currency words
  static String numberToIndianWords(double amount) {
    if (amount <= 0) return 'Rupees Zero Only';

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    final result = StringBuffer('Rupees ');
    result.write(_convertNumberToWords(rupees));

    if (paise > 0) {
      result.write(' and ${_convertNumberToWords(paise)} Paise');
    }

    result.write(' Only');
    return result.toString();
  }

  static String _convertNumberToWords(int number) {
    if (number == 0) return 'Zero';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String twoDigits(int n) {
      if (n < 20) return units[n];
      return '${tens[n ~/ 10]}${n % 10 > 0 ? " ${units[n % 10]}" : ""}';
    }

    String threeDigits(int n) {
      if (n >= 100) {
        final h = n ~/ 100;
        final rem = n % 100;
        return '${units[h]} Hundred${rem > 0 ? " and ${twoDigits(rem)}" : ""}';
      }
      return twoDigits(n);
    }

    int remaining = number;
    final parts = <String>[];

    // Crores (>= 1,00,00,000)
    if (remaining >= 10000000) {
      final cr = remaining ~/ 10000000;
      parts.add('${_convertNumberToWords(cr)} Crore');
      remaining %= 10000000;
    }

    // Lakhs (>= 1,00,000)
    if (remaining >= 100000) {
      final lk = remaining ~/ 100000;
      parts.add('${twoDigits(lk)} Lakh');
      remaining %= 100000;
    }

    // Thousands (>= 1,000)
    if (remaining >= 1000) {
      final th = remaining ~/ 1000;
      parts.add('${twoDigits(th)} Thousand');
      remaining %= 1000;
    }

    // Hundreds & units (< 1,000)
    if (remaining > 0) {
      parts.add(threeDigits(remaining));
    }

    return parts.join(' ');
  }

  // ===========================================================================
  // 6. SAVE AS WINDOWS DIALOG FILE HELPERS
  // ===========================================================================

  /// Prompts Windows Save-As dialog to save XML file
  static Future<bool> saveXmlFile({
    required BuildContext context,
    required String suggestedName,
    required String xmlContent,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to Tally XML — Save As',
        fileName: '$suggestedName.xml',
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (path == null) return false;

      final file = File(path);
      await file.writeAsString(xmlContent, encoding: utf8);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tally XML Saved: ${file.path.split(Platform.pathSeparator).last}'),
            backgroundColor: const Color(0xFF1B4F72),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving Tally XML: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  /// Prompts Windows Save-As dialog to save CSV file
  static Future<bool> saveCsvFile({
    required BuildContext context,
    required String suggestedName,
    required String csvContent,
  }) async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Statutory Return — Save As',
        fileName: '$suggestedName.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (path == null) return false;

      final file = File(path);
      await file.writeAsString(csvContent, encoding: utf8);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statutory CSV Exported: ${file.path.split(Platform.pathSeparator).last}'),
            backgroundColor: const Color(0xFF1E8449),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving CSV: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _escapeCsv(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _getSalesLedgerName(ErpInvoiceType type) {
    switch (type) {
      case ErpInvoiceType.roomStay:
        return 'Room Sales Account';
      case ErpInvoiceType.restaurantPos:
        return 'Restaurant Food Sales A/c';
      case ErpInvoiceType.onlineDelivery:
        return 'Online Food Delivery Sales';
      case ErpInvoiceType.banquetHall:
        return 'Banquet & Events Revenue';
    }
  }

  static String _getPurchaseLedgerName(String department) {
    final lower = department.toLowerCase();
    if (lower.contains('kitchen') || lower.contains('grocery')) {
      return 'Kitchen Grocery & Food Purchases';
    } else if (lower.contains('beverage') || lower.contains('bar')) {
      return 'Beverages & Soft Drinks Purchases';
    } else if (lower.contains('housekeeping')) {
      return 'Housekeeping & Toiletries Purchases';
    } else if (lower.contains('linen') || lower.contains('laundry')) {
      return 'Linen & Laundry Purchases';
    }
    return 'Hotel Operating Supplies A/c';
  }

  static String _getPaymentLedger(String mode) {
    final lower = mode.toLowerCase();
    if (lower.contains('cash')) return 'Cash in Hand (Front Office)';
    if (lower.contains('upi') || lower.contains('gpay') || lower.contains('phonepe') || lower.contains('paytm')) {
      return 'UPI QR Collections Clearing A/c';
    }
    if (lower.contains('razorpay')) return 'Razorpay Payment Gateway A/c';
    if (lower.contains('card') || lower.contains('pos')) return 'HDFC Hotel Current Account';
    return 'HDFC Hotel Current Account';
  }

  static String _getHsnDescription(String hsn) {
    switch (hsn) {
      case '996311':
        return 'Room Accommodation Services';
      case '996331':
        return 'Restaurant and Food Service';
      case '996332':
        return 'Banquet and Catering Service';
      case '996412':
        return 'Local Passenger Transport Service';
      default:
        return 'Hospitality and Catering Services';
    }
  }
}

// =============================================================================
// Helper Data Classes
// =============================================================================

class Gstr3bSummary {
  final double outwardTaxable;
  final double outwardCgst;
  final double outwardSgst;
  final double outwardIgst;
  final double totalOutwardTax;

  final double itcCgst;
  final double itcSgst;
  final double itcIgst;
  final double totalEligibleItc;

  final double netCgstPayable;
  final double netSgstPayable;
  final double netIgstPayable;
  final double netCashTaxPayable;

  const Gstr3bSummary({
    required this.outwardTaxable,
    required this.outwardCgst,
    required this.outwardSgst,
    required this.outwardIgst,
    required this.totalOutwardTax,
    required this.itcCgst,
    required this.itcSgst,
    required this.itcIgst,
    required this.totalEligibleItc,
    required this.netCgstPayable,
    required this.netSgstPayable,
    required this.netIgstPayable,
    required this.netCashTaxPayable,
  });
}

class McaAuditTrailEntry {
  final DateTime timestamp;
  final String voucherNo;
  final String action; // CREATED, MODIFIED, CANCELLED, EXPORTED
  final String userId;
  final String userRole;
  final String details;
  final String checksum;

  const McaAuditTrailEntry({
    required this.timestamp,
    required this.voucherNo,
    required this.action,
    required this.userId,
    required this.userRole,
    required this.details,
    required this.checksum,
  });
}
