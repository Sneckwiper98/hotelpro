import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_theme.dart';
import 'tabs/room_type_pricing_tab.dart';
import 'tabs/floor_room_bed_tab.dart';
import 'tabs/food_menu_pricing_tab.dart';
import 'tabs/inventory_items_tab.dart';
import 'tabs/mobile_menu_tab.dart';
import 'tabs/staff_management_tab.dart';
import 'tabs/user_roles_tab.dart';

class MasterSectionView extends StatefulWidget {
  const MasterSectionView({super.key});

  @override
  State<MasterSectionView> createState() => _MasterSectionViewState();
}

class _MasterSectionViewState extends State<MasterSectionView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_MasterTab> _tabs = [
    _MasterTab(Icons.meeting_room_rounded, 'Room Types & Pricing'),
    _MasterTab(Icons.layers_rounded, 'Floors & Rooms'),
    _MasterTab(Icons.restaurant_menu_rounded, 'Food Menu & Pricing'),
    _MasterTab(Icons.inventory_2_rounded, 'Inventory Items'),
    _MasterTab(Icons.phone_android_rounded, 'Mobile Menu Builder'),
    _MasterTab(Icons.badge_rounded, 'Staff Management'),
    _MasterTab(Icons.manage_accounts_rounded, 'Users & Roles'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              color: AppTheme.slateCard,
              border: Border(bottom: BorderSide(color: AppTheme.slateBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.imperialGold, AppTheme.goldDark],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Master Configuration Center',
                            style: Theme.of(context).textTheme.headlineMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Hotel setup, pricing, staff & system configuration — all in one place',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.imperialGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.imperialGold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded,
                              color: AppTheme.imperialGold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'SUPER ADMIN',
                            style: GoogleFonts.inter(
                              color: AppTheme.imperialGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Tab Bar ──────────────────────────────────────────
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    color: AppTheme.imperialGold.withValues(alpha: 0.15),
                    border: Border(
                      top: BorderSide(color: AppTheme.imperialGold.withValues(alpha: 0.6), width: 2),
                    ),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.imperialGold,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: _tabs.map((t) {
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Tab Content ─────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                RoomTypePricingTab(),
                FloorRoomBedTab(),
                FoodMenuPricingTab(),
                InventoryItemsTab(),
                MobileMenuTab(),
                StaffManagementTab(),
                UserRolesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterTab {
  final IconData icon;
  final String label;
  const _MasterTab(this.icon, this.label);
}
