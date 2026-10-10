import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/models/pos_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

/// Mobile Menu Builder — Preview how menu looks in Customer App
/// Staff can enable/disable items, set photos, manage mobile visibility
class MobileMenuTab extends StatefulWidget {
  const MobileMenuTab({super.key});

  @override
  State<MobileMenuTab> createState() => _MobileMenuTabState();
}

class _MobileMenuTabState extends State<MobileMenuTab> {
  String _selectedCategory = 'all';
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final items = repo.activeBranchMenuItems;
    final categories = ['all', ...items.map((m) => m.category).toSet().toList()..sort()];
    final filtered = _selectedCategory == 'all'
        ? items
        : items.where((m) => m.category == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobile App Menu Builder', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Preview & manage how menu appears in Customer App. Toggle mobile visibility.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.statusClean.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.statusClean.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android_rounded, color: AppTheme.statusClean, size: 16),
                    SizedBox(width: 6),
                    Text('Live Preview Mode', style: TextStyle(color: AppTheme.statusClean, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final sel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.imperialGold : AppTheme.slateCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppTheme.imperialGold : AppTheme.slateBorder),
                      ),
                      child: Text(
                        cat == 'all' ? '🍽️ All' : cat,
                        style: TextStyle(
                          color: sel ? Colors.black : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Preview Grid — simulates Customer App look
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No items found. Add items from Food Menu tab.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 230,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildMobileMenuCard(filtered[i], repo),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenuCard(PosMenuItemModel item, HotelRepository repo) {
    return AnimatedOpacity(
      opacity: item.isAvailable ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.slateCardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isAvailable ? AppTheme.imperialGold.withValues(alpha: 0.3) : AppTheme.slateBorder,
            width: item.isAvailable ? 1.5 : 1,
          ),
          boxShadow: item.isAvailable
              ? [BoxShadow(color: AppTheme.imperialGold.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo area (simulated)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.slateCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: item.isVeg
                      ? [Colors.green.withValues(alpha: 0.15), Colors.green.withValues(alpha: 0.05)]
                      : [Colors.red.withValues(alpha: 0.15), Colors.red.withValues(alpha: 0.05)],
                ),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(color: item.isVeg ? Colors.green : Colors.red, width: 1.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: item.isVeg ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.category, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currency.format(item.price),
                          style: const TextStyle(color: AppTheme.textGold, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Mobile toggle switch
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: item.isAvailable,
                          onChanged: (v) => repo.updateMenuItem(item.id, isAvailable: v),
                          activeThumbColor: AppTheme.statusClean,
                        ),
                      ),
                    ],
                  ),
                  if (!item.isAvailable)
                    const Text('Hidden from app', style: TextStyle(color: AppTheme.statusDirty, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
