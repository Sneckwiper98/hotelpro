import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/models/invoice_model.dart';
import '../../../../data/repositories/hotel_repository.dart';
import '../../../../data/services/tally_accounting_service.dart';
import '../classic_datagrid.dart';

/// Classic Win32 GST Tax Invoices & Multi-Channel Billing Register Dialog
class ClassicInvoiceRegisterDialog extends StatefulWidget {
  const ClassicInvoiceRegisterDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ClassicInvoiceRegisterDialog(),
    );
  }

  @override
  State<ClassicInvoiceRegisterDialog> createState() => _ClassicInvoiceRegisterDialogState();
}

class _ClassicInvoiceRegisterDialogState extends State<ClassicInvoiceRegisterDialog> {
  int _selectedRowIndex = 0;
  String _channelFilter = 'ALL';
  String _statusFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final invoices = _getFilteredInvoices(repo.allInvoices);

    // Calculate live aggregates
    double totalTaxable = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalGrand = 0.0;
    int paidCount = 0;
    int creditCount = 0;

    for (final inv in invoices) {
      totalTaxable += inv.taxableAmount;
      totalCgst += inv.cgst;
      totalSgst += inv.sgst;
      totalGrand += inv.totalAmount;
      if (inv.status == ErpInvoiceStatus.paid) {
        paidCount++;
      } else if (inv.status == ErpInvoiceStatus.credit || inv.status == ErpInvoiceStatus.pending) {
        creditCount++;
      }
    }

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 1060,
        height: 720,
        decoration: BoxDecoration(
          color: ClassicErpTheme.dialogBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Win32 Dialog Title Bar ──────────────────────────────
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  const Text(
                    'GST Tax Invoices & Multi-Channel Billing Register — HotelPro Win32 ERP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 18,
                      height: 16,
                      color: const Color(0xFFC0392B),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Top GST & Tax Revenue Summary Cards ─────────────────
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  _summaryMetricCard(
                    'Total Taxable Turnover',
                    _currency.format(totalTaxable),
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF1B4F72),
                  ),
                  const SizedBox(width: 8),
                  _summaryMetricCard(
                    'Total CGST Collected',
                    _currency.format(totalCgst),
                    Icons.payments_rounded,
                    const Color(0xFF7D6608),
                  ),
                  const SizedBox(width: 8),
                  _summaryMetricCard(
                    'Total SGST Collected',
                    _currency.format(totalSgst),
                    Icons.assured_workload_rounded,
                    const Color(0xFF7D6608),
                  ),
                  const SizedBox(width: 8),
                  _summaryMetricCard(
                    'Gross Invoiced Value',
                    _currency.format(totalGrand),
                    Icons.receipt_rounded,
                    const Color(0xFF196F3D),
                  ),
                  const SizedBox(width: 8),
                  _summaryStatusPill('Paid Settled: $paidCount', const Color(0xFF27AE60)),
                  const SizedBox(width: 4),
                  _summaryStatusPill('Credit / Due: $creditCount', const Color(0xFFC0392B)),
                ],
              ),
            ),

            // ── 3. Filters & Operations Toolbar ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F7),
                border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
              ),
              child: Row(
                children: [
                  // Search Box
                  Container(
                    width: 260,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.search, size: 14, color: ClassicErpTheme.textMuted),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                            decoration: const InputDecoration(
                              hintText: 'Search Inv No, Guest, GSTIN...',
                              hintStyle: TextStyle(fontSize: 10.5, color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                            ),
                            onChanged: (val) => setState(() {
                              _searchQuery = val.trim();
                              _selectedRowIndex = 0;
                            }),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedRowIndex = 0;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.close, size: 13, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Channel Filter
                  const Text('Channel: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _channelFilter,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Channels')),
                          DropdownMenuItem(value: 'ROOM', child: Text('Room Stay (18% GST)')),
                          DropdownMenuItem(value: 'POS', child: Text('Restaurant POS (5% GST)')),
                          DropdownMenuItem(value: 'DELIVERY', child: Text('Online Delivery (5% GST)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _channelFilter = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status Filter
                  const Text('Status: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                          DropdownMenuItem(value: 'PAID', child: Text('Paid Settled')),
                          DropdownMenuItem(value: 'CREDIT', child: Text('Credit / BTC')),
                          DropdownMenuItem(value: 'PENDING', child: Text('Pending / COD')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _statusFilter = v);
                        },
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Quick Action Buttons
                  _win32ToolbarButton(
                    icon: Icons.add_task_rounded,
                    label: '+ Create Invoice',
                    isPrimary: true,
                    onTap: () => _showCreateInvoiceDialog(repo),
                  ),
                  const SizedBox(width: 6),
                  _win32ToolbarButton(
                    icon: Icons.print_rounded,
                    label: 'Preview & Print',
                    onTap: () {
                      if (invoices.isNotEmpty && _selectedRowIndex < invoices.length) {
                        _showTaxInvoicePreview(invoices[_selectedRowIndex], repo);
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _win32ToolbarButton(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Tally XML',
                    onTap: () => _showTallyExportDialog(context, invoices, repo),
                  ),
                  const SizedBox(width: 6),
                  _win32ToolbarButton(
                    icon: Icons.table_view_rounded,
                    label: 'GSTR-1 Returns',
                    onTap: () => _showGstr1ExportDialog(context, invoices),
                  ),
                ],
              ),
            ),

            // ── 4. Main Invoices DataGrid ───────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _buildInvoicesDataGrid(invoices, repo),
              ),
            ),

            // ── 5. Bottom Status Bar & Selected Row Operations ──────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: ClassicErpTheme.menuBarBg,
                border: Border(top: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    'Total Filtered Records: ${invoices.length} invoices',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                  ),
                  const Spacer(),
                  if (invoices.isNotEmpty && _selectedRowIndex < invoices.length) ...[
                    if (invoices[_selectedRowIndex].status != ErpInvoiceStatus.paid)
                      _win32ToolbarButton(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Settle / Mark as Paid',
                        onTap: () => _markSelectedAsPaid(invoices[_selectedRowIndex], repo),
                      ),
                    const SizedBox(width: 8),
                  ],
                  _win32ToolbarButton(
                    icon: Icons.close,
                    label: 'Close Window',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(value, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  List<ErpInvoiceRecord> _getFilteredInvoices(List<ErpInvoiceRecord> list) {
    return list.where((inv) {
      if (_channelFilter == 'ROOM' && inv.type != ErpInvoiceType.roomStay) return false;
      if (_channelFilter == 'POS' && inv.type != ErpInvoiceType.restaurantPos) return false;
      if (_channelFilter == 'DELIVERY' && inv.type != ErpInvoiceType.onlineDelivery) return false;

      if (_statusFilter == 'PAID' && inv.status != ErpInvoiceStatus.paid) return false;
      if (_statusFilter == 'CREDIT' && inv.status != ErpInvoiceStatus.credit) return false;
      if (_statusFilter == 'PENDING' && inv.status != ErpInvoiceStatus.pending) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.customerName.toLowerCase().contains(q) ||
            inv.customerPhone.contains(q) ||
            (inv.customerGstin?.toLowerCase().contains(q) ?? false) ||
            (inv.referenceId?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildInvoicesDataGrid(List<ErpInvoiceRecord> invoices, HotelRepository repo) {
    final columns = const [
      ClassicGridColumn(title: 'Invoice No', width: 110),
      ClassicGridColumn(title: 'Date & Time', width: 135),
      ClassicGridColumn(title: 'Channel', width: 115, align: TextAlign.center),
      ClassicGridColumn(title: 'Customer / Corporate Entity', width: 170),
      ClassicGridColumn(title: 'GSTIN (Tax ID)', width: 130, align: TextAlign.center),
      ClassicGridColumn(title: 'Taxable (₹)', width: 95, align: TextAlign.right),
      ClassicGridColumn(title: 'CGST (₹)', width: 75, align: TextAlign.right),
      ClassicGridColumn(title: 'SGST (₹)', width: 75, align: TextAlign.right),
      ClassicGridColumn(title: 'Total Amount (₹)', width: 110, align: TextAlign.right),
      ClassicGridColumn(title: 'Payment Mode', width: 130),
      ClassicGridColumn(title: 'Status', width: 85, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < invoices.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: invoices[i],
          cells: [
            invoices[i].invoiceNumber,
            _dateFormat.format(invoices[i].date),
            _channelBadge(invoices[i].type),
            invoices[i].customerName.toUpperCase(),
            invoices[i].customerGstin ?? '— (B2C)',
            _currency.format(invoices[i].taxableAmount),
            _currency.format(invoices[i].cgst),
            _currency.format(invoices[i].sgst),
            Text(
              _currency.format(invoices[i].totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
            ),
            invoices[i].paymentMode,
            _statusBadge(invoices[i].status),
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _showTaxInvoicePreview(row.rawData as ErpInvoiceRecord, repo),
    );
  }

  Widget _channelBadge(ErpInvoiceType type) {
    Color bg;
    Color fg;
    String label;
    switch (type) {
      case ErpInvoiceType.roomStay:
        bg = const Color(0xFFD4E6F1);
        fg = const Color(0xFF1B4F72);
        label = 'ROOM FOLIO';
        break;
      case ErpInvoiceType.restaurantPos:
        bg = const Color(0xFFD5F5E3);
        fg = const Color(0xFF1E8449);
        label = 'POS DINING';
        break;
      case ErpInvoiceType.onlineDelivery:
        bg = const Color(0xFFFCF3CF);
        fg = const Color(0xFF7D6608);
        label = 'FOOD DELIVERY';
        break;
      case ErpInvoiceType.banquetHall:
        bg = const Color(0xFFE8DAEF);
        fg = const Color(0xFF8E44AD);
        label = 'BANQUET HALL';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      color: bg,
      child: Text(label, style: TextStyle(color: fg, fontSize: 8.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(ErpInvoiceStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case ErpInvoiceStatus.paid:
        bg = const Color(0xFFD4EFDF);
        fg = const Color(0xFF1E8449);
        label = 'PAID';
        break;
      case ErpInvoiceStatus.pending:
        bg = const Color(0xFFFCF3CF);
        fg = const Color(0xFFB7950B);
        label = 'PENDING';
        break;
      case ErpInvoiceStatus.credit:
        bg = const Color(0xFFFADBD8);
        fg = const Color(0xFFC0392B);
        label = 'CREDIT';
        break;
      case ErpInvoiceStatus.cancelled:
        bg = const Color(0xFFE5E7E9);
        fg = const Color(0xFF7F8C8D);
        label = 'CANCELLED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      color: bg,
      child: Text(label, style: TextStyle(color: fg, fontSize: 8.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _win32ToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1B4F72) : Colors.white,
          border: Border.all(
            color: isPrimary ? const Color(0xFF154360) : ClassicErpTheme.borderDark,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isPrimary ? Colors.white : const Color(0xFF1B4F72)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : ClassicErpTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markSelectedAsPaid(ErpInvoiceRecord invoice, HotelRepository repo) {
    String paymentMode = 'Cash Counter';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('Settle Invoice — ${invoice.invoiceNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Outstanding Amount: ${_currency.format(invoice.totalAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
              const SizedBox(height: 12),
              const Text('Select Payment Settlement Mode:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: paymentMode,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash Counter', child: Text('Cash Counter')),
                  DropdownMenuItem(value: 'UPI (Google Pay / PhonePe)', child: Text('UPI (Google Pay / PhonePe)')),
                  DropdownMenuItem(value: 'Credit / Debit Card POS', child: Text('Credit / Debit Card POS')),
                  DropdownMenuItem(value: 'Corporate Bank NEFT / RTGS', child: Text('Corporate Bank NEFT / RTGS')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => paymentMode = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8449),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () {
                repo.markInvoicePaid(invoice.invoiceNumber, paymentMode);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice ${invoice.invoiceNumber} marked as PAID via $paymentMode.'),
                    backgroundColor: const Color(0xFF1E8449),
                  ),
                );
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaxInvoicePreview(ErpInvoiceRecord invoice, HotelRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 720,
          height: 650,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Invoice Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.clientBusinessName.toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                        Text(repo.clientTagline, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${repo.activeBranch.address}, ${repo.activeBranch.city} - Maharashtra', style: const TextStyle(fontSize: 10)),
                        Text('GSTIN: ${repo.activeBranch.taxIdentifier} • State Code: 27 (MH)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('Phone: ${repo.activeBranch.phone} • Email: ${repo.activeBranch.email}', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: const Color(0xFF1B4F72),
                        child: const Text('TAX INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(height: 6),
                      Text('Invoice No: ${invoice.invoiceNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Date: ${_dateFormat.format(invoice.date)}', style: const TextStyle(fontSize: 10)),
                      Text('Channel: ${invoice.type.name.toUpperCase()}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const Divider(thickness: 1.5, height: 20),

              // Billed To / Buyer Info (Indian GST Statutory Requirement)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9F9),
                  border: Border.all(color: ClassicErpTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BILLED TO / CUSTOMER DETAILS:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('Guest Name: ${invoice.customerName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Phone: ${invoice.customerPhone}', style: const TextStyle(fontSize: 10.5)),
                          if (invoice.customerAddress != null) Text('Address: ${invoice.customerAddress}', style: const TextStyle(fontSize: 10)),
                          Text('Place of Supply (POS): ${invoice.placeOfSupply}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TAX & STATUTORY REFERENCE:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text('GSTIN: ${invoice.customerGstin ?? "Unregistered (B2C)"}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                          Text('Reverse Charge (RCM): ${invoice.isReverseCharge ? "YES" : "NO"}', style: const TextStyle(fontSize: 10)),
                          Text('Supply Type: ${invoice.isInterState ? "Inter-State (IGST)" : "Intra-State (CGST+SGST)"}', style: const TextStyle(fontSize: 10, color: Color(0xFF7D6608), fontWeight: FontWeight.w600)),
                          Text('Payment Mode: ${invoice.paymentMode}', style: const TextStyle(fontSize: 10.5)),
                          Text('Status: ${invoice.status.name.toUpperCase()}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: invoice.status == ErpInvoiceStatus.paid ? const Color(0xFF1E8449) : const Color(0xFFC0392B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Items Table
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: ClassicErpTheme.borderLight, width: 1),
                    columnWidths: const {
                      0: FixedColumnWidth(35),
                      1: FlexColumnWidth(4),
                      2: FixedColumnWidth(70),
                      3: FixedColumnWidth(40),
                      4: FixedColumnWidth(75),
                      5: FixedColumnWidth(55),
                      6: FixedColumnWidth(85),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFEAECEE)),
                        children: [
                          _th('#'),
                          _th('Item Description'),
                          _th('HSN/SAC'),
                          _th('Qty'),
                          _th('Rate (₹)'),
                          _th('GST %'),
                          _th('Amount (₹)'),
                        ],
                      ),
                      for (int i = 0; i < invoice.items.length; i++)
                        TableRow(
                          children: [
                            _td('${i + 1}', align: TextAlign.center),
                            _td(invoice.items[i].description),
                            _td(invoice.items[i].hsnSacCode, align: TextAlign.center),
                            _td('${invoice.items[i].quantity}', align: TextAlign.center),
                            _td(_currency.format(invoice.items[i].unitRate), align: TextAlign.right),
                            _td('${invoice.items[i].gstRate.toStringAsFixed(0)}%', align: TextAlign.center),
                            _td(_currency.format(invoice.items[i].amount), align: TextAlign.right),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Calculation Breakdown Box
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFFF2F4F4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Taxable Amount:', style: TextStyle(fontSize: 11)),
                        Text(_currency.format(invoice.taxableAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (invoice.isInterState || invoice.igst > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Integrated GST (IGST):', style: const TextStyle(fontSize: 10.5, color: Color(0xFF7D6608))),
                          Text(_currency.format(invoice.igst > 0 ? invoice.igst : (invoice.cgst + invoice.sgst)), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF7D6608))),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Central GST (CGST): ${_currency.format(invoice.cgst)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF7D6608))),
                          Text('State GST (SGST): ${_currency.format(invoice.sgst)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF7D6608))),
                        ],
                      ),
                    const Divider(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Invoice Amount (INR):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                        Text(_currency.format(invoice.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Amount in Words: ${TallyAccountingService.numberToIndianWords(invoice.totalAmount)}',
                        style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print 80mm Thermal Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Printing 80mm GST thermal receipt for ${invoice.invoiceNumber}...'),
                          backgroundColor: const Color(0xFF2C3E50),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                    label: const Text('Export A4 GST PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8449),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('A4 GST Tax Invoice PDF generated for ${invoice.invoiceNumber}.'),
                          backgroundColor: const Color(0xFF1E8449),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _td(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 10), textAlign: align),
    );
  }

  void _showTallyExportDialog(BuildContext context, List<ErpInvoiceRecord> invoices, HotelRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1B4F72), size: 20),
            SizedBox(width: 8),
            Text('TallyPrime / Tally ERP 9 XML Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate standard Tally XML files for instant import into Tally via "Import > Vouchers" or "Import > Masters".',
                style: TextStyle(fontSize: 11, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _tallyActionTile(
                icon: Icons.receipt_long_rounded,
                title: 'Export Sales Vouchers XML',
                subtitle: '${invoices.length} Invoices • Debits Debtors/Cash, Credits Room/POS Sales & GST Output',
                onTap: () async {
                  Navigator.pop(ctx);
                  final xml = TallyAccountingService.generateSalesVouchersXml(
                    invoices: invoices,
                    companyName: repo.clientBusinessName,
                  );
                  await TallyAccountingService.saveXmlFile(
                    context: context,
                    suggestedName: 'Tally_Sales_Vouchers_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                    xmlContent: xml,
                  );
                  TallyAccountingService.logAudit(
                    voucherNo: 'BATCH-SALES-XML',
                    action: 'EXPORTED_TO_TALLY',
                    userId: repo.currentErpUser.username,
                    userRole: repo.currentErpUser.role.displayName,
                    details: 'Exported ${invoices.length} sales vouchers to Tally XML.',
                  );
                },
              ),
              const SizedBox(height: 8),
              _tallyActionTile(
                icon: Icons.payments_rounded,
                title: 'Export Receipt Vouchers XML',
                subtitle: '${invoices.where((i) => i.status == ErpInvoiceStatus.paid).length} Paid Settlements • Debits Bank/Cash, Credits Debtors',
                onTap: () async {
                  Navigator.pop(ctx);
                  final xml = TallyAccountingService.generateReceiptVouchersXml(
                    invoices: invoices,
                    companyName: repo.clientBusinessName,
                  );
                  await TallyAccountingService.saveXmlFile(
                    context: context,
                    suggestedName: 'Tally_Receipt_Vouchers_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                    xmlContent: xml,
                  );
                  TallyAccountingService.logAudit(
                    voucherNo: 'BATCH-RECEIPT-XML',
                    action: 'EXPORTED_TO_TALLY',
                    userId: repo.currentErpUser.username,
                    userRole: repo.currentErpUser.role.displayName,
                    details: 'Exported receipt vouchers to Tally XML.',
                  );
                },
              ),
              const SizedBox(height: 8),
              _tallyActionTile(
                icon: Icons.account_tree_rounded,
                title: 'Export Chart of Accounts Masters XML',
                subtitle: 'Pre-create all 25+ Hotel Ledgers, GST Duties, Bank A/cs in Tally in 1-Click',
                onTap: () async {
                  Navigator.pop(ctx);
                  final xml = TallyAccountingService.generateChartOfAccountsMasterXml(
                    companyName: repo.clientBusinessName,
                  );
                  await TallyAccountingService.saveXmlFile(
                    context: context,
                    suggestedName: 'Tally_Hotel_Masters_ChartOfAccounts',
                    xmlContent: xml,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGstr1ExportDialog(BuildContext context, List<ErpInvoiceRecord> invoices) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Row(
          children: [
            Icon(Icons.table_view_rounded, color: Color(0xFF1E8449), size: 20),
            SizedBox(width: 8),
            Text('GSTR-1 Monthly Return Filing Package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export government-compliant CSV tables ready for direct upload into the GST Offline Tool or GST Portal.',
                style: TextStyle(fontSize: 11, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              _tallyActionTile(
                icon: Icons.business_rounded,
                title: 'Table 4: B2B Invoices CSV',
                subtitle: '${invoices.where((i) => i.isB2B).length} Registered Corporate Invoices with GSTIN',
                onTap: () async {
                  Navigator.pop(ctx);
                  final csv = TallyAccountingService.generateGstr1B2bCsv(invoices: invoices);
                  await TallyAccountingService.saveCsvFile(
                    context: context,
                    suggestedName: 'GSTR1_Table4_B2B_${DateFormat('yyyyMM').format(DateTime.now())}',
                    csvContent: csv,
                  );
                },
              ),
              const SizedBox(height: 8),
              _tallyActionTile(
                icon: Icons.person_rounded,
                title: 'Table 7: B2C Small Invoices CSV',
                subtitle: '${invoices.where((i) => !i.isB2B).length} Unregistered Walk-in & Dining Guests',
                onTap: () async {
                  Navigator.pop(ctx);
                  final csv = TallyAccountingService.generateGstr1B2csCsv(invoices: invoices);
                  await TallyAccountingService.saveCsvFile(
                    context: context,
                    suggestedName: 'GSTR1_Table7_B2CS_${DateFormat('yyyyMM').format(DateTime.now())}',
                    csvContent: csv,
                  );
                },
              ),
              const SizedBox(height: 8),
              _tallyActionTile(
                icon: Icons.category_rounded,
                title: 'Table 12: HSN Summary CSV',
                subtitle: 'SAC 996311 (Rooms), 996331 (F&B), 996332 (Banquets)',
                onTap: () async {
                  Navigator.pop(ctx);
                  final csv = TallyAccountingService.generateGstr1HsnCsv(invoices: invoices);
                  await TallyAccountingService.saveCsvFile(
                    context: context,
                    suggestedName: 'GSTR1_Table12_HSN_${DateFormat('yyyyMM').format(DateTime.now())}',
                    csvContent: csv,
                  );
                },
              ),
              const SizedBox(height: 8),
              _tallyActionTile(
                icon: Icons.description_rounded,
                title: 'Table 13: Documents Summary CSV',
                subtitle: 'Total Serial Numbers Issued & Cancelled Invoices',
                onTap: () async {
                  Navigator.pop(ctx);
                  final csv = TallyAccountingService.generateGstr1DocsCsv(invoices: invoices);
                  await TallyAccountingService.saveCsvFile(
                    context: context,
                    suggestedName: 'GSTR1_Table13_Docs_${DateFormat('yyyyMM').format(DateTime.now())}',
                    csvContent: csv,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _tallyActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8F9F9),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ClassicErpTheme.borderLight),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: const Color(0xFF1B4F72), size: 20),
        title: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        trailing: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF1B4F72)),
        onTap: onTap,
      ),
    );
  }

  void _showCreateInvoiceDialog(HotelRepository repo) {
    final custNameCtrl = TextEditingController();
    final custPhoneCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final itemDescCtrl = TextEditingController(text: 'Room Stay & Dining Services');
    final amountCtrl = TextEditingController(text: '5000');
    double gstRate = 18.0;
    ErpInvoiceType type = ErpInvoiceType.roomStay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final double baseAmt = double.tryParse(amountCtrl.text) ?? 0.0;
          final double cgstAmt = (baseAmt * (gstRate / 2)) / 100;
          final double sgstAmt = (baseAmt * (gstRate / 2)) / 100;
          final double totalAmt = baseAmt + cgstAmt + sgstAmt;

          return AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF1B4F72), size: 18),
                SizedBox(width: 8),
                Text('Generate Manual Tax Invoice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ErpInvoiceType>(
                            initialValue: type,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Channel',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: ErpInvoiceType.roomStay, child: Text('Room Stay (18% GST)')),
                              DropdownMenuItem(value: ErpInvoiceType.restaurantPos, child: Text('Restaurant POS (5% GST)')),
                              DropdownMenuItem(value: ErpInvoiceType.onlineDelivery, child: Text('Online Delivery (5% GST)')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() {
                                  type = v;
                                  gstRate = v == ErpInvoiceType.roomStay ? 18.0 : 5.0;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: custNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer / Corporate Name *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: custPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Phone *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: gstinCtrl,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN (Optional B2B)',
                              hintText: 'e.g. 27AAAAA0000A1Z5',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: itemDescCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Billing Description *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Taxable Amount (₹) *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            initialValue: gstRate,
                            decoration: const InputDecoration(
                              labelText: 'GST Slab',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                              DropdownMenuItem(value: 5.0, child: Text('5% GST (F&B)')),
                              DropdownMenuItem(value: 12.0, child: Text('12% GST (Banquet)')),
                              DropdownMenuItem(value: 18.0, child: Text('18% GST (Rooms)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => gstRate = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Live Calculation Box
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2F8),
                        border: Border.all(color: const Color(0xFFAED6F1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Taxable Base:', style: TextStyle(fontSize: 10.5)),
                              Text(_currency.format(baseAmt), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CGST (${(gstRate / 2).toStringAsFixed(1)}%):', style: const TextStyle(fontSize: 10.5)),
                              Text(_currency.format(cgstAmt), style: const TextStyle(fontSize: 10.5)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SGST (${(gstRate / 2).toStringAsFixed(1)}%):', style: const TextStyle(fontSize: 10.5)),
                              Text(_currency.format(sgstAmt), style: const TextStyle(fontSize: 10.5)),
                            ],
                          ),
                          const Divider(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                              Text(_currency.format(totalAmt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () {
                  if (custNameCtrl.text.trim().isNotEmpty && baseAmt > 0) {
                    final invNum = 'INV-MAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    final inv = ErpInvoiceRecord(
                      invoiceNumber: invNum,
                      type: type,
                      customerName: custNameCtrl.text.trim(),
                      customerPhone: custPhoneCtrl.text.trim().isEmpty ? '+91 99999 00000' : custPhoneCtrl.text.trim(),
                      customerGstin: gstinCtrl.text.trim().isNotEmpty ? gstinCtrl.text.trim().toUpperCase() : null,
                      date: DateTime.now(),
                      taxableAmount: baseAmt,
                      cgst: cgstAmt,
                      sgst: sgstAmt,
                      totalAmount: totalAmt,
                      paymentMode: 'Cash Counter',
                      status: ErpInvoiceStatus.paid,
                      items: [
                        ErpInvoiceLineItem(
                          description: itemDescCtrl.text.trim(),
                          hsnSacCode: type == ErpInvoiceType.roomStay ? '996311' : '996331',
                          quantity: 1,
                          unitRate: baseAmt,
                          amount: baseAmt,
                          gstRate: gstRate,
                        ),
                      ],
                    );
                    repo.addInvoice(inv);
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tax Invoice $invNum created successfully!'),
                        backgroundColor: const Color(0xFF1E8449),
                      ),
                    );
                  }
                },
                child: const Text('Create & Issue Invoice'),
              ),
            ],
          );
        },
      ),
    );
  }
}
