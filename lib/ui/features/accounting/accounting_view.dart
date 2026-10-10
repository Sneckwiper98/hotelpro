import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/accounting_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_form_widgets.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';

class AccountingView extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final bool isMaximized;
  final bool isActive;
  final int initialTab;

  const AccountingView({
    super.key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.isMaximized = true,
    this.isActive = true,
    this.initialTab = 0,
  });

  @override
  State<AccountingView> createState() => _AccountingViewState();
}

class _AccountingViewState extends State<AccountingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Filters
  String _purchaseFilterDept = 'All';
  String _purchaseFilterStatus = 'All';
  String _purchaseSearchQuery = '';

  String _expenseFilterCat = 'All';
  String _expenseFilterMode = 'All';
  String _expenseSearchQuery = '';

  DateTime _balanceSheetAsOf = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final purchases = repo.activeBranchPurchases;
    final expenses = repo.activeBranchExpenses;
    final balanceSheet = repo.getActiveBranchBalanceSheet(asOfDate: _balanceSheetAsOf);

    return Material(
      color: ClassicErpTheme.windowBg,
      child: Container(
        color: ClassicErpTheme.windowBg,
        child: Column(
        children: [
          // ── Module Win32 Ribbon Bar ────────────────────────────────────────
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isActive
                    ? const [Color(0xFF0C2461), Color(0xFF1B4F72)]
                    : const [Color(0xFF5D6D7E), Color(0xFF85929E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Financial Accounts — [Purchase Register, Operating Expenses & Balance Sheet]',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'Branch: ${repo.activeBranch.code} • FY 2026-27',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                if (widget.onMinimize != null) ...[
                  const SizedBox(width: 6),
                  _winButton(Icons.remove, widget.onMinimize!),
                ],
                if (widget.onMaximize != null) ...[
                  const SizedBox(width: 4),
                  _winButton(widget.isMaximized ? Icons.filter_none : Icons.crop_square, widget.onMaximize!),
                ],
                if (widget.onClose != null) ...[
                  const SizedBox(width: 4),
                  _winButton(Icons.close, widget.onClose!, isClose: true),
                ],
              ],
            ),
          ),

          // ── Tab Bar Navigation ─────────────────────────────────────────────
          Container(
            height: 32,
            decoration: const BoxDecoration(
              color: ClassicErpTheme.toolbarBg,
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF0C2461),
              unselectedLabelColor: Colors.black87,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              indicatorColor: const Color(0xFF0C2461),
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_checkout_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('1. 🛒 Purchase Register & Bills'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('2. 💸 Expense Sheet & Bill Copies'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.balance_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('3. ⚖️ Balance Sheet & Financial Statements'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab View Content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPurchaseTab(repo, purchases),
                _buildExpenseTab(repo, expenses),
                _buildBalanceSheetTab(repo, balanceSheet),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _winButton(IconData icon, VoidCallback onTap, {bool isClose = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isClose ? Colors.red.shade700 : Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }

  // ===========================================================================
  // 1. PURCHASE REGISTER TAB
  // ===========================================================================

  Widget _buildPurchaseTab(HotelRepository repo, List<PurchaseEntry> purchases) {
    // Filtering
    final filtered = purchases.where((p) {
      if (_purchaseFilterDept != 'All' && p.department != _purchaseFilterDept) return false;
      if (_purchaseFilterStatus != 'All' && p.paymentStatus != _purchaseFilterStatus) return false;
      if (_purchaseSearchQuery.isNotEmpty) {
        final q = _purchaseSearchQuery.toLowerCase();
        final match = p.invoiceNumber.toLowerCase().contains(q) ||
            p.vendorName.toLowerCase().contains(q) ||
            p.department.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    final totalPurchaseAmount = purchases.fold(0.0, (s, p) => s + p.grandTotal);
    final totalTaxPaid = purchases.fold(0.0, (s, p) => s + p.totalTax);
    final totalPendingPayables = purchases.where((p) => p.paymentStatus != 'Paid').fold(0.0, (s, p) => s + p.grandTotal);

    return Column(
      children: [
        // ── KPI Summary Cards ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFF1F5F9),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _kpiCard('Total Purchases', _currency.format(totalPurchaseAmount), '${purchases.length} Invoices', const Color(0xFF1B4F72)),
                        const SizedBox(width: 8),
                        _kpiCard('GST Input Tax Credit', _currency.format(totalTaxPaid), 'Eligible Credit', const Color(0xFF27AE60)),
                        const SizedBox(width: 8),
                        _kpiCard('Pending Payables', _currency.format(totalPendingPayables), 'To Suppliers', const Color(0xFFC0392B)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showNewPurchaseDialog(context, repo),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                          label: const Text('New Purchase Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C2461),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _printPurchaseSummaryReport(repo, purchases),
                          icon: const Icon(Icons.print_rounded, size: 15),
                          label: const Text('Print Register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0C2461),
                            side: const BorderSide(color: Color(0xFF0C2461)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Filter Controls ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 0.8)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search Input
                        Container(
                          width: 240,
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => setState(() => _purchaseSearchQuery = v),
                                  style: const TextStyle(fontSize: 11),
                                  decoration: const InputDecoration(
                                    hintText: 'Search Supplier / Invoice No...',
                                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Department:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _purchaseFilterDept,
                              isDense: true,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                              items: ['All', 'Kitchen & Provisions', 'Housekeeping & Linen', 'Bar & F&B Outlet', 'Maintenance']
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (v) => setState(() => _purchaseFilterDept = v ?? 'All'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Payment Status:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _purchaseFilterStatus,
                              isDense: true,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                              items: ['All', 'Paid', 'Pending', 'Partial']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _purchaseFilterStatus = v ?? 'All'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text('Showing ${filtered.length} of ${purchases.length} invoices',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Data Table ───────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No purchase entries found matching your filters.', Icons.shopping_bag_outlined)
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 28,
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 36,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
                      columns: const [
                        DataColumn(label: Text('Invoice No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Vendor / Supplier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Department', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Items Count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('SubTotal (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('GST (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Grand Total (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Payment Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((entry) {
                        return DataRow(
                          cells: [
                            DataCell(Text(entry.invoiceNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            DataCell(Text(DateFormat('dd-MMM-yyyy').format(entry.purchaseDate), style: const TextStyle(fontSize: 11))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(entry.vendorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  if (entry.vendorGstin.isNotEmpty)
                                    Text('GSTIN: ${entry.vendorGstin}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                ],
                              ),
                            ),
                            DataCell(Text(entry.department, style: const TextStyle(fontSize: 11))),
                            DataCell(Text('${entry.items.length} items', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(_currency.format(entry.subTotal), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(_currency.format(entry.totalTax), style: const TextStyle(fontSize: 11, color: Colors.green))),
                            DataCell(Text(_currency.format(entry.grandTotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            DataCell(Text(entry.paymentMode, style: const TextStyle(fontSize: 10))),
                            DataCell(_statusBadge(entry.paymentStatus)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _showPurchaseBill(context, repo, entry),
                                    child: const Tooltip(
                                      message: 'View / Print Tax Bill',
                                      child: Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF1B4F72)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _confirmDeletePurchase(context, repo, entry),
                                    child: const Tooltip(
                                      message: 'Delete Purchase Entry',
                                      child: Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. EXPENSE SHEET & BILL COPIES TAB
  // ===========================================================================

  Widget _buildExpenseTab(HotelRepository repo, List<ExpenseEntry> expenses) {
    // Filtering
    final filtered = expenses.where((e) {
      if (_expenseFilterCat != 'All' && e.category != _expenseFilterCat) return false;
      if (_expenseFilterMode != 'All' && e.paymentMode != _expenseFilterMode) return false;
      if (_expenseSearchQuery.isNotEmpty) {
        final q = _expenseSearchQuery.toLowerCase();
        final match = e.voucherNo.toLowerCase().contains(q) ||
            e.paidTo.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.netAmount);
    final cashOutflow = expenses.where((e) => e.paymentMode.toLowerCase().contains('cash')).fold(0.0, (s, e) => s + e.netAmount);
    final attachedBillsCount = expenses.where((e) => e.hasBillCopy).length;

    return Column(
      children: [
        // ── KPI Summary Cards ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFF1F5F9),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _kpiCard('Total Operating Expenses', _currency.format(totalExpenses), '${expenses.length} Vouchers', const Color(0xFF0C2461)),
                        const SizedBox(width: 8),
                        _kpiCard('Petty Cash Outflow', _currency.format(cashOutflow), 'Cash Disbursed', const Color(0xFFD35400)),
                        const SizedBox(width: 8),
                        _kpiCard('Bill Copies Uploaded', '$attachedBillsCount Attached', 'Verified Vouchers', const Color(0xFF27AE60)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showNewExpenseDialog(context, repo),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                          label: const Text('+ New Expense & Upload Bill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006266),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _printExpenseSheetReport(repo, expenses),
                          icon: const Icon(Icons.print_rounded, size: 15),
                          label: const Text('Print Expense Sheet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0C2461),
                            side: const BorderSide(color: Color(0xFF0C2461)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Filter Controls ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 0.8)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
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
                          width: 240,
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => setState(() => _expenseSearchQuery = v),
                                  style: const TextStyle(fontSize: 11),
                                  decoration: const InputDecoration(
                                    hintText: 'Search Payee / Voucher / Detail...',
                                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Category:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _expenseFilterCat,
                              isDense: true,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                              items: [
                                'All',
                                'Electricity & Utilities',
                                'Repairs & Maintenance',
                                'Kitchen & Provisions',
                                'Staff Salaries & Welfare',
                                'Generator & Diesel',
                                'Software & Internet',
                                'Laundry & Linen',
                                'Marketing',
                                'Miscellaneous',
                              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _expenseFilterCat = v ?? 'All'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Payment Mode:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _expenseFilterMode,
                              isDense: true,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                              items: ['All', 'Cash', 'Bank', 'Bank Transfer / NEFT', 'UPI', 'Cheque']
                                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (v) => setState(() => _expenseFilterMode = v ?? 'All'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text('Showing ${filtered.length} of ${expenses.length} expenses',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Data Table ───────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No operating expenses found matching your filters.', Icons.receipt_outlined)
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 28,
                      dataRowMinHeight: 34,
                      dataRowMaxHeight: 40,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
                      columns: const [
                        DataColumn(label: Text('Voucher No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Paid To', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Description / Purpose', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Amount (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Reference / UTR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('📎 Bill Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((entry) {
                        return DataRow(
                          cells: [
                            DataCell(Text(entry.voucherNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            DataCell(Text(DateFormat('dd-MMM-yyyy').format(entry.date), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(entry.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                            DataCell(Text(entry.paidTo, style: const TextStyle(fontSize: 11))),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(entry.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                            DataCell(Text(_currency.format(entry.netAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)))),
                            DataCell(Text(entry.paymentMode, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(entry.referenceNo.isNotEmpty ? entry.referenceNo : '—', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                            DataCell(_buildBillCopyCell(context, entry)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _showExpenseVoucher(context, repo, entry),
                                    child: const Tooltip(
                                      message: 'Print Expense Voucher',
                                      child: Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.print_rounded, size: 16, color: Color(0xFF1B4F72)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _confirmDeleteExpense(context, repo, entry),
                                    child: const Tooltip(
                                      message: 'Delete Expense Entry',
                                      child: Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBillCopyCell(BuildContext context, ExpenseEntry entry) {
    if (entry.hasBillCopy) {
      return InkWell(
        onTap: () => _showBillAttachmentViewer(context, entry),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            border: Border.all(color: const Color(0xFF81C784)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file_rounded, size: 13, color: Color(0xFF2E7D32)),
              const SizedBox(width: 4),
              Text(
                entry.billAttachmentName ?? 'View Bill Copy',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.visibility_rounded, size: 12, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      );
    }

    return Text('No copy', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic));
  }

  // ===========================================================================
  // 3. BALANCE SHEET TAB
  // ===========================================================================

  Widget _buildBalanceSheetTab(HotelRepository repo, BalanceSheetData bs) {
    return Column(
      children: [
        // ── Top Header & As-of Date Controller ───────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFF8FAFC),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BALANCE SHEET — ${repo.activeBranch.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0C2461), letterSpacing: 0.5),
                            ),
                            Text(
                              'Statement of Financial Position as on ${DateFormat('dd MMMM yyyy').format(bs.asOfDate)} • ${bs.financialYear}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _balanceSheetAsOf,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => _balanceSheetAsOf = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF0C2461)),
                                const SizedBox(width: 4),
                                Text('As of: ${DateFormat('dd-MMM-yyyy').format(_balanceSheetAsOf)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Balanced Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: bs.isBalanced ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            border: Border.all(color: bs.isBalanced ? const Color(0xFF4CAF50) : Colors.red),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(bs.isBalanced ? Icons.check_circle : Icons.warning_rounded,
                                  size: 14, color: bs.isBalanced ? const Color(0xFF2E7D32) : Colors.red),
                              const SizedBox(width: 6),
                              Text(
                                bs.isBalanced ? 'BALANCED: Assets = Liabilities + Equity' : 'UNBALANCED DISCREPANCY DETECTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: bs.isBalanced ? const Color(0xFF2E7D32) : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _printBalanceSheetReport(repo, bs),
                          icon: const Icon(Icons.print_rounded, size: 15),
                          label: const Text('Print Balance Sheet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C2461),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _exportBalanceSheetCsv(context, repo, bs),
                          icon: const Icon(Icons.file_download_outlined, size: 15),
                          label: const Text('Export CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0C2461),
                            side: const BorderSide(color: Color(0xFF0C2461)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const Divider(height: 1, thickness: 1, color: ClassicErpTheme.borderDark),

        // ── Double-Entry Dual Column Statement ───────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: ASSETS
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _statementHeader('ASSETS (APPLICATION OF FUNDS)', const Color(0xFF1B4F72)),
                        _subSectionTitle('Current Assets, Loans & Advances'),
                        ...bs.currentAssets.map((item) => _financialRow(item.code, item.title, item.amount)),
                        _subTotalRow('Total Current Assets', bs.totalCurrentAssets),
                        const Divider(height: 12, thickness: 1),
                        _subSectionTitle('Fixed Assets (Tangible Property & Plant)'),
                        ...bs.fixedAssets.map((item) => _financialRow(item.code, item.title, item.amount)),
                        _subTotalRow('Total Fixed Assets', bs.totalFixedAssets),
                        const SizedBox(height: 20),
                        _grandTotalRow('TOTAL ASSETS', bs.totalAssets, const Color(0xFF1B4F72)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right Column: LIABILITIES & EQUITY
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _statementHeader('LIABILITIES & CAPITAL (SOURCES OF FUNDS)', const Color(0xFF0C2461)),
                        _subSectionTitle('Current Liabilities & Provisions'),
                        ...bs.currentLiabilities.map((item) => _financialRow(item.code, item.title, item.amount)),
                        _subTotalRow('Total Current Liabilities', bs.totalCurrentLiabilities),
                        const Divider(height: 12, thickness: 1),
                        _subSectionTitle('Long-Term Secured Borrowings'),
                        ...bs.longTermLiabilities.map((item) => _financialRow(item.code, item.title, item.amount)),
                        _subTotalRow('Total Long-Term Liabilities', bs.totalLongTermLiabilities),
                        const Divider(height: 12, thickness: 1),
                        _subSectionTitle("Partners' / Shareholders' Capital & Reserves"),
                        ...bs.equityItems.map((item) => _financialRow(item.code, item.title, item.amount, bold: item.code == 'EQ-502')),
                        _subTotalRow("Total Equity & Reserves", bs.totalEquity),
                        const SizedBox(height: 20),
                        _grandTotalRow('TOTAL LIABILITIES & EQUITY', bs.totalLiabilitiesAndEquity, const Color(0xFF0C2461)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER WIDGETS & DIALOGS
  // ===========================================================================

  Widget _statementHeader(String title, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: bgColor,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
      ),
    );
  }

  Widget _subSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: const Color(0xFFF1F5F9),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      ),
    );
  }

  Widget _financialRow(String code, String title, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(code, style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: amount < 0 ? Colors.red.shade800 : Colors.black87,
              ),
            ),
          ),
          Text(
            _currency.format(amount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: amount < 0 ? Colors.red.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subTotalRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: const Color(0xFFFAFAFA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          Text(_currency.format(amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _grandTotalRow(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(top: BorderSide(color: color, width: 2), bottom: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          Text(_currency.format(amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, String subtitle, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFE8F5E9);
    Color fg = const Color(0xFF2E7D32);
    if (status == 'Pending') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC0392B);
    } else if (status == 'Partial') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF39C12);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ===========================================================================
  // NEW PURCHASE ENTRY DIALOG
  // ===========================================================================

  void _showNewPurchaseDialog(BuildContext context, HotelRepository repo) {
    final invCtrl = TextEditingController(text: 'INV-PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final vendorCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String department = 'Kitchen & Provisions';
    String paymentMode = 'Bank Transfer / NEFT';
    String paymentStatus = 'Paid';
    DateTime purchaseDate = DateTime.now();

    final List<PurchaseItem> items = [
      PurchaseItem(
        id: 'pi-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Organic Basmati Rice (25kg Bag)',
        category: 'Grocery',
        quantity: 10,
        unit: 'Bag',
        unitPrice: 2200,
        taxPercent: 5,
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final subTotal = items.fold(0.0, (s, i) => s + i.subTotal);
            final taxTotal = items.fold(0.0, (s, i) => s + i.taxAmount);
            final grandTotal = items.fold(0.0, (s, i) => s + i.totalAmount);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: SizedBox(
                width: 780,
                height: 600,
                child: Column(
                  children: [
                    // Title Bar
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFF0C2461),
                      child: Row(
                        children: [
                          const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('New Purchase Bill & Materials Entry',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Invoice & Vendor details
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _dialogTextField('Invoice Number', invCtrl),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: _dialogTextField('Vendor / Supplier Name', vendorCtrl),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: _dialogTextField('Vendor GSTIN', gstinCtrl),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Row 2: Department, Date, Payment Mode
                            Row(
                              children: [
                                Expanded(
                                  child: _dialogDropdown(
                                    'Department',
                                    department,
                                    ['Kitchen & Provisions', 'Housekeeping & Linen', 'Bar & F&B Outlet', 'Maintenance', 'Front Office'],
                                    (v) => setDialogState(() => department = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _dialogDropdown(
                                    'Payment Mode',
                                    paymentMode,
                                    ['Bank Transfer / NEFT', 'UPI', 'Cash', 'Cheque', 'Credit'],
                                    (v) => setDialogState(() => paymentMode = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _dialogDropdown(
                                    'Payment Status',
                                    paymentStatus,
                                    ['Paid', 'Pending', 'Partial'],
                                    (v) => setDialogState(() => paymentStatus = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Items Header & Add Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Purchase Line Items (Materials & Supplies):',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      items.add(PurchaseItem(
                                        id: 'pi-${DateTime.now().millisecondsSinceEpoch}',
                                        name: 'New Item',
                                        category: 'General',
                                        quantity: 1,
                                        unit: 'Pcs',
                                        unitPrice: 100,
                                        taxPercent: 5,
                                      ));
                                    });
                                  },
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('+ Add Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF27AE60),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Items Table
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                children: [
                                  Container(
                                    height: 24,
                                    color: const Color(0xFFE2E8F0),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 4, child: Text('Item Description', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        Expanded(flex: 2, child: Text('Rate (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        Expanded(flex: 1, child: Text('GST%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        Expanded(flex: 2, child: Text('Total (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                        SizedBox(width: 24),
                                      ],
                                    ),
                                  ),
                                  ...items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: idx.isEven ? Colors.white : const Color(0xFFF8FAFC),
                                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: TextFormField(
                                              initialValue: item.name,
                                              style: const TextStyle(fontSize: 11),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4)),
                                              onChanged: (v) => items[idx] = PurchaseItem(
                                                id: item.id, name: v, category: item.category,
                                                quantity: item.quantity, unit: item.unit, unitPrice: item.unitPrice, taxPercent: item.taxPercent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              initialValue: item.category,
                                              style: const TextStyle(fontSize: 11),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4)),
                                              onChanged: (v) => items[idx] = PurchaseItem(
                                                id: item.id, name: item.name, category: v,
                                                quantity: item.quantity, unit: item.unit, unitPrice: item.unitPrice, taxPercent: item.taxPercent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              initialValue: item.quantity.toStringAsFixed(0),
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 11),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4)),
                                              onChanged: (v) {
                                                final q = double.tryParse(v) ?? 1.0;
                                                setDialogState(() {
                                                  items[idx] = PurchaseItem(
                                                    id: item.id, name: item.name, category: item.category,
                                                    quantity: q, unit: item.unit, unitPrice: item.unitPrice, taxPercent: item.taxPercent,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              initialValue: item.unit,
                                              style: const TextStyle(fontSize: 11),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4)),
                                              onChanged: (v) => items[idx] = PurchaseItem(
                                                id: item.id, name: item.name, category: item.category,
                                                quantity: item.quantity, unit: v, unitPrice: item.unitPrice, taxPercent: item.taxPercent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              initialValue: item.unitPrice.toStringAsFixed(0),
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 11),
                                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4)),
                                              onChanged: (v) {
                                                final p = double.tryParse(v) ?? 0.0;
                                                setDialogState(() {
                                                  items[idx] = PurchaseItem(
                                                    id: item.id, name: item.name, category: item.category,
                                                    quantity: item.quantity, unit: item.unit, unitPrice: p, taxPercent: item.taxPercent,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 1,
                                            child: DropdownButton<double>(
                                              value: item.taxPercent,
                                              isDense: true,
                                              underline: const SizedBox(),
                                              style: const TextStyle(fontSize: 10, color: Colors.black87),
                                              items: [0.0, 5.0, 12.0, 18.0, 28.0]
                                                  .map((t) => DropdownMenuItem(value: t, child: Text('${t.toInt()}%')))
                                                  .toList(),
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setDialogState(() {
                                                    items[idx] = PurchaseItem(
                                                      id: item.id, name: item.name, category: item.category,
                                                      quantity: item.quantity, unit: item.unit, unitPrice: item.unitPrice, taxPercent: v,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 2,
                                            child: Text(_currency.format(item.totalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          InkWell(
                                            onTap: items.length > 1
                                                ? () => setDialogState(() => items.removeAt(idx))
                                                : null,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Icon(
                                                Icons.remove_circle,
                                                size: 16,
                                                color: items.length > 1 ? Colors.red : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtotal & Grand Total breakdown
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 280,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Column(
                                  children: [
                                    _dialogSummaryRow('Taxable SubTotal:', _currency.format(subTotal)),
                                    _dialogSummaryRow('GST Tax Total:', _currency.format(taxTotal), color: Colors.green),
                                    const Divider(height: 8),
                                    _dialogSummaryRow('Invoice Grand Total:', _currency.format(grandTotal), bold: true, color: const Color(0xFF0C2461)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(top: BorderSide(color: ClassicErpTheme.borderDark, width: 0.8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (vendorCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter vendor/supplier name.')),
                                );
                                return;
                              }

                              final entry = PurchaseEntry(
                                id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
                                branchId: repo.activeBranch.id,
                                invoiceNumber: invCtrl.text.trim().isNotEmpty ? invCtrl.text.trim() : 'INV-${DateTime.now().millisecondsSinceEpoch}',
                                vendorName: vendorCtrl.text.trim(),
                                vendorGstin: gstinCtrl.text.trim(),
                                vendorPhone: phoneCtrl.text.trim(),
                                purchaseDate: purchaseDate,
                                department: department,
                                items: items,
                                paymentStatus: paymentStatus,
                                paymentMode: paymentMode,
                                notes: notesCtrl.text.trim(),
                                createdAt: DateTime.now(),
                              );

                              repo.addPurchaseEntry(entry);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Purchase invoice ${entry.invoiceNumber} recorded successfully!'),
                                  backgroundColor: const Color(0xFF27AE60),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save & Post Purchase Entry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C2461),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // NEW EXPENSE VOUCHER DIALOG (WITH BILL COPY UPLOAD!)
  // ===========================================================================

  void _showNewExpenseDialog(BuildContext context, HotelRepository repo) {
    final vchCtrl = TextEditingController(text: 'VCH-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final paidToCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final taxCtrl = TextEditingController(text: '0');
    final refCtrl = TextEditingController();

    String category = 'Kitchen & Provisions';
    String paymentMode = 'Cash';
    String status = 'Approved';
    DateTime expenseDate = DateTime.now();

    // Bill copy file attachment state
    String? attachmentName;
    String? attachmentPath;
    Uint8List? attachmentBytes;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final amt = double.tryParse(amountCtrl.text) ?? 0.0;
            final tax = double.tryParse(taxCtrl.text) ?? 0.0;
            final net = amt + tax;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: SizedBox(
                width: 680,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title Bar
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFF006266),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Record Expense Voucher & Upload Bill Copy',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _dialogTextField('Voucher Number', vchCtrl),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: _dialogDropdown(
                                  'Expense Category',
                                  category,
                                  [
                                    'Kitchen & Provisions',
                                    'Electricity & Utilities',
                                    'Repairs & Maintenance',
                                    'Staff Salaries & Welfare',
                                    'Generator & Diesel',
                                    'Software & Internet',
                                    'Laundry & Linen',
                                    'Marketing',
                                    'Miscellaneous',
                                  ],
                                  (v) => setDialogState(() => category = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _dialogTextField('Paid To (Vendor / Staff / Payee)', paidToCtrl),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _dialogDropdown(
                                  'Payment Mode',
                                  paymentMode,
                                  ['Cash', 'Bank Transfer / NEFT', 'UPI', 'Cheque', 'Bank'],
                                  (v) => setDialogState(() => paymentMode = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          _dialogTextField('Expense Description / Purpose', descCtrl, maxLines: 2),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _dialogTextField('Base Amount (₹)', amountCtrl, isNumber: true, onChanged: (_) => setDialogState(() {})),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dialogTextField('Tax / GST (₹)', taxCtrl, isNumber: true, onChanged: (_) => setDialogState(() {})),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dialogTextField('Reference No (UTR/Cheque)', refCtrl),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Bill Copy Upload & Attachment Box ───────────────
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF006266)),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Bill Copy / Receipt Attachment (Mandatory for Audit):',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final result = await FilePicker.platform.pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
                                            withData: true,
                                          );
                                          if (result != null && result.files.isNotEmpty) {
                                            final file = result.files.first;
                                            setDialogState(() {
                                              attachmentName = file.name;
                                              attachmentPath = file.path;
                                              attachmentBytes = file.bytes;
                                            });
                                          }
                                        } catch (e) {
                                          debugPrint('File picker error: $e');
                                        }
                                      },
                                      icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                                      label: Text(attachmentName != null ? 'Change Bill Copy' : '📁 Browse / Upload Bill Copy'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF006266),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Attachment Preview
                                if (attachmentName != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      children: [
                                        // Image thumbnail if bytes present
                                        if (attachmentBytes != null && attachmentBytes!.isNotEmpty &&
                                            !attachmentName!.toLowerCase().endsWith('.pdf')) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: Image.memory(
                                              attachmentBytes!,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ] else ...[
                                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(attachmentName!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              Text(
                                                attachmentBytes != null ? '${(attachmentBytes!.length / 1024).toStringAsFixed(1)} KB' : 'Attached from path',
                                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              attachmentName = null;
                                              attachmentPath = null;
                                              attachmentBytes = null;
                                            });
                                          },
                                          child: const Tooltip(
                                            message: 'Remove bill copy',
                                            child: Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.cancel, color: Colors.red, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    'No bill copy attached yet. Click "Browse / Upload Bill Copy" to select scanned bill photo, invoice receipt or PDF.',
                                    style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Net Payable Display
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total Net Outflow: ${_currency.format(net)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFC0392B)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(top: BorderSide(color: ClassicErpTheme.borderDark, width: 0.8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (paidToCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter payee name and amount.')),
                                );
                                return;
                              }

                              final entry = ExpenseEntry(
                                id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                                branchId: repo.activeBranch.id,
                                voucherNo: vchCtrl.text.trim().isNotEmpty ? vchCtrl.text.trim() : 'VCH-${DateTime.now().millisecondsSinceEpoch}',
                                date: expenseDate,
                                category: category,
                                paidTo: paidToCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                amount: amt,
                                taxAmount: tax,
                                paymentMode: paymentMode,
                                referenceNo: refCtrl.text.trim(),
                                status: status,
                                recordedBy: repo.currentErpUser.displayName,
                                billAttachmentName: attachmentName,
                                billAttachmentPath: attachmentPath,
                                billAttachmentBytes: attachmentBytes,
                                createdAt: DateTime.now(),
                              );

                              repo.addExpenseEntry(entry);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Expense voucher ${entry.voucherNo} recorded successfully!'),
                                  backgroundColor: const Color(0xFF27AE60),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save Expense Voucher'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006266),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // ATTACHED BILL COPY FULLSCREEN VIEWER
  // ===========================================================================

  void _showBillAttachmentViewer(BuildContext context, ExpenseEntry expense) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Container(
            width: 700,
            height: 600,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Header
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      const Icon(Icons.image_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Attached Bill Copy: ${expense.billAttachmentName ?? expense.voucherNo} — [Paid To: ${expense.paidTo}]',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Image / Document Viewer
                Expanded(
                  child: Center(
                    child: Builder(
                      builder: (_) {
                        if (expense.billAttachmentBytes != null && expense.billAttachmentBytes!.isNotEmpty) {
                          return InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.memory(
                              expense.billAttachmentBytes!,
                              fit: BoxFit.contain,
                            ),
                          );
                        } else if (expense.billAttachmentPath != null && File(expense.billAttachmentPath!).existsSync()) {
                          return InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(
                              File(expense.billAttachmentPath!),
                              fit: BoxFit.contain,
                            ),
                          );
                        } else {
                          // PDF or mock placeholder image
                          return Container(
                            padding: const EdgeInsets.all(24),
                            color: Colors.white,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFF1B4F72)),
                                const SizedBox(height: 12),
                                Text(
                                  'SCANNED BILL / RECEIPT DOCKET: ${expense.billAttachmentName ?? 'Voucher Slip'}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text('Voucher: ${expense.voucherNo} • Date: ${DateFormat('dd-MMM-yyyy').format(expense.date)}'),
                                Text('Payee: ${expense.paidTo} • Amount: ${_currency.format(expense.netAmount)}'),
                                Text('Description: ${expense.description}'),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: const Color(0xFFF1F5F9),
                                  child: const Text('Verified by Accounts Controller — Digital Audit Stamp Approved',
                                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),

                // Footer
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      Text('Amount: ${_currency.format(expense.netAmount)} (${expense.paymentMode})',
                          style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      const Spacer(),
                      Text('Recorded By: ${expense.recordedBy}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // PURCHASE BILL TAX INVOICE PRINT DOCUMENT
  // ===========================================================================

  void _showPurchaseBill(BuildContext context, HotelRepository repo, PurchaseEntry entry) {
    final doc = Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Hotel Logo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HotelLogoWidget(repo: repo, width: 48, height: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repo.clientBusinessName.toUpperCase(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0C2461))),
                    Text(repo.activeBranch.address, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                    Text('GSTIN: ${repo.activeBranch.taxIdentifier} • Phone: ${repo.activeBranch.phone}',
                        style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: const Color(0xFF0C2461),
                    child: const Text('PURCHASE TAX BILL',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text('Invoice: ${entry.invoiceNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('Date: ${DateFormat('dd-MMM-yyyy').format(entry.purchaseDate)}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1),

          // Vendor & Department Box
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SUPPLIER / VENDOR DETAILS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(entry.vendorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (entry.vendorGstin.isNotEmpty) Text('GSTIN: ${entry.vendorGstin}', style: const TextStyle(fontSize: 10)),
                      if (entry.vendorPhone.isNotEmpty) Text('Phone: ${entry.vendorPhone}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECEIVING DEPARTMENT & STATUS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('Dept: ${entry.department}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Payment Mode: ${entry.paymentMode}', style: const TextStyle(fontSize: 10)),
                      Text('Status: ${entry.paymentStatus}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Line Items Table
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(5),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
              5: FlexColumnWidth(2),
              6: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                children: ['#', 'Item Description', 'Qty', 'Unit', 'Rate (₹)', 'GST%', 'Total (₹)']
                    .map((h) => Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
              ...entry.items.asMap().entries.map((itemEntry) {
                final idx = itemEntry.key + 1;
                final i = itemEntry.value;
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text('$idx', style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(i.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(i.quantity.toStringAsFixed(0), style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(i.unit, style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_currency.format(i.unitPrice), style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.all(6), child: Text('${i.taxPercent.toInt()}%', style: const TextStyle(fontSize: 10))),
                    Padding(padding: const EdgeInsets.all(6), child: Text(_currency.format(i.totalAmount), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                );
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    _billTotalRow('SubTotal (Excl. Tax):', _currency.format(entry.subTotal)),
                    _billTotalRow('GST Taxes:', _currency.format(entry.totalTax), color: Colors.green),
                    const Divider(height: 8),
                    _billTotalRow('Grand Total:', _currency.format(entry.grandTotal), bold: true),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Signatures
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('_____________________________', style: TextStyle(color: Colors.grey)),
                  Text('Goods Received & Checked By', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('_____________________________', style: TextStyle(color: Colors.grey)),
                  Text('Authorized Accounts Signatory', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    PrintPreviewDialog.show(
      context,
      title: 'Purchase Bill — ${entry.invoiceNumber}',
      content: doc,
    );
  }

  // ===========================================================================
  // EXPENSE VOUCHER PRINT DOCUMENT
  // ===========================================================================

  void _showExpenseVoucher(BuildContext context, HotelRepository repo, ExpenseEntry expense) {
    final doc = Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              HotelLogoWidget(repo: repo, width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repo.clientBusinessName.toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                    Text(repo.activeBranch.name, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: const Color(0xFF006266),
                child: const Text('PAYMENT VOUCHER',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(thickness: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Voucher No: ${expense.voucherNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Date: ${DateFormat('dd-MMM-yyyy').format(expense.date)}', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _voucherDetailRow('Head of Account / Category:', expense.category),
                _voucherDetailRow('Paid To:', expense.paidTo),
                _voucherDetailRow('Payment Mode:', '${expense.paymentMode} ${expense.referenceNo.isNotEmpty ? '(Ref: ${expense.referenceNo})' : ''}'),
                _voucherDetailRow('Description:', expense.description),
                _voucherDetailRow('Bill Attachment:', expense.billAttachmentName ?? 'Physical Cash Memo on File'),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Net Disbursed:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(_currency.format(expense.netAmount),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFC0392B))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('_____________________', style: TextStyle(color: Colors.grey)),
                  Text('Receiver Sign / Thumb', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('_____________________', style: TextStyle(color: Colors.grey)),
                  Text('Prepared By', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('_____________________', style: TextStyle(color: Colors.grey)),
                  Text('Manager / Passed By', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    PrintPreviewDialog.show(
      context,
      title: 'Payment Voucher — ${expense.voucherNo}',
      content: doc,
    );
  }

  // ===========================================================================
  // REPORT GENERATORS
  // ===========================================================================

  void _printPurchaseSummaryReport(HotelRepository repo, List<PurchaseEntry> purchases) {
    PrintPreviewDialog.show(
      context,
      title: 'Purchase Register Report',
      content: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HotelLogoWidget(repo: repo, width: 44, height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.clientBusinessName.toUpperCase(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                      Text('Purchase Register Report • Branch: ${repo.activeBranch.name}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                  children: ['Invoice No', 'Date', 'Supplier', 'Dept', 'SubTotal', 'GST', 'Grand Total', 'Status']
                      .map((h) => Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(h, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...purchases.map((p) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(5), child: Text(p.invoiceNumber, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(DateFormat('dd-MM-yy').format(p.purchaseDate), style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(p.vendorName, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(p.department, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(_currency.format(p.subTotal), style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(_currency.format(p.totalTax), style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(_currency.format(p.grandTotal), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(p.paymentStatus, style: const TextStyle(fontSize: 9))),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _printExpenseSheetReport(HotelRepository repo, List<ExpenseEntry> expenses) {
    PrintPreviewDialog.show(
      context,
      title: 'Expense Sheet Report',
      content: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HotelLogoWidget(repo: repo, width: 44, height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.clientBusinessName.toUpperCase(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                      Text('Consolidated Operating Expense Sheet • Branch: ${repo.activeBranch.name}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                  children: ['Voucher No', 'Date', 'Category', 'Paid To', 'Purpose', 'Mode', 'Net Outflow (₹)']
                      .map((h) => Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(h, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...expenses.map((e) => TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(5), child: Text(e.voucherNo, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(DateFormat('dd-MM-yy').format(e.date), style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(e.category, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(e.paidTo, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(e.description, style: const TextStyle(fontSize: 8))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(e.paymentMode, style: const TextStyle(fontSize: 9))),
                        Padding(padding: const EdgeInsets.all(5), child: Text(_currency.format(e.netAmount), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _printBalanceSheetReport(HotelRepository repo, BalanceSheetData bs) {
    PrintPreviewDialog.show(
      context,
      title: 'Balance Sheet Statement',
      content: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HotelLogoWidget(repo: repo, width: 48, height: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.clientBusinessName.toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                      Text('Audited Balance Sheet Statement as on ${DateFormat('dd MMMM yyyy').format(bs.asOfDate)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text('Branch: ${bs.branchName} • ${bs.financialYear}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assets
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        color: const Color(0xFF1B4F72),
                        child: const Center(
                          child: Text('ASSETS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      ...bs.currentAssets.map((i) => _printBsRow(i.title, i.amount)),
                      _printBsSubtotal('Total Current Assets', bs.totalCurrentAssets),
                      const SizedBox(height: 10),
                      ...bs.fixedAssets.map((i) => _printBsRow(i.title, i.amount)),
                      _printBsSubtotal('Total Fixed Assets', bs.totalFixedAssets),
                      const SizedBox(height: 12),
                      _printBsGrandTotal('TOTAL ASSETS', bs.totalAssets),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Liabilities & Equity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        color: const Color(0xFF0C2461),
                        child: const Center(
                          child: Text('LIABILITIES & EQUITY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      ...bs.currentLiabilities.map((i) => _printBsRow(i.title, i.amount)),
                      _printBsSubtotal('Total Current Liabilities', bs.totalCurrentLiabilities),
                      const SizedBox(height: 10),
                      ...bs.longTermLiabilities.map((i) => _printBsRow(i.title, i.amount)),
                      _printBsSubtotal('Total Long-Term Liabilities', bs.totalLongTermLiabilities),
                      const SizedBox(height: 10),
                      ...bs.equityItems.map((i) => _printBsRow(i.title, i.amount)),
                      _printBsSubtotal('Total Equity & Capital', bs.totalEquity),
                      const SizedBox(height: 12),
                      _printBsGrandTotal('TOTAL LIABILITIES & EQUITY', bs.totalLiabilitiesAndEquity),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('_______________________________', style: TextStyle(color: Colors.grey)),
                    Text('Head Accountant / Finance Manager', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('_______________________________', style: TextStyle(color: Colors.grey)),
                    Text('Director / Managing Trustee', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportBalanceSheetCsv(BuildContext context, HotelRepository repo, BalanceSheetData bs) {
    final rows = <List<String>>[
      ['SECTION', 'LINE ITEM', 'CODE', 'AMOUNT (INR)'],
      ['CURRENT ASSETS', '', '', ''],
      ...bs.currentAssets.map((i) => ['Current Assets', i.title, i.code, i.amount.toString()]),
      ['Current Assets Total', 'TOTAL CURRENT ASSETS', '', bs.totalCurrentAssets.toString()],
      ['FIXED ASSETS', '', '', ''],
      ...bs.fixedAssets.map((i) => ['Fixed Assets', i.title, i.code, i.amount.toString()]),
      ['Fixed Assets Total', 'TOTAL FIXED ASSETS', '', bs.totalFixedAssets.toString()],
      ['TOTAL ASSETS', 'GRAND TOTAL ASSETS', '', bs.totalAssets.toString()],
      ['CURRENT LIABILITIES', '', '', ''],
      ...bs.currentLiabilities.map((i) => ['Current Liabilities', i.title, i.code, i.amount.toString()]),
      ['Current Liabilities Total', 'TOTAL CURRENT LIABILITIES', '', bs.totalCurrentLiabilities.toString()],
      ['LONG TERM LIABILITIES', '', '', ''],
      ...bs.longTermLiabilities.map((i) => ['Long Term Liabilities', i.title, i.code, i.amount.toString()]),
      ['Long Term Liabilities Total', 'TOTAL LONG TERM LIABILITIES', '', bs.totalLongTermLiabilities.toString()],
      ['EQUITY & CAPITAL', '', '', ''],
      ...bs.equityItems.map((i) => ['Equity & Capital', i.title, i.code, i.amount.toString()]),
      ['Equity Total', 'TOTAL EQUITY & RESERVES', '', bs.totalEquity.toString()],
      ['TOTAL LIABILITIES & EQUITY', 'GRAND TOTAL LIABILITIES & EQUITY', '', bs.totalLiabilitiesAndEquity.toString()],
    ];

    ExcelExportService.saveAsCsv(
      context,
      suggestedName: 'Balance_Sheet_${DateFormat('yyyyMMdd').format(bs.asOfDate)}',
      headers: rows.first,
      rows: rows.skip(1).toList(),
    );
  }

  // Row Helpers
  Widget _printBsRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 9))),
          Text(_currency.format(amount), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _printBsSubtotal(String title, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
          Text(_currency.format(amount), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _printBsGrandTotal(String title, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 1), bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
          Text(_currency.format(amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _billTotalRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _voucherDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 170, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _dialogTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, ValueChanged<String>? onChanged}) {
    if (maxLines > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
          const SizedBox(height: 2),
          SizedBox(
            height: 52,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.multiline,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  borderSide: BorderSide(color: Color(0xFFB0BEC5), width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  borderSide: BorderSide(color: Color(0xFF1B4F72), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ClassicErpInput(
      label: label,
      controller: ctrl,
      isNumeric: isNumber,
      onChanged: onChanged,
    );
  }

  Widget _dialogDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return ClassicErpDropdown<String>(
      label: label,
      value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _dialogSummaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _confirmDeletePurchase(BuildContext context, HotelRepository repo, PurchaseEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete purchase invoice ${entry.invoiceNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              repo.deletePurchaseEntry(entry.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice ${entry.invoiceNumber} deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, HotelRepository repo, ExpenseEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete expense voucher ${entry.voucherNo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              repo.deleteExpenseEntry(entry.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Voucher ${entry.voucherNo} deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
