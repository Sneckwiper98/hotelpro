import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/pos_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/geofence_service.dart';
import 'customer_auth_view.dart';

class CustomerFoodHomeView extends StatefulWidget {
  final VoidCallback onOpenCart;

  const CustomerFoodHomeView({
    super.key,
    required this.onOpenCart,
  });

  @override
  State<CustomerFoodHomeView> createState() => _CustomerFoodHomeViewState();
}

class _CustomerFoodHomeViewState extends State<CustomerFoodHomeView> {
  String _selectedCategory = 'All';
  bool _onlyVeg = false;
  bool _onlyBestsellers = false;
  bool _under300 = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': '🍽️'},
    {'name': 'Royal Biryani', 'icon': '🍚'},
    {'name': 'Starters', 'icon': '🍢'},
    {'name': 'Main Course', 'icon': '🍲'},
    {'name': 'Continental & Italian', 'icon': '🍕'},
    {'name': 'Tandoor & Breads', 'icon': '🫓'},
    {'name': 'Desserts', 'icon': '🍨'},
    {'name': 'Beverages', 'icon': '🥤'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;
    final selectedAddress = repo.selectedDeliveryAddress;
    final distanceKm = selectedAddress?.distanceKmFromHotel ?? 2.8;
    final isWithin10Km = distanceKm <= GeofenceService.maxDeliveryRadiusKm;
    final cartCount = repo.customerCartCount;
    final cartTotal = repo.customerCartGrandTotal;

    // Filter menu items
    final allItems = repo.activeBranchMenuItems.where((item) {
      if (!item.isAvailable) return false;
      if (_onlyVeg && !item.isVeg) return false;
      if (_selectedCategory != 'All' && item.category != _selectedCategory) return false;
      if (_onlyBestsellers && item.price < 400) return false;
      if (_under300 && item.price > 300) return false;
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !item.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    // Calculate system status bar padding to strictly prevent overlapping with wifi/battery/clock
    final topInset = MediaQuery.of(context).padding.top;
    final effectiveTop = topInset > 0 ? topInset + 6 : 12.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Top Header App Bar (Delivery location + Search) ───────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      top: effectiveTop,
                      left: 16,
                      right: 16,
                      bottom: 14,
                    ),
                    child: Column(
                      children: [
                        // Location Bar with 10km badge & ETA
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE23744).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFFE23744), size: 19),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showLocationPicker(context, repo),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            selectedAddress?.label ?? 'Select Location',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Colors.black87),
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: Colors.black87),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isWithin10Km ? const Color(0xFFE8F8F5) : const Color(0xFFFDEDEC),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isWithin10Km ? Colors.green.shade400 : Colors.red.shade400,
                                              width: 0.6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isWithin10Km ? Icons.bolt_rounded : Icons.warning_amber_rounded,
                                                size: 11,
                                                color: isWithin10Km ? Colors.green.shade800 : Colors.red.shade800,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$distanceKm km ${isWithin10Km ? "• ~25m" : "• Out of range"}',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isWithin10Km ? Colors.green.shade900 : Colors.red.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedAddress?.fullAddress ?? 'Tap to choose delivery address',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Customer Profile Avatar
                            GestureDetector(
                              onTap: () {
                                if (!repo.isCustomerLoggedIn) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (ctx) => CustomerAuthView(onLoginSuccess: () {})),
                                  );
                                } else {
                                  _showProfileMenu(context, repo);
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE23744), width: 1.5),
                                ),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF1B4F72),
                                  child: Text(
                                    repo.isCustomerLoggedIn
                                        ? repo.currentCustomer!.name.substring(0, 1).toUpperCase()
                                        : '👤',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Modern Search Bar with Voice & Clear Icons
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search_rounded, color: Color(0xFFE23744), size: 21),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: const InputDecoration(
                                    hintText: 'Search Biryani, Butter Chicken, Paneer Tikka...',
                                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(Icons.mic_none_rounded, size: 19, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Offers Hero Carousel ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    height: 125,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildPromoCard(
                          context: context,
                          title: 'FLAT 50% OFF',
                          subtitle: 'Use Code: HOTELPRO50\nOn all orders above ₹399',
                          couponCode: 'HOTELPRO50',
                          bgGradient: const [Color(0xFFE23744), Color(0xFFB71C1C)],
                          icon: Icons.percent_rounded,
                        ),
                        _buildPromoCard(
                          context: context,
                          title: 'FREE DELIVERY',
                          subtitle: 'Within 10 km Radius\nUse Code: FREEDEL on ₹499+',
                          couponCode: 'FREEDEL',
                          bgGradient: const [Color(0xFF0C2340), Color(0xFF1E3A8A)],
                          icon: Icons.moped_rounded,
                        ),
                        _buildPromoCard(
                          context: context,
                          title: 'CHEF\'S ROYALE',
                          subtitle: 'Authentic Nizami Dum Handi\nUse Code: CHEFGOLD',
                          couponCode: 'CHEFGOLD',
                          bgGradient: const [Color(0xFFB78103), Color(0xFF7D5700)],
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Veg / Non-Veg Filter Switch & Branch Badge ─────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Veg Only Toggle Chip
                        FilterChip(
                          selected: _onlyVeg,
                          onSelected: (v) => setState(() => _onlyVeg = v),
                          avatar: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              border: Border.all(color: _onlyVeg ? Colors.white : Colors.green.shade700, width: 1.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.circle, color: _onlyVeg ? Colors.white : Colors.green.shade700, size: 6),
                          ),
                          label: const Text('Veg Only', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          selectedColor: Colors.green.shade700,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: _onlyVeg ? Colors.white : Colors.black87),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: _onlyVeg ? Colors.green.shade700 : Colors.green.shade300),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Branch Badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant_rounded, size: 14, color: Color(0xFF1B4F72)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    activeBranch.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                  ),
                                ),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Quick Category Pills ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
                        final catName = cat['name']!;
                        final catIcon = cat['icon']!;
                        final isSelected = _selectedCategory == catName;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Text(catIcon, style: const TextStyle(fontSize: 13)),
                            label: Text(catName),
                            selected: isSelected,
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedCategory = catName);
                            },
                            selectedColor: const Color(0xFFE23744),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? const Color(0xFFE23744) : Colors.grey.shade300),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Secondary Quick Filters (Bestsellers / Under ₹300) ────
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _onlyBestsellers,
                          onSelected: (v) => setState(() => _onlyBestsellers = v),
                          label: const Text('Bestsellers ⭐', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          selectedColor: const Color(0xFFFFF3CD),
                          checkmarkColor: const Color(0xFF856404),
                          labelStyle: TextStyle(color: _onlyBestsellers ? const Color(0xFF856404) : Colors.black87),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: _onlyBestsellers ? const Color(0xFFFFC107) : Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _under300,
                          onSelected: (v) => setState(() => _under300 = v),
                          label: const Text('Under ₹300 🏷️', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          selectedColor: const Color(0xFFD1ECF1),
                          checkmarkColor: const Color(0xFF0C5460),
                          labelStyle: TextStyle(color: _under300 ? const Color(0xFF0C5460) : Colors.black87),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: _under300 ? const Color(0xFF17A2B8) : Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Restaurant Menu Dish Cards ───────────────────────────
                if (allItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No delicious dishes found matching filters.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, idx) {
                          final item = allItems[idx];
                          return _buildDishCard(context, repo, item);
                        },
                        childCount: allItems.length,
                      ),
                    ),
                  ),

                // Bottom padding for floating cart
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // ── Floating Bottom Cart Bar (Zomato Style) ───────────────────
            if (cartCount > 0)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: widget.onOpenCart,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE23744), Color(0xFFC0392B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE23744).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$cartCount ITEM${cartCount > 1 ? "S" : ""} ADDED',
                              style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${cartTotal.toStringAsFixed(2)} plus taxes',
                              style: const TextStyle(fontSize: 14.5, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'View Cart',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String couponCode,
    required List<Color> bgGradient,
    required IconData icon,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: bgGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: bgGradient.first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -6,
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.18), size: 70),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.2)),
                ],
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: couponCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Coupon code "$couponCode" copied to clipboard!'),
                      backgroundColor: Colors.black87,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, color: Colors.white, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'CODE: $couponCode',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(BuildContext context, HotelRepository repo, PosMenuItemModel item) {
    final cartItem = repo.customerCart.firstWhere(
      (c) => c.menuItemId == item.id,
      orElse: () => CustomerCartItem(
        menuItemId: '',
        name: '',
        price: 0,
        isVeg: true,
        quantity: 0,
      ),
    );
    final inCartQty = cartItem.quantity;
    final isBestseller = item.price >= 400;

    return InkWell(
      onTap: () => _showDishCustomizer(context, repo, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/Non-Veg Badge & Category Tag
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.circle, size: 6, color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700),
                      ),
                      const SizedBox(width: 6),
                      if (isBestseller) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⭐ BESTSELLER',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.category,
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Dish Name
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),

                  // Rating & Prep Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Text('4.8', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            SizedBox(width: 2),
                            Icon(Icons.star_rounded, size: 10, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•  ⏱️ 20-25m', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price with original MRP strike-through
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0C2340)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${(item.price * 1.25).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '20% OFF',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ],
                  ),

                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Customisable', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Image & Add Button
            Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 108,
                        height: 98,
                        color: Colors.grey.shade100,
                        child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Center(
                                  child: Text(item.emoji, style: const TextStyle(fontSize: 38)),
                                ),
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE23744)),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(item.emoji, style: const TextStyle(fontSize: 38)),
                              ),
                      ),
                    ),

                    // Dynamic Add / Counter Button
                    Positioned(
                      bottom: -12,
                      child: inCartQty == 0
                          ? ElevatedButton(
                              onPressed: () => repo.addToCustomerCart(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFE23744),
                                elevation: 2.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFFE23744), width: 1.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                                minimumSize: const Size(78, 30),
                              ),
                              child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          : Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE23744),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                                    onPressed: () => repo.updateCartItemQuantity(item.id, -1),
                                  ),
                                  Text(
                                    '$inCartQty',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                                    onPressed: () => repo.updateCartItemQuantity(item.id, 1),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ADVANCED DISH CUSTOMIZER MODAL ───────────────────────────────────────
  void _showDishCustomizer(BuildContext context, HotelRepository repo, PosMenuItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DishCustomizerSheet(item: item, repo: repo),
    );
  }

  void _showLocationPicker(BuildContext context, HotelRepository repo) {
    final demoLocations = GeofenceService.getDemoDeliveryLocations(repo.activeBranch.code);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.near_me_rounded, color: Color(0xFFE23744), size: 22),
                SizedBox(width: 8),
                Text('Select Delivery Location (Max 10 km)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'HotelPro strictly delivers within a 10 km radius of the hotel to guarantee hot, fresh meals.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
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
                leading: Icon(isUnder10Km ? Icons.check_circle : Icons.cancel, color: isUnder10Km ? Colors.green : Colors.red, size: 20),
                title: Row(
                  children: [
                    Text(loc['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isUnder10Km ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$dist km ${isUnder10Km ? "(Available)" : "(Outside 10km)"}',
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
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, HotelRepository repo) {
    final cust = repo.currentCustomer;
    if (cust == null) return;
    final isVip = cust.walletBalance >= 500;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final activeCust = repo.currentCustomer ?? cust;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Avatar and Details
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE23744),
                        child: Text(
                          activeCust.name.isNotEmpty ? activeCust.name.substring(0, 1).toUpperCase() : '👤',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    activeCust.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isVip ? Colors.amber.shade100 : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isVip ? Colors.amber.shade600 : Colors.blue.shade300, width: 0.6),
                                  ),
                                  child: Text(
                                    isVip ? '⭐ VIP GOLD' : 'MEMBER',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: isVip ? Colors.amber.shade900 : Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(activeCust.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Text(activeCust.email, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Wallet Card with +₹500 Recharge
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF145A32), Color(0xFF1E8449)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E8449).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.amberAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HotelPro Food Wallet', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                              Text(
                                '₹${activeCust.walletBalance.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            repo.setCustomer(activeCust.copyWith(walletBalance: activeCust.walletBalance + 500));
                            setSheetState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 ₹500 credited to HotelPro Food Wallet!'),
                                backgroundColor: Color(0xFF1E8449),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text('Add ₹500', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF145A32),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Actions
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1B4F72), size: 18),
                    ),
                    title: const Text('Switch Customer Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                    subtitle: const Text('Log in with your registered mobile or WhatsApp OTP', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    onTap: () {
                      repo.logoutCustomer();
                      Navigator.of(ctx).pop();
                    },
                  ),

                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    ),
                    title: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                    subtitle: const Text('End customer dining session', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    onTap: () {
                      repo.logoutCustomer();
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── DISH CUSTOMIZER BOTTOM SHEET ──────────────────────────────────────────
class _DishCustomizerSheet extends StatefulWidget {
  final PosMenuItemModel item;
  final HotelRepository repo;

  const _DishCustomizerSheet({required this.item, required this.repo});

  @override
  State<_DishCustomizerSheet> createState() => _DishCustomizerSheetState();
}

class _DishCustomizerSheetState extends State<_DishCustomizerSheet> {
  String _portion = 'Full Portion';
  String _spiceLevel = 'Medium';
  final Set<String> _selectedAddons = {};

  final Map<String, double> _addons = {
    'Extra Boondi Raita': 40.0,
    'Special Salan Gravy': 50.0,
    'Fried Papad & Mint Chutney': 30.0,
  };

  @override
  Widget build(BuildContext context) {
    double basePrice = widget.item.price;
    if (_portion == 'Half Portion') {
      basePrice = (basePrice * 0.65).roundToDouble();
    }

    double addonsTotal = 0;
    for (final a in _selectedAddons) {
      addonsTotal += _addons[a] ?? 0;
    }
    final finalPrice = basePrice + addonsTotal;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),

              // Title and Veg tag
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.item.isVeg ? Colors.green.shade700 : Colors.red.shade700, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.circle, size: 6, color: widget.item.isVeg ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Customize "${widget.item.name}"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select your portion, spice preference & extras',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Divider(height: 20),

              // Portion Size Selection
              const Text('1. SELECT PORTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _choiceTile('Full Portion', '₹${widget.item.price.toStringAsFixed(0)}', _portion == 'Full Portion', () {
                    setState(() => _portion = 'Full Portion');
                  }),
                  const SizedBox(width: 10),
                  _choiceTile('Half Portion', '₹${(widget.item.price * 0.65).toStringAsFixed(0)}', _portion == 'Half Portion', () {
                    setState(() => _portion = 'Half Portion');
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Spice Level
              const Text('2. SPICE PREFERENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _spiceTile('Mild', '🌱', _spiceLevel == 'Mild', () => setState(() => _spiceLevel = 'Mild')),
                  const SizedBox(width: 8),
                  _spiceTile('Medium', '🌶️', _spiceLevel == 'Medium', () => setState(() => _spiceLevel = 'Medium')),
                  const SizedBox(width: 8),
                  _spiceTile('Extra Spicy', '🌶️🌶️', _spiceLevel == 'Extra Spicy', () => setState(() => _spiceLevel = 'Extra Spicy')),
                ],
              ),
              const SizedBox(height: 16),

              // Add-on Accompaniments
              const Text('3. EXTRA ACCOMPANIMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              ..._addons.entries.map((entry) {
                final isChecked = _selectedAddons.contains(entry.key);
                return CheckboxListTile(
                  value: isChecked,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFFE23744),
                  title: Text(entry.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  secondary: Text('+₹${entry.value.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedAddons.add(entry.key);
                      } else {
                        _selectedAddons.remove(entry.key);
                      }
                    });
                  },
                );
              }),

              const SizedBox(height: 16),

              // Add to Cart Button
              ElevatedButton(
                onPressed: () {
                  widget.repo.addToCustomerCart(widget.item);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ Added ${widget.item.name} ($_portion, $_spiceLevel) to basket!'),
                      backgroundColor: const Color(0xFFE23744),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: ₹${finalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Row(
                      children: [
                        Text('Add to Basket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceTile(String label, String price, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFDE8E9) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFFE23744) : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFFE23744) : Colors.black87)),
              const SizedBox(height: 2),
              Text(price, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFE23744) : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spiceTile(String label, String icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3CD) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF856404) : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
