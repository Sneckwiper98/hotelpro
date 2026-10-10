import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../components/mobile_app_scaffold.dart';
import '../components/mobile_staff_login_view.dart';

class DeliveryBoyAppShell extends StatefulWidget {
  final VoidCallback? onBackToGateway;
  final Function(MobileAppRole role)? onSwitchRole;

  const DeliveryBoyAppShell({
    super.key,
    this.onBackToGateway,
    this.onSwitchRole,
  });

  @override
  State<DeliveryBoyAppShell> createState() => _DeliveryBoyAppShellState();
}

class _DeliveryBoyAppShellState extends State<DeliveryBoyAppShell> {
  StaffProfileAuth? _authenticatedStaff;

  static const List<StaffProfileAuth> _riderDemoProfiles = [
    StaffProfileAuth(
      id: 'RIDER-01',
      name: 'Amit Sharma',
      role: 'Senior Delivery Partner',
      phone: '+91 98203 66789',
      pin: '1234',
      avatarEmoji: '🛵',
      shift: 'Full-Time Shift',
      vehicleNo: 'MH 02 BV 9912 (Activa 6G)',
    ),
    StaffProfileAuth(
      id: 'RIDER-02',
      name: 'Vikram Jadhav',
      role: 'Express Delivery Partner',
      phone: '+91 98200 11223',
      pin: '1234',
      avatarEmoji: '🏍️',
      shift: 'Night Rush Shift',
      vehicleNo: 'MH 02 DQ 8821 (Pulsar 150)',
    ),
    StaffProfileAuth(
      id: 'RIDER-03',
      name: 'Raju Patil',
      role: 'Delivery Partner',
      phone: '+91 98204 55678',
      pin: '1234',
      avatarEmoji: '🛴',
      shift: 'Evening Peak Shift',
      vehicleNo: 'MH 02 CK 4410 (Jupiter 125)',
    ),
    StaffProfileAuth(
      id: 'RIDER-04',
      name: 'Suresh Yadav',
      role: 'Weekend Rider Partner',
      phone: '+91 98205 99887',
      pin: '1234',
      avatarEmoji: '🛵',
      shift: 'Weekend Shift',
      vehicleNo: 'MH 03 AZ 1205 (Splendor+)',
    ),
  ];

  int _currentTabIndex = 0;
  bool _isOnDuty = true;
  String get _riderId => _authenticatedStaff?.id ?? 'rider-01';
  String get _riderName => _authenticatedStaff?.name ?? 'Amit Sharma';
  String get _riderPhone => _authenticatedStaff?.phone ?? '+91 98203 66789';
  String get _vehicleNo => _authenticatedStaff?.vehicleNo ?? 'MH 02 BV 9912 (Honda Activa)';
  final double _riderRating = 4.9;
  final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;

    // ── Authentication Gate ───────────────────────────────────────────────
    if (_authenticatedStaff == null) {
      return MobileStaffLoginView(
        role: MobileAppRole.deliveryBoy,
        appTitle: 'Delivery Boy Partner App',
        appSubtitle: 'Express Food Delivery, Live Dispatch & Order Fulfillment',
        quickProfiles: _riderDemoProfiles,
        onAuthenticate: (profile) {
          setState(() {
            _authenticatedStaff = profile;
          });
        },
        onBackToGateway: widget.onBackToGateway,
      );
    }

    final allOrders = repo.customerOrders;

    // Filter assigned or pending orders
    final activeOrders = allOrders.where((o) =>
        o.orderStatus == CustomerOrderStatus.placed ||
        o.orderStatus == CustomerOrderStatus.kitchenPreparing ||
        o.orderStatus == CustomerOrderStatus.outForDelivery).toList();

    final completedOrders = allOrders.where((o) => o.orderStatus == CustomerOrderStatus.delivered).toList();
    final todayEarnings = completedOrders.length * 40.0; // ₹40 per delivery payout

    return MobileAppScaffold(
      title: 'Delivery Boy Partner',
      subtitle: '${activeBranch.name} • $_riderName',
      currentRole: MobileAppRole.deliveryBoy,
      onBack: widget.onBackToGateway,
      onSwitchRole: widget.onSwitchRole,
      operatorName: _authenticatedStaff!.name,
      operatorRole: _authenticatedStaff!.role,
      operatorEmoji: _authenticatedStaff!.avatarEmoji,
      onLogout: () => setState(() => _authenticatedStaff = null),
      body: Column(
        children: [
          // ── Duty Toggle & Rider Pulse Banner ────────────────────────────
          Container(
            color: const Color(0xFFD35400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🏍️', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _riderName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '$_vehicleNo • ⭐ $_riderRating',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                // Duty Switch
                InkWell(
                  onTap: () {
                    setState(() => _isOnDuty = !_isOnDuty);
                    repo.toggleRiderAvailability(_riderId);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOnDuty ? const Color(0xFF1E8449) : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: _isOnDuty ? const Color(0xFF2ECC71) : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Today's Earnings Strip ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _earningMetric('Today\'s Payout', _cur.format(todayEarnings), const Color(0xFF1E8449)),
                Container(width: 1, height: 26, color: Colors.grey.shade200),
                _earningMetric('Completed Trips', '${completedOrders.length}', const Color(0xFF1B4F72)),
                Container(width: 1, height: 26, color: Colors.grey.shade200),
                _earningMetric('Active Orders', '${activeOrders.length}', const Color(0xFFD35400)),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Main Body Tabs ──────────────────────────────────────────────
          Expanded(
            child: !_isOnDuty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause_circle_outline, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'You are currently OFF DUTY',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toggle the switch above to go ON DUTY and receive food orders',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : IndexedStack(
                    index: _currentTabIndex.clamp(0, 2),
                    children: [
                      _buildActiveOrdersTab(context, repo, activeOrders),
                      _buildCompletedOrdersTab(context, completedOrders),
                      _buildRiderProfileTab(context, activeBranch.name),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (idx) => setState(() => _currentTabIndex = idx),
        selectedItemColor: const Color(0xFFD35400),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: activeOrders.isNotEmpty,
              label: Text('${activeOrders.length}'),
              child: const Icon(Icons.delivery_dining_rounded),
            ),
            label: 'Assigned Orders',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: completedOrders.isNotEmpty,
              label: Text('${completedOrders.length}'),
              child: const Icon(Icons.check_circle_outline),
            ),
            label: 'Completed Trips',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_circle_rounded),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }

  Widget _earningMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Tab 1: Active Orders ──────────────────────────────────────────────────
  Widget _buildActiveOrdersTab(BuildContext context, HotelRepository repo, List<CustomerFoodOrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.moped_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No active delivery orders',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 4),
            Text('Waiting for kitchen orders to be ready...', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _buildOrderFulfillmentCard(ctx, repo, orders[i]),
    );
  }

  Widget _buildOrderFulfillmentCard(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    final isOut = order.orderStatus == CustomerOrderStatus.outForDelivery;
    final isPreparing = order.orderStatus == CustomerOrderStatus.kitchenPreparing;
    final isCod = order.paymentMethod == OnlinePaymentMethod.cashOnDelivery;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOut ? const Color(0xFFD35400) : Colors.grey.shade200,
          width: isOut ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID + Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOut ? Colors.orange.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOut ? 'OUT FOR DELIVERY' : (isPreparing ? 'KITCHEN PREPARING' : 'ORDER PLACED'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOut ? const Color(0xFFD35400) : const Color(0xFF1B4F72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Customer Info with Tap-to-Call
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                order.customerName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling customer: ${order.customerPhone}')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 12, color: Color(0xFF1E8449)),
                      const SizedBox(width: 4),
                      Text(
                        order.customerPhone,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Address with Distance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFFC0392B)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deliveryAddress.fullAddress,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF566573), height: 1.3),
                    ),
                    Text(
                      '${order.deliveryAddress.distanceKmFromHotel.toStringAsFixed(1)} km from Hotel • ${order.deliveryAddress.landmark}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1B4F72)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Items Summary & Payment Flag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} Food Items (Total: ₹${order.grandTotal.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCod ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCod ? '💵 COD: COLLECT ₹${order.grandTotal.toStringAsFixed(0)}' : '✅ PREPAID ONLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCod ? const Color(0xFFC0392B) : const Color(0xFF1E8449),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Step Actions
          if (!isOut)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD35400),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  repo.advanceDeliveryOrderStatus(
                    orderId: order.id,
                    newStatus: CustomerOrderStatus.outForDelivery,
                    riderId: _riderId,
                  );
                  HotelSyncBridgeService.instance.sendDeliveryUpdateToWindowsErp(
                    orderId: order.id,
                    status: CustomerOrderStatus.outForDelivery,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${order.id} picked up! Now Out for Delivery.')),
                  );
                },
                icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                label: const Text('PICK UP & START DELIVERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8449),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showDeliveryCompletionDialog(context, repo, order),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('MARK DELIVERED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: const Color(0xFF1B4F72),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.navigation_rounded),
                  tooltip: 'Navigate with Google Maps',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening GPS route to ${order.deliveryAddress.fullAddress}')),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showDeliveryCompletionDialog(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    final otpCtrl = TextEditingController(text: '123456');
    final isCod = order.paymentMethod == OnlinePaymentMethod.cashOnDelivery;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: Color(0xFF1E8449), size: 22),
            SizedBox(width: 8),
            Text('Complete Delivery', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 10),
            if (isCod)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: Color(0xFFC0392B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CASH PAYMENT: Collect ₹${order.grandTotal.toStringAsFixed(0)} cash from customer before handing over package.',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF922B21)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Customer Delivery OTP',
                hintText: 'Ask customer for 6-digit OTP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              repo.advanceDeliveryOrderStatus(
                orderId: order.id,
                newStatus: CustomerOrderStatus.delivered,
                riderId: _riderId,
              );
              HotelSyncBridgeService.instance.sendDeliveryUpdateToWindowsErp(
                orderId: order.id,
                status: CustomerOrderStatus.delivered,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order ${order.id} marked DELIVERED successfully! (+₹40 payout added)')),
              );
            },
            child: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Completed Orders ───────────────────────────────────────────────
  Widget _buildCompletedOrdersTab(BuildContext context, List<CustomerFoodOrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text('No completed deliveries yet today', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final order = orders[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF1E8449), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.id} • ${order.customerName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      'Delivered at ${DateFormat('HH:mm a').format(order.createdAt)} • ${order.deliveryAddress.city}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '+₹40.00',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                  ),
                  Text(
                    'Order: ₹${order.grandTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 3: Rider Profile ──────────────────────────────────────────────────
  Widget _buildRiderProfileTab(BuildContext context, String branchName) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFD35400),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🏍️', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 10),
              Text(
                _riderName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              Text(
                '$_riderPhone • Assigned: $branchName',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _profileDetailTile('Vehicle Registration', _vehicleNo, Icons.two_wheeler_rounded),
        _profileDetailTile('Driver License No.', 'MH-02-2022-0098124', Icons.badge_rounded),
        _profileDetailTile('Delivery Partner Status', 'Verified Active (Lifetime)', Icons.verified_user_rounded),
        _profileDetailTile('Lifetime Deliveries', '840 Orders Completed', Icons.check_circle_outline),
        _profileDetailTile('Rider Payout Account', 'UPI: amit.sharma@okaxis', Icons.account_balance_wallet_rounded),
      ],
    );
  }

  Widget _profileDetailTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD35400), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
