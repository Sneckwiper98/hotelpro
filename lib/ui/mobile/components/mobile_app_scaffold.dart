import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../../core/components/hotel_logo_widget.dart';

enum MobileAppRole {
  gateway('gateway', 'App Gateway', '🏠', 'All Hotel Apps Hub', Color(0xFF1B4F72)),
  customer('customer', 'Customer Food & Dining', '🍕', 'Guest In-Room & Online Ordering', Color(0xFFE23744)),
  waiter('waiter', 'Waiter POS & Captain', '🍽️', 'Table-side digital ordering & KOT', Color(0xFF1E8449)),
  housekeeping('housekeeping', 'Housekeeping & Inspection', '🧹', 'Room status & cleaning checklist', Color(0xFF6C3483)),
  manager('manager', 'Manager & Owner MIS', '📊', 'Live Executive Revenue & Occupancy', Color(0xFF922B21)),
  deliveryBoy('delivery_boy', 'Delivery Boy Partner', '🏍️', 'Rider order dispatch & fulfillment', Color(0xFFD35400));

  final String id;
  final String title;
  final String emoji;
  final String subtitle;
  final Color themeColor;

  const MobileAppRole(this.id, this.title, this.emoji, this.subtitle, this.themeColor);
}

class MobileAppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final MobileAppRole currentRole;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Function(MobileAppRole role)? onSwitchRole;
  final Color? primaryColor;
  final bool showRoleSwitcher;
  final String? operatorName;
  final String? operatorRole;
  final String? operatorEmoji;
  final VoidCallback? onLogout;

  const MobileAppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentRole,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions,
    this.onBack,
    this.onSwitchRole,
    this.primaryColor,
    this.showRoleSwitcher = false,
    this.operatorName,
    this.operatorRole,
    this.operatorEmoji,
    this.onLogout,
  });

  void _showRoleSwitcherModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoleSwitcherSheet(
        currentRole: currentRole,
        onRoleSelected: (role) {
          Navigator.pop(ctx);
          if (onSwitchRole != null) {
            onSwitchRole!(role);
          }
        },
      ),
    );
  }

  void _showOperatorProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: currentRole.themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(operatorEmoji ?? currentRole.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operatorName ?? 'Operator',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        operatorRole ?? currentRole.title,
                        style: TextStyle(fontSize: 12, color: currentRole.themeColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('ON DUTY', style: TextStyle(color: Color(0xFF27AE60), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (onLogout != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onLogout!();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('End Shift & Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSyncConfigDialog(BuildContext context) {
    final sync = HotelSyncBridgeService.instance;
    final ctrl = TextEditingController(text: sync.configuredServerHost);
    String testStatus = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.sync_rounded, color: Color(0xFF1B4F72)),
              SizedBox(width: 8),
              Text('Windows ERP Live Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA3E4D7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: Color(0xFF1E8449), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HotelPro Project Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E8449))),
                          Text(
                            sync.isCloudConnected ? '🟢 Auto-Connected (Live Real-Time Cloud Sync)' : '🔴 Offline',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF145A32)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Local Wi-Fi Server (Windows Desktop PC):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Windows Server IP',
                  hintText: 'e.g. 192.168.0.100',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.computer_rounded, size: 18),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      setDialogState(() => testStatus = 'Testing connection...');
                      final ok = await sync.testConnectionToHost(ctrl.text.trim());
                      setDialogState(() {
                        testStatus = ok ? '🟢 Connected to Windows ERP!' : '🔴 Could not connect to host';
                      });
                    },
                    icon: const Icon(Icons.network_check_rounded, size: 14),
                    label: const Text('Test Ping', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  if (testStatus.isNotEmpty)
                    Expanded(
                      child: Text(
                        testStatus,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: testStatus.contains('Connected') ? const Color(0xFF27AE60) : const Color(0xFFC0392B),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${sync.syncEngineMode}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E8449))),
                    const SizedBox(height: 2),
                    const Text('Orders and actions punched in this mobile app are synced in real-time.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontSize: 11)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                sync.setConfiguredHost(ctrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Windows ERP Host set to ${ctrl.text.trim()}'),
                    backgroundColor: const Color(0xFF27AE60),
                  ),
                );
              },
              child: const Text('Save & Sync', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = primaryColor ?? currentRole.themeColor;
    final repo = context.watch<HotelRepository>();
    final hotelName = repo.clientBusinessName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: themeColor,
          elevation: 2,
          foregroundColor: Colors.white,
          leading: onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBack,
                )
              : (showRoleSwitcher
                  ? IconButton(
                      icon: const Icon(Icons.grid_view_rounded),
                      tooltip: 'Switch App / Role',
                      onPressed: () => _showRoleSwitcherModal(context),
                    )
                  : null),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const ClipOval(
                      child: HotelLogoWidget(width: 20, height: 20, fit: BoxFit.cover),
                    ),
                  ),
                  Text(
                    currentRole.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                subtitle ?? hotelName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            // Real-Time LAN & Cloud Sync Indicator
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => _showSyncConfigDialog(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'SYNC',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (operatorName != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () => _showOperatorProfileSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(operatorEmoji ?? '👤', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 85),
                          child: Text(
                            operatorName!,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onLogout != null) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.logout_rounded, size: 12, color: Colors.white70),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ...?actions,
            if (showRoleSwitcher)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Apps',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                tooltip: 'Switch App Role',
                onPressed: () => _showRoleSwitcherModal(context),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          bottom: bottomNavigationBar == null,
          child: body,
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class _RoleSwitcherSheet extends StatelessWidget {
  final MobileAppRole currentRole;
  final Function(MobileAppRole role) onRoleSelected;

  const _RoleSwitcherSheet({
    required this.currentRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apps_rounded, color: Color(0xFF1B4F72), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HotelPro Mobile App Suite',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      repo.clientBusinessName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const Text(
            'SELECT APPLICATION / ROLE:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          ...MobileAppRole.values.map((role) {
            final isSelected = role == currentRole;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected ? role.themeColor.withValues(alpha: 0.08) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onRoleSelected(role),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? role.themeColor : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: role.themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(role.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? role.themeColor : const Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                role.subtitle,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: role.themeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
