import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/classic_erp_theme.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';

/// ============================================================
/// Delivery Boy Management — Windows Classic ERP Style
/// Features:
///  • Rider roster list with photo, phone, vehicle, rating
///  • Availability toggle (On Duty / Off Duty)
///  • Add / Edit / Delete rider dialog
///  • Active order assignment view per rider
///  • Today's earnings & deliveries summary
///  • Attendance log (In / Out time)
/// ============================================================
class DeliveryBoyManagementView extends StatefulWidget {
  const DeliveryBoyManagementView({super.key});

  @override
  State<DeliveryBoyManagementView> createState() => _DeliveryBoyManagementViewState();
}

class _DeliveryBoyManagementViewState extends State<DeliveryBoyManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _riderSearch = '';
  String _filterStatus = 'ALL'; // ALL | ON_DUTY | OFF_DUTY
  DeliveryRiderModel? _selectedRider;

  final NumberFormat _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final riders = _filteredRiders(repo.deliveryRiders);

    // Keep selected in sync
    if (riders.isNotEmpty) {
      if (_selectedRider == null || !riders.any((r) => r.id == _selectedRider!.id)) {
        _selectedRider = riders.first;
      } else {
        _selectedRider = riders.firstWhere((r) => r.id == _selectedRider!.id);
      }
    } else {
      _selectedRider = null;
    }

    return Column(
      children: [
        _buildToolbar(context, repo),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildRosterTab(context, repo, riders),
              _buildActiveOrdersTab(context, repo),
              _buildEarningsTab(context, repo),
            ],
          ),
        ),
      ],
    );
  }

  // ── Toolbar ─────────────────────────────────────────────────────────────
  Widget _buildToolbar(BuildContext context, HotelRepository repo) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: ClassicErpTheme.toolbarBg,
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolBtn('➕ Add Rider', () => _showRiderDialog(context, repo, null)),
            const SizedBox(width: 6),
            _toolBtn('✏️ Edit', () {
              if (_selectedRider != null) _showRiderDialog(context, repo, _selectedRider);
            }),
            const SizedBox(width: 6),
            _toolBtn('🗑️ Delete', () {
              if (_selectedRider != null) _confirmDelete(context, repo, _selectedRider!);
            }),
            const SizedBox(width: 6),
            _toolBtn('🔄 Toggle Duty', () {
              if (_selectedRider != null) repo.toggleRiderAvailability(_selectedRider!.id);
            }),
            const SizedBox(width: 16),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
            const SizedBox(width: 16),
            // Search
            SizedBox(
              width: 200,
              height: 26,
              child: TextField(
                onChanged: (v) => setState(() => _riderSearch = v),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search rider name / phone...',
                  hintStyle: const TextStyle(fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 14),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Filter chips
            _filterChip('All', 'ALL'),
            const SizedBox(width: 4),
            _filterChip('On Duty', 'ON_DUTY'),
            const SizedBox(width: 4),
            _filterChip('Off Duty', 'OFF_DUTY'),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade300, Colors.grey.shade400],
            ),
            border: Border.all(color: Colors.grey.shade600),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _filterChip(String label, String value) => GestureDetector(
        onTap: () => setState(() => _filterStatus = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _filterStatus == value ? const Color(0xFF1A5276) : Colors.white,
            border: Border.all(
              color: _filterStatus == value ? const Color(0xFF1A5276) : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _filterStatus == value ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );

  Widget _buildTabBar() => Container(
        decoration: const BoxDecoration(
          color: ClassicErpTheme.menuBarBg,
          border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          indicatorColor: const Color(0xFF1A5276),
          labelColor: const Color(0xFF1A5276),
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: '🛵  Rider Roster'),
            Tab(text: '📦  Active Orders'),
            Tab(text: '💰  Earnings & Reports'),
          ],
        ),
      );

  // ── Tab 1: Rider Roster ──────────────────────────────────────────────────
  Widget _buildRosterTab(BuildContext context, HotelRepository repo, List<DeliveryRiderModel> riders) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT: Rider List
        Container(
          width: 280,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
            color: const Color(0xFFF8F9FA),
          ),
          child: Column(
            children: [
              // Header count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2461),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${riders.length} Rider${riders.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${riders.where((r) => r.isAvailable).length} On Duty',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: riders.isEmpty
                    ? const Center(
                        child: Text(
                          'No riders found.\nAdd a rider using the toolbar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: riders.length,
                        itemBuilder: (ctx, i) => _riderListTile(context, repo, riders[i]),
                      ),
              ),
            ],
          ),
        ),

        // RIGHT: Rider Detail Panel
        Expanded(
          child: _selectedRider == null
              ? const Center(
                  child: Text(
                    'Select a rider to view details',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : _buildRiderDetailPanel(context, repo, _selectedRider!),
        ),
      ],
    );
  }

  Widget _riderListTile(BuildContext context, HotelRepository repo, DeliveryRiderModel rider) {
    final isSelected = _selectedRider?.id == rider.id;
    final activeOrders = _activeOrdersForRider(repo, rider.name);

    return GestureDetector(
      onTap: () => setState(() => _selectedRider = rider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A5276).withAlpha(15) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF1A5276) : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    rider.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5276),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: rider.isAvailable ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(rider.phone, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  if (activeOrders > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$activeOrders order${activeOrders != 1 ? 's' : ''} active',
                        style: TextStyle(fontSize: 9, color: Colors.orange.shade800),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 11),
                    Text(rider.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: rider.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(
                      color: rider.isAvailable ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rider.isAvailable ? 'ON DUTY' : 'OFF',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: rider.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderDetailPanel(BuildContext context, HotelRepository repo, DeliveryRiderModel rider) {
    final activeOrders = repo.customerOrders
        .where((o) =>
            o.riderName == rider.name &&
            o.orderStatus == CustomerOrderStatus.outForDelivery)
        .toList();
    final completedToday = _todayDeliveries(repo, rider.name);
    final earningsToday = completedToday * 40.0; // ₹40 per delivery

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rider Header Card ──────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2461), Color(0xFF1A5276)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withAlpha(40),
                  child: Text(
                    rider.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rider.name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.phone, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(rider.phone,
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.two_wheeler, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(rider.vehicleNo,
                              style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ]),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(rider.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    Text('${rider.deliveriesCompleted} total',
                        style: const TextStyle(color: Colors.white60, fontSize: 10)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => repo.toggleRiderAvailability(rider.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rider.isAvailable ? Colors.green : Colors.red.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rider.isAvailable ? '● ON DUTY' : '○ OFF DUTY',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Today's Stats ──────────────────────────────
          _sectionHeader('📊 Today\'s Performance'),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard('Deliveries\nCompleted', '$completedToday', Colors.green),
              const SizedBox(width: 8),
              _statCard('Active\nOrders', '${activeOrders.length}', Colors.orange),
              const SizedBox(width: 8),
              _statCard('Today\'s\nEarnings', _cur.format(earningsToday), const Color(0xFF1A5276)),
              const SizedBox(width: 8),
              _statCard('Rating', '${rider.rating.toStringAsFixed(1)} ⭐', Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 14),

          // ── Active Orders ──────────────────────────────
          if (activeOrders.isNotEmpty) ...[
            _sectionHeader('📦 Currently Out for Delivery'),
            const SizedBox(height: 8),
            ...activeOrders.map((order) => _miniOrderCard(order)),
            const SizedBox(height: 14),
          ],

          // ── Attendance ────────────────────────────────
          _sectionHeader('🕐 Attendance — Today'),
          const SizedBox(height: 8),
          _attendanceCard(rider),
          const SizedBox(height: 14),

          // ── Actions ───────────────────────────────────
          _sectionHeader('⚙️ Quick Actions'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _actionBtn('✏️ Edit Profile', () => _showRiderDialog(context, repo, rider)),
              _actionBtn('📲 Assign New Order', () => _showAssignOrderDialog(context, repo, rider)),
              _actionBtn('🗑️ Remove Rider', () => _confirmDelete(context, repo, rider)),
              _actionBtn(
                rider.isAvailable ? '⛔ Mark Off Duty' : '✅ Mark On Duty',
                () => repo.toggleRiderAvailability(rider.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            border: Border.all(color: color.withAlpha(60)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 3),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Colors.black54)),
            ],
          ),
        ),
      );

  Widget _miniOrderCard(CustomerFoodOrderModel order) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Text('🛵', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${order.id} — ${order.customerName}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(order.deliveryAddress.fullAddress,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              '~${order.estimatedDeliveryMinutes} min',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
      );

  Widget _attendanceCard(DeliveryRiderModel rider) {
    // Simulated attendance based on seed from rider id
    final seed = rider.id.hashCode.abs();
    final inHour = 8 + (seed % 3);
    final inMin = (seed * 7) % 60;
    final inTime = '${inHour.toString().padLeft(2, '0')}:${inMin.toString().padLeft(2, '0')} AM';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          _attendanceItem('📍 Check-In', inTime, Colors.green),
          const SizedBox(width: 20),
          _attendanceItem(
            '📍 Check-Out',
            rider.isAvailable ? 'Still on duty' : '6:30 PM',
            rider.isAvailable ? Colors.orange : Colors.red,
          ),
          const Spacer(),
          _attendanceItem('⏱️ Hours', rider.isAvailable ? 'Active' : '10h 30m', Colors.blue),
        ],
      ),
    );
  }

  Widget _attendanceItem(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      );

  Widget _actionBtn(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade400],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.grey.shade600),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _sectionHeader(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FB),
          border: const Border(
            left: BorderSide(color: Color(0xFF1A5276), width: 3),
          ),
        ),
        child: Text(title,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
      );

  // ── Tab 2: Active Orders ─────────────────────────────────────────────────
  Widget _buildActiveOrdersTab(BuildContext context, HotelRepository repo) {
    final outOrders = repo.customerOrders
        .where((o) => o.orderStatus == CustomerOrderStatus.outForDelivery)
        .toList();

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '${outOrders.length} order${outOrders.length != 1 ? 's' : ''} currently out for delivery',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: outOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✅', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('No orders currently out for delivery',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: outOrders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _activeOrderCard(ctx, repo, outOrders[i]),
                ),
        ),
      ],
    );
  }

  Widget _activeOrderCard(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: Colors.orange,
                child: Text(order.id,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.two_wheeler, color: Colors.orange, size: 16),
              const Text(' OUT FOR DELIVERY',
                  style: TextStyle(
                      color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(cur.format(order.grandTotal),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _orderDetailRow('👤 Customer', order.customerName),
                    _orderDetailRow('📞 Phone', order.customerPhone),
                    _orderDetailRow('📍 Address', order.deliveryAddress.fullAddress),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _orderDetailRow('🛵 Rider', order.riderName ?? 'N/A'),
                    _orderDetailRow('📱 Rider Phone', order.riderPhone ?? 'N/A'),
                    _orderDetailRow('🚗 Vehicle', order.riderVehicleNo ?? 'N/A'),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '~${order.estimatedDeliveryMinutes}\nmin',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('ETA', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _smallBtn('✅ Mark Delivered', () {
                repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.delivered);
              }, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _smallBtn(String label, VoidCallback onTap, Color color) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      );

  // ── Tab 3: Earnings & Reports ────────────────────────────────────────────
  Widget _buildEarningsTab(BuildContext context, HotelRepository repo) {
    final riders = repo.deliveryRiders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('💰 Today\'s Rider Earnings Summary'),
          const SizedBox(height: 10),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF0C2461),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Rider Name', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Deliveries', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Earnings', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Rating', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...riders.asMap().entries.map((e) {
            final idx = e.key;
            final r = e.value;
            final deliveries = _todayDeliveries(repo, r.name);
            final active = _activeOrdersForRider(repo, r.name);
            final earnings = deliveries * 40.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: idx.isEven ? Colors.grey.shade50 : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1A5276).withAlpha(30),
                        child: Text(r.name.substring(0, 1),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5276))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(r.vehicleNo.split('[').first.trim(),
                                style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Text(
                      '$deliveries',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$active',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: active > 0 ? Colors.orange : Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _cur.format(earnings),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 11),
                        Text(r.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: r.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                          border: Border.all(
                            color: r.isAvailable ? Colors.green.shade400 : Colors.red.shade400,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.isAvailable ? 'ON DUTY' : 'OFF',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: r.isAvailable ? Colors.green.shade700 : Colors.red.shade700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Totals row
          const Divider(height: 1, thickness: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFFF0F8FF),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  child: Text(
                    '${riders.fold<int>(0, (sum, r) => sum + _todayDeliveries(repo, r.name))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                  ),
                ),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text(
                    _cur.format(riders.fold<double>(0, (sum, r) => sum + _todayDeliveries(repo, r.name) * 40.0)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A5276)),
                  ),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  void _showRiderDialog(BuildContext context, HotelRepository repo, DeliveryRiderModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final vehicleCtrl = TextEditingController(text: existing?.vehicleNo ?? '');
    bool isAvailable = existing?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF0C2461),
            child: Text(
              existing == null ? '➕ Add New Delivery Rider' : '✏️ Edit Rider — ${existing.name}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField('Rider Name *', nameCtrl, 'e.g. Ramesh Patel'),
                  const SizedBox(height: 10),
                  _dialogField('Phone Number *', phoneCtrl, 'e.g. +91 98201 54321'),
                  const SizedBox(height: 10),
                  _dialogField('Vehicle No. & Type', vehicleCtrl, 'e.g. MH 02 CZ 4421 [Honda Activa]'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setS(() => isAvailable = true),
                        child: Row(children: [
                          Radio<bool>(value: true, groupValue: isAvailable, onChanged: (v) => setS(() => isAvailable = v!)),
                          const Text('On Duty', style: TextStyle(fontSize: 12)),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () => setS(() => isAvailable = false),
                        child: Row(children: [
                          Radio<bool>(value: false, groupValue: isAvailable, onChanged: (v) => setS(() => isAvailable = v!)),
                          const Text('Off Duty', style: TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C2461),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                final rng = Random();
                final updated = DeliveryRiderModel(
                  id: existing?.id ?? 'rider-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  vehicleNo: vehicleCtrl.text.trim().isEmpty
                      ? 'Vehicle Not Specified'
                      : vehicleCtrl.text.trim(),
                  rating: existing?.rating ?? (4.5 + rng.nextDouble() * 0.5),
                  deliveriesCompleted: existing?.deliveriesCompleted ?? 0,
                  isAvailable: isAvailable,
                );
                if (existing == null) {
                  repo.addDeliveryRider(updated);
                } else {
                  repo.updateDeliveryRider(updated);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add Rider' : 'Save Changes',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, String hint) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      );

  void _showAssignOrderDialog(BuildContext context, HotelRepository repo, DeliveryRiderModel rider) {
    final assignableOrders = repo.customerOrders
        .where((o) => o.orderStatus == CustomerOrderStatus.kitchenPreparing)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF0C2461),
          child: Text(
            '📲 Assign Order to ${rider.name}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        content: SizedBox(
          width: 380,
          child: assignableOrders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No orders in "Kitchen Preparing" state to assign.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: assignableOrders.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final o = assignableOrders[i];
                    return ListTile(
                      dense: true,
                      title: Text('${o.id} — ${o.customerName}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      subtitle: Text(o.deliveryAddress.fullAddress,
                          style: const TextStyle(fontSize: 10)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: () {
                          repo.assignDeliveryRider(o.id, rider);
                          repo.updateCustomerOrderStatus(o.id, CustomerOrderStatus.outForDelivery);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Assign', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HotelRepository repo, DeliveryRiderModel rider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Confirm Delete', style: TextStyle(fontSize: 14)),
        content: Text('Remove ${rider.name} from the rider roster?\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              repo.removeDeliveryRider(rider.id);
              if (_selectedRider?.id == rider.id) setState(() => _selectedRider = null);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  List<DeliveryRiderModel> _filteredRiders(List<DeliveryRiderModel> all) {
    return all.where((r) {
      if (_filterStatus == 'ON_DUTY' && !r.isAvailable) return false;
      if (_filterStatus == 'OFF_DUTY' && r.isAvailable) return false;
      if (_riderSearch.trim().isNotEmpty) {
        final q = _riderSearch.toLowerCase();
        if (!r.name.toLowerCase().contains(q) && !r.phone.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int _todayDeliveries(HotelRepository repo, String riderName) {
    return repo.customerOrders
        .where((o) => o.riderName == riderName && o.orderStatus == CustomerOrderStatus.delivered)
        .length;
  }

  int _activeOrdersForRider(HotelRepository repo, String riderName) {
    return repo.customerOrders
        .where((o) =>
            o.riderName == riderName && o.orderStatus == CustomerOrderStatus.outForDelivery)
        .length;
  }
}
