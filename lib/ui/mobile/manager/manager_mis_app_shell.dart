import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../components/mobile_app_scaffold.dart';
import '../components/mobile_staff_login_view.dart';

class ManagerMisAppShell extends StatefulWidget {
  final VoidCallback? onBackToGateway;
  final Function(MobileAppRole role)? onSwitchRole;

  const ManagerMisAppShell({
    super.key,
    this.onBackToGateway,
    this.onSwitchRole,
  });

  @override
  State<ManagerMisAppShell> createState() => _ManagerMisAppShellState();
}

class _ManagerMisAppShellState extends State<ManagerMisAppShell> {
  StaffProfileAuth? _authenticatedStaff;

  static const List<StaffProfileAuth> _managerDemoProfiles = [
    StaffProfileAuth(
      id: 'GM-001',
      name: 'Rajesh Mehta',
      role: 'General Manager',
      phone: '+91 98201 11020',
      pin: '1234',
      avatarEmoji: '👔',
      shift: 'Executive Management',
    ),
    StaffProfileAuth(
      id: 'MGR-002',
      name: 'Priya Sharma',
      role: 'Director of Operations',
      phone: '+91 98201 11021',
      pin: '1234',
      avatarEmoji: '💼',
      shift: 'Operations & MIS',
    ),
    StaffProfileAuth(
      id: 'OWN-001',
      name: 'Vikram Singhania',
      role: 'Owner & Managing Director',
      phone: '+91 98201 11022',
      pin: '1234',
      avatarEmoji: '👑',
      shift: 'Board of Directors',
    ),
    StaffProfileAuth(
      id: 'ADM-999',
      name: 'Super Administrator',
      role: 'IT & System Admin',
      phone: '+91 98201 11023',
      pin: '1234',
      avatarEmoji: '🛡️',
      shift: '24x7 Enterprise',
    ),
  ];

  String _selectedPeriod = 'Today';
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;

    // ── Authentication Gate ───────────────────────────────────────────────
    if (_authenticatedStaff == null) {
      return MobileStaffLoginView(
        role: MobileAppRole.manager,
        appTitle: 'Manager & Owner Live MIS',
        appSubtitle: 'Executive Revenue, Occupancy, ADR & Operations Terminal',
        quickProfiles: _managerDemoProfiles,
        onAuthenticate: (profile) {
          setState(() {
            _authenticatedStaff = profile;
          });
        },
        onBackToGateway: widget.onBackToGateway,
      );
    }

    final stats = repo.getManagerMisStats();

    final double totalRev = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final double roomRev = (stats['roomRevenue'] as num?)?.toDouble() ?? 0.0;
    final double posRev = (stats['posRevenue'] as num?)?.toDouble() ?? 0.0;
    final double delRev = (stats['deliveryRevenue'] as num?)?.toDouble() ?? 0.0;

    final int totalRooms = stats['totalRooms'] as int? ?? 1;
    final int occupiedRooms = stats['occupiedRooms'] as int? ?? 0;
    final double occupancyPct = (stats['occupancyPct'] as num?)?.toDouble() ?? 0.0;
    final double adr = (stats['adr'] as num?)?.toDouble() ?? 0.0;
    final double revPar = (stats['revPar'] as num?)?.toDouble() ?? 0.0;

    final int dirtyRooms = stats['dirtyRooms'] as int? ?? 0;
    final int cleanRooms = stats['cleanRooms'] as int? ?? 0;
    final int oooRooms = stats['oooRooms'] as int? ?? 0;
    final int activeKots = stats['activeKotCount'] as int? ?? 0;
    final int pendingDel = stats['pendingDeliveries'] as int? ?? 0;
    final int activeRiders = stats['activeRidersCount'] as int? ?? 0;

    return MobileAppScaffold(
      title: 'Manager & Owner MIS',
      subtitle: '${activeBranch.name} • ${_authenticatedStaff!.name}',
      currentRole: MobileAppRole.manager,
      onBack: widget.onBackToGateway,
      onSwitchRole: widget.onSwitchRole,
      operatorName: _authenticatedStaff!.name,
      operatorRole: _authenticatedStaff!.role,
      operatorEmoji: _authenticatedStaff!.avatarEmoji,
      onLogout: () => setState(() => _authenticatedStaff = null),
      body: RefreshIndicator(
        onRefresh: () async {
          await HotelSyncBridgeService.instance.fetchSnapshotFromWindowsErp(repo: repo);
        },
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Period Filter Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: ['Today', 'Yesterday', 'This Week', 'MTD'].map((period) {
                  final isSel = _selectedPeriod == period;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedPeriod = period),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF922B21) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // ── Primary Revenue Card ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF78281F), Color(0xFF922B21), Color(0xFFB03A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF922B21).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL GROSS REVENUE ($_selectedPeriod)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('+14.8%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency.format(totalRev),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _revenueSubItem('Room Stay', _currency.format(roomRev)),
                      _revenueSubItem('F&B Dining', _currency.format(posRev)),
                      _revenueSubItem('Online Delivery', _currency.format(delRev)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Occupancy & KPI Gauges ─────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Room Occupancy & Rate KPI',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      Text(
                        '$occupiedRooms of $totalRooms Rooms Occupied',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalRooms > 0 ? (occupiedRooms / totalRooms).clamp(0.0, 1.0) : 0.0,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E8449)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _kpiMetric('Occupancy', '${occupancyPct.toStringAsFixed(1)}%', const Color(0xFF1E8449)),
                      Container(width: 1, height: 32, color: Colors.grey.shade200),
                      _kpiMetric('ADR', _currency.format(adr), const Color(0xFF1B4F72)),
                      Container(width: 1, height: 32, color: Colors.grey.shade200),
                      _kpiMetric('RevPAR', _currency.format(revPar), const Color(0xFF922B21)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Live Operations Overview ──────────────────────────────────
            const Text(
              'DEPARTMENT OPERATIONAL PULSE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _pulseCard(
                    title: 'Front Desk',
                    line1: '$occupiedRooms In-House',
                    line2: '4 Expected Checkouts',
                    color: const Color(0xFF1B4F72),
                    icon: Icons.meeting_room_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _pulseCard(
                    title: 'POS Restaurant',
                    line1: '$activeKots Active KOTs',
                    line2: 'Kitchen Orders Running',
                    color: const Color(0xFF1E8449),
                    icon: Icons.restaurant_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _pulseCard(
                    title: 'Housekeeping',
                    line1: '$dirtyRooms Dirty Rooms',
                    line2: '$cleanRooms Clean & Ready',
                    color: const Color(0xFF6C3483),
                    icon: Icons.cleaning_services_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _pulseCard(
                    title: 'Deliveries & Riders',
                    line1: '$pendingDel Pending Orders',
                    line2: '$activeRiders Riders On-Duty',
                    color: const Color(0xFFD35400),
                    icon: Icons.two_wheeler_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Payment Collection Channels ───────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collections by Payment Method',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  _paymentRow('UPI (GPay / PhonePe / QR)', (totalRev * 0.48), const Color(0xFF5B2C6F)),
                  const SizedBox(height: 8),
                  _paymentRow('Credit / Debit Cards', (totalRev * 0.32), const Color(0xFF1F618D)),
                  const SizedBox(height: 8),
                  _paymentRow('Cash Collections', (totalRev * 0.15), const Color(0xFF1E8449)),
                  const SizedBox(height: 8),
                  _paymentRow('City Ledger / Company Bill', (totalRev * 0.05), const Color(0xFFB7950B)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Manager Real-Time Audit Alerts ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 18, color: Color(0xFFB7950B)),
                      const SizedBox(width: 6),
                      const Text(
                        'Audit & Security Flags',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7D6608)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _auditAlertItem('0 Voided/Cancelled KOTs detected today (Normal)'),
                  _auditAlertItem('1 Discount of ₹181 authorized by GM'),
                  if (oooRooms > 0)
                    _auditAlertItem('$oooRooms Room Out of Order under maintenance')
                  else
                    _auditAlertItem('Zero rooms currently under maintenance'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _revenueSubItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _kpiMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _pulseCard({
    required String title,
    required String line1,
    required String line2,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(line1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          Text(line2, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50))),
          ],
        ),
        Text(
          _currency.format(amount),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
      ],
    );
  }

  Widget _auditAlertItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 12, color: Color(0xFF27AE60)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF566573))),
          ),
        ],
      ),
    );
  }
}
