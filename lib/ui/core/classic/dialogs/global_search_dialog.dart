import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';

class GlobalSearchResult {
  final String category;
  final String title;
  final String subtitle;
  final String code;
  final IconData icon;
  final Color iconColor;
  final int moduleIndex;
  final dynamic data;

  GlobalSearchResult({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.icon,
    required this.iconColor,
    required this.moduleIndex,
    this.data,
  });
}

/// Enterprise Global Search Dialog (Ctrl+F)
/// Instant cross-entity search across Rooms, Guests, Invoices, Food Dishes, Materials & Vendors.
class GlobalSearchDialog extends StatefulWidget {
  final void Function(int moduleIndex, dynamic targetData) onNavigateToModule;

  const GlobalSearchDialog({super.key, required this.onNavigateToModule});

  static void show(BuildContext context, void Function(int moduleIndex, dynamic targetData) onNavigate) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => GlobalSearchDialog(onNavigateToModule: onNavigate),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  String _selectedCategory = 'ALL';
  List<GlobalSearchResult> _results = [];

  final List<String> _categories = [
    'ALL',
    'ROOMS & GUESTS',
    'INVOICES & BILLS',
    'RESTAURANT F&B',
    'STOCK & MATERIALS',
    'VENDORS & PURCHASES',
  ];

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final repo = context.read<HotelRepository>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final q = query.trim().toLowerCase();
    final List<GlobalSearchResult> list = [];

    // 1. Rooms & In-House Guests
    if (_selectedCategory == 'ALL' || _selectedCategory == 'ROOMS & GUESTS') {
      for (final r in repo.activeBranchRooms) {
        final guest = r.currentGuestName ?? '';
        if (q.isEmpty ||
            r.roomNumber.toLowerCase().contains(q) ||
            r.roomTypeName.toLowerCase().contains(q) ||
            guest.toLowerCase().contains(q)) {
          list.add(GlobalSearchResult(
            category: 'ROOMS & GUESTS',
            title: 'Room ${r.roomNumber} — ${r.roomTypeName.toUpperCase()}',
            subtitle: guest.isNotEmpty ? 'Occupant: $guest • ${r.status.label}' : 'Status: ${r.status.label} • Floor ${r.floorNumber}',
            code: 'RM-${r.roomNumber}',
            icon: Icons.hotel_rounded,
            iconColor: const Color(0xFF1B4F72),
            moduleIndex: 0, // Front Desk
            data: r,
          ));
        }
      }
    }

    // 2. Invoices & Billing
    if (_selectedCategory == 'ALL' || _selectedCategory == 'INVOICES & BILLS') {
      for (final inv in repo.allInvoices) {
        if (q.isEmpty ||
            inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.customerName.toLowerCase().contains(q) ||
            (inv.customerGstin?.toLowerCase().contains(q) ?? false) ||
            inv.type.label.toLowerCase().contains(q)) {
          list.add(GlobalSearchResult(
            category: 'INVOICES & BILLS',
            title: '${inv.invoiceNumber} — ${inv.customerName.toUpperCase()}',
            subtitle: '${inv.type.label} • Total: ${currency.format(inv.totalAmount)} • Mode: ${inv.paymentMode} • ${inv.status.label}',
            code: inv.invoiceNumber,
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF27AE60),
            moduleIndex: 1, // Billing & Folios
            data: inv,
          ));
        }
      }
    }

    // 3. Restaurant F&B Dishes
    if (_selectedCategory == 'ALL' || _selectedCategory == 'RESTAURANT F&B') {
      for (final m in repo.activeBranchMenuItems) {
        if (q.isEmpty ||
            m.name.toLowerCase().contains(q) ||
            m.category.toLowerCase().contains(q) ||
            m.id.toLowerCase().contains(q)) {
          list.add(GlobalSearchResult(
            category: 'RESTAURANT F&B',
            title: '${m.emoji} ${m.name.toUpperCase()}',
            subtitle: 'Category: ${m.category} • Price: ${currency.format(m.price)} (+${m.taxRate.toStringAsFixed(0)}% GST) • ${m.isVeg ? "VEG" : "NON-VEG"}',
            code: m.id,
            icon: Icons.restaurant_menu_rounded,
            iconColor: const Color(0xFFE67E22),
            moduleIndex: 2, // POS Restaurant
            data: m,
          ));
        }
      }
    }

    // 4. Stock & Materials
    if (_selectedCategory == 'ALL' || _selectedCategory == 'STOCK & MATERIALS') {
      for (final s in repo.activeBranchStockItems) {
        if (q.isEmpty ||
            s.name.toLowerCase().contains(q) ||
            s.itemCode.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q)) {
          list.add(GlobalSearchResult(
            category: 'STOCK & MATERIALS',
            title: '${s.name.toUpperCase()} (${s.itemCode})',
            subtitle: 'Location: ${s.storageLocation} • Stock: ${s.currentStock} ${s.unit} • Reorder: ${s.reorderLevel} ${s.unit}',
            code: s.itemCode,
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFF8E44AD),
            moduleIndex: 8, // Stock & Inventory
            data: s,
          ));
        }
      }
    }

    // 5. Vendors & Purchases
    if (_selectedCategory == 'ALL' || _selectedCategory == 'VENDORS & PURCHASES') {
      for (final p in repo.activeBranchPurchases) {
        if (q.isEmpty ||
            p.vendorName.toLowerCase().contains(q) ||
            p.invoiceNumber.toLowerCase().contains(q) ||
            p.vendorGstin.toLowerCase().contains(q)) {
          list.add(GlobalSearchResult(
            category: 'VENDORS & PURCHASES',
            title: '${p.vendorName.toUpperCase()} — Inv #${p.invoiceNumber}',
            subtitle: 'GSTIN: ${p.vendorGstin} • Dept: ${p.department} • Total: ${currency.format(p.grandTotal)} • ${p.paymentStatus}',
            code: p.invoiceNumber,
            icon: Icons.shopping_bag_rounded,
            iconColor: const Color(0xFF2980B9),
            moduleIndex: 7, // Purchase & Finance
            data: p,
          ));
        }
      }
    }

    setState(() {
      _results = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ClassicErpTheme.panelBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 780,
        height: 520,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          children: [
            // 1. Classic Windows Dialog Title Bar
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
                  const Icon(Icons.search_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Global Search & Jump Terminal — HotelPro ERP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 16,
                      height: 14,
                      color: const Color(0xFFC0392B),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Box & Filter Chips
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCF3CF).withValues(alpha: 0.3),
                            border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 16, color: ClassicErpTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: _queryController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: 'Type room number, guest name, invoice ID, food item, stock material...',
                                    hintStyle: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.normal),
                                  ),
                                  onChanged: _performSearch,
                                ),
                              ),
                              if (_queryController.text.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    _queryController.clear();
                                    _performSearch('');
                                  },
                                  child: const Icon(Icons.clear, size: 14, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAECEE),
                          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                        ),
                        child: Text(
                          '${_results.length} Matches',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _performSearch(_queryController.text);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF1B4F72) : const Color(0xFFF2F4F4),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF154360) : ClassicErpTheme.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                  color: isSel ? Colors.white : ClassicErpTheme.textMain,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: ClassicErpTheme.borderDark),

            // 3. Results List
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'No records found matching your search term.',
                            style: TextStyle(fontSize: 12, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching with partial keywords or select ALL categories.',
                            style: TextStyle(fontSize: 10, color: Colors.black45),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemExtent: 52,
                      itemBuilder: (context, idx) {
                        final item = _results[idx];
                        final isEven = idx.isEven;
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onNavigateToModule(item.moduleIndex, item.data);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isEven ? Colors.white : const Color(0xFFF9FAFB),
                              border: const Border(bottom: BorderSide(color: Color(0xFFEAEDED), width: 0.8)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: item.iconColor.withValues(alpha: 0.12),
                                    border: Border.all(color: item.iconColor.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Icon(item.icon, size: 16, color: item.iconColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: ClassicErpTheme.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: ClassicErpTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBF5FB),
                                    border: Border.all(color: const Color(0xFFAED6F1), width: 0.6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(fontSize: 8.5, color: Color(0xFF2471A3), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 4. Footer Status Bar
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: const Color(0xFFE5E7E9),
              child: Row(
                children: [
                  const Text('Click any entry to jump directly to its workstation module.', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                  const Spacer(),
                  const Text('ESC or Close to exit', style: TextStyle(fontSize: 9.5, color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
