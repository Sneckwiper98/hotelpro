import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/hotel_repository.dart';
import '../../data/models/customer_model.dart';
import '../../config/app_constants.dart';
import 'components/mobile_app_scaffold.dart';

class MobileRoleGateway extends StatelessWidget {
  final Function(MobileAppRole role) onSelectRole;
  final VoidCallback? onSwitchToDesktopErp;

  const MobileRoleGateway({
    super.key,
    required this.onSelectRole,
    this.onSwitchToDesktopErp,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final hotelName = repo.clientBusinessName;
    final tagline = repo.clientTagline;
    final activeBranch = repo.activeBranch;

    // Calculate live badges
    final runningTablesCount = repo.posOrders
        .where((o) => o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled)
        .length;
    final pendingRoomsCleanCount = repo.activeBranchRooms
        .where((r) => r.status == RoomStatus.dirtyVacant || r.status == RoomStatus.cleaningInProgress)
        .length;
    final pendingDeliveryCount = repo.customerOrders
        .where((o) => o.orderStatus == CustomerOrderStatus.placed || o.orderStatus == CustomerOrderStatus.kitchenPreparing)
        .length;
    final occupiedRoomsCount = repo.activeBranchRooms.where((r) => r.isOccupied).length;
    final totalRoomsCount = repo.activeBranchRooms.length;
    final occupancyPct = totalRoomsCount > 0 ? ((occupiedRoomsCount / totalRoomsCount) * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Hotel Hero ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1B4F72),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B2545), Color(0xFF134074), Color(0xFF1B4F72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text('🏨', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotelName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                tagline,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: Color(0xFF5DADE2)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${activeBranch.name} • ${activeBranch.city}',
                                    style: const TextStyle(color: Color(0xFF5DADE2), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (onSwitchToDesktopErp != null)
                TextButton.icon(
                  onPressed: onSwitchToDesktopErp,
                  icon: const Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 16),
                  label: const Text(
                    'ERP Desktop',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 6),
            ],
          ),

          // ── Quick Live Stats Bar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStatItem(
                    icon: Icons.hotel_rounded,
                    color: const Color(0xFF1B4F72),
                    label: 'Occupancy',
                    value: '$occupancyPct%',
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade200),
                  _miniStatItem(
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFF1E8449),
                    label: 'Live Tables',
                    value: '$runningTablesCount',
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade200),
                  _miniStatItem(
                    icon: Icons.cleaning_services_rounded,
                    color: const Color(0xFF6C3483),
                    label: 'Dirty Rooms',
                    value: '$pendingRoomsCleanCount',
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade200),
                  _miniStatItem(
                    icon: Icons.delivery_dining_rounded,
                    color: const Color(0xFFD35400),
                    label: 'Deliveries',
                    value: '$pendingDeliveryCount',
                  ),
                ],
              ),
            ),
          ),

          // ── App Role Selector Title ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SELECT ROLE / APPLICATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 5 Application Cards ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Customer Food & Dining App
                _buildAppCard(
                  title: 'Customer Food & Dining',
                  subtitle: 'Guest In-Room & Online Ordering',
                  description: 'Browse restaurant menu, add items to cart, customized orders & live order tracking.',
                  role: MobileAppRole.customer,
                  badge: 'GUEST READY',
                  badgeColor: const Color(0xFFE23744),
                  primaryColor: const Color(0xFFE23744),
                  gradient: const [Color(0xFFE23744), Color(0xFFC0392B)],
                  icon: Icons.restaurant_menu_rounded,
                  onTap: () => onSelectRole(MobileAppRole.customer),
                ),

                // 2. Waiter POS & Captain App
                _buildAppCard(
                  title: 'Staff Waiter & Captain POS',
                  subtitle: 'Table-Side Digital Ordering & KOT',
                  description: 'Interactive table matrix, instant kitchen KOT punch, running table orders & bill request.',
                  role: MobileAppRole.waiter,
                  badge: runningTablesCount > 0 ? '$runningTablesCount TABLES ACTIVE' : 'TABLE ORDERING',
                  badgeColor: const Color(0xFF1E8449),
                  primaryColor: const Color(0xFF1E8449),
                  gradient: const [Color(0xFF1E8449), Color(0xFF145A32)],
                  icon: Icons.table_restaurant_rounded,
                  onTap: () => onSelectRole(MobileAppRole.waiter),
                ),

                // 3. Housekeeping & Room Inspection App
                _buildAppCard(
                  title: 'Housekeeping & Inspection',
                  subtitle: 'Room Cleanliness & Readiness Checklist',
                  description: 'Live room status matrix, sanitation checklist, quick cleaning updates & maintenance repair logging.',
                  role: MobileAppRole.housekeeping,
                  badge: pendingRoomsCleanCount > 0 ? '$pendingRoomsCleanCount DIRTY ROOMS' : 'INSPECTION',
                  badgeColor: const Color(0xFF6C3483),
                  primaryColor: const Color(0xFF6C3483),
                  gradient: const [Color(0xFF6C3483), Color(0xFF4A235A)],
                  icon: Icons.cleaning_services_rounded,
                  onTap: () => onSelectRole(MobileAppRole.housekeeping),
                ),

                // 4. Manager & Owner Live MIS App
                _buildAppCard(
                  title: 'Manager & Owner Live MIS',
                  subtitle: 'Executive Revenue, Occupancy & Operations',
                  description: 'Real-time daily revenue, RevPAR, ADR, occupied rooms breakdown, payment collection & audit flags.',
                  role: MobileAppRole.manager,
                  badge: 'EXECUTIVE PULSE',
                  badgeColor: const Color(0xFF922B21),
                  primaryColor: const Color(0xFF922B21),
                  gradient: const [Color(0xFF922B21), Color(0xFF641E16)],
                  icon: Icons.insights_rounded,
                  onTap: () => onSelectRole(MobileAppRole.manager),
                ),

                // 5. Delivery Boy & Rider Partner App
                _buildAppCard(
                  title: 'Delivery Boy Partner App',
                  subtitle: 'Rider Order Pickup & Fulfillment',
                  description: 'Duty toggle ON/OFF, assigned food orders, customer address & tap-to-call, live delivery OTP & daily earnings.',
                  role: MobileAppRole.deliveryBoy,
                  badge: pendingDeliveryCount > 0 ? '$pendingDeliveryCount PENDING ORDERS' : 'RIDER DISPATCH',
                  badgeColor: const Color(0xFFD35400),
                  primaryColor: const Color(0xFFD35400),
                  gradient: const [Color(0xFFD35400), Color(0xFFA04000)],
                  icon: Icons.two_wheeler_rounded,
                  onTap: () => onSelectRole(MobileAppRole.deliveryBoy),
                ),

                const SizedBox(height: 18),

                // ── Footer Note ───────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'iSecure Systems • HotelPro Mobile Enterprise',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cross-Platform Android & iOS Production Release',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAppCard({
    required String title,
    required String subtitle,
    required String description,
    required MobileAppRole role,
    required String badge,
    required Color badgeColor,
    required Color primaryColor,
    required List<Color> gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    role.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 14),

                // Card Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFFBDC3C7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
