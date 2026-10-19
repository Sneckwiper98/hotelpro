import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/geofence_service.dart';
import 'customer_payment_view.dart';
import 'customer_order_tracking_view.dart';
import 'customer_auth_view.dart';

class CustomerCartCheckoutView extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const CustomerCartCheckoutView({
    super.key,
    required this.onBackToMenu,
  });

  @override
  State<CustomerCartCheckoutView> createState() => _CustomerCartCheckoutViewState();
}

class _CustomerCartCheckoutViewState extends State<CustomerCartCheckoutView> {
  final _couponCtrl = TextEditingController(text: 'HOTELPRO50');
  final _instructionsCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final cart = repo.customerCart;
    final activeBranch = repo.activeBranch;
    final selectedAddress = repo.selectedDeliveryAddress;

    // Check 10km geofence eligibility
    final double distanceKm = selectedAddress?.distanceKmFromHotel ?? 2.8;
    final bool isEligible = distanceKm <= GeofenceService.maxDeliveryRadiusKm;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBackToMenu,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Food Basket',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${activeBranch.name} • ${cart.length} item(s)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => repo.clearCustomerCart(),
              child: const Text('Clear', style: TextStyle(color: Color(0xFFE23744), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mandatory Registration Banner for Guest
                  if (!repo.isCustomerLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3CD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFE65100), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guest Order • Registration Mandatory',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFE65100)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Profile creation is mandatory to place this order.',
                                  style: TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _promptMandatoryProfile(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE23744),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                            child: const Text('Register', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 10km Geofencing Banner (Critical Requirement!)
                  _buildGeofenceAlertBanner(context, repo, distanceKm, isEligible),
                  const SizedBox(height: 14),

                  // Delivery Address Card with Switch/Add Location
                  _buildAddressSelectorCard(context, repo, selectedAddress),
                  const SizedBox(height: 14),

                  // Cart Items Card
                  _buildCartItemsCard(repo, cart),
                  const SizedBox(height: 14),

                  // Cooking Instructions Note
                  _buildCookingInstructionsCard(),
                  const SizedBox(height: 14),

                  // Coupon & Offers Card
                  _buildCouponCard(context, repo),
                  const SizedBox(height: 14),

                  // Detailed Bill Breakdown (Subtotal, GST, Packaging, Delivery Fee, Coupon)
                  _buildBillBreakdownCard(repo, isEligible),
                  const SizedBox(height: 80), // bottom space for checkout button
                ],
              ),
            ),
      bottomSheet: cart.isEmpty
          ? null
          : _buildCheckoutBottomSheet(context, repo, isEligible, distanceKm),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, size: 45, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('Your cart is empty!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          const Text('Good food is always just a few taps away.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onBackToMenu,
            icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
            label: const Text('Browse Hotel Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23744),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceAlertBanner(BuildContext context, HotelRepository repo, double distanceKm, bool isEligible) {
    if (isEligible) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade400, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eligible for Home Delivery! ($distanceKm km away)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.green.shade900),
                  ),
                  Text(
                    'Within hotel\'s 10 km service radius. Fast delivery in ~${GeofenceService.calculateEstimatedMinutes(distanceKm)} mins.',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade400, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Out of Delivery Range ($distanceKm km)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'We strictly deliver within a 10 km radius of our hotel to ensure fresh & hot food quality. Please select a closer address, or choose Takeaway / Dine-in!',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showChangeAddressModal(context, repo),
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'Select Address within 10 km ➔',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFE23744), decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAddressSelectorCard(BuildContext context, HotelRepository repo, CustomerAddressModel? address) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFE23744), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Delivery Address (${address?.label ?? "Home"})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showChangeAddressModal(context, repo),
                behavior: HitTestBehavior.opaque,
                child: const Text(
                  'CHANGE',
                  style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            address?.fullAddress ?? 'Select a delivery address',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          if (address?.landmark.isNotEmpty == true)
            Text(
              'Landmark: ${address!.landmark}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 4),
          Text(
            'Distance: ${address?.distanceKmFromHotel ?? 0.0} km from ${repo.activeBranch.name}',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.indigo.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsCard(HotelRepository repo, List<CustomerCartItem> cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items Added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          ...cart.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('₹${item.price.toStringAsFixed(0)} each', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  // Quantity Incrementer / Decrementer (- 1 +)
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE23744).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: const Icon(Icons.remove, size: 14, color: Color(0xFFE23744)),
                          onPressed: () => repo.updateCartItemQuantity(item.menuItemId, -1),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE23744))),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: const Icon(Icons.add, size: 14, color: Color(0xFFE23744)),
                          onPressed: () => repo.updateCartItemQuantity(item.menuItemId, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 55,
                    child: Text(
                      '₹${item.subtotal.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCookingInstructionsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: Colors.grey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(
                hintText: 'Add cooking instructions (e.g. Less spicy, extra lemon)...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, HotelRepository repo) {
    final applied = repo.appliedCouponCode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              const Text('Coupons & Bank Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (applied != null)
                GestureDetector(
                  onTap: () => repo.removeCoupon(),
                  behavior: HitTestBehavior.opaque,
                  child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (applied != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text('Code "$applied" applied: ${repo.couponDiscountPercentage.toInt()}% Off!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade800)),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _couponCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter Coupon (Try: HOTELPRO50)',
                        hintStyle: TextStyle(fontSize: 11),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final ok = repo.applyCoupon(_couponCtrl.text);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Coupon ${_couponCtrl.text.toUpperCase()} applied!'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid coupon. Try HOTELPRO50, FLAT20, or ROYAL10'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBillBreakdownCard(HotelRepository repo, bool isEligible) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          _billRow('Item Total', '₹${repo.customerCartSubtotal.toStringAsFixed(2)}'),
          _billRow('GST (5% F&B)', '₹${repo.customerCartGst.toStringAsFixed(2)}'),
          _billRow('Restaurant Packaging', '₹${repo.customerCartPackaging.toStringAsFixed(2)}'),
          _billRow(
            'Delivery Partner Fee',
            repo.customerCartDeliveryFee == 0 ? 'FREE' : '₹${repo.customerCartDeliveryFee.toStringAsFixed(2)}',
            color: repo.customerCartDeliveryFee == 0 ? Colors.green.shade800 : null,
          ),
          if (repo.customerCartDiscount > 0)
            _billRow('Coupon Discount', '-₹${repo.customerCartDiscount.toStringAsFixed(2)}', color: Colors.green.shade800),
          const Divider(thickness: 1.2, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B4F72))),
              Text(
                '₹${repo.customerCartGrandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B4F72)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomSheet(BuildContext context, HotelRepository repo, bool isEligible, double distanceKm) {
    final grandTotal = repo.customerCartGrandTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                const Text('TOTAL PAYABLE', style: TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: !isEligible
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address exceeds 10 km radius! Please change address or choose Takeaway.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  : () {
                      if (!repo.isCustomerLoggedIn) {
                        _promptMandatoryProfile(context);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CustomerPaymentView(
                            onPaymentSuccess: (order) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (ctx) => CustomerOrderTrackingView(initialOrder: order),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isEligible ? const Color(0xFFE23744) : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                children: [
                  Text(
                    isEligible ? 'Proceed to Pay' : 'Outside 10km Radius',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeAddressModal(BuildContext context, HotelRepository repo) {
    final demoLocations = GeofenceService.getDemoDeliveryLocations(repo.activeBranch.code);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.location_city_rounded, color: Color(0xFFE23744), size: 20),
                SizedBox(width: 8),
                Text('Select Delivery Location (10 km Radius)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            ...demoLocations.map((loc) {
              final lat = loc['lat'] as double;
              final lng = loc['lng'] as double;
              final dist = GeofenceService.getDistanceForBranch(
                branchCode: repo.activeBranch.code,
                customerLat: lat,
                customerLng: lng,
              );
              final isUnder10Km = dist <= GeofenceService.maxDeliveryRadiusKm;

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                leading: Icon(
                  isUnder10Km ? Icons.check_circle : Icons.cancel,
                  color: isUnder10Km ? Colors.green : Colors.red,
                  size: 20,
                ),
                title: Row(
                  children: [
                    Text(loc['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isUnder10Km ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$dist km ${isUnder10Km ? "(Eligible)" : "(Outside Limit)"}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUnder10Km ? Colors.green.shade800 : Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(loc['address'] as String, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  final newAddr = CustomerAddressModel(
                    id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                    label: loc['label'] as String,
                    fullAddress: loc['address'] as String,
                    landmark: loc['landmark'] as String,
                    city: repo.activeBranch.city,
                    latitude: lat,
                    longitude: lng,
                    distanceKmFromHotel: dist,
                    isWithin10Km: isUnder10Km,
                  );
                  repo.setSelectedDeliveryAddress(newAddr);
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const Divider(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showAddCustomAddressDialog(context, repo);
              },
              icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFFE23744), size: 18),
              label: const Text('Add New Custom Delivery Address', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE23744)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomAddressDialog(BuildContext context, HotelRepository repo) {
    final titleCtrl = TextEditingController(text: 'Home');
    final addrCtrl = TextEditingController();
    final landmarkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_location_rounded, color: Color(0xFFE23744)),
            SizedBox(width: 8),
            Text('Add Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Address Label (e.g. Home, Office, Hotel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Full Street Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: landmarkCtrl,
                decoration: InputDecoration(
                  labelText: 'Landmark (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (addrCtrl.text.trim().isEmpty) return;
              final newAddress = CustomerAddressModel(
                id: 'addr-cust-${DateTime.now().millisecondsSinceEpoch}',
                label: titleCtrl.text.trim().isEmpty ? 'Home' : titleCtrl.text.trim(),
                fullAddress: landmarkCtrl.text.trim().isNotEmpty
                    ? '${addrCtrl.text.trim()}, Near ${landmarkCtrl.text.trim()}'
                    : addrCtrl.text.trim(),
                landmark: landmarkCtrl.text.trim(),
                city: repo.activeBranch.city,
                latitude: 19.1150,
                longitude: 72.8700,
                distanceKmFromHotel: 3.1,
                isWithin10Km: true,
              );
              repo.addCustomerDeliveryAddress(newAddress);
              Navigator.of(dCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📍 Delivery address updated!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23744),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  void _promptMandatoryProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE23744).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_pin_rounded, color: Color(0xFFE23744), size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              'Profile Registration Required',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
            ),
            const SizedBox(height: 8),
            Text(
              'Guest users can browse menus, but placing an order requires user registration. Please create your profile or sign in to complete your order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(bCtx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => CustomerAuthView(
                      initialTab: AuthTab.register,
                      onLoginSuccess: () {
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.app_registration_rounded, size: 18),
              label: const Text('Create Profile / Register Now', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE23744),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(bCtx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => CustomerAuthView(
                      initialTab: AuthTab.signIn,
                      onLoginSuccess: () {
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18, color: Color(0xFF1B4F72)),
              label: const Text('Already Have an Account? Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Color(0xFF1B4F72)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
