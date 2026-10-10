import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/models/pos_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

class FoodMenuPricingTab extends StatefulWidget {
  const FoodMenuPricingTab({super.key});

  @override
  State<FoodMenuPricingTab> createState() => _FoodMenuPricingTabState();
}

class _FoodMenuPricingTabState extends State<FoodMenuPricingTab> {
  String _selectedCategory = 'all';
  String _selectedOutletId = '';
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final outlets = repo.activeBranchOutlets;
    final allItems = repo.activeBranchMenuItems;

    if (_selectedOutletId.isEmpty && outlets.isNotEmpty) {
      _selectedOutletId = outlets.first.id;
    }

    final outletItems = allItems.where((m) => m.outletId == _selectedOutletId).toList();
    final categories = ['all', ...outletItems.map((m) => m.category).toSet().toList()..sort()];
    final filtered = _selectedCategory == 'all'
        ? outletItems
        : outletItems.where((m) => m.category == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              // Outlet selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.slateCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.slateBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOutletId.isEmpty ? null : _selectedOutletId,
                    dropdownColor: AppTheme.slateCardElevated,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    hint: const Text('Select Outlet', style: TextStyle(color: AppTheme.textMuted)),
                    items: outlets.map((o) {
                      return DropdownMenuItem(value: o.id, child: Text(o.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedOutletId = v ?? _selectedOutletId),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Category filter chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final sel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.imperialGold.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: sel ? AppTheme.imperialGold : AppTheme.slateBorder),
                            ),
                            child: Text(
                              cat == 'all' ? 'All Items' : cat,
                              style: TextStyle(
                                color: sel ? AppTheme.imperialGold : AppTheme.textSecondary,
                                fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: outlets.isEmpty ? null : () => _showAddItemDialog(context, repo, outlets),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                label: const Text('Add Menu Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Menu Items Grid
          Expanded(
            child: filtered.isEmpty
                ? _empty()
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisExtent: 165,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildMenuCard(context, filtered[i], repo),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, PosMenuItemModel item, HotelRepository repo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.slateCardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isAvailable ? AppTheme.slateBorder : AppTheme.statusOccupied.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(item.category,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              // Veg/Non-veg indicator
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  border: Border.all(color: item.isVeg ? Colors.green : Colors.red, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: item.isVeg ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.format(item.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textGold, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '+${item.taxRate.toStringAsFixed(0)}% GST',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: item.isAvailable,
                      onChanged: (v) => repo.updateMenuItem(item.id, isAvailable: v),
                      activeThumbColor: AppTheme.statusClean,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.imperialGold),
                    onPressed: () => _showEditItemDialog(context, repo, item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, size: 15, color: AppTheme.statusOccupied),
                    onPressed: () => repo.deleteMenuItem(item.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, HotelRepository repo, List<PosOutletModel> outlets) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '250');
    final catCtrl = TextEditingController(text: 'Main Course');
    final descCtrl = TextEditingController();
    bool isVeg = true;
    double taxRate = 5.0;
    String outletId = outlets.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: const Text('Add Menu Item', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Item Name', nameCtrl),
                  const SizedBox(height: 12),
                  _field('Category (e.g. Starters, Main Course, Beverages)', catCtrl),
                  const SizedBox(height: 12),
                  _field('Price (₹)', priceCtrl, isNumber: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    initialValue: taxRate,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'GST Rate'),
                    items: [0.0, 5.0, 12.0, 18.0].map((t) => DropdownMenuItem(value: t, child: Text('$t%'))).toList(),
                    onChanged: (v) => setS(() => taxRate = v ?? taxRate),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: outletId,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Outlet'),
                    items: outlets.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))).toList(),
                    onChanged: (v) => setS(() => outletId = v ?? outletId),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Item Type:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        isSelected: [isVeg, !isVeg],
                        onPressed: (i) => setS(() => isVeg = i == 0),
                        color: AppTheme.textMuted,
                        selectedColor: Colors.white,
                        fillColor: isVeg ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('🟢 Veg')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('🔴 Non-Veg')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field('Description (optional)', descCtrl, maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                repo.addMenuItem(
                  outletId: outletId,
                  name: nameCtrl.text.trim(),
                  category: catCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 250,
                  taxRate: taxRate,
                  isVeg: isVeg,
                  description: descCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Add Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, HotelRepository repo, PosMenuItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
    final catCtrl = TextEditingController(text: item.category);
    bool isVeg = item.isVeg;
    double taxRate = item.taxRate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: Text('Edit: ${item.name}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Item Name', nameCtrl),
                const SizedBox(height: 12),
                _field('Category', catCtrl),
                const SizedBox(height: 12),
                _field('Price (₹)', priceCtrl, isNumber: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<double>(
                  initialValue: taxRate,
                  dropdownColor: AppTheme.slateCard,
                  decoration: const InputDecoration(labelText: 'GST Rate'),
                  items: [0.0, 5.0, 12.0, 18.0].map((t) => DropdownMenuItem(value: t, child: Text('$t%'))).toList(),
                  onChanged: (v) => setS(() => taxRate = v ?? taxRate),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Type:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(width: 12),
                    ToggleButtons(
                      isSelected: [isVeg, !isVeg],
                      onPressed: (i) => setS(() => isVeg = i == 0),
                      selectedColor: Colors.white,
                      fillColor: isVeg ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Veg')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Non-Veg')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                repo.updateMenuItem(item.id,
                    name: nameCtrl.text.trim(), category: catCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text), isVeg: isVeg, taxRate: taxRate);
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🍽️', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('No menu items found. Add your first item!', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      ],
    ),
  );

  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(labelText: label),
      );
}
