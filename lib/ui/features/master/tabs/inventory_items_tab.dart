import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';

/// Inventory Items Tab — simple placeholder for stock items
/// (full inventory module can be expanded in Phase 2)
class InventoryItemsTab extends StatefulWidget {
  const InventoryItemsTab({super.key});

  @override
  State<InventoryItemsTab> createState() => _InventoryItemsTabState();
}

class _InventoryItemsTabState extends State<InventoryItemsTab> {
  final List<Map<String, dynamic>> _items = [
    {'name': 'Shampoo Sachets', 'category': 'Amenities', 'unit': 'pcs', 'stock': 500, 'minStock': 100},
    {'name': 'Towels (Bath)', 'category': 'Linen', 'unit': 'pcs', 'stock': 150, 'minStock': 50},
    {'name': 'Toilet Paper Rolls', 'category': 'Supplies', 'unit': 'rolls', 'stock': 300, 'minStock': 80},
    {'name': 'Mineral Water (1L)', 'category': 'Minibar', 'unit': 'bottles', 'stock': 200, 'minStock': 60},
    {'name': 'Basmati Rice (Kg)', 'category': 'Kitchen', 'unit': 'kg', 'stock': 50, 'minStock': 20},
    {'name': 'Cooking Oil (L)', 'category': 'Kitchen', 'unit': 'litre', 'stock': 30, 'minStock': 10},
    {'name': 'Bed Sheets (King)', 'category': 'Linen', 'unit': 'pcs', 'stock': 80, 'minStock': 30},
    {'name': 'Coffee Sachets', 'category': 'Minibar', 'unit': 'pcs', 'stock': 400, 'minStock': 120},
    {'name': 'Hand Soap Bars', 'category': 'Amenities', 'unit': 'pcs', 'stock': 350, 'minStock': 100},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Inventory & Stock Management',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddItemDialog(context),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                label: const Text('Add Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Track consumables, amenities, linen, kitchen supplies and minibar stock.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Responsive Table Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minWidth = 780.0;
                final tableWidth = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.slateCardElevated,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            border: Border.all(color: AppTheme.slateBorder),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('Item Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 2, child: Text('Category', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 80, child: Text('Unit', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 100, child: Text('Stock', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 110, child: Text('Min. Stock', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 80, child: Text('Status', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 80, child: Text('Actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (ctx, i) {
                              final item = _items[i];
                              final isLow = (item['stock'] as int) < (item['minStock'] as int);
                              final statusColor = isLow ? AppTheme.statusDirty : AppTheme.statusClean;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: i.isEven ? AppTheme.slateCard : AppTheme.obsidianBg,
                                  border: Border(
                                    left: BorderSide(color: isLow ? AppTheme.statusDirty.withValues(alpha: 0.5) : AppTheme.slateBorder, width: isLow ? 2 : 1),
                                    right: const BorderSide(color: AppTheme.slateBorder),
                                    bottom: const BorderSide(color: AppTheme.slateBorder),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(item['name'] as String,
                                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                                    Expanded(flex: 2, child: Text(item['category'] as String,
                                        style: const TextStyle(color: AppTheme.champagneAccent, fontSize: 12))),
                                    SizedBox(width: 80, child: Text(item['unit'] as String,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                    SizedBox(width: 100, child: Text('${item['stock']}',
                                        style: TextStyle(color: isLow ? AppTheme.statusDirty : AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold, fontSize: 14))),
                                    SizedBox(width: 110, child: Text('${item['minStock']}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                    SizedBox(
                                      width: 80,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(isLow ? 'LOW' : 'OK',
                                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.imperialGold),
                                            onPressed: () => _showEditItemDialog(context, i),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_rounded, size: 15, color: AppTheme.statusOccupied),
                                            onPressed: () => setState(() => _items.removeAt(i)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Amenities');
    final unitCtrl = TextEditingController(text: 'pcs');
    final stockCtrl = TextEditingController(text: '100');
    final minStockCtrl = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.slateCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
        title: const Text('Add Inventory Item', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Item Name', nameCtrl),
              const SizedBox(height: 10),
              _field('Category', catCtrl),
              const SizedBox(height: 10),
              _field('Unit (pcs, kg, litre, rolls)', unitCtrl),
              const SizedBox(height: 10),
              _field('Current Stock', stockCtrl, isNumber: true),
              const SizedBox(height: 10),
              _field('Minimum Stock (alert level)', minStockCtrl, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              setState(() {
                _items.add({
                  'name': nameCtrl.text.trim(),
                  'category': catCtrl.text.trim(),
                  'unit': unitCtrl.text.trim(),
                  'stock': int.tryParse(stockCtrl.text) ?? 0,
                  'minStock': int.tryParse(minStockCtrl.text) ?? 0,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, int idx) {
    final item = _items[idx];
    final stockCtrl = TextEditingController(text: '${item['stock']}');
    final minStockCtrl = TextEditingController(text: '${item['minStock']}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.slateCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
        title: Text('Update Stock: ${item['name']}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Current Stock', stockCtrl, isNumber: true),
            const SizedBox(height: 12),
            _field('Min. Stock Level', minStockCtrl, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items[idx]['stock'] = int.tryParse(stockCtrl.text) ?? _items[idx]['stock'];
                _items[idx]['minStock'] = int.tryParse(minStockCtrl.text) ?? _items[idx]['minStock'];
              });
              Navigator.pop(ctx);
            },
            child: const Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label),
      );
}
