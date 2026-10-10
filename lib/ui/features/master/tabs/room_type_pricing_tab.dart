import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

class RoomTypePricingTab extends StatefulWidget {
  const RoomTypePricingTab({super.key});

  @override
  State<RoomTypePricingTab> createState() => _RoomTypePricingTabState();
}

class _RoomTypePricingTabState extends State<RoomTypePricingTab> {
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final roomTypes = repo.activeBranchRoomTypes;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Room Types & Tariff Configuration',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddRoomTypeDialog(context, repo),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
                label: const Text('Add Room Type', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Responsive Table Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minWidth = 750.0;
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
                              Expanded(flex: 3, child: Text('Room Type', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 1, child: Text('Code', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 2, child: Text('Bed Type', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 1, child: Text('Max Adults', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 2, child: Text('Base Tariff / Night', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 100, child: Text('Actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ),

                        // Room Type Rows
                        Expanded(
                          child: roomTypes.isEmpty
                              ? _emptyState('No room types configured yet.')
                              : ListView.builder(
                                  itemCount: roomTypes.length,
                                  itemBuilder: (ctx, i) {
                                    final rt = roomTypes[i];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: i.isEven ? AppTheme.slateCard : AppTheme.obsidianBg,
                                        border: const Border(
                                          left: BorderSide(color: AppTheme.slateBorder),
                                          right: BorderSide(color: AppTheme.slateBorder),
                                          bottom: BorderSide(color: AppTheme.slateBorder),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(rt.name,
                                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.imperialGold.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(rt.code,
                                                  style: const TextStyle(color: AppTheme.imperialGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(rt.bedType,
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text('${rt.maxAdults} Adults',
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              currency.format(rt.basePrice),
                                              style: const TextStyle(color: AppTheme.textGold, fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.imperialGold),
                                                  onPressed: () => _showEditRoomTypeDialog(context, repo, rt),
                                                  tooltip: 'Edit',
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.currency_rupee_rounded, size: 16, color: AppTheme.statusClean),
                                                  onPressed: () => _showPriceChangeDialog(context, repo, rt),
                                                  tooltip: 'Change Price',
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.statusOccupied),
                                                  onPressed: () => _confirmDelete(context, repo, rt),
                                                  tooltip: 'Delete',
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  padding: EdgeInsets.zero,
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

  void _showAddRoomTypeDialog(BuildContext context, HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '5000');
    final descCtrl = TextEditingController();
    String bedType = 'King Size';
    int maxAdults = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.imperialGold),
          ),
          title: const Text('Add New Room Type', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Room Type Name (e.g. Grand Deluxe Ocean View)', nameCtrl),
                  const SizedBox(height: 12),
                  _field('Code (e.g. DLX, STE, PRS)', codeCtrl),
                  const SizedBox(height: 12),
                  _field('Base Tariff / Night (₹)', priceCtrl, isNumber: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: bedType,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Bed Type'),
                    items: ['King Size', 'Queen Size', 'Twin Beds', 'Double Bed', 'Single Bed', 'Bunk Bed']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setS(() => bedType = v ?? bedType),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: maxAdults,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Max Adults'),
                    items: [1, 2, 3, 4, 5, 6].map((n) => DropdownMenuItem(value: n, child: Text('$n Adults'))).toList(),
                    onChanged: (v) => setS(() => maxAdults = v ?? maxAdults),
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
                if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
                repo.addRoomType(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  basePrice: double.tryParse(priceCtrl.text) ?? 5000,
                  bedType: bedType,
                  maxAdults: maxAdults,
                  description: descCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Add Room Type', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomTypeDialog(BuildContext context, HotelRepository repo, RoomTypeModel rt) {
    final nameCtrl = TextEditingController(text: rt.name);
    final descCtrl = TextEditingController(text: rt.description ?? '');
    String bedType = rt.bedType;
    int maxAdults = rt.maxAdults;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: Text('Edit: ${rt.code}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Room Type Name', nameCtrl),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: bedType,
                  dropdownColor: AppTheme.slateCard,
                  decoration: const InputDecoration(labelText: 'Bed Type'),
                  items: ['King Size', 'Queen Size', 'Twin Beds', 'Double Bed', 'Single Bed']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setS(() => bedType = v ?? bedType),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: maxAdults,
                  dropdownColor: AppTheme.slateCard,
                  decoration: const InputDecoration(labelText: 'Max Adults'),
                  items: [1, 2, 3, 4].map((n) => DropdownMenuItem(value: n, child: Text('$n Adults'))).toList(),
                  onChanged: (v) => setS(() => maxAdults = v ?? maxAdults),
                ),
                const SizedBox(height: 12),
                _field('Description', descCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                repo.updateRoomType(rt.id, name: nameCtrl.text.trim(), bedType: bedType, maxAdults: maxAdults, description: descCtrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceChangeDialog(BuildContext context, HotelRepository repo, RoomTypeModel rt) {
    final priceCtrl = TextEditingController(text: rt.basePrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.slateCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.statusClean)),
        title: Text('Update Price: ${rt.name}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yeh change sabhi rooms aur future bookings ke liye apply hoga.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            _field('New Base Tariff / Night (₹)', priceCtrl, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusClean),
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text);
              if (newPrice != null && newPrice > 0) {
                repo.updateRoomTypePrice(rt.id, newPrice);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${rt.name} tariff updated to ${currency.format(newPrice)} / night'), backgroundColor: AppTheme.statusClean),
                );
              }
            },
            child: const Text('Update Price', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HotelRepository repo, RoomTypeModel rt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.slateCardElevated,
        title: Text('Delete ${rt.name}?', style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Agar is type ke rooms assigned hain, toh delete nahi hoga.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusOccupied),
            onPressed: () {
              repo.deleteRoomType(rt.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.meeting_room_rounded, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      ],
    ),
  );

  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }
}
