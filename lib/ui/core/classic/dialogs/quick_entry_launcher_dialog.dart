import 'package:flutter/material.dart';
import '../../../../config/classic_erp_theme.dart';

class QuickActionItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int moduleIndex;
  final String actionCode;

  QuickActionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.moduleIndex,
    required this.actionCode,
  });
}

/// Quick Creation Launcher Modal (Ribbon 'New' Action on Desktop)
class QuickEntryLauncherDialog extends StatelessWidget {
  final Function(int moduleIndex, String actionCode) onActionSelected;

  const QuickEntryLauncherDialog({super.key, required this.onActionSelected});

  static void show(BuildContext context, Function(int moduleIndex, String actionCode) onAction) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => QuickEntryLauncherDialog(onActionSelected: onAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<QuickActionItem> actions = [
      QuickActionItem(
        title: 'New Guest Reservation (CRS)',
        description: 'Create advance guest booking with dates & room type.',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF1B4F72),
        moduleIndex: 4,
        actionCode: 'NEW_RESERVATION',
      ),
      QuickActionItem(
        title: 'Front Desk Quick Check-In',
        description: 'Check-in walk-in or booked guest & assign room RFID.',
        icon: Icons.room_service_rounded,
        color: const Color(0xFF117A65),
        moduleIndex: 0,
        actionCode: 'QUICK_CHECKIN',
      ),
      QuickActionItem(
        title: 'New Restaurant Table KOT Order',
        description: 'Open a dining table and punch kitchen food items.',
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFFD35400),
        moduleIndex: 2,
        actionCode: 'NEW_KOT',
      ),
      QuickActionItem(
        title: 'Create GST Tax Invoice',
        description: 'Generate on-the-spot SAC tax bill with B2B GSTIN.',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF27AE60),
        moduleIndex: 1,
        actionCode: 'CREATE_INVOICE',
      ),
      QuickActionItem(
        title: 'New Material Purchase & Supplier GRN',
        description: 'Enter vendor material bill with input tax credits.',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF2980B9),
        moduleIndex: 7,
        actionCode: 'NEW_PURCHASE',
      ),
      QuickActionItem(
        title: 'Add New Inventory Stock Item',
        description: 'Register raw material, linen, or amenities in stores.',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF8E44AD),
        moduleIndex: 8,
        actionCode: 'NEW_STOCK_ITEM',
      ),
      QuickActionItem(
        title: 'New Operating Expense Voucher',
        description: 'Record utility, maintenance, or petty cash outlay.',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFC0392B),
        moduleIndex: 7,
        actionCode: 'NEW_EXPENSE',
      ),
      QuickActionItem(
        title: 'Add New Food Dish to Menu',
        description: 'Create F&B item with photo, price, and GST slab.',
        icon: Icons.fastfood_rounded,
        color: const Color(0xFFB7950B),
        moduleIndex: 6,
        actionCode: 'NEW_MENU_ITEM',
      ),
    ];

    return Dialog(
      backgroundColor: ClassicErpTheme.panelBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 680,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Bar
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
                  const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Create New Entry — Quick Action Launcher',
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

            // Grid of quick actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3.2,
                ),
                itemCount: actions.length,
                itemBuilder: (ctx, idx) {
                  final act = actions[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onActionSelected(act.moduleIndex, act.actionCode);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: ClassicErpTheme.borderLight, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: act.color.withValues(alpha: 0.12),
                              border: Border.all(color: act.color.withValues(alpha: 0.3), width: 0.8),
                            ),
                            child: Icon(act.icon, size: 18, color: act.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  act.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: ClassicErpTheme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  act.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: ClassicErpTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFE5E7E9),
              child: const Row(
                children: [
                  Text('Select any item to launch the direct entry form.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  Spacer(),
                  Text('ESC to close', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
