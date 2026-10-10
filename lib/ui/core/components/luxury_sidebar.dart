import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_theme.dart';

class LuxurySidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const LuxurySidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.obsidianBg,
        border: Border(
          right: BorderSide(color: AppTheme.slateBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. Logo & Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.imperialGold, AppTheme.goldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.imperialGold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.castle_rounded, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOTELPRO',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.textGold,
                      ),
                    ),
                    const Text(
                      '5-STAR LUXURY ERP',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.slateBorder, height: 1),
          const SizedBox(height: 16),

          // 2. Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  title: 'Front Desk & Rooms',
                  badge: 'LIVE',
                  badgeColor: AppTheme.statusClean,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_rounded,
                  title: 'Guest Folio & Billing',
                  badge: null,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Restaurant & POS',
                  badge: 'KOT',
                  badgeColor: AppTheme.imperialGold,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.cleaning_services_rounded,
                  title: 'Housekeeping Matrix',
                  badge: null,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.calendar_month_rounded,
                  title: 'CRS Reservations',
                  badge: null,
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons.analytics_rounded,
                  title: 'Executive Analytics',
                  badge: 'GM',
                  badgeColor: AppTheme.champagneAccent,
                ),
                const SizedBox(height: 8),
                const Divider(color: AppTheme.slateBorder, height: 1),
                const SizedBox(height: 8),
                _buildNavItem(
                  index: 6,
                  icon: Icons.tune_rounded,
                  title: 'Master Configuration',
                  badge: 'ADMIN',
                  badgeColor: const Color(0xFFFF6B6B),
                ),
              ],
            ),
          ),

          // 3. Database & System Footer
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.slateCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slateBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage_rounded, size: 16, color: AppTheme.statusClean),
                    SizedBox(width: 8),
                    Text(
                      'Cloud Server Connected',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Enterprise Multi-Branch Data Sync Active',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String title,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onDestinationSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.slateCardElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppTheme.imperialGold.withValues(alpha: 0.6), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.imperialGold : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppTheme.imperialGold).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor ?? AppTheme.imperialGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
