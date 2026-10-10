import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../dialogs/customer_invoice_dialog.dart';

class CustomerOrderTrackingView extends StatefulWidget {
  final CustomerFoodOrderModel initialOrder;

  const CustomerOrderTrackingView({
    super.key,
    required this.initialOrder,
  });

  @override
  State<CustomerOrderTrackingView> createState() => _CustomerOrderTrackingViewState();
}

class _CustomerOrderTrackingViewState extends State<CustomerOrderTrackingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final order = repo.customerOrders.firstWhere(
      (o) => o.id == widget.initialOrder.id,
      orElse: () => widget.initialOrder,
    );

    final status = order.orderStatus;
    final riderName = order.riderName ?? 'Ramesh Patel';
    final riderPhone = order.riderPhone ?? '+91 98201 54321';
    final riderVehicle = order.riderVehicleNo ?? 'MH 02 CZ 4421';
    final riderRating = order.riderRating ?? 4.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking Order #${order.id}',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '${order.branchName} • Live Updates',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => CustomerInvoiceDialog.show(context, order, repo.activeBranch),
            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1B4F72), size: 18),
            label: const Text('Invoice', style: TextStyle(color: Color(0xFF1B4F72), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. ETA & Status Header Card ────────────────────────────────
            _buildEtaCard(order, status),
            const SizedBox(height: 16),

            // ── 2. Live Delivery Route Radar & Moving Rider Map ────────────
            _buildLiveRouteMapCard(order, status),
            const SizedBox(height: 16),

            // ── 3. Delivery Partner Profile & Contact Card ─────────────────
            _buildRiderContactCard(context, riderName, riderPhone, riderVehicle, riderRating, status),
            const SizedBox(height: 16),

            // ── 4. Live Order Step Progression ────────────────────────────
            _buildOrderStepsCard(status),
            const SizedBox(height: 16),

            // ── 5. Destination Delivery Address Card ──────────────────────
            _buildDestinationCard(order),
            const SizedBox(height: 16),

            // ── 6. Order Summary & Item List ──────────────────────────────
            _buildOrderSummaryCard(order),
            const SizedBox(height: 20),

            // Simulation Helper Bar for Testing
            _buildSimulationActionsBar(context, repo, order),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── 1. ETA Header Card ───────────────────────────────────────────────────
  Widget _buildEtaCard(CustomerFoodOrderModel order, CustomerOrderStatus status) {
    int minutesRemaining = order.estimatedDeliveryMinutes;
    String statusTitle;
    String statusSub;

    switch (status) {
      case CustomerOrderStatus.placed:
        statusTitle = 'Order Received & Confirmed';
        statusSub = 'Restaurant accepted your order. Kitchen prep starting...';
        break;
      case CustomerOrderStatus.kitchenPreparing:
        statusTitle = 'Chef Cooking Your Meal';
        statusSub = 'Freshly prepared with premium 5-star hotel ingredients';
        break;
      case CustomerOrderStatus.outForDelivery:
        statusTitle = 'Rider On The Way to You!';
        statusSub = 'Delivery partner has picked up your food package';
        break;
      case CustomerOrderStatus.delivered:
        statusTitle = 'Order Delivered! Enjoy Your Food';
        statusSub = 'Delivered safely at your doorstep';
        minutesRemaining = 0;
        break;
      case CustomerOrderStatus.cancelled:
        statusTitle = 'Order Cancelled';
        statusSub = 'Payment refund initiated to original source';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: status == CustomerOrderStatus.delivered
              ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
              : [const Color(0xFFE23744), const Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (status == CustomerOrderStatus.delivered ? Colors.green : const Color(0xFFE23744)).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTIMATED ARRIVAL',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == CustomerOrderStatus.delivered ? 'DELIVERED' : '$minutesRemaining MINS',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == CustomerOrderStatus.delivered
                      ? Icons.check_circle_rounded
                      : (status == CustomerOrderStatus.outForDelivery
                          ? Icons.delivery_dining_rounded
                          : Icons.access_time_filled_rounded),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(statusSub, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Live Route Map Card with Animated Delivery Motorcycle ──────────────
  Widget _buildLiveRouteMapCard(CustomerFoodOrderModel order, CustomerOrderStatus status) {
    double progress = 0.05;
    if (status == CustomerOrderStatus.placed) progress = 0.08;
    if (status == CustomerOrderStatus.kitchenPreparing) progress = 0.25;
    if (status == CustomerOrderStatus.outForDelivery) progress = 0.68;
    if (status == CustomerOrderStatus.delivered) progress = 1.0;

    final distanceKm = order.deliveryAddress.distanceKmFromHotel;
    final remainingKm = (distanceKm * (1.0 - progress)).clamp(0.0, distanceKm);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar_rounded, color: Color(0xFFE23744), size: 18),
                    SizedBox(width: 8),
                    Text('Live Rider GPS Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == CustomerOrderStatus.outForDelivery ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: status == CustomerOrderStatus.outForDelivery ? Colors.green.shade300 : Colors.blue.shade300,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: status == CustomerOrderStatus.outForDelivery ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status == CustomerOrderStatus.outForDelivery ? 'LIVE ON ROAD' : 'KITCHEN DISPATCH',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: status == CustomerOrderStatus.outForDelivery ? Colors.green.shade800 : Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Animated Map Canvas
          Container(
            height: 190,
            color: const Color(0xFFF1F5F9), // Slate map background
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: DeliveryRouteMapPainter(
                    progress: progress,
                    pulseValue: _animController.value,
                    isOutForDelivery: status == CustomerOrderStatus.outForDelivery,
                    isDelivered: status == CustomerOrderStatus.delivered,
                  ),
                  child: Stack(
                    children: [
                      // Top pill: Live distance remaining
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFFE23744)),
                              const SizedBox(width: 4),
                              Text(
                                status == CustomerOrderStatus.delivered
                                    ? 'Delivered at Doorstep'
                                    : '${remainingKm.toStringAsFixed(1)} km away • ${order.branchName}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Route Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF1B4F72), shape: BoxShape.circle),
                      child: const Icon(Icons.restaurant, color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 6),
                    const Text('Hotel Kitchen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
                Container(
                  height: 1,
                  width: 30,
                  color: Colors.grey.shade400,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFE23744), shape: BoxShape.circle),
                      child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status == CustomerOrderStatus.delivered ? 'Reached' : 'Live Delivery Bike',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE23744)),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  width: 30,
                  color: Colors.grey.shade400,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(order.deliveryAddress.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Delivery Rider Profile & Contact Card ─────────────────────────────
  Widget _buildRiderContactCard(
    BuildContext context,
    String name,
    String phone,
    String vehicle,
    double rating,
    CustomerOrderStatus status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE23744).withValues(alpha: 0.1),
                    child: const Icon(Icons.sports_motorsports_rounded, color: Color(0xFFE23744), size: 30),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vehicle: $vehicle',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Contact: $phone',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B4F72), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Actions: Direct Call & Message
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Call button
                  IconButton(
                    onPressed: () => _simulatePhoneCall(context, name, phone),
                    tooltip: 'Call Delivery Partner',
                    icon: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                    ),
                  ),
                  // Chat / SMS button
                  IconButton(
                    onPressed: () => _simulateChatModal(context, name),
                    tooltip: 'Send Delivery Instructions',
                    icon: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE23744).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE23744).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFE23744), size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vaccinated & Temperature checked • Contactless Doorstep Delivery',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _simulatePhoneCall(BuildContext context, String name, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 36),
            ),
            const SizedBox(height: 12),
            Text('Calling $name...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(phone, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.call_end_rounded, color: Colors.red),
                  label: const Text('End Call', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connected to rider $name. He is approaching your address!'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.speaker_phone_rounded),
                  label: const Text('Simulate Answer'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _simulateChatModal(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_rounded, color: Color(0xFFE23744)),
                const SizedBox(width: 8),
                Text('Quick Message to $name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            ...[
              '🔔 Please ring the doorbell upon arrival.',
              '🚪 Please leave food package with security guard.',
              '📦 Call me when you reach the building gate.',
              '🌶️ Please don\'t forget extra napkins & spoons.',
            ].map((msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sent to $name: "$msg"'), backgroundColor: const Color(0xFF1B4F72)),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(msg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── 4. Live Order Steps Card ─────────────────────────────────────────────
  Widget _buildOrderStepsCard(CustomerOrderStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 16),
          _buildStep(
            title: 'Order Confirmed & Placed',
            subtitle: 'Accepted by hotel kitchen',
            icon: Icons.check_circle_rounded,
            isCompleted: true,
            isActive: status == CustomerOrderStatus.placed,
          ),
          _buildStep(
            title: 'Chef Preparing in Kitchen (KOT)',
            subtitle: 'Cooking fresh with gourmet spices',
            icon: Icons.soup_kitchen_rounded,
            isCompleted: status.index >= CustomerOrderStatus.kitchenPreparing.index,
            isActive: status == CustomerOrderStatus.kitchenPreparing,
          ),
          _buildStep(
            title: 'Rider Picked Up (On The Road)',
            subtitle: 'Rider on bike heading towards your location',
            icon: Icons.delivery_dining_rounded,
            isCompleted: status.index >= CustomerOrderStatus.outForDelivery.index,
            isActive: status == CustomerOrderStatus.outForDelivery,
          ),
          _buildStep(
            title: 'Delivered at Doorstep',
            subtitle: 'Enjoy your delicious 5-star meal!',
            icon: Icons.home_rounded,
            isCompleted: status == CustomerOrderStatus.delivered,
            isActive: status == CustomerOrderStatus.delivered,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    final activeColor = isActive ? const Color(0xFFE23744) : (isCompleted ? Colors.green : Colors.grey.shade400);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : (isActive ? const Color(0xFFE23744) : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(color: const Color(0xFFE23744).withValues(alpha: 0.4), blurRadius: 6)]
                      : null,
                ),
                child: Icon(icon, size: 14, color: (isCompleted || isActive) ? Colors.white : Colors.grey),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Destination Card ──────────────────────────────────────────────────
  Widget _buildDestinationCard(CustomerFoodOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE23744).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: Color(0xFFE23744), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivering to: ${order.deliveryAddress.label}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(order.deliveryAddress.fullAddress, style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(
                  'Distance: ${order.deliveryAddress.distanceKmFromHotel} km from ${order.branchName}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Order Summary Card ────────────────────────────────────────────────
  Widget _buildOrderSummaryCard(CustomerFoodOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Items & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: it.isVeg ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${it.quantity}x ${it.name}', style: const TextStyle(fontSize: 12))),
                    Text('₹${it.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid (Incl. GST)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('₹${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B4F72))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Paid via Online (${order.transactionId})',
            style: TextStyle(fontSize: 10.5, color: Colors.green.shade800, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Quick simulation trigger for testing live progression ────────────────
  Widget _buildSimulationActionsBar(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: Colors.amber.shade900),
              const SizedBox(width: 6),
              const Text('Simulate Delivery Flow (Or update from Windows ERP):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.kitchenPreparing),
                child: const Text('Kitchen Prep', style: TextStyle(fontSize: 10.5)),
              ),
              OutlinedButton(
                onPressed: () => repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.outForDelivery),
                child: const Text('Out for Delivery', style: TextStyle(fontSize: 10.5)),
              ),
              ElevatedButton(
                onPressed: () => repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.delivered),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Mark Delivered', style: TextStyle(fontSize: 10.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom Route Radar Map Painter ──────────────────────────────────────────
class DeliveryRouteMapPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double pulseValue;
  final bool isOutForDelivery;
  final bool isDelivered;

  DeliveryRouteMapPainter({
    required this.progress,
    required this.pulseValue,
    required this.isOutForDelivery,
    required this.isDelivered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startPt = Offset(size.width * 0.15, size.height * 0.72); // Restaurant
    final endPt = Offset(size.width * 0.85, size.height * 0.28); // Customer Home

    // Control point for a natural curved road path
    final controlPt = Offset(size.width * 0.52, size.height * 0.88);

    // 1. Draw decorative background grid & streets
    final roadBgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Cross streets
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.5), roadBgPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), roadBgPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadBgPaint);

    // 2. Base Route Path
    final routePath = Path()
      ..moveTo(startPt.dx, startPt.dy)
      ..quadraticBezierTo(controlPt.dx, controlPt.dy, endPt.dx, endPt.dy);

    final routeBasePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(routePath, routeBasePaint);

    // 3. Completed Route Path (Zomato Red / Green)
    final completedPaint = Paint()
      ..color = isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFE23744)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Sample points along quadratic bezier
    final bikePt = _getQuadraticBezierPoint(startPt, controlPt, endPt, progress.clamp(0.0, 1.0));

    final subPath = Path()..moveTo(startPt.dx, startPt.dy);
    const steps = 30;
    final maxStep = (steps * progress).toInt();
    for (int i = 1; i <= maxStep; i++) {
      final t = i / steps;
      final pt = _getQuadraticBezierPoint(startPt, controlPt, endPt, t);
      subPath.lineTo(pt.dx, pt.dy);
    }
    subPath.lineTo(bikePt.dx, bikePt.dy);
    canvas.drawPath(subPath, completedPaint);

    // 4. Restaurant Marker (Hotel)
    final restPaint = Paint()..color = const Color(0xFF1B4F72);
    canvas.drawCircle(startPt, 11, restPaint);
    canvas.drawCircle(startPt, 8, Paint()..color = Colors.white);
    canvas.drawCircle(startPt, 4, restPaint);

    // 5. Customer Destination Marker with Pulsing Waves
    final destColor = isDelivered ? Colors.green : const Color(0xFFE23744);
    final pulseRadius = 14 + (pulseValue * 16);
    final pulsePaint = Paint()
      ..color = destColor.withValues(alpha: (1.0 - pulseValue) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(endPt, pulseRadius, pulsePaint);

    canvas.drawCircle(endPt, 11, Paint()..color = destColor);
    canvas.drawCircle(endPt, 8, Paint()..color = Colors.white);
    canvas.drawCircle(endPt, 4, Paint()..color = destColor);

    // 6. Moving Delivery Rider (Bike Marker)
    if (isOutForDelivery && !isDelivered) {
      // Pulse beacon behind bike
      final bikePulse = 10 + (pulseValue * 12);
      canvas.drawCircle(
        bikePt,
        bikePulse,
        Paint()
          ..color = const Color(0xFFE23744).withValues(alpha: (1.0 - pulseValue) * 0.6)
          ..style = PaintingStyle.fill,
      );
    }

    // Bike Outer Badge
    canvas.drawCircle(
      bikePt,
      14,
      Paint()
        ..color = isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFE23744)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      bikePt,
      12,
      Paint()..color = Colors.white,
    );

    // Scooter / Motorcycle Icon representation
    final iconColor = isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFE23744);
    canvas.drawCircle(bikePt.translate(-3, 2), 3, Paint()..color = iconColor); // rear wheel
    canvas.drawCircle(bikePt.translate(3, 2), 3, Paint()..color = iconColor); // front wheel
    canvas.drawLine(
      bikePt.translate(-3, 2),
      bikePt.translate(2, -3),
      Paint()
        ..color = iconColor
        ..strokeWidth = 2,
    );
  }

  Offset _getQuadraticBezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final x = (u * u * p0.dx) + (2 * u * t * p1.dx) + (t * t * p2.dx);
    final y = (u * u * p0.dy) + (2 * u * t * p1.dy) + (t * t * p2.dy);
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant DeliveryRouteMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isOutForDelivery != isOutForDelivery ||
        oldDelegate.isDelivered != isDelivered;
  }
}
