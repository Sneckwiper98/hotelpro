import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/folio_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_form_widgets.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';

/// Classic Windows Desktop Folio & Billing View
/// High-density spreadsheet ledger, classic Win32 action ribbon, and tax invoice generator.
class FolioView extends StatefulWidget {
  const FolioView({super.key});

  @override
  State<FolioView> createState() => _FolioViewState();
}

class _FolioViewState extends State<FolioView> {
  String? _selectedFolioId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final folios = repo.activeBranchFolios;

    // Default select first open folio if none selected
    if ((_selectedFolioId == null || !folios.any((f) => f.id == _selectedFolioId)) && folios.isNotEmpty) {
      _selectedFolioId = folios.first.id;
    }

    final selectedFolio = folios.firstWhere(
      (f) => f.id == _selectedFolioId,
      orElse: () => folios.isNotEmpty ? folios.first : const FolioModel(
        id: '',
        reservationId: '',
        folioNumber: '',
        roomNumber: '',
        guestName: 'No Folio Available',
        transactions: [],
      ),
    );

    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Container(
      color: ClassicErpTheme.windowBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Column: Active Folios Spreadsheet (260px) ──────────────
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F7),
              border: Border(right: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ribbon Header
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: ClassicErpTheme.gridHeaderBg,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'ACTIVE GUEST FOLIOS',
                    style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: folios.isEmpty
                      ? const Center(child: Text('No active folios', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)))
                      : ListView.builder(
                          itemCount: folios.length,
                          itemBuilder: (context, index) {
                            final folio = folios[index];
                            final isSelected = folio.id == _selectedFolioId;

                            return InkWell(
                              onTap: () => setState(() => _selectedFolioId = folio.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ClassicErpTheme.gridSelectedRow
                                      : (index.isEven ? Colors.white : const Color(0xFFF8F9F9)),
                                  border: Border(
                                    bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 0.5),
                                    left: isSelected ? const BorderSide(color: Color(0xFF1B4F72), width: 3) : BorderSide.none,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          color: const Color(0xFF1B4F72),
                                          child: Text(
                                            'RM ${folio.roomNumber}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            folio.guestName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: ClassicErpTheme.textMain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(folio.folioNumber, style: const TextStyle(color: ClassicErpTheme.textMuted, fontSize: 9.5)),
                                        Text(
                                          'Due: ${currency.format(folio.balanceDue)}',
                                          style: TextStyle(
                                            color: folio.balanceDue > 0 ? const Color(0xFFC0392B) : const Color(0xFF27AE60),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10.5,
                                          ),
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
              ],
            ),
          ),

          // ── Right Column: Master Folio Ledger Details Canvas ─────────────
          Expanded(
            child: selectedFolio.id.isEmpty
                ? const Center(child: Text('Select a guest folio to inspect ledger', style: TextStyle(color: ClassicErpTheme.textMuted)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Action & Summary Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          color: ClassicErpTheme.panelBg,
                          border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
                        ),
                        child: Column(
                          children: [
                            LayoutBuilder(
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
                                            Text(
                                              'FOLIO: ${selectedFolio.folioNumber} [Room ${selectedFolio.roomNumber}]',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• Guest: ${selectedFolio.guestName}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClassicErpTheme.textMain),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),

                                        // Action Buttons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _classicButton(Icons.add_rounded, 'Post Extra Charge', () => _showAddChargeDialog(context, selectedFolio, repo)),
                                            const SizedBox(width: 4),
                                            _classicButton(Icons.payment_rounded, 'Post Payment', () => _showRecordPaymentDialog(context, selectedFolio, repo), color: const Color(0xFF27AE60)),
                                            const SizedBox(width: 4),
                                            _classicButton(Icons.download_rounded, 'Export Folio', () {
                                              final currency = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2);
                                              ExcelExportService.saveAsCsv(
                                                context,
                                                suggestedName: 'Folio_${selectedFolio.folioNumber}_${selectedFolio.guestName.replaceAll(' ', '_')}',
                                                headers: ['Date', 'Description', 'Category', 'Amount', 'Tax', 'Credit'],
                                                rows: selectedFolio.transactions.map((t) => [
                                                  DateFormat('dd-MMM-yyyy HH:mm').format(t.timestamp),
                                                  t.description,
                                                  t.category,
                                                  currency.format(t.amount),
                                                  currency.format(t.taxAmount),
                                                  t.isCredit ? 'YES' : 'NO',
                                                ]).toList(),
                                              );
                                            }, color: const Color(0xFF1E7145)),
                                            const SizedBox(width: 4),
                                            _classicButton(Icons.print_rounded, 'Print Tax Invoice', () => _showTaxInvoiceDialog(context, selectedFolio, repo)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // KPI Financial Summary Counters
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              color: Colors.white,
                              child: LayoutBuilder(
                                builder: (context, kpiConstraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: kpiConstraints.maxWidth),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatBlock('Total Charges', currency.format(selectedFolio.totalCharges)),
                                          _statDivider(),
                                          _buildStatBlock('Taxes (GST)', currency.format(selectedFolio.totalTaxes)),
                                          _statDivider(),
                                          _buildStatBlock('Credits / Paid', currency.format(selectedFolio.totalPaid), color: const Color(0xFF27AE60)),
                                          _statDivider(),
                                          _buildStatBlock(
                                            'Net Balance Due',
                                            currency.format(selectedFolio.balanceDue),
                                            color: selectedFolio.balanceDue > 0 ? const Color(0xFFC0392B) : const Color(0xFF27AE60),
                                            isBold: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Transactions Spreadsheet Grid Header & Table
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, tableConstraints) {
                            const double minTableWidth = 580.0;
                            final double effectiveWidth = tableConstraints.maxWidth < minTableWidth
                                ? minTableWidth
                                : tableConstraints.maxWidth;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: effectiveWidth,
                                child: Column(
                                  children: [
                                    // Grid Header
                                    Container(
                                      height: 24,
                                      color: ClassicErpTheme.gridHeaderBg,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: const Row(
                                        children: [
                                          SizedBox(width: 130, child: Text('DATE / TIME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 100, child: Text('CATEGORY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                          Expanded(child: Text('TRANSACTION DESCRIPTION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 100, child: Text('VOUCHER / REF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 110, child: Align(alignment: Alignment.centerRight, child: Text('AMOUNT (₹)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                        ],
                                      ),
                                    ),

                                    // Itemized Transactions Table
                                    Expanded(
                                      child: selectedFolio.transactions.isEmpty
                                          ? const Center(
                                              child: Text('No transactions recorded for this folio.', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
                                            )
                                          : ListView.builder(
                                              itemCount: selectedFolio.transactions.length,
                                              itemBuilder: (context, index) {
                                                final txn = selectedFolio.transactions[index];
                                                final dtStr = DateFormat('yyyy-MM-dd HH:mm').format(txn.timestamp);

                                                return Container(
                                                  height: 26,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    color: index.isEven ? Colors.white : const Color(0xFFF4F6F7),
                                                    border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 130,
                                                        child: Text(dtStr, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain)),
                                                      ),
                                                      SizedBox(
                                                        width: 100,
                                                        child: Text(
                                                          txn.category.label,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: txn.isCredit ? const Color(0xFF27AE60) : const Color(0xFF1B4F72),
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          txn.description,
                                                          style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 100,
                                                        child: Text(txn.referenceId ?? '-', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                                                      ),
                                                      SizedBox(
                                                        width: 110,
                                                        child: Align(
                                                          alignment: Alignment.centerRight,
                                                          child: Text(
                                                            '${txn.isCredit ? '-' : '+'}${currency.format(txn.amount + txn.taxAmount)}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: txn.isCredit ? const Color(0xFF27AE60) : const Color(0xFF1B4F72),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: color ?? ClassicErpTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 26, color: ClassicErpTheme.borderLight, margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _classicButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color ?? ClassicErpTheme.buttonBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color != null ? Colors.white : const Color(0xFF1B4F72)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: color != null ? Colors.white : ClassicErpTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog: Add Custom Charge (Spa, Laundry, Minibar, etc.)
  void _showAddChargeDialog(BuildContext context, FolioModel folio, HotelRepository repo) {
    FolioCategory category = FolioCategory.spa;
    final descCtrl = TextEditingController(text: 'Royal Spa Treatment');
    final amountCtrl = TextEditingController(text: '3500');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: ClassicErpTheme.panelBg,
                border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF1B4F72),
                    child: Row(
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Post Extra Charge — Room ${folio.roomNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            color: const Color(0xFFC0392B),
                            child: const Icon(Icons.close, size: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClassicErpDropdown<FolioCategory>(
                          label: 'Category',
                          value: category,
                          items: [
                            FolioCategory.spa,
                            FolioCategory.minibar,
                            FolioCategory.laundry,
                            FolioCategory.restaurant,
                            FolioCategory.banquet,
                          ].map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                category = val;
                                descCtrl.text = '${val.label} Service';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),

                        _classicInput('Description / Item Details', descCtrl),
                        const SizedBox(height: 8),
                        _classicInput('Amount (₹) (Before GST)', amountCtrl, isNumeric: true),

                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _classicDialogButton('Cancel', () => Navigator.pop(ctx)),
                            const SizedBox(width: 6),
                            _classicDialogButton('Post Charge', () {
                              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                              if (amt <= 0) return;
                              final tax = amt * 0.18; // 18% GST

                              repo.postChargeToRoomFolio(
                                roomNumber: folio.roomNumber,
                                category: category,
                                description: descCtrl.text,
                                amount: amt,
                                taxAmount: tax,
                                referenceId: 'CHG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              );

                              Navigator.pop(ctx);
                            }, color: const Color(0xFF1B4F72), textColor: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Dialog: Collect Payment / Settlement
  void _showRecordPaymentDialog(BuildContext context, FolioModel folio, HotelRepository repo) {
    PaymentMethod method = PaymentMethod.creditCard;
    final amountCtrl = TextEditingController(text: folio.balanceDue.toStringAsFixed(0));
    final refCtrl = TextEditingController(text: 'TXN-POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: ClassicErpTheme.panelBg,
                border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF27AE60),
                    child: Row(
                      children: [
                        const Icon(Icons.payment_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Record Settlement Payment — Room ${folio.roomNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            color: const Color(0xFFC0392B),
                            child: const Icon(Icons.close, size: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClassicErpDropdown<PaymentMethod>(
                          label: 'Payment Method',
                          value: method,
                          items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => method = val);
                          },
                        ),
                        const SizedBox(height: 8),

                        _classicInput('Payment Amount (₹)', amountCtrl, isNumeric: true),
                        const SizedBox(height: 8),
                        _classicInput('Transaction Reference / Receipt #', refCtrl),

                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _classicDialogButton('Cancel', () => Navigator.pop(ctx)),
                            const SizedBox(width: 6),
                            _classicDialogButton('Record Payment', () {
                              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                              if (amt <= 0) return;

                              repo.recordFolioPayment(
                                folioId: folio.id,
                                amount: amt,
                                method: method,
                                reference: refCtrl.text,
                              );

                              Navigator.pop(ctx);
                            }, color: const Color(0xFF27AE60), textColor: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Dialog: 5-Star Luxury GST Tax Invoice
  void _showTaxInvoiceDialog(BuildContext context, FolioModel folio, HotelRepository repo) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final activeBranch = repo.activeBranch;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.clientBusinessName.toUpperCase(), style: const TextStyle(color: Color(0xFF1B4F72), fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${activeBranch.name} • ${activeBranch.city}', style: const TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
                      Text('GSTIN: ${activeBranch.taxIdentifier}', style: const TextStyle(color: ClassicErpTheme.textMain, fontSize: 11)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: const Color(0xFF1B4F72),
                    child: const Text('TAX INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const Divider(color: ClassicErpTheme.borderDark, height: 20),

              // Guest Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BILLED TO:', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      Text(folio.guestName, style: const TextStyle(color: ClassicErpTheme.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Room ${folio.roomNumber}', style: const TextStyle(color: Color(0xFF1B4F72), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Invoice #: ${folio.folioNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}', style: const TextStyle(color: ClassicErpTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items breakdown table
              Container(
                decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderLight)),
                child: Column(
                  children: [
                    Container(
                      height: 22,
                      color: ClassicErpTheme.panelBg,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DESCRIPTION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                          Text('AMOUNT (₹)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    for (final txn in folio.transactions)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(txn.description, style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
                            Text(
                              '${txn.isCredit ? '-' : ''}${currency.format(txn.amount + txn.taxAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: txn.isCredit ? const Color(0xFF27AE60) : ClassicErpTheme.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Totals
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal: ${currency.format(folio.totalCharges - folio.totalTaxes)}', style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
                    Text('GST: ${currency.format(folio.totalTaxes)}', style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
                    Text('Total Paid: ${currency.format(folio.totalPaid)}', style: const TextStyle(fontSize: 11, color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Balance Due: ${currency.format(folio.balanceDue)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFC0392B))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _classicDialogButton('Close', () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _classicDialogButton('Print Preview', () {
                    Navigator.pop(ctx);
                    PrintPreviewDialog.show(
                      context,
                      title: 'Tax Invoice — ${folio.folioNumber}',
                      content: _buildInvoiceDocument(folio, repo, currency, activeBranch),
                    );
                  }, color: const Color(0xFF1B4F72), textColor: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classicInput(String label, TextEditingController controller, {bool isNumeric = false}) {
    return ClassicErpInput(
      label: label,
      controller: controller,
      isNumeric: isNumeric,
    );
  }

  Widget _classicDialogButton(String label, VoidCallback onTap, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color ?? ClassicErpTheme.buttonBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: textColor ?? ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }

  /// Builds the formatted Tax Invoice document for print preview.
  Widget _buildInvoiceDocument(FolioModel folio, HotelRepository repo, NumberFormat currency, dynamic activeBranch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Hotel Brand Logo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                HotelLogoWidget(
                  repo: repo,
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repo.clientBusinessName.toUpperCase(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    Text('${activeBranch.name} • ${activeBranch.city}',
                        style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                    Text('GSTIN: ${activeBranch.taxIdentifier}',
                        style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain)),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: const Color(0xFF1B4F72),
              child: const Text('TAX INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const Divider(thickness: 1.5, color: Color(0xFF1B4F72), height: 20),

        // Guest + Invoice Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BILLED TO:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
                Text(folio.guestName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                Text('Room: ${folio.roomNumber}', style: const TextStyle(fontSize: 10, color: Color(0xFF1B4F72))),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Invoice #: ${folio.folioNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text('Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Transaction Table
        Table(
          border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: ClassicErpTheme.panelBg),
              children: [
                const Padding(padding: EdgeInsets.all(6), child: Text('DESCRIPTION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                const Padding(padding: EdgeInsets.all(6), child: Text('AMOUNT (Rs.)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            ...folio.transactions.map((txn) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(5), child: Text(txn.description, style: const TextStyle(fontSize: 10))),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    '${txn.isCredit ? '-' : ''}${currency.format(txn.amount + txn.taxAmount)}',
                    style: TextStyle(fontSize: 10, color: txn.isCredit ? const Color(0xFF27AE60) : ClassicErpTheme.textMain, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            )),
          ],
        ),
        const SizedBox(height: 10),

        // Totals
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 250,
            child: Table(
              border: TableBorder.all(color: ClassicErpTheme.borderLight, width: 0.5),
              children: [
                _totalsRow('Subtotal', currency.format(folio.totalCharges - folio.totalTaxes)),
                _totalsRow('GST', currency.format(folio.totalTaxes)),
                _totalsRow('Total Paid', currency.format(folio.totalPaid), bold: true, color: const Color(0xFF27AE60)),
                _totalsRow('Balance Due', currency.format(folio.balanceDue), bold: true, color: const Color(0xFFC0392B), larger: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const Text('iSecure Systems Pvt. Ltd.  \u2022  Contact: 9326770568  \u2022  Thank you for staying with us!',
            style: TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted), textAlign: TextAlign.center),
      ],
    );
  }

  TableRow _totalsRow(String label, String value, {bool bold = false, Color? color, bool larger = false}) {
    final style = TextStyle(
      fontSize: larger ? 12 : 10,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color ?? ClassicErpTheme.textMain,
    );
    return TableRow(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text(label, style: style)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text(value, style: style, textAlign: TextAlign.right)),
    ]);
  }
}
