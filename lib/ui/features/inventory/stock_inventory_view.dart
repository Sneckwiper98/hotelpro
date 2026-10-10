import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/accounting_model.dart';
import '../../../data/models/inventory_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_form_widgets.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';

/// Classic Windows Desktop Stock & Inventory Terminal
/// Features:
/// 1. Live Stock Status & In-Hand Quantity Ledger (with Reorder alerts & valuation)
/// 2. New Purchase Entry / Material Inward (automatic stock increment)
/// 3. Purchase Billings & Inward Tax Invoices Register (with printable GRN / Invoices)
class StockInventoryView extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final bool isMaximized;
  final bool isActive;
  final int initialTab;

  const StockInventoryView({
    super.key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.isMaximized = true,
    this.isActive = true,
    this.initialTab = 0,
  });

  @override
  State<StockInventoryView> createState() => _StockInventoryViewState();
}

class _StockInventoryViewState extends State<StockInventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Tab 1 (Stock Status) Filters
  String _stockSearchQuery = '';
  String _stockCategoryFilter = 'All';
  String _stockStatusFilter = 'All'; // All, In Stock, Low Stock, Out of Stock

  // Tab 2 (Purchase Billings) Filters
  String _purchaseSearchQuery = '';
  String _purchaseDeptFilter = 'All';
  String _purchaseStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final allStock = repo.activeBranchStockItems;
    final allPurchases = repo.activeBranchPurchases;

    // Filtered Stock Items
    final filteredStock = allStock.where((item) {
      final matchesSearch = _stockSearchQuery.isEmpty ||
          item.name.toLowerCase().contains(_stockSearchQuery.toLowerCase()) ||
          item.itemCode.toLowerCase().contains(_stockSearchQuery.toLowerCase()) ||
          item.storageLocation.toLowerCase().contains(_stockSearchQuery.toLowerCase());
      final matchesCategory = _stockCategoryFilter == 'All' || item.category == _stockCategoryFilter;
      final matchesStatus = _stockStatusFilter == 'All' ||
          (_stockStatusFilter == 'Low Stock' && item.isLowStock) ||
          (_stockStatusFilter == 'Out of Stock' && item.isOutOfStock) ||
          (_stockStatusFilter == 'In Stock' && !item.isLowStock && !item.isOutOfStock);
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    // Filtered Purchases
    final filteredPurchases = allPurchases.where((p) {
      final matchesSearch = _purchaseSearchQuery.isEmpty ||
          p.invoiceNumber.toLowerCase().contains(_purchaseSearchQuery.toLowerCase()) ||
          p.vendorName.toLowerCase().contains(_purchaseSearchQuery.toLowerCase()) ||
          p.items.any((i) => i.name.toLowerCase().contains(_purchaseSearchQuery.toLowerCase()));
      final matchesDept = _purchaseDeptFilter == 'All' || p.department == _purchaseDeptFilter;
      final matchesStatus = _purchaseStatusFilter == 'All' || p.paymentStatus == _purchaseStatusFilter;
      return matchesSearch && matchesDept && matchesStatus;
    }).toList();

    return Material(
      color: ClassicErpTheme.windowBg,
      child: Container(
        color: ClassicErpTheme.windowBg,
        child: Column(
        children: [
          // ── 1. Module Win32 Ribbon Bar ────────────────────────────────────────
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
                const Icon(Icons.inventory_2_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'STOCK & MATERIAL INVENTORY TERMINAL — Live Stock Ledger & Purchase Billings',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    border: Border.all(color: Colors.white30, width: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'BRANCH: ${repo.activeBranch.code} (${repo.activeBranch.name})',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.onMinimize != null)
                  _ribbonBtn(Icons.remove, widget.onMinimize!),
                if (widget.onMaximize != null)
                  _ribbonBtn(widget.isMaximized ? Icons.filter_none : Icons.crop_square, widget.onMaximize!),
                if (widget.onClose != null)
                  _ribbonBtn(Icons.close, widget.onClose!, isClose: true),
              ],
            ),
          ),

          // ── 2. Action Ribbon & KPI Summary Cards ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFECEFF1),
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Primary Action: New Purchase Entry (Material Inward)
                  ElevatedButton.icon(
                    onPressed: () => _showNewPurchaseDialog(context, repo),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 15, color: Colors.white),
                    label: const Text('+ NEW PURCHASE ENTRY (INWARD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 1,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Add New Stock Item SKU
                  OutlinedButton.icon(
                    onPressed: () => _showAddStockItemDialog(context, repo),
                    icon: const Icon(Icons.add_box_rounded, size: 14, color: Color(0xFF1B4F72)),
                    label: const Text('ADD NEW SKU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF1B4F72)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Refresh Button
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded, size: 14, color: ClassicErpTheme.textMain),
                    label: const Text('Refresh', style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFB0BEC5)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // KPI Stats Pill: Total Stock Value
                  _kpiPill('TOTAL VALUATION', _currency.format(repo.totalStockValuation), const Color(0xFF117864), const Color(0xFFE8F8F5)),
                  const SizedBox(width: 6),

                  // KPI Stats Pill: Total SKUs
                  _kpiPill('ACTIVE SKUs', '${allStock.length} Items', const Color(0xFF1B4F72), const Color(0xFFEBF5FB)),
                  const SizedBox(width: 6),

                  // KPI Stats Pill: Low Stock
                  _kpiPill('LOW STOCK', '${repo.lowStockCount}', const Color(0xFFD35400), const Color(0xFFFEF9E7)),
                  const SizedBox(width: 6),

                  // KPI Stats Pill: Out of Stock
                  _kpiPill('OUT OF STOCK', '${repo.outOfStockCount}', const Color(0xFFC0392B), const Color(0xFFFDEDEC)),
                ],
              ),
            ),
          ),

          // ── 3. View Switcher Tabs ─────────────────────────────────────────────
          Container(
            height: 32,
            color: const Color(0xFFD6DBDF),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF1B4F72),
              indicatorWeight: 3,
              labelColor: const Color(0xFF1B4F72),
              unselectedLabelColor: ClassicErpTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_rounded, size: 14),
                      const SizedBox(width: 6),
                      Text('1. Live Stock Status & Levels (${filteredStock.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14),
                      const SizedBox(width: 6),
                      Text('2. Purchase Billings & Invoices (${filteredPurchases.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 4. Main Body Content ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Stock Status & In-Hand Ledger
                _buildStockStatusTab(filteredStock, allStock, repo),

                // TAB 2: Purchase Billings & Invoices Ledger
                _buildPurchaseBillingsTab(filteredPurchases, repo),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // ===========================================================================
  // TAB 1: LIVE STOCK STATUS & LEVELS
  // ===========================================================================
  Widget _buildStockStatusTab(List<StockItemModel> items, List<StockItemModel> allItems, HotelRepository repo) {
    final categories = ['All', 'Kitchen & Provisions', 'Housekeeping & Linen', 'Guest Amenities', 'Bar & Beverages'];

    return Column(
      children: [
        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Search Field
                SizedBox(
                  width: 250,
                  child: ClassicErpSearchField(
                    hintText: 'Search SKU code, item name, store...',
                    onChanged: (val) => setState(() => _stockSearchQuery = val),
                    onClear: () => setState(() => _stockSearchQuery = ''),
                  ),
                ),
                const SizedBox(width: 12),

                // Category Filter Dropdown
                const Text('Category:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 200,
                  child: ClassicErpDropdown<String>(
                    value: _stockCategoryFilter,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _stockCategoryFilter = val);
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Status Filter Chips
                const Text('Status:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                const SizedBox(width: 6),
                ...['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((status) {
                  final isSelected = _stockStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(status, style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : ClassicErpTheme.textMain)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B4F72),
                      backgroundColor: const Color(0xFFF0F3F4),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      onSelected: (val) {
                        if (val) setState(() => _stockStatusFilter = status);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: ClassicErpTheme.borderDark),

        // Spreadsheet Grid Table
        Expanded(
          child: items.isEmpty
              ? _buildEmptyState('No inventory items match current filter criteria.')
              : Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        height: 28,
                        color: const Color(0xFF2C3E50),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Row(
                          children: [
                            SizedBox(width: 90, child: Text('SKU CODE', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('ITEM / MATERIAL NAME', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('CATEGORY', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('STORE LOCATION', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 100, child: Text('IN-HAND QTY', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 90, child: Text('REORDER LVL', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 95, child: Text('UNIT RATE', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 110, child: Text('VALUATION (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 110, child: Center(child: Text('STATUS', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)))),
                            SizedBox(width: 100, child: Center(child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ),

                      // Rows List
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (ctx, index) {
                            final item = items[index];
                            final isEven = index % 2 == 0;

                            return Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF9FAFB),
                                border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  // SKU Code
                                  SizedBox(
                                    width: 90,
                                    child: Text(item.itemCode, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                  ),

                                  // Item Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClassicErpTheme.textMain),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Category
                                  Expanded(
                                    flex: 2,
                                    child: Text(item.category, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),

                                  // Store Location
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.place_outlined, size: 11, color: ClassicErpTheme.textMuted),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(item.storageLocation, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // In-Hand Qty
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '${item.currentStock % 1 == 0 ? item.currentStock.toInt() : item.currentStock} ${item.unit}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: item.isOutOfStock ? const Color(0xFFC0392B) : (item.isLowStock ? const Color(0xFFD35400) : const Color(0xFF117864)),
                                      ),
                                    ),
                                  ),

                                  // Reorder Level
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      '${item.reorderLevel % 1 == 0 ? item.reorderLevel.toInt() : item.reorderLevel} ${item.unit}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                                    ),
                                  ),

                                  // Unit Price
                                  SizedBox(
                                    width: 95,
                                    child: Text(_currency.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain)),
                                  ),

                                  // Total Valuation
                                  SizedBox(
                                    width: 110,
                                    child: Text(_currency.format(item.stockValue), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                  ),

                                  // Status Badge
                                  SizedBox(
                                    width: 110,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.status.bgColor,
                                          border: Border.all(color: item.status.color.withValues(alpha: 0.5), width: 1),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          item.status.label,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item.status.color),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Actions
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Quick Adjust / Audit Count
                                        InkWell(
                                          onTap: () => _showAdjustStockDialog(context, repo, item),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEBF5FB),
                                              border: Border.all(color: const Color(0xFF2980B9), width: 0.8),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.tune_rounded, size: 10, color: Color(0xFF2980B9)),
                                                SizedBox(width: 2),
                                                Text('Adjust', style: TextStyle(fontSize: 9.5, color: Color(0xFF2980B9), fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),

                                        // Edit SKU
                                        InkWell(
                                          onTap: () => _showEditStockItemDialog(context, repo, item),
                                          child: const Icon(Icons.edit_outlined, size: 14, color: ClassicErpTheme.textMuted),
                                        ),
                                      ],
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
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: PURCHASE BILLINGS & INVOICES LEDGER
  // ===========================================================================
  Widget _buildPurchaseBillingsTab(List<PurchaseEntry> purchases, HotelRepository repo) {
    final departments = ['All', 'Kitchen & Provisions', 'Housekeeping & Linen', 'Guest Amenities', 'Bar & Beverages'];

    return Column(
      children: [
        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Search Field
                SizedBox(
                  width: 250,
                  child: ClassicErpSearchField(
                    hintText: 'Search Invoice #, Supplier, Item...',
                    onChanged: (val) => setState(() => _purchaseSearchQuery = val),
                    onClear: () => setState(() => _purchaseSearchQuery = ''),
                  ),
                ),
                const SizedBox(width: 12),

                // Department Filter
                const Text('Department:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 200,
                  child: ClassicErpDropdown<String>(
                    value: _purchaseDeptFilter,
                    items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _purchaseDeptFilter = val);
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Payment Status Filter Chips
                const Text('Payment:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                const SizedBox(width: 6),
                ...['All', 'Paid', 'Pending'].map((status) {
                  final isSelected = _purchaseStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(status == 'Pending' ? 'Credit / Due' : status, style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : ClassicErpTheme.textMain)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B4F72),
                      backgroundColor: const Color(0xFFF0F3F4),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      onSelected: (val) {
                        if (val) setState(() => _purchaseStatusFilter = status);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: ClassicErpTheme.borderDark),

        // Spreadsheet Grid Table
        Expanded(
          child: purchases.isEmpty
              ? _buildEmptyState('No purchase bills match current criteria.')
              : Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        height: 28,
                        color: const Color(0xFF2C3E50),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Row(
                          children: [
                            SizedBox(width: 110, child: Text('INVOICE #', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 85, child: Text('DATE', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('SUPPLIER / VENDOR NAME', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 80, child: Text('ITEMS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 95, child: Text('TAXABLE (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 85, child: Text('GST (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 110, child: Text('NET TOTAL (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                            SizedBox(width: 110, child: Center(child: Text('PAYMENT MODE', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)))),
                            SizedBox(width: 85, child: Center(child: Text('STATUS', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)))),
                            SizedBox(width: 140, child: Center(child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ),

                      // Rows List
                      Expanded(
                        child: ListView.builder(
                          itemCount: purchases.length,
                          itemBuilder: (ctx, index) {
                            final p = purchases[index];
                            final isEven = index % 2 == 0;
                            final isPaid = p.paymentStatus == 'Paid';

                            return Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF9FAFB),
                                border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  // Invoice #
                                  SizedBox(
                                    width: 110,
                                    child: Text(p.invoiceNumber, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                  ),

                                  // Date
                                  SizedBox(
                                    width: 85,
                                    child: Text(DateFormat('dd/MM/yyyy').format(p.purchaseDate), style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain)),
                                  ),

                                  // Vendor Name
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(p.vendorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ClassicErpTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        if (p.vendorGstin.isNotEmpty)
                                          Text('GSTIN: ${p.vendorGstin}', style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted), maxLines: 1),
                                      ],
                                    ),
                                  ),

                                  // Department
                                  Expanded(
                                    flex: 2,
                                    child: Text(p.department, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),

                                  // Items Count
                                  SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: const Color(0xFFEAECEE), borderRadius: BorderRadius.circular(2)),
                                        child: Text('${p.items.length} SKUs', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                                      ),
                                    ),
                                  ),

                                  // Taxable Subtotal
                                  SizedBox(
                                    width: 95,
                                    child: Text(_currency.format(p.subTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain)),
                                  ),

                                  // GST
                                  SizedBox(
                                    width: 85,
                                    child: Text(_currency.format(p.totalTax), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted)),
                                  ),

                                  // Net Total
                                  SizedBox(
                                    width: 110,
                                    child: Text(_currency.format(p.grandTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                  ),

                                  // Payment Mode
                                  SizedBox(
                                    width: 110,
                                    child: Center(
                                      child: Text(p.paymentMode, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),

                                  // Payment Status
                                  SizedBox(
                                    width: 85,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPaid ? const Color(0xFFE8F8F5) : const Color(0xFFFEF9E7),
                                          border: Border.all(color: isPaid ? const Color(0xFF27AE60) : const Color(0xFFE67E22), width: 0.8),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          isPaid ? 'PAID' : 'DUE',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPaid ? const Color(0xFF27AE60) : const Color(0xFFE67E22)),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Actions: View Bill / Print
                                  SizedBox(
                                    width: 140,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () => _showPurchaseInvoiceViewer(context, repo, p),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B4F72),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.visibility_rounded, size: 10, color: Colors.white),
                                                SizedBox(width: 3),
                                                Text('View', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        InkWell(
                                          onTap: () => _handleDirectPrint(context, p),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.print_rounded, size: 10, color: Colors.white),
                                                SizedBox(width: 3),
                                                Text('Print', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
        ),
      ],
    );
  }

  // ===========================================================================
  // MODAL 1: NEW PURCHASE ENTRY (MATERIAL INWARD & STOCK INCREMENT)
  // ===========================================================================
  void _showNewPurchaseDialog(BuildContext context, HotelRepository repo) {
    final vendorCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final invoiceNoCtrl = TextEditingController(text: 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final notesCtrl = TextEditingController();

    DateTime purchaseDate = DateTime.now();
    String department = 'Kitchen & Provisions';
    String paymentMode = 'Bank Transfer / NEFT';
    String paymentStatus = 'Paid';

    // Temporary list of line items being entered
    final List<Map<String, dynamic>> purchaseLines = [
      {
        'nameCtrl': TextEditingController(text: 'Organic Basmati Rice (Daawat Gold)'),
        'category': 'Kitchen & Provisions',
        'unit': 'Kg',
        'qtyCtrl': TextEditingController(text: '50'),
        'rateCtrl': TextEditingController(text: '140'),
        'taxPercent': 5.0,
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculate running totals
          double taxableSubtotal = 0.0;
          double totalGst = 0.0;

          for (final line in purchaseLines) {
            final qty = double.tryParse((line['qtyCtrl'] as TextEditingController).text) ?? 0.0;
            final rate = double.tryParse((line['rateCtrl'] as TextEditingController).text) ?? 0.0;
            final taxPct = (line['taxPercent'] as double?) ?? 5.0;
            final lineSub = qty * rate;
            final lineTax = lineSub * (taxPct / 100.0);
            taxableSubtotal += lineSub;
            totalGst += lineTax;
          }

          final grandTotal = taxableSubtotal + totalGst;

          return Dialog(
            backgroundColor: ClassicErpTheme.dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
              side: const BorderSide(color: Color(0xFF1B4F72), width: 2),
            ),
            child: SizedBox(
              width: 780,
              height: 600,
              child: Column(
                children: [
                  // Dialog Header
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: const Color(0xFF1B4F72),
                    child: Row(
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'NEW MATERIAL PURCHASE & INWARD ENTRY (GRN)',
                            style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            color: const Color(0xFFC0392B),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Body (Scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Vendor & Bill Header Details
                          const ClassicErpSectionHeader(title: 'VENDOR & PURCHASE INVOICE PARTICULARS', icon: Icons.store_rounded),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClassicErpInput(
                                  label: 'Supplier / Vendor Name',
                                  isRequired: true,
                                  controller: vendorCtrl,
                                  hintText: 'e.g. Apex Food & Dairy Suppliers Ltd.',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ClassicErpInput(
                                  label: 'Supplier GSTIN',
                                  controller: gstinCtrl,
                                  hintText: '27AABCA1234F1Z5',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ClassicErpInput(
                                  label: 'Vendor Contact #',
                                  controller: phoneCtrl,
                                  hintText: '+91 98000 00000',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ClassicErpInput(
                                  label: 'Purchase Invoice / Bill #',
                                  isRequired: true,
                                  controller: invoiceNoCtrl,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ClassicErpDropdown<String>(
                                  label: 'Department',
                                  isRequired: true,
                                  value: department,
                                  items: ['Kitchen & Provisions', 'Housekeeping & Linen', 'Guest Amenities', 'Bar & Beverages'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => department = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ClassicErpDropdown<String>(
                                  label: 'Payment Mode',
                                  isRequired: true,
                                  value: paymentMode,
                                  items: ['Bank Transfer / NEFT', 'Cash', 'UPI', 'Cheque', 'Credit / 30 Days'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => paymentMode = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ClassicErpDropdown<String>(
                                  label: 'Payment Status',
                                  isRequired: true,
                                  value: paymentStatus,
                                  items: ['Paid', 'Pending'].map((s) => DropdownMenuItem(value: s, child: Text(s == 'Pending' ? 'Credit / Due' : s))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => paymentStatus = val);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Section 2: Line Items
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const ClassicErpSectionHeader(title: 'PURCHASE MATERIAL ITEMS (INCREASES IN-HAND STOCK)', icon: Icons.checklist_rounded),
                              InkWell(
                                onTap: () {
                                  setModalState(() {
                                    purchaseLines.add({
                                      'nameCtrl': TextEditingController(),
                                      'category': department,
                                      'unit': 'Kg',
                                      'qtyCtrl': TextEditingController(text: '1'),
                                      'rateCtrl': TextEditingController(text: '100'),
                                      'taxPercent': 5.0,
                                    });
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4F72),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.add, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('ADD LINE ITEM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Table of purchase line inputs
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                            ),
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  height: 24,
                                  color: const Color(0xFFD6DBDF),
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 4, child: Text('Item Name', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 80, child: Text('Quantity', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 70, child: Text('Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 90, child: Text('Rate (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 75, child: Text('GST %', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 95, child: Text('Total (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                      SizedBox(width: 30),
                                    ],
                                  ),
                                ),

                                // Line Items List
                                ...purchaseLines.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final line = entry.value;
                                  final nameCtrl = line['nameCtrl'] as TextEditingController;
                                  final qtyCtrl = line['qtyCtrl'] as TextEditingController;
                                  final rateCtrl = line['rateCtrl'] as TextEditingController;
                                  final unit = line['unit'] as String? ?? 'Kg';
                                  final taxPct = (line['taxPercent'] as double?) ?? 5.0;

                                  final q = double.tryParse(qtyCtrl.text) ?? 0.0;
                                  final r = double.tryParse(rateCtrl.text) ?? 0.0;
                                  final total = (q * r) * (1 + (taxPct / 100.0));

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFEAEDED))),
                                    ),
                                    child: Row(
                                      children: [
                                        // Item Name
                                        Expanded(
                                          flex: 4,
                                          child: SizedBox(
                                            height: 26,
                                            child: TextField(
                                              controller: nameCtrl,
                                              style: const TextStyle(fontSize: 11),
                                              decoration: const InputDecoration(
                                                hintText: 'Material / SKU title',
                                                hintStyle: TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Qty
                                        SizedBox(
                                          width: 80,
                                          height: 26,
                                          child: TextField(
                                            controller: qtyCtrl,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => setModalState(() {}),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Unit
                                        SizedBox(
                                          width: 70,
                                          height: 26,
                                          child: DropdownButtonHideUnderline(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB0BEC5))),
                                              child: DropdownButton<String>(
                                                value: unit,
                                                isExpanded: true,
                                                style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain),
                                                items: ['Kg', 'Ltr', 'Pcs', 'Box', 'Can', 'Pack', 'Bottle', 'Set'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                                onChanged: (v) {
                                                  if (v != null) setModalState(() => line['unit'] = v);
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Rate
                                        SizedBox(
                                          width: 90,
                                          height: 26,
                                          child: TextField(
                                            controller: rateCtrl,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => setModalState(() {}),
                                            style: const TextStyle(fontSize: 11),
                                            decoration: const InputDecoration(
                                              prefixText: '₹',
                                              prefixStyle: TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // GST %
                                        SizedBox(
                                          width: 75,
                                          height: 26,
                                          child: DropdownButtonHideUnderline(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFB0BEC5))),
                                              child: DropdownButton<double>(
                                                value: taxPct,
                                                isExpanded: true,
                                                style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain),
                                                items: [0.0, 5.0, 12.0, 18.0, 28.0].map((t) => DropdownMenuItem(value: t, child: Text('${t.toInt()}%'))).toList(),
                                                onChanged: (v) {
                                                  if (v != null) setModalState(() => line['taxPercent'] = v);
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Total
                                        SizedBox(
                                          width: 95,
                                          child: Text(_currency.format(total), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                        ),

                                        // Delete Line
                                        SizedBox(
                                          width: 30,
                                          child: purchaseLines.length > 1
                                              ? IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                                  padding: EdgeInsets.zero,
                                                  onPressed: () => setModalState(() => purchaseLines.removeAt(idx)),
                                                )
                                              : const SizedBox(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Notes
                          ClassicErpInput(
                            label: 'Receiving Remarks / Notes',
                            controller: notesCtrl,
                            hintText: 'e.g. Received in good condition at central receiving dock. Inspected by Chef / Storekeeper.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Summary & Actions Ribbon
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECEFF1),
                      border: Border(top: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
                    ),
                    child: Row(
                      children: [
                        // Live Financial Totals
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Taxable: ${_currency.format(taxableSubtotal)}  •  GST: ${_currency.format(totalGst)}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                            Text('GRAND TOTAL: ${_currency.format(grandTotal)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                          ],
                        ),

                        const Spacer(),

                        // Cancel
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),

                        // Submit Button
                        ElevatedButton.icon(
                          onPressed: () {
                            if (vendorCtrl.text.trim().isEmpty || invoiceNoCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please provide Supplier Name and Invoice Number.')),
                              );
                              return;
                            }

                            final itemsToSave = <PurchaseItem>[];
                            for (final line in purchaseLines) {
                              final name = (line['nameCtrl'] as TextEditingController).text.trim();
                              if (name.isEmpty) continue;
                              final qty = double.tryParse((line['qtyCtrl'] as TextEditingController).text) ?? 1.0;
                              final rate = double.tryParse((line['rateCtrl'] as TextEditingController).text) ?? 0.0;
                              final taxPct = (line['taxPercent'] as double?) ?? 5.0;
                              final unit = (line['unit'] as String?) ?? 'Kg';

                              itemsToSave.add(PurchaseItem(
                                id: 'pi-${DateTime.now().millisecondsSinceEpoch}-${itemsToSave.length}',
                                name: name,
                                category: department,
                                quantity: qty,
                                unit: unit,
                                unitPrice: rate,
                                taxPercent: taxPct,
                              ));
                            }

                            if (itemsToSave.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please add at least one valid material line item.')),
                              );
                              return;
                            }

                            final newEntry = PurchaseEntry(
                              id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
                              branchId: repo.activeBranch.id,
                              invoiceNumber: invoiceNoCtrl.text.trim(),
                              vendorName: vendorCtrl.text.trim(),
                              vendorGstin: gstinCtrl.text.trim(),
                              vendorPhone: phoneCtrl.text.trim(),
                              purchaseDate: purchaseDate,
                              department: department,
                              items: itemsToSave,
                              paymentStatus: paymentStatus,
                              paymentMode: paymentMode,
                              notes: notesCtrl.text.trim(),
                              createdAt: DateTime.now(),
                            );

                            // Save & automatically increment live stock in repository!
                            repo.addPurchaseEntry(newEntry);
                            Navigator.pop(ctx);

                            // Show Success & Preview
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B4F72),
                                content: Text('✅ Purchase ${newEntry.invoiceNumber} recorded! In-hand stock updated for ${itemsToSave.length} items.'),
                              ),
                            );

                            _showPurchaseInvoiceViewer(context, repo, newEntry);
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                          label: const Text('SAVE INWARD & UPDATE STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
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
      ),
    );
  }

  // ===========================================================================
  // MODAL 2: PRINTABLE MATERIAL INWARD & PURCHASE TAX INVOICE WITH PRINTER SELECT
  // ===========================================================================
  void _handleDirectPrint(BuildContext context, PurchaseEntry p) {
    final repo = Provider.of<HotelRepository>(context, listen: false);
    _showPurchaseInvoiceViewer(context, repo, p);
  }

  void _showPurchaseInvoiceViewer(BuildContext context, HotelRepository repo, PurchaseEntry p) {
    showDialog(
      context: context,
      builder: (ctx) => _PurchaseInvoiceViewerDialog(
        repo: repo,
        purchase: p,
      ),
    );
  }

  // ===========================================================================
  // MODAL 3: QUICK ADJUST / PHYSICAL STOCK AUDIT
  // ===========================================================================
  void _showAdjustStockDialog(BuildContext context, HotelRepository repo, StockItemModel item) {
    final countCtrl = TextEditingController(text: '${item.currentStock % 1 == 0 ? item.currentStock.toInt() : item.currentStock}');
    final reasonCtrl = TextEditingController(text: 'Physical stock verification audit');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFF1B4F72),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Adjust Stock — ${item.itemCode}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 13, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                    Text('Category: ${item.category} • Location: ${item.storageLocation}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                    const SizedBox(height: 10),

                    ClassicErpInput(
                      label: 'Verified Physical Count (${item.unit})',
                      isRequired: true,
                      controller: countCtrl,
                      isNumeric: true,
                    ),
                    const SizedBox(height: 8),

                    ClassicErpInput(
                      label: 'Adjustment Reason / Note',
                      controller: reasonCtrl,
                      hintText: 'e.g. Breakage, spoilage or month-end audit discrepancy',
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            final newCount = double.tryParse(countCtrl.text) ?? item.currentStock;
                            final delta = newCount - item.currentStock;
                            repo.adjustStockQuantity(item.id, delta);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✅ ${item.name} stock updated to $newCount ${item.unit}')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          child: const Text('Update Stock Level', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL 4: ADD NEW STOCK SKU DIRECTLY
  // ===========================================================================
  void _showAddStockItemDialog(BuildContext context, HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final unitPriceCtrl = TextEditingController(text: '100');
    final initialStockCtrl = TextEditingController(text: '20');
    final reorderCtrl = TextEditingController(text: '5');
    final locationCtrl = TextEditingController(text: 'Main Central Store');

    String category = 'Kitchen & Provisions';
    String unit = 'Kg';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFF1B4F72),
                  child: Row(
                    children: [
                      const Icon(Icons.add_box_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text('Add New Inventory SKU Item', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 13, color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClassicErpInput(
                        label: 'Item / Material Name',
                        isRequired: true,
                        controller: nameCtrl,
                        hintText: 'e.g. Sunflower Refined Cooking Oil (15L Tin)',
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ClassicErpDropdown<String>(
                              label: 'Category',
                              isRequired: true,
                              value: category,
                              items: ['Kitchen & Provisions', 'Housekeeping & Linen', 'Guest Amenities', 'Bar & Beverages'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) {
                                if (v != null) setModalState(() => category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClassicErpDropdown<String>(
                              label: 'Unit of Measure',
                              isRequired: true,
                              value: unit,
                              items: ['Kg', 'Ltr', 'Pcs', 'Box', 'Can', 'Pack', 'Bottle', 'Set'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (v) {
                                if (v != null) setModalState(() => unit = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ClassicErpInput(
                              label: 'Initial Stock Qty',
                              isRequired: true,
                              controller: initialStockCtrl,
                              isNumeric: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClassicErpInput(
                              label: 'Reorder Alert Qty',
                              isRequired: true,
                              controller: reorderCtrl,
                              isNumeric: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClassicErpInput(
                              label: 'Unit Price (₹)',
                              isRequired: true,
                              controller: unitPriceCtrl,
                              isNumeric: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ClassicErpInput(
                        label: 'Storage Store / Location',
                        controller: locationCtrl,
                        hintText: 'e.g. Kitchen Pantry / Linen Room',
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final codePrefix = category.length >= 2 ? category.substring(0, 2).toUpperCase() : 'SK';
                              final newItem = StockItemModel(
                                id: 'stk-${DateTime.now().millisecondsSinceEpoch}',
                                branchId: repo.activeBranch.id,
                                itemCode: 'STK-$codePrefix-${(100 + repo.activeBranchStockItems.length + 1)}',
                                name: nameCtrl.text.trim(),
                                category: category,
                                unit: unit,
                                currentStock: double.tryParse(initialStockCtrl.text) ?? 0.0,
                                reorderLevel: double.tryParse(reorderCtrl.text) ?? 5.0,
                                unitPrice: double.tryParse(unitPriceCtrl.text) ?? 100.0,
                                storageLocation: locationCtrl.text.trim().isEmpty ? 'Central Store' : locationCtrl.text.trim(),
                                lastRestockedAt: DateTime.now(),
                              );
                              repo.addStockItem(newItem);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('✅ Added new SKU: ${newItem.name}')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4F72),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                            child: const Text('Add SKU to Inventory', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL 5: EDIT STOCK ITEM
  // ===========================================================================
  void _showEditStockItemDialog(BuildContext context, HotelRepository repo, StockItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final reorderCtrl = TextEditingController(text: '${item.reorderLevel % 1 == 0 ? item.reorderLevel.toInt() : item.reorderLevel}');
    final unitPriceCtrl = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    final locationCtrl = TextEditingController(text: item.storageLocation);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFF1B4F72),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Edit Item — ${item.itemCode}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, size: 13, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClassicErpInput(
                      label: 'Item Title',
                      controller: nameCtrl,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ClassicErpInput(
                            label: 'Reorder Level (${item.unit})',
                            controller: reorderCtrl,
                            isNumeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClassicErpInput(
                            label: 'Unit Price (₹)',
                            controller: unitPriceCtrl,
                            isNumeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ClassicErpInput(
                      label: 'Storage Store / Location',
                      controller: locationCtrl,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            final updated = item.copyWith(
                              name: nameCtrl.text.trim(),
                              reorderLevel: double.tryParse(reorderCtrl.text) ?? item.reorderLevel,
                              unitPrice: double.tryParse(unitPriceCtrl.text) ?? item.unitPrice,
                              storageLocation: locationCtrl.text.trim(),
                            );
                            repo.updateStockItem(updated);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================
  Widget _kpiPill(String title, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: textColor)),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ),
    );
  }

  Widget _ribbonBtn(IconData icon, VoidCallback onTap, {bool isClose = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 16,
        margin: const EdgeInsets.only(left: 2),
        color: isClose ? const Color(0xFFC0392B) : Colors.white12,
        alignment: Alignment.center,
        child: Icon(icon, size: 10, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 40, color: ClassicErpTheme.textMuted),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 11.5, color: ClassicErpTheme.textMuted)),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL: PRINTABLE MATERIAL INWARD & PURCHASE TAX INVOICE WITH PRINTER SELECT
// =============================================================================
class _PurchaseInvoiceViewerDialog extends StatefulWidget {
  final HotelRepository repo;
  final PurchaseEntry purchase;

  const _PurchaseInvoiceViewerDialog({
    required this.repo,
    required this.purchase,
  });

  @override
  State<_PurchaseInvoiceViewerDialog> createState() => _PurchaseInvoiceViewerDialogState();
}

class _PurchaseInvoiceViewerDialogState extends State<_PurchaseInvoiceViewerDialog> {
  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final GlobalKey _invoiceKey = GlobalKey();
  List<String> _printers = [];
  String _selectedPrinter = 'Microsoft Print to PDF';
  PrinterSettings? _printerSettings;
  bool _isLoadingPrinters = true;
  bool _isSavingPdf = false;

  @override
  void initState() {
    super.initState();
    _selectedPrinter = PrinterHelper.getDefaultPrinter();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final list = await PrinterHelper.getInstalledPrinters();
    if (mounted) {
      setState(() {
        _printers = list;
        if (!_printers.contains(_selectedPrinter)) {
          _selectedPrinter = _printers.isNotEmpty ? _printers.first : PrinterHelper.getDefaultPrinter();
        }
        _isLoadingPrinters = false;
      });
    }
  }

  Future<void> _saveAsPdf() async {
    setState(() => _isSavingPdf = true);
    try {
      final savedPath = await PdfExportService.savePdfFromBoundary(
        context,
        boundaryKey: _invoiceKey,
        suggestedName: 'Purchase_Invoice_${widget.purchase.invoiceNumber}',
        orientation: _printerSettings?.orientation ?? 'Portrait',
      );
      if (savedPath != null && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  Future<void> _openPrinterSetup() async {
    final settings = await PrinterSelectionDialog.show(
      context,
      documentTitle: 'Purchase Inward Bill / GRN (${widget.purchase.invoiceNumber})',
      initialPrinter: _selectedPrinter,
    );
    if (settings != null && mounted) {
      setState(() {
        _selectedPrinter = settings.printerName;
        _printerSettings = settings;
      });
    }
  }

  Future<void> _selectPrinterAndPrint() async {
    final settings = await PrinterSelectionDialog.show(
      context,
      documentTitle: 'Purchase Inward Bill / GRN (${widget.purchase.invoiceNumber})',
      initialPrinter: _selectedPrinter,
    );
    if (settings != null && mounted) {
      setState(() {
        _selectedPrinter = settings.printerName;
        _printerSettings = settings;
      });
      _dispatchPrint(settings);
    }
  }

  void _printDirect() {
    final settings = _printerSettings ??
        PrinterSettings(
          printerName: _selectedPrinter,
          copies: 1,
          paperSize: 'A4 (210 × 297 mm)',
          orientation: 'Portrait',
        );
    _dispatchPrint(settings);
  }

  void _dispatchPrint(PrinterSettings settings) {
    final isPdf = settings.printerName.toLowerCase().contains('pdf') ||
        settings.printerName.toLowerCase().contains('xps') ||
        settings.printerName.toLowerCase().contains('document writer');
    if (isPdf) {
      _saveAsPdf();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _sumLine(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 11 : 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? ClassicErpTheme.textMain)),
          Text(value, style: TextStyle(fontSize: isBold ? 12 : 10.5, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color ?? ClassicErpTheme.textMain)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.purchase;
    final repo = widget.repo;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: Color(0xFF1B4F72), width: 1.5),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: 860,
            height: 680,
            child: Column(
              children: [
                // Top Action Header
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFF1B4F72),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PURCHASE INWARD INVOICE & GRN — ${p.invoiceNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Top Printer Ribbon Toolbar
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.print_rounded, size: 14, color: Color(0xFF1B4F72)),
                        const SizedBox(width: 6),
                        const Text('Select Printer:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(width: 8),
                        _isLoadingPrinters
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : Container(
                                height: 24,
                                constraints: const BoxConstraints(maxWidth: 240),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: const Color(0xFF90A4AE)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _printers.contains(_selectedPrinter) ? _selectedPrinter : (_printers.isNotEmpty ? _printers.first : null),
                                    isDense: true,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1B4F72)),
                                    items: _printers.map((prn) => DropdownMenuItem(
                                      value: prn,
                                      child: Row(
                                        children: [
                                          Icon(prn.toLowerCase().contains('pdf') ? Icons.picture_as_pdf_outlined : Icons.print_outlined, size: 12, color: const Color(0xFF546E7A)),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              prn,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedPrinter = val);
                                    },
                                  ),
                                ),
                              ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _openPrinterSetup,
                          icon: const Icon(Icons.tune_rounded, size: 11, color: Color(0xFF1B4F72)),
                          label: const Text('Printer Setup...', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            side: const BorderSide(color: Color(0xFF1B4F72)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            minimumSize: const Size(0, 24),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: _saveAsPdf,
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 11, color: Color(0xFFC0392B)),
                          label: const Text('Save as PDF', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            side: const BorderSide(color: Color(0xFFC0392B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            minimumSize: const Size(0, 24),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8F5),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: const Color(0xFFA2D9CE)),
                          ),
                          child: Text(
                            '${_printerSettings?.copies ?? 1} Copy • ${_printerSettings?.paperSize.split(' ').first ?? 'A4'} • ${_printerSettings?.orientation ?? 'Portrait'}',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A085)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Invoice Document Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: RepaintBoundary(
                        key: _invoiceKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hotel & Document Banner
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HotelLogoWidget(width: 40, height: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(repo.clientBusinessName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72))),
                                        Text('${repo.activeBranch.name} • ${repo.activeBranch.address}, ${repo.activeBranch.city}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                                        Text('GSTIN: ${repo.activeBranch.taxIdentifier}  •  Ph: ${repo.activeBranch.phone}', style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF5FB),
                                      border: Border.all(color: const Color(0xFF1B4F72)),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('GOODS RECEIPT NOTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72))),
                                        Text(p.invoiceNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                                        Text('Date: ${DateFormat('dd MMM yyyy').format(p.purchaseDate)}', style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 20, color: Color(0xFF1B4F72), thickness: 1.5),

                              // Supplier & Inward Particulars Box
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9F9),
                                  border: Border.all(color: const Color(0xFFD6DBDF)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('SUPPLIER / VENDOR DETAILS:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(p.vendorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                                          if (p.vendorGstin.isNotEmpty)
                                            Text('GSTIN: ${p.vendorGstin}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                                          if (p.vendorPhone.isNotEmpty)
                                            Text('Phone: ${p.vendorPhone}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('INWARD & PAYMENT PARTICULARS:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
                                          const SizedBox(height: 2),
                                          Text('Receiving Dept: ${p.department}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                                          Text('Payment Mode: ${p.paymentMode}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                                          Text('Status: ${p.paymentStatus.toUpperCase()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: p.paymentStatus == 'Paid' ? const Color(0xFF27AE60) : const Color(0xFFE67E22))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Itemized Table
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFBDC3C7))),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 24,
                                      color: const Color(0xFF1B4F72),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: const Row(
                                        children: [
                                          SizedBox(width: 30, child: Text('#', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                          Expanded(flex: 4, child: Text('Item / Material Description', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 80, child: Text('Quantity', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 80, child: Text('Rate (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 60, child: Text('GST %', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                          SizedBox(width: 90, child: Text('Amount (₹)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    ),
                                    ...p.items.asMap().entries.map((entry) {
                                      final idx = entry.key + 1;
                                      final item = entry.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFECF0F1)))),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 30, child: Text('$idx', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted))),
                                            Expanded(flex: 4, child: Text(item.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ClassicErpTheme.textMain))),
                                            SizedBox(width: 80, child: Text('${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain))),
                                            SizedBox(width: 80, child: Text(_currency.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain))),
                                            SizedBox(width: 60, child: Text('${item.taxPercent.toInt()}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted))),
                                            SizedBox(width: 90, child: Text(_currency.format(item.totalAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)))),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Grand Totals Summary Block
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 260,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9F9),
                                      border: Border.all(color: const Color(0xFFBDC3C7)),
                                    ),
                                    child: Column(
                                      children: [
                                        _sumLine('Taxable Amount:', _currency.format(p.subTotal)),
                                        _sumLine('Total GST / VAT:', _currency.format(p.totalTax)),
                                        const Divider(height: 8, color: Color(0xFFBDC3C7)),
                                        _sumLine('GRAND TOTAL:', _currency.format(p.grandTotal), isBold: true, color: const Color(0xFF1B4F72)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (p.notes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Remarks: ${p.notes}', style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: ClassicErpTheme.textMuted)),
                              ],

                              const SizedBox(height: 24),

                              // Signatures
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 140, child: Divider(color: Colors.black45, thickness: 1)),
                                      Text('Received By (Storekeeper)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(width: 140, child: Divider(color: Colors.black45, thickness: 1)),
                                      Text('Verified (Accounts / GM)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Actions
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFFECEFF1),
                  child: Row(
                    children: [
                      const Icon(Icons.print_rounded, size: 14, color: Color(0xFF1B4F72)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Target: $_selectedPrinter',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _saveAsPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 13, color: Color(0xFFC0392B)),
                        label: const Text('SAVE AS PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          side: const BorderSide(color: Color(0xFFC0392B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: _selectPrinterAndPrint,
                        icon: const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF1B4F72)),
                        label: const Text('SETUP & PRINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          side: const BorderSide(color: Color(0xFF1B4F72)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: _printDirect,
                        icon: const Icon(Icons.print_rounded, size: 13, color: Colors.white),
                        label: const Text('PRINT INWARD BILL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4F72),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay when generating PDF
          if (_isSavingPdf)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF1B4F72), width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text(
                          'Generating & Saving PDF Document...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1B4F72)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
