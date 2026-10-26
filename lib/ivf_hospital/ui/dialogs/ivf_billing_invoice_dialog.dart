import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_billing_model.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Hospital Billing, IVF Package & GST Invoice Register Dialog
class IvfBillingInvoiceDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const IvfBillingInvoiceDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => IvfBillingInvoiceDialog(repo: repo),
    );
  }

  @override
  State<IvfBillingInvoiceDialog> createState() => _IvfBillingInvoiceDialogState();
}

class _IvfBillingInvoiceDialogState extends State<IvfBillingInvoiceDialog> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  String _categoryFilter = 'ALL';
  String _searchQuery = '';
  int _selectedRow = 0;

  void _showNewInvoiceModal() {
    String? selectedUhid = widget.repo.patients.isNotEmpty ? widget.repo.patients.first.uhid : null;
    String category = 'IVF Package';
    final descCtrl = TextEditingController(text: 'All-Inclusive ICSI + Day 5 Blastocyst + FET Package');
    final amountCtrl = TextEditingController(text: '140000');
    final paidCtrl = TextEditingController(text: '140000');
    String paymentMode = 'UPI (PhonePe / Google Pay)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final total = double.tryParse(amountCtrl.text) ?? 0.0;
          final paid = double.tryParse(paidCtrl.text) ?? 0.0;
          final due = (total - paid).clamp(0.0, double.infinity);

          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: IvfErpTheme.primaryNavy, size: 18),
                SizedBox(width: 8),
                Text('Generate Hospital Bill / IVF Package Invoice', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Patient *', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.repo.patients.any((p) => p.uhid == selectedUhid)
                              ? selectedUhid
                              : (widget.repo.patients.isNotEmpty ? widget.repo.patients.first.uhid : null),
                          isDense: true,
                          isExpanded: true,
                          items: widget.repo.patients.map((p) => DropdownMenuItem(
                            value: p.uhid,
                            child: Text('${p.uhid} — ${p.femaleName}', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setModalState(() => selectedUhid = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Service Category *', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Container(
                                height: 28,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ['IVF Package', 'Consultation & OPD', 'Diagnostics Lab', 'Pharmacy & Meds', 'OT & Delivery'].contains(category) ? category : 'IVF Package',
                                    isDense: true,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'IVF Package', child: Text('IVF Package')),
                                      DropdownMenuItem(value: 'OPD Consultation', child: Text('OPD Consultation')),
                                      DropdownMenuItem(value: 'Maternity Delivery IPD', child: Text('Maternity Delivery IPD')),
                                      DropdownMenuItem(value: 'Diagnostics / Lab', child: Text('Diagnostics / Lab')),
                                      DropdownMenuItem(value: 'Pharmacy', child: Text('Pharmacy')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setModalState(() {
                                          category = v;
                                          if (v == 'OPD Consultation') {
                                            descCtrl.text = 'Gynecology Consultation & Pelvic USG';
                                            amountCtrl.text = '1500';
                                            paidCtrl.text = '1500';
                                          } else if (v == 'Maternity Delivery IPD') {
                                            descCtrl.text = 'LSCS Delivery Package + 3 Days Deluxe Room';
                                            amountCtrl.text = '55000';
                                            paidCtrl.text = '55000';
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Payment Settlement Mode *', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Container(
                                height: 28,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ['Cash Counter', 'UPI (PhonePe / Google Pay)', 'Credit / Debit Card (POS)', 'NEFT / RTGS', 'TPA / Insurance Desk'].contains(paymentMode) ? paymentMode : 'UPI (PhonePe / Google Pay)',
                                    isDense: true,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'Cash Counter', child: Text('Cash Counter')),
                                      DropdownMenuItem(value: 'UPI (PhonePe / Google Pay)', child: Text('UPI (PhonePe / GPay)')),
                                      DropdownMenuItem(value: 'Credit / Debit Card POS', child: Text('Credit / Debit Card POS')),
                                      DropdownMenuItem(value: 'Bank NEFT / RTGS', child: Text('Bank NEFT / RTGS')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => paymentMode = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Service Description *', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: TextField(
                        controller: descCtrl,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Bill Amount (₹) *', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Container(
                                height: 28,
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                                child: TextField(
                                  controller: amountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Paid Amount (₹) *', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Container(
                                height: 28,
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                                child: TextField(
                                  controller: paidCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald),
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Balance Due (₹)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.alertRuby)),
                              const SizedBox(height: 3),
                              Container(
                                height: 28,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                color: const Color(0xFFFADBD8),
                                child: Text(_currency.format(due), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.alertRuby)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text('Confirm & Generate Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IvfErpTheme.medicalEmerald,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () {
                  final patient = widget.repo.patients.firstWhere(
                    (p) => p.uhid == selectedUhid,
                    orElse: () => widget.repo.patients.isNotEmpty ? widget.repo.patients.first : IvfPatientModel.empty(),
                  );
                  if (patient.uhid == 'N/A') return;
                  final invNo = '${widget.repo.config.invoicePrefix}${(widget.repo.invoices.length + 101)}';
                  final inv = IvfBillingModel(
                    invoiceNumber: invNo,
                    patientUhid: patient.uhid,
                    patientName: patient.femaleName,
                    category: category,
                    serviceDescription: descCtrl.text.trim(),
                    baseTaxable: total,
                    totalAmount: total,
                    paidAmount: paid,
                    balanceDue: due,
                    paymentMode: paymentMode,
                    status: due <= 0 ? 'PAID' : (paid > 0 ? 'PARTIAL' : 'DUE'),
                  );
                  widget.repo.addBillingInvoice(inv);
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invoice $invNo generated successfully!'), backgroundColor: IvfErpTheme.medicalEmerald),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalInvoiced = 0.0;
    double totalCollected = 0.0;
    double totalDue = 0.0;

    final filtered = widget.repo.invoices.where((inv) {
      if (_categoryFilter != 'ALL' && inv.category != _categoryFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.patientName.toLowerCase().contains(q) ||
            inv.patientUhid.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    for (var i in filtered) {
      totalInvoiced += i.totalAmount;
      totalCollected += i.paidAmount;
      totalDue += i.balanceDue;
    }

    return Win32WindowFrame(
      title: 'HOSPITAL BILLING, IVF PACKAGES & GST INVOICES',
      subtitle: '${widget.repo.config.hospitalName} • ${widget.repo.config.activeBranch.branchName}',
      icon: Icons.receipt_long_rounded,
      defaultWidth: 1040,
      defaultHeight: 650,
      child: Column(
        children: [
          // Top Summary Cards
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  _metricCard('Gross Invoiced Value', _currency.format(totalInvoiced), Icons.receipt_rounded, IvfErpTheme.primaryNavy),
                  const SizedBox(width: 8),
                  _metricCard('Total Paid / Collected', _currency.format(totalCollected), Icons.payments_rounded, IvfErpTheme.medicalEmerald),
                  const SizedBox(width: 8),
                  _metricCard('Outstanding Due / BTC', _currency.format(totalDue), Icons.pending_actions_rounded, IvfErpTheme.alertRuby),
                ],
              ),
            ),

            // Filter Toolbar (with SingleChildScrollView to guarantee zero overflow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: IvfErpTheme.toolbarBg,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 200,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: IvfErpTheme.borderDark),
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.search, size: 13, color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        style: const TextStyle(fontSize: 11),
                                        decoration: const InputDecoration(
                                          hintText: 'Search Invoice, UHID, Patient...',
                                          hintStyle: TextStyle(fontSize: 10, color: Colors.grey),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                                        ),
                                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Category: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Container(
                                height: 28,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: IvfErpTheme.borderDark),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ['ALL', 'IVF Package', 'OPD Consultation', 'Maternity Delivery IPD'].contains(_categoryFilter) ? _categoryFilter : 'ALL',
                                    isDense: true,
                                    style: const TextStyle(fontSize: 11, color: IvfErpTheme.textMain, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'ALL', child: Text('All Categories')),
                                      DropdownMenuItem(value: 'IVF Package', child: Text('IVF Package')),
                                      DropdownMenuItem(value: 'OPD Consultation', child: Text('OPD Consultation')),
                                      DropdownMenuItem(value: 'Maternity Delivery IPD', child: Text('Maternity Delivery IPD')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setState(() => _categoryFilter = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_task_rounded, size: 13),
                                label: const Text('+ New Bill / Invoice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IvfErpTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: _showNewInvoiceModal,
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_rounded, size: 13),
                                label: const Text('Print 80mm POS Slip'),
                                style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                onPressed: () {
                                  if (filtered.isNotEmpty) {
                                    final idx = _selectedRow.clamp(0, filtered.length - 1);
                                    _openPrintPreview(filtered[idx], is80mm: true);
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.print_rounded, size: 13),
                                label: const Text('Print A4 Tax Invoice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IvfErpTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () {
                                  if (filtered.isNotEmpty) {
                                    final idx = _selectedRow.clamp(0, filtered.length - 1);
                                    _openPrintPreview(filtered[idx], is80mm: false);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Invoices DataGrid
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(border: Border.all(color: IvfErpTheme.borderDark)),
                child: filtered.isEmpty
                    ? const Center(child: Text('No invoice records found.', style: TextStyle(fontSize: 11, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == 0) {
                            return Container(
                              height: 28,
                              color: IvfErpTheme.gridHeaderBg,
                              child: const Row(
                                children: [
                                  SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 120, child: Text('Invoice No', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 90, child: Text('UHID', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('Patient Name', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 3, child: Text('Billing Description', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 100, child: Text('Total (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 100, child: Text('Paid (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 80, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            );
                          }

                          final item = filtered[idx - 1];
                          final isSelected = _selectedRow == (idx - 1);

                          return InkWell(
                            onTap: () => setState(() => _selectedRow = idx - 1),
                            child: Container(
                              height: 26,
                              color: isSelected ? IvfErpTheme.gridRowSelected : (idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd),
                              child: Row(
                                children: [
                                  SizedBox(width: 35, child: Text('$idx', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                                  SizedBox(width: 120, child: Text(item.invoiceNumber, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                                  SizedBox(width: 90, child: Text(item.patientUhid, style: const TextStyle(fontSize: 10))),
                                  Expanded(flex: 2, child: Text(item.patientName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                                  Expanded(flex: 3, child: Text(item.serviceDescription, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                                  SizedBox(width: 100, child: Text(_currency.format(item.totalAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 100, child: Text(_currency.format(item.paidAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold))),
                                  SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        color: item.status == 'PAID' ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
                                        child: Text(
                                          item.status,
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: item.status == 'PAID' ? IvfErpTheme.medicalEmerald : IvfErpTheme.alertRuby,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Bottom Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Filtered Bills: ${filtered.length} | Invoiced: ${_currency.format(totalInvoiced)} | Collected: ${_currency.format(totalCollected)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Window'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _openPrintPreview(IvfBillingModel inv, {required bool is80mm}) {
    PrintPreviewDialog.show(
      context: context,
      config: widget.repo.config,
      documentTitle: is80mm ? 'CASH RECEIPT / POS SLIP' : 'TAX INVOICE / BILL OF SUPPLY',
      documentSubtitle: inv.category,
      documentNumber: inv.invoiceNumber,
      initialPaperFormat: is80mm ? '80MM' : 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient: ${inv.patientName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('UHID: ${inv.patientUhid}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Payment Mode: ${inv.paymentMode}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      Text('Status: ${inv.status}', style: const TextStyle(fontSize: 10, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.8),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFEBF5FB)),
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Service Description', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Rate (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('GST (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Total (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(inv.serviceDescription, style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(_currency.format(inv.taxableAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(_currency.format(inv.totalGst), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(_currency.format(inv.totalAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 260,
                padding: const EdgeInsets.all(8),
                color: const Color(0xFFF4F6F6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Invoiced Amount:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                        Text(_currency.format(inv.totalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid / Deposited:', style: TextStyle(fontSize: 10.5, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold)),
                        Text(_currency.format(inv.paidAmount), style: const TextStyle(fontSize: 11, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (inv.balanceDue > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance Due Pending:', style: TextStyle(fontSize: 10.5, color: IvfErpTheme.alertRuby, fontWeight: FontWeight.bold)),
                          Text(_currency.format(inv.balanceDue), style: const TextStyle(fontSize: 11, color: IvfErpTheme.alertRuby, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderLight)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: IvfErpTheme.textMuted, fontWeight: FontWeight.w600)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
