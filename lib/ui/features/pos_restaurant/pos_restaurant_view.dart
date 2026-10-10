import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/pos_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_form_widgets.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import 'online_delivery_dashboard_view.dart';

/// Classic Windows Desktop Restaurant POS & Multi-Stream Billing Terminal
/// Supports dedicated, separated workflows for:
/// 1. 🍽️ Table Dining (Dine-In Restaurant Billing)
/// 2. 🛎️ Room Folio (In-Room Service Billing & Folio Posting)
/// 3. 🏛️ Hall Bookings (Banquet Hall Rental & Event Catering Billing)
/// 4. 📋 Bill Register & Invoices (Separated History for All Types)
class PosRestaurantView extends StatefulWidget {
  const PosRestaurantView({super.key});

  @override
  State<PosRestaurantView> createState() => _PosRestaurantViewState();
}

class _PosRestaurantViewState extends State<PosRestaurantView> {
  // ── View Navigation ────────────────────────────────────────────────────────
  // 0: Order Punch Terminal, 1: Bill Register & Invoices
  int _currentViewIndex = 0;

  // ── Active Billing Stream (in Terminal) ────────────────────────────────────
  PosBillingType _activeBillingStream = PosBillingType.tableDining;

  // ── Outlet & Category Filters ──────────────────────────────────────────────
  String? _selectedOutletId;
  String _selectedCategory = 'all';
  String _menuSearchQuery = '';

  // ── Order Cart ─────────────────────────────────────────────────────────────
  final List<PosOrderItem> _cart = [];

  // ── Table Dining State ─────────────────────────────────────────────────────
  String _tableNumber = 'Table 4';
  late final TextEditingController _tableNumberController;
  int _tableCovers = 2;
  String _selectedWaiter = 'Vikram S.';
  final List<String> _waiters = [
    'Vikram S.',
    'Ramesh K.',
    'Priya M.',
    'Sunil D.',
    'Anil J.',
  ];
  final List<String> _quickTables = [
    'Table 1',
    'Table 2',
    'Table 3',
    'Table 4',
    'Table 5',
    'Table 6',
    'VIP Room 1',
    'Lawn Patio 1',
    'Lawn Patio 2',
  ];

  // ── Room Folio State ───────────────────────────────────────────────────────
  String? _selectedRoomNumber;
  String _deliverySteward = 'Ramesh Kumar (Steward)';
  final List<String> _stewards = [
    'Ramesh Kumar (Steward)',
    'Mahesh N. (Bell Desk)',
    'Suresh P. (Room Service)',
  ];

  // ── Hall Bookings State ────────────────────────────────────────────────────
  String? _selectedHallId;
  late final TextEditingController _hallEventNameController;
  late final TextEditingController _hallHostNameController;
  late final TextEditingController _hallHostPhoneController;
  late final TextEditingController _hallRentController;
  late final TextEditingController _hallAdvanceController;
  String _hallSlot = 'Evening (18:00 - 23:30)';
  int _hallPaxCount = 100;
  String _hallPaymentMode = 'Bank Transfer / NEFT';

  // ── Bill Register State ───────────────────────────────────────────────────
  String _registerFilter = 'all'; // 'all', 'table_dining', 'room_folio', 'hall_booking'
  final TextEditingController _registerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(text: _tableNumber);
    _hallEventNameController = TextEditingController(text: 'Annual Corporate Gala 2026');
    _hallHostNameController = TextEditingController(text: 'Adani Logistics Ltd / Rajiv Mehta');
    _hallHostPhoneController = TextEditingController(text: '+91 98201 55432');
    _hallRentController = TextEditingController(text: '65000');
    _hallAdvanceController = TextEditingController(text: '35000');
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _hallEventNameController.dispose();
    _hallHostNameController.dispose();
    _hallHostPhoneController.dispose();
    _hallRentController.dispose();
    _hallAdvanceController.dispose();
    _registerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final outlets = repo.activeBranchOutlets;
    final menuItems = repo.activeBranchMenuItems;
    final occupiedRooms = repo.activeBranchRooms
        .where((r) => r.status == RoomStatus.occupied)
        .toList();
    final banquetHalls = repo.activeBranchBanquetHalls;

    if (_selectedOutletId == null && outlets.isNotEmpty) {
      _selectedOutletId = outlets.first.id;
    }

    if (_selectedRoomNumber == null && occupiedRooms.isNotEmpty) {
      _selectedRoomNumber = occupiedRooms.first.roomNumber;
    }

    if (_selectedHallId == null && banquetHalls.isNotEmpty) {
      _selectedHallId = banquetHalls.first.id;
      _hallRentController.text = banquetHalls.first.baseRental.toStringAsFixed(0);
    }

    // Filter menu items
    final filteredMenu = menuItems.where((item) {
      if (_selectedOutletId != null && item.outletId != _selectedOutletId) {
        return false;
      }
      if (_selectedCategory != 'all' && item.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_menuSearchQuery.trim().isNotEmpty) {
        final q = _menuSearchQuery.trim().toLowerCase();
        if (!item.name.toLowerCase().contains(q) && !item.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final categories = ['all', 'Starters', 'Main Course', 'Cocktails', 'Desserts', 'Champagne'];
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final cartSubtotal = _cart.fold(0.0, (sum, i) => sum + i.subtotal);
    final cartTax = _cart.fold(0.0, (sum, i) => sum + i.tax);
    final cartTotal = cartSubtotal + cartTax;

    return Container(
      color: ClassicErpTheme.windowBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Navigation & View Switcher Ribbon ───────────────────────────
          _buildTopRibbon(repo, outlets),

          // ── Main Content Area (Punch Terminal, Live Tables/KOTs, Bill Register, or Online Delivery Dispatch) ────────────
          Expanded(
            child: _currentViewIndex == 0
                ? _buildPunchTerminal(
                    repo: repo,
                    filteredMenu: filteredMenu,
                    categories: categories,
                    occupiedRooms: occupiedRooms,
                    banquetHalls: banquetHalls,
                    currency: currency,
                    cartSubtotal: cartSubtotal,
                    cartTax: cartTax,
                    cartTotal: cartTotal,
                  )
                : (_currentViewIndex == 1
                    ? _buildLiveTablesAndKotsView(repo, currency)
                    : (_currentViewIndex == 2
                        ? _buildBillRegisterView(repo, currency)
                        : const OnlineDeliveryDashboardView(isEmbedded: true))),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 1. TOP RIBBON & VIEW SWITCHER
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildTopRibbon(HotelRepository repo, List<PosOutletModel> outlets) {
    final activeKotsCount = repo.posOrders
        .where((o) => o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled)
        .length;
    final totalBills = repo.activeBranchPosBills.length;
    final totalOnlineOrders = repo.customerOrders.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.point_of_sale_rounded, size: 16, color: ClassicErpTheme.mdiHeaderActive),
                      const SizedBox(width: 6),
                      const Text(
                        'POS Restaurant & Multi-Stream Billing Terminal',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                      ),
                      const SizedBox(width: 14),

                      // View Switcher Buttons
                      _topTabButton('🛒 Punch Terminal', 0, _currentViewIndex == 0),
                      const SizedBox(width: 4),
                      _topTabButton('🔴 Live Tables & KOTs ($activeKotsCount)', 1, _currentViewIndex == 1),
                      const SizedBox(width: 4),
                      _topTabButton('📋 Bill Register & Invoices ($totalBills)', 2, _currentViewIndex == 2),
                      const SizedBox(width: 4),
                      _topTabButton('🛵 Online Delivery ($totalOnlineOrders)', 3, _currentViewIndex == 3),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Local Wi-Fi Sync Server Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          border: Border.all(color: const Color(0xFF2ECC71)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27AE60),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LAN Sync: ${HotelSyncBridgeService.instance.localIpAddress ?? "127.0.0.1"}:8088',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E8449),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showLanPairingDialog(context, repo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FB),
                            border: Border.all(color: const Color(0xFF3498DB)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_android_rounded, size: 12, color: Color(0xFF2980B9)),
                              SizedBox(width: 4),
                              Text(
                                'Pair Mobile Apps',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2980B9)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Outlet Dropdown (in Punch mode)
                      if (_currentViewIndex == 0 && outlets.isNotEmpty) ...[
                        const Text('F&B Outlet: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedOutletId,
                              style: const TextStyle(color: ClassicErpTheme.textMain, fontSize: 10.5, fontWeight: FontWeight.bold),
                              items: outlets.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))).toList(),
                              onChanged: (id) => setState(() => _selectedOutletId = id),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topTabButton(String label, int index, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _currentViewIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.borderDark, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 2. ORDER PUNCH TERMINAL (MENU GRID + STREAM DOCKET)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildPunchTerminal({
    required HotelRepository repo,
    required List<PosMenuItemModel> filteredMenu,
    required List<String> categories,
    required List<RoomModel> occupiedRooms,
    required List<BanquetHallModel> banquetHalls,
    required NumberFormat currency,
    required double cartSubtotal,
    required double cartTax,
    required double cartTotal,
  }) {
    return Column(
      children: [
        // Billing Stream Selection Ribbon
        _buildBillingStreamRibbon(),

        // Content Area: Menu Grid + Right Docket
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Menu & Search Grid
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category & Search Bar
                    _buildCategoryAndSearchBar(categories),

                    // Quick Hall Packages Banner (if in Hall Booking mode)
                    if (_activeBillingStream == PosBillingType.hallBooking)
                      _buildQuickBanquetPackagesBar(),

                    // Food Menu Grid
                    Expanded(
                      child: filteredMenu.isEmpty
                          ? const Center(
                              child: Text(
                                'No menu items found matching search or category.',
                                style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisExtent: 88,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount: filteredMenu.length,
                              itemBuilder: (context, index) {
                                return _buildClassicMenuTile(filteredMenu[index], currency);
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Right: Dedicated Billing Stream Docket & Settle Panel
              Container(
                width: 350,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9F9),
                  border: Border(left: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scrollable Docket Body: Stream Inputs + Cart Items List
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStreamSpecificInputs(repo, occupiedRooms, banquetHalls),
                            const Divider(color: ClassicErpTheme.borderLight, height: 1),
                            _buildCartItemsList(currency),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Totals & Actions Panel (Always pinned at bottom)
                    _buildBottomTotalsAndActions(
                      repo: repo,
                      currency: currency,
                      cartSubtotal: cartSubtotal,
                      cartTax: cartTax,
                      cartTotal: cartTotal,
                      occupiedRooms: occupiedRooms,
                      banquetHalls: banquetHalls,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Billing Stream Selection Tabs ──────────────────────────────────────────
  Widget _buildBillingStreamRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFEAECEE),
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'BILLING STREAM: ',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
            ),
            const SizedBox(width: 8),

            _streamTabButton(
              stream: PosBillingType.tableDining,
              label: '🍽️ Table Dining (Dine-In)',
              desc: 'Restaurant Tables, Waiter, Direct Settle',
            ),
            const SizedBox(width: 6),

            _streamTabButton(
              stream: PosBillingType.roomFolio,
              label: '🛎️ Room Folio (In-Room)',
              desc: 'Room Service & Direct Post to Room Master Folio',
            ),
            const SizedBox(width: 6),

            _streamTabButton(
              stream: PosBillingType.hallBooking,
              label: '🏛️ Hall & Banquet Booking',
              desc: 'Event Halls, Function Catering & Advance Deposit',
            ),
          ],
        ),
      ),
    );
  }

  Widget _streamTabButton({
    required PosBillingType stream,
    required String label,
    required String desc,
  }) {
    final isSelected = _activeBillingStream == stream;
    return Tooltip(
      message: desc,
      child: InkWell(
        onTap: () => setState(() => _activeBillingStream = stream),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.borderDark,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : ClassicErpTheme.textMain,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Category Tabs & Search Bar ─────────────────────────────────────────────
  Widget _buildCategoryAndSearchBar(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F4),
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.borderDark,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : ClassicErpTheme.textMain,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Search Field
          ClassicErpSearchField(
            hintText: 'Search food dishes...',
            width: 170,
            height: 26,
            onChanged: (val) => setState(() => _menuSearchQuery = val),
          ),
        ],
      ),
    );
  }

  // ── Quick Banquet Packages Bar (for Hall Bookings) ──────────────────────────
  Widget _buildQuickBanquetPackagesBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F8F5),
        border: Border(bottom: BorderSide(color: Color(0xFF1ABC9C), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.room_service_rounded, size: 14, color: Color(0xFF0E6251)),
          const SizedBox(width: 6),
          const Text(
            'Quick Banquet Packages:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0E6251)),
          ),
          const SizedBox(width: 8),
          _quickPackageChip('Royal Buffet (₹85,000)', 'banq-pkg-01', 'Royal Buffet Spread & Hi-Tea Catering', 85000.0),
          const SizedBox(width: 4),
          _quickPackageChip('Executive Hi-Tea (₹35,000)', 'banq-pkg-02', 'Executive Conference Hi-Tea & Snacks', 35000.0),
          const SizedBox(width: 4),
          _quickPackageChip('Gala Dinner (₹1,20,000)', 'banq-pkg-03', 'Grand Gala Dinner & Cocktails Spread', 120000.0),
        ],
      ),
    );
  }

  Widget _quickPackageChip(String label, String id, String name, double price) {
    return InkWell(
      onTap: () {
        setState(() {
          _cart.add(PosOrderItem(
            menuItemId: id,
            name: name,
            quantity: 1,
            price: price,
            taxRate: 5.0,
          ));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF16A085), width: 1),
        ),
        child: Text(
          '+ $label',
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0E6251)),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 3. RIGHT DOCKET: DEDICATED INPUTS FOR EACH STREAM
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStreamSpecificInputs(
    HotelRepository repo,
    List<RoomModel> occupiedRooms,
    List<BanquetHallModel> banquetHalls,
  ) {
    switch (_activeBillingStream) {
      case PosBillingType.tableDining:
        return _buildTableDiningInputs();
      case PosBillingType.roomFolio:
        return _buildRoomFolioInputs(occupiedRooms);
      case PosBillingType.hallBooking:
        return _buildHallBookingInputs(banquetHalls);
    }
  }

  // ── Mode 1: Table Dining Inputs ────────────────────────────────────────────
  Widget _buildTableDiningInputs() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: ClassicErpTheme.panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClassicErpSectionHeader(
            icon: Icons.restaurant_rounded,
            title: 'TABLE DINING DOCKET',
            color: Color(0xFF1B4F72),
          ),
          const SizedBox(height: 6),

          // Table Number + Covers
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: ClassicErpInput(
                  label: 'Table Number',
                  isRequired: true,
                  controller: _tableNumberController,
                  hintText: 'e.g. Table 4',
                  height: 28,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  onChanged: (v) => _tableNumber = v,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: ClassicErpDropdown<int>(
                  label: 'Covers (Pax)',
                  value: _tableCovers,
                  height: 28,
                  items: [1, 2, 3, 4, 5, 6, 8, 10, 12, 16]
                      .map((c) => DropdownMenuItem(value: c, child: Text('$c Pax')))
                      .toList(),
                  onChanged: (val) => setState(() => _tableCovers = val ?? 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Quick Table Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickTables.map((t) {
                final isSelected = _tableNumber.toLowerCase() == t.toLowerCase();
                return InkWell(
                  onTap: () {
                    setState(() {
                      _tableNumber = t;
                      _tableNumberController.text = t;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1B4F72) : const Color(0xFFB0BEC5),
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : ClassicErpTheme.textMain,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Waiter / Steward
          ClassicErpDropdown<String>(
            label: 'Steward / Waiter Assigned',
            value: _selectedWaiter,
            height: 28,
            items: _waiters.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (val) => setState(() => _selectedWaiter = val ?? _waiters.first),
          ),
        ],
      ),
    );
  }

  // ── Mode 2: Room Folio Inputs ──────────────────────────────────────────────
  Widget _buildRoomFolioInputs(List<RoomModel> occupiedRooms) {
    final selectedRoom = occupiedRooms.where((r) => r.roomNumber == _selectedRoomNumber).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFEBF5FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClassicErpSectionHeader(
            icon: Icons.bed_rounded,
            title: 'ROOM FOLIO CHARGE DOCKET',
            color: Color(0xFF2980B9),
          ),
          const SizedBox(height: 6),

          // Occupied Room Dropdown
          ClassicErpDropdown<String>(
            label: 'Select In-House Occupied Room',
            isRequired: true,
            value: _selectedRoomNumber,
            height: 28,
            items: occupiedRooms.isEmpty
                ? const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('No rooms currently occupied', style: TextStyle(color: Colors.red)),
                    )
                  ]
                : occupiedRooms.map((r) {
                    return DropdownMenuItem(
                      value: r.roomNumber,
                      child: Text('Room ${r.roomNumber} — ${r.currentGuestName ?? "In-House Guest"}'),
                    );
                  }).toList(),
            onChanged: (val) => setState(() => _selectedRoomNumber = val),
          ),
          const SizedBox(height: 6),

          // In-House Guest Info Card
          if (selectedRoom != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFFB0BEC5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2980B9)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Guest: ${selectedRoom.currentGuestName ?? "Valued Guest"} • ${selectedRoom.roomTypeName}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),

          // Delivery Steward
          ClassicErpDropdown<String>(
            label: 'Delivered By (Room Service Steward)',
            value: _deliverySteward,
            height: 28,
            items: _stewards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _deliverySteward = v ?? _stewards.first),
          ),
        ],
      ),
    );
  }

  // ── Mode 3: Hall & Banquet Booking Inputs ──────────────────────────────────
  Widget _buildHallBookingInputs(List<BanquetHallModel> banquetHalls) {
    final selectedHall = banquetHalls.where((h) => h.id == _selectedHallId).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFF5EEF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClassicErpSectionHeader(
            icon: Icons.celebration_rounded,
            title: 'BANQUET & EVENT HALL DOCKET',
            color: Color(0xFF6C3483),
          ),
          const SizedBox(height: 6),

          // Hall Selector
          ClassicErpDropdown<String>(
            label: 'Select Banquet / Conference Hall',
            isRequired: true,
            value: _selectedHallId,
            height: 28,
            items: banquetHalls.map((h) {
              return DropdownMenuItem(value: h.id, child: Text('${h.name} (Cap: ${h.capacity})'));
            }).toList(),
            onChanged: (id) {
              if (id != null) {
                final hall = banquetHalls.firstWhere((h) => h.id == id);
                setState(() {
                  _selectedHallId = id;
                  _hallRentController.text = hall.baseRental.toStringAsFixed(0);
                });
              }
            },
          ),
          if (selectedHall != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                selectedHall.features,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF6C3483), fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Event Name + Slot
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: ClassicErpInput(
                  label: 'Event / Occasion',
                  isRequired: true,
                  controller: _hallEventNameController,
                  hintText: 'e.g. Wedding Reception',
                  height: 28,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: ClassicErpDropdown<String>(
                  label: 'Slot',
                  value: _hallSlot,
                  height: 28,
                  items: const [
                    DropdownMenuItem(value: 'Morning (09:00 - 15:00)', child: Text('Morning')),
                    DropdownMenuItem(value: 'Evening (18:00 - 23:30)', child: Text('Evening')),
                    DropdownMenuItem(value: 'Full Day Event', child: Text('Full Day')),
                  ],
                  onChanged: (v) => setState(() => _hallSlot = v ?? 'Evening (18:00 - 23:30)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Host Name & Mobile
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ClassicErpInput(
                  label: 'Host / Organizer',
                  isRequired: true,
                  controller: _hallHostNameController,
                  hintText: 'Client name / Org',
                  height: 28,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClassicErpInput(
                  label: 'Phone / Mobile',
                  isRequired: true,
                  controller: _hallHostPhoneController,
                  hintText: '+91 98000 00000',
                  keyboardType: TextInputType.phone,
                  height: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Pax Count & Payment Mode
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ClassicErpDropdown<int>(
                  label: 'Expected Pax',
                  value: _hallPaxCount,
                  height: 28,
                  items: [25, 50, 75, 100, 150, 200, 250, 300, 400, 500]
                      .map((p) => DropdownMenuItem(value: p, child: Text('$p Pax')))
                      .toList(),
                  onChanged: (v) => setState(() => _hallPaxCount = v ?? 100),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClassicErpDropdown<String>(
                  label: 'Payment Mode',
                  value: _hallPaymentMode,
                  height: 28,
                  items: const [
                    DropdownMenuItem(value: 'Bank Transfer / NEFT', child: Text('NEFT / Bank')),
                    DropdownMenuItem(value: 'Credit / Debit Card', child: Text('Card (POS)')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'UPI / QR Code', child: Text('UPI / QR')),
                    DropdownMenuItem(value: 'Cash Deposit', child: Text('Cash')),
                  ],
                  onChanged: (v) => setState(() => _hallPaymentMode = v ?? 'Bank Transfer / NEFT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Hall Rent & Advance Paid
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ClassicErpInput(
                  label: 'Hall Hire Fee (₹)',
                  controller: _hallRentController,
                  isNumeric: true,
                  height: 28,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClassicErpInput(
                  label: 'Advance Paid (₹)',
                  controller: _hallAdvanceController,
                  isNumeric: true,
                  height: 28,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Cart Items List ────────────────────────────────────────────────────────
  Widget _buildCartItemsList(NumberFormat currency) {
    if (_cart.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeBillingStream == PosBillingType.hallBooking
                  ? Icons.celebration_outlined
                  : (_activeBillingStream == PosBillingType.roomFolio ? Icons.room_service_outlined : Icons.touch_app_rounded),
              size: 24,
              color: ClassicErpTheme.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              _activeBillingStream == PosBillingType.hallBooking
                  ? 'Optional: Add F&B catering items or packages from left menu'
                  : 'Tap menu dishes to punch order items',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ClassicErpTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                    Text('${currency.format(item.price)} each', style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                  ],
                ),
              ),
              // Stepper
              InkWell(
                onTap: () {
                  setState(() {
                    if (item.quantity > 1) {
                      item.quantity--;
                    } else {
                      _cart.removeAt(index);
                    }
                  });
                },
                child: Container(
                  width: 18,
                  height: 18,
                  color: ClassicErpTheme.buttonBg,
                  alignment: Alignment.center,
                  child: const Text('-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
              ),
              InkWell(
                onTap: () => setState(() => item.quantity++),
                child: Container(
                  width: 18,
                  height: 18,
                  color: ClassicErpTheme.buttonBg,
                  alignment: Alignment.center,
                  child: const Text('+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                currency.format(item.subtotal),
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom Totals & Action Buttons ─────────────────────────────────────────
  Widget _buildBottomTotalsAndActions({
    required HotelRepository repo,
    required NumberFormat currency,
    required double cartSubtotal,
    required double cartTax,
    required double cartTotal,
    required List<RoomModel> occupiedRooms,
    required List<BanquetHallModel> banquetHalls,
  }) {
    final hallRent = double.tryParse(_hallRentController.text) ?? 0.0;
    final hallAdvance = double.tryParse(_hallAdvanceController.text) ?? 0.0;
    final hallTax = (hallRent * 0.18) + (cartSubtotal * 0.05); // 18% hall service + 5% F&B
    final hallGrandTotal = hallRent + cartSubtotal + hallTax;
    final hallBalanceDue = (hallGrandTotal - hallAdvance).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border(top: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: Column(
        children: [
          // Clear Items link if cart has items
          if (_cart.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => setState(() => _cart.clear()),
                child: const Text('Clear Docket', style: TextStyle(color: Colors.red, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ),
            ),

          if (_activeBillingStream == PosBillingType.hallBooking) ...[
            // Hall Financials Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hall Hire Charges:', style: TextStyle(fontSize: 10)),
                Text(currency.format(hallRent), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('F&B Catering Subtotal:', style: TextStyle(fontSize: 10)),
                Text(currency.format(cartSubtotal), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GST (18% Rent + 5% F&B):', style: TextStyle(fontSize: 10)),
                Text(currency.format(hallTax), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: ClassicErpTheme.borderDark, height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Banquet Package:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(currency.format(hallGrandTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF6C3483))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Advance Deposit Paid:', style: TextStyle(fontSize: 10, color: Color(0xFF27AE60))),
                Text(currency.format(hallAdvance), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BALANCE DUE AT EVENT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                Text(currency.format(hallBalanceDue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red)),
              ],
            ),
          ] else ...[
            // Restaurant / Room Service Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 10.5)),
                Text(currency.format(cartSubtotal), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('F&B GST (${repo.foodGstRate.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 10.5)),
                Text(currency.format(cartTax), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: ClassicErpTheme.borderDark, height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                Text(
                  currency.format(cartTotal),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Action Buttons per Stream
          if (_activeBillingStream == PosBillingType.tableDining)
            _buildTableDiningActionButtons(repo, currency, cartSubtotal, cartTax, cartTotal)
          else if (_activeBillingStream == PosBillingType.roomFolio)
            _buildRoomFolioActionButtons(repo, currency, cartSubtotal, cartTax, cartTotal, occupiedRooms)
          else
            _buildHallBookingActionButtons(repo, currency, banquetHalls, cartSubtotal, hallRent, hallTax, hallGrandTotal, hallAdvance),
        ],
      ),
    );
  }

  // ── Action Buttons: Table Dining ───────────────────────────────────────────
  Widget _buildTableDiningActionButtons(
    HotelRepository repo,
    NumberFormat currency,
    double subtotal,
    double tax,
    double total,
  ) {
    return Row(
      children: [
        // Print KOT
        Expanded(
          child: SizedBox(
            height: 28,
            child: OutlinedButton.icon(
              onPressed: _cart.isEmpty
                  ? null
                  : () {
                      PrintPreviewDialog.show(
                        context,
                        title: 'Kitchen Order Ticket (KOT) — $_tableNumber',
                        content: _buildKotDoc(repo, _tableNumber, 'Table Dining', _cart),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B4F72),
                side: const BorderSide(color: Color(0xFF1B4F72)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.print_outlined, size: 13),
              label: const Text('PRINT KOT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Settle & Print Tax Invoice
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 28,
            child: ElevatedButton.icon(
              onPressed: _cart.isEmpty
                  ? null
                  : () => _showTableDiningSettlementModal(repo, currency, subtotal, tax, total),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 13),
              label: const Text('SETTLE & PRINT BILL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Action Buttons: Room Folio ─────────────────────────────────────────────
  Widget _buildRoomFolioActionButtons(
    HotelRepository repo,
    NumberFormat currency,
    double subtotal,
    double tax,
    double total,
    List<RoomModel> occupiedRooms,
  ) {
    final hasRoom = _selectedRoomNumber != null && occupiedRooms.any((r) => r.roomNumber == _selectedRoomNumber);

    return Row(
      children: [
        // Print KOT
        Expanded(
          child: SizedBox(
            height: 28,
            child: OutlinedButton.icon(
              onPressed: _cart.isEmpty
                  ? null
                  : () {
                      PrintPreviewDialog.show(
                        context,
                        title: 'Room Service KOT — Room ${_selectedRoomNumber ?? ""}',
                        content: _buildKotDoc(repo, 'Room ${_selectedRoomNumber ?? ""}', 'In-Room Service', _cart),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2980B9),
                side: const BorderSide(color: Color(0xFF2980B9)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.print_outlined, size: 13),
              label: const Text('KOT DOCKET', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Post to Room Folio
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 28,
            child: ElevatedButton.icon(
              onPressed: (_cart.isEmpty || !hasRoom)
                  ? null
                  : () {
                      final bill = repo.createRoomFolioBill(
                        outletId: _selectedOutletId ?? 'outlet-1',
                        outletName: repo.activeBranchOutlets.where((o) => o.id == _selectedOutletId).firstOrNull?.name ?? 'In-Room Dining',
                        roomNumber: _selectedRoomNumber!,
                        deliverySteward: _deliverySteward,
                        items: _cart,
                        subtotal: subtotal,
                        taxAmount: tax,
                        totalAmount: total,
                      );

                      if (bill != null) {
                        setState(() => _cart.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ₹${total.toStringAsFixed(0)} successfully posted to Room ${bill.roomNumber} Master Folio (${bill.guestName})!'),
                            backgroundColor: const Color(0xFF27AE60),
                          ),
                        );

                        // Show Printable Voucher
                        PrintPreviewDialog.show(
                          context,
                          title: 'In-Room Dining Voucher — Room ${bill.roomNumber}',
                          content: _buildRoomFolioBillDoc(repo, bill, currency),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2980B9),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.post_add_rounded, size: 14),
              label: const Text('POST TO ROOM FOLIO & PRINT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Action Buttons: Hall Bookings ──────────────────────────────────────────
  Widget _buildHallBookingActionButtons(
    HotelRepository repo,
    NumberFormat currency,
    List<BanquetHallModel> banquetHalls,
    double cartSubtotal,
    double hallRent,
    double hallTax,
    double grandTotal,
    double advancePaid,
  ) {
    final hall = banquetHalls.where((h) => h.id == _selectedHallId).firstOrNull;

    return SizedBox(
      height: 30,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (hall == null || _hallEventNameController.text.isEmpty || _hallHostNameController.text.isEmpty)
            ? null
            : () {
                final bill = repo.createHallBookingBill(
                  outletId: _selectedOutletId ?? 'banq-outlet-01',
                  outletName: 'Banquet & Events Department',
                  hallName: hall.name,
                  eventName: _hallEventNameController.text.trim(),
                  hostName: _hallHostNameController.text.trim(),
                  hostPhone: _hallHostPhoneController.text.trim(),
                  eventSlot: _hallSlot,
                  paxCount: _hallPaxCount,
                  hallRentAmount: hallRent,
                  cateringAmount: cartSubtotal,
                  taxAmount: hallTax,
                  advancePaid: advancePaid,
                  paymentMethod: _hallPaymentMode,
                  items: _cart,
                );

                setState(() => _cart.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🏛️ Banquet Booking Confirmed for ${bill.hallName}! Advance: ₹${advancePaid.toStringAsFixed(0)}'),
                    backgroundColor: const Color(0xFF6C3483),
                  ),
                );

                PrintPreviewDialog.show(
                  context,
                  title: 'Banquet Booking Tax Invoice — ${bill.hallName}',
                  content: _buildBanquetHallBillDoc(repo, bill, currency),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C3483),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        icon: const Icon(Icons.receipt_long_rounded, size: 14),
        label: const Text('CONFIRM BOOKING & PRINT BANQUET INVOICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Table Dining Settlement Modal Dialog ───────────────────────────────────
  void _showTableDiningSettlementModal(
    HotelRepository repo,
    NumberFormat currency,
    double subtotal,
    double tax,
    double total,
  ) {
    String paymentMethod = 'Cash';
    final tenderedCtrl = TextEditingController(text: total.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final tendered = double.tryParse(tenderedCtrl.text) ?? total;
          final changeDue = (tendered - total).clamp(0.0, double.infinity);

          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: ClassicErpTheme.dialogBg,
                border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Bar
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF1B4F72),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Settle Bill — $_tableNumber (Covers: $_tableCovers)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Card
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: const Color(0xFFD4E6F1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total Payable (Inc GST):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                currency.format(total),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Payment Method Selection
                        const Text('Select Settlement Payment Method:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: ['Cash', 'Credit / Debit Card', 'UPI / QR Code', 'Complimentary'].map((m) {
                            final isSel = paymentMethod == m;
                            return Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => paymentMethod = m),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF1B4F72) : Colors.white,
                                    border: Border.all(color: isSel ? const Color(0xFF1B4F72) : ClassicErpTheme.borderDark),
                                  ),
                                  child: Text(
                                    m,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.white : ClassicErpTheme.textMain,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // Cash Tendered & Change
                        if (paymentMethod == 'Cash') ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: ClassicErpInput(
                                  label: 'Amount Tendered (₹)',
                                  controller: tenderedCtrl,
                                  isNumeric: true,
                                  height: 28,
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Return Change (₹)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                                    const SizedBox(height: 3),
                                    Container(
                                      height: 28,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAFAF1),
                                        borderRadius: BorderRadius.circular(2),
                                        border: Border.all(color: const Color(0xFF27AE60), width: 1),
                                      ),
                                      child: Text(
                                        currency.format(changeDue),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Dialog Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel', style: TextStyle(fontSize: 10.5)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F72),
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                final bill = repo.createTableDiningBill(
                                  outletId: _selectedOutletId ?? 'outlet-1',
                                  outletName: repo.activeBranchOutlets.where((o) => o.id == _selectedOutletId).firstOrNull?.name ?? 'The Royal Bistro',
                                  tableNumber: _tableNumber,
                                  covers: _tableCovers,
                                  waiterName: _selectedWaiter,
                                  items: _cart,
                                  subtotal: subtotal,
                                  taxAmount: tax,
                                  totalAmount: total,
                                  paymentMethod: paymentMethod,
                                );

                                setState(() => _cart.clear());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Bill ${bill.billNumber} settled for $_tableNumber! (Paid via $paymentMethod)'),
                                    backgroundColor: const Color(0xFF27AE60),
                                  ),
                                );

                                PrintPreviewDialog.show(
                                  context,
                                  title: 'Restaurant Bill — ${bill.tableNumber}',
                                  content: _buildTableDiningBillDoc(repo, bill, currency),
                                );
                              },
                              child: const Text('Confirm Settle & Print', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 3.5. LIVE RUNNING TABLES & KITCHEN KOTS STREAM (REAL-TIME MOBILE SYNC)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildLiveTablesAndKotsView(HotelRepository repo, NumberFormat currency) {
    final activeOrders = repo.posOrders
        .where((o) => o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled)
        .toList();

    final tableList = List.generate(16, (i) => 'T-${(i + 1).toString().padLeft(2, "0")}');
    final occupiedCount = tableList.where((t) => activeOrders.any((o) => o.tableNumber == t)).length;
    final vacantCount = tableList.length - occupiedCount;
    final totalRunningSales = activeOrders.fold(0.0, (sum, o) => sum + o.total);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: Interactive Restaurant Floor & Table Grid ─────────────────
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Metrics Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
                ),
                child: Row(
                  children: [
                    _metricPill('🔴 OCCUPIED TABLES', '$occupiedCount / 16', const Color(0xFFC0392B)),
                    const SizedBox(width: 12),
                    _metricPill('🟢 VACANT READY', '$vacantCount', const Color(0xFF27AE60)),
                    const SizedBox(width: 12),
                    _metricPill('💰 RUNNING SALES', currency.format(totalRunningSales), const Color(0xFF2980B9)),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4F72),
                        side: const BorderSide(color: Color(0xFF1B4F72)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Refresh Tables', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 16 Tables Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 165,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: tableList.length,
                  itemBuilder: (context, index) {
                    final tableNo = tableList[index];
                    final order = activeOrders.where((o) => o.tableNumber == tableNo).firstOrNull;
                    final isOccupied = order != null;

                    if (isOccupied) {
                      final elapsed = DateTime.now().difference(order.createdAt).inMinutes;
                      final guestName = order.guestName ?? '';
                      final isBirthday = guestName.contains('🎂') ||
                          (guestName.toLowerCase().contains('sharma') && DateTime.now().month == 9);

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEDEC),
                          border: Border.all(color: const Color(0xFFE74C3C), width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE74C3C).withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: const Color(0xFFC0392B),
                              child: Row(
                                children: [
                                  Text(
                                    'TABLE $tableNo',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isBirthday)
                                    const Text('🎂', style: TextStyle(fontSize: 11)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '${elapsed}m ago',
                                      style: const TextStyle(color: Color(0xFFC0392B), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Guest & Order Info
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guestName.isEmpty ? 'Walk-in Guests' : guestName,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${order.items.length} items (${order.items.fold(0, (s, i) => s + i.quantity)} qty)',
                                    style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currency.format(order.total),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Actions Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFADBD8),
                                border: Border(top: BorderSide(color: Color(0xFFF5B7B1))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF27AE60),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                      ),
                                      onPressed: () => _showTableSettleDialog(context, repo, order, currency),
                                      child: const Text('Settle Bill', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF1B4F72)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Print Kitchen KOT',
                                    onPressed: () {
                                      PrintPreviewDialog.show(
                                        context,
                                        title: 'KITCHEN ORDER TICKET • $tableNo',
                                        content: _buildKotDoc(repo, 'Table $tableNo', 'Table Dining', order.items),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Vacant Table
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFA),
                          border: Border.all(color: const Color(0xFFD5D8DC), width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: const Color(0xFFEAEDED),
                              child: Row(
                                children: [
                                  Text(
                                    'TABLE $tableNo',
                                    style: const TextStyle(color: ClassicErpTheme.textMain, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4EFDF),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'VACANT',
                                      style: TextStyle(color: Color(0xFF1E8449), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.table_restaurant_outlined, size: 28, color: Color(0xFFBDC3C7)),
                                    SizedBox(height: 4),
                                    Text('Ready for Guests', style: TextStyle(fontSize: 10, color: Color(0xFF7F8C8D))),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF1B4F72)),
                                  foregroundColor: const Color(0xFF1B4F72),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _tableNumber = tableNo;
                                    _activeBillingStream = PosBillingType.tableDining;
                                    _currentViewIndex = 0; // Switch to punch terminal
                                  });
                                },
                                child: const Text('Seat & Punch KOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Right: Live Kitchen KOT Feed (Punched by Waiter Phones) ─────────
        Container(
          width: 380,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9F9),
            border: Border(left: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stream Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: const Color(0xFF1B4F72),
                child: Row(
                  children: [
                    const Icon(Icons.soup_kitchen_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'KITCHEN KOT STREAM (${activeOrders.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('LIVE SYNC ⚡', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Active KOT Tickets List
              Expanded(
                child: activeOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 40, color: Color(0xFF27AE60)),
                            SizedBox(height: 8),
                            Text('Kitchen is all clear!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ClassicErpTheme.textMain)),
                            SizedBox(height: 4),
                            Text('Incoming orders from Waiter Mobile Apps\nwill appear here in real time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: activeOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final order = activeOrders[idx];
                          final elapsed = DateTime.now().difference(order.createdAt).inMinutes;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFBDC3C7)),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // KOT Card Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEAEDED),
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        order.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF1B4F72)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Table ${order.tableNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFFC0392B)),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${elapsed}m ago',
                                        style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),

                                // Guest & Waiter info
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    order.guestName ?? 'Walk-in Guests',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                                  ),
                                ),

                                const Divider(height: 1, color: ClassicErpTheme.borderLight),

                                // Items Table
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: order.items.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEBF5FB),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                '${item.quantity}x',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2980B9)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain),
                                              ),
                                            ),
                                            Text(
                                              currency.format(item.price * item.quantity),
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                // Bottom Actions
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8F9F9),
                                    border: Border(top: BorderSide(color: ClassicErpTheme.borderLight)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Total: ${currency.format(order.total)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                                      ),
                                      const Spacer(),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          side: const BorderSide(color: Color(0xFF1B4F72)),
                                          foregroundColor: const Color(0xFF1B4F72),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                        ),
                                        onPressed: () {
                                          PrintPreviewDialog.show(
                                            context,
                                            title: 'KITCHEN ORDER TICKET • Table ${order.tableNumber}',
                                            content: _buildKotDoc(repo, 'Table ${order.tableNumber}', 'Table Dining', order.items),
                                          );
                                        },
                                        child: const Text('Print Slip', style: TextStyle(fontSize: 9.5)),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          backgroundColor: const Color(0xFF27AE60),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                        ),
                                        onPressed: () => _showTableSettleDialog(context, repo, order, currency),
                                        child: const Text('Settle', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ── Table Settle Dialog ───────────────────────────────────────────────────
  void _showTableSettleDialog(BuildContext context, HotelRepository repo, PosOrderModel order, NumberFormat currency) {
    String paymentMethod = 'Cash';
    double discount = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final discountedSubtotal = (order.subtotal - discount).clamp(0.0, double.infinity);
            final taxAmt = discountedSubtotal * 0.05;
            final grandTotal = discountedSubtotal + taxAmt;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              child: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: const Color(0xFF1B4F72),
                      child: Row(
                        children: [
                          const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'SETTLE TABLE ${order.tableNumber} • ${order.orderNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Guest: ${order.guestName ?? "Walk-in Guests"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: ClassicErpTheme.borderDark),
                              color: const Color(0xFFFBFCFC),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(6),
                              itemCount: order.items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final item = order.items[i];
                                return Row(
                                  children: [
                                    Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    Expanded(child: Text(item.name, style: const TextStyle(fontSize: 11))),
                                    Text(currency.format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Discount Selection
                          const Text('Discount:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('None (0%)', style: TextStyle(fontSize: 10)),
                                selected: discount == 0.0,
                                onSelected: (_) => setDialogState(() => discount = 0.0),
                              ),
                              ChoiceChip(
                                label: const Text('5% Food', style: TextStyle(fontSize: 10)),
                                selected: discount == order.subtotal * 0.05,
                                onSelected: (_) => setDialogState(() => discount = order.subtotal * 0.05),
                              ),
                              ChoiceChip(
                                label: const Text('10% Birthday 🎂', style: TextStyle(fontSize: 10)),
                                selected: discount == order.subtotal * 0.10,
                                onSelected: (_) => setDialogState(() => discount = order.subtotal * 0.10),
                              ),
                              ChoiceChip(
                                label: const Text('Flat ₹100', style: TextStyle(fontSize: 10)),
                                selected: discount == 100.0,
                                onSelected: (_) => setDialogState(() => discount = 100.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Payment Method
                          const Text('Payment Method:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: paymentMethod,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Cash', child: Text('💵 Cash')),
                              DropdownMenuItem(value: 'UPI QR', child: Text('📱 UPI QR / Dynamic Intent')),
                              DropdownMenuItem(value: 'Card', child: Text('💳 Credit / Debit Card')),
                              DropdownMenuItem(value: 'Room Folio', child: Text('🛎️ Charge to Room Master Folio')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => paymentMethod = val);
                            },
                          ),
                          const SizedBox(height: 10),

                          // Calculations summary
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2F8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:', style: TextStyle(fontSize: 10.5)),
                                    Text(currency.format(order.subtotal), style: const TextStyle(fontSize: 10.5)),
                                  ],
                                ),
                                if (discount > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Discount:', style: TextStyle(fontSize: 10.5, color: Color(0xFF27AE60))),
                                      Text('- ${currency.format(discount)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF27AE60))),
                                    ],
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('GST (CGST 2.5% + SGST 2.5%):', style: TextStyle(fontSize: 10.5)),
                                    Text(currency.format(taxAmt), style: const TextStyle(fontSize: 10.5)),
                                  ],
                                ),
                                const Divider(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('GRAND TOTAL PAYABLE:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                    Text(currency.format(grandTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAEDED),
                        border: Border(top: BorderSide(color: ClassicErpTheme.borderDark)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(fontSize: 10.5)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Finalize Settle & Print Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              repo.settleWaiterTableOrder(
                                orderId: order.id,
                                paymentMethod: paymentMethod,
                                discount: discount,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Table ${order.tableNumber} bill settled successfully! Reflected in Bill Register & Invoices.'),
                                  backgroundColor: const Color(0xFF27AE60),
                                ),
                              );
                              final recentBill = repo.activeBranchPosBills.firstOrNull;
                              if (recentBill != null) {
                                PrintPreviewDialog.show(
                                  context,
                                  title: 'GST TAX INVOICE • Table ${order.tableNumber}',
                                  content: _buildTableDiningBillDoc(repo, recentBill, currency),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Mobile Device Pairing & LAN Sync Dialog ───────────────────────────────
  void _showLanPairingDialog(BuildContext context, HotelRepository repo) {
    final serverIp = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
    final serverPort = HotelSyncBridgeService.instance.serverPort;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          title: const Row(
            children: [
              Icon(Icons.wifi_tethering_rounded, color: Color(0xFF1B4F72)),
              SizedBox(width: 8),
              Text('Mobile Apps & Windows ERP Live Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Android mobile apps (Waiter POS, Delivery, Housekeeping, Manager) reflect live data to this Windows ERP Software.',
                  style: TextStyle(fontSize: 11.5, color: ClassicErpTheme.textMain),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    border: Border.all(color: const Color(0xFF2ECC71)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Color(0xFF27AE60)),
                          SizedBox(width: 6),
                          Text('Local Hotel Wi-Fi Sync Server: ONLINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E8449))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Server Host IP: http://$serverIp:$serverPort', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B4F72))),
                      const SizedBox(height: 4),
                      const Text('Port: 8088 • Protocol: HTTP REST & Server-Sent Events', style: TextStyle(fontSize: 10, color: Color(0xFF2C3E50))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: Color(0xFF1E8449)),
                            SizedBox(width: 5),
                            Text(
                              'Security Shield Active: Encrypted Token Authorization Enforced',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E8449)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('How to Pair Android Mobile Devices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                const SizedBox(height: 6),
                const Text('1. Connect Android phones/tablets to the same Hotel Wi-Fi network.', style: TextStyle(fontSize: 10.5)),
                const SizedBox(height: 3),
                Text('2. Open Waiter POS, Delivery, or Housekeeping app.', style: const TextStyle(fontSize: 10.5)),
                const SizedBox(height: 3),
                Text('3. Tap the green Sync icon in the app bar and confirm host: $serverIp', style: const TextStyle(fontSize: 10.5)),
                const SizedBox(height: 3),
                const Text('4. Punched orders and room cleanings will appear on this Windows PC immediately!', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E8449))),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(fontSize: 11)),
            ),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 4. BILL REGISTER & INVOICES VIEW (SEPARATE HISTORY FOR ALL BILLS)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildBillRegisterView(HotelRepository repo, NumberFormat currency) {
    final allBills = repo.activeBranchPosBills;
    final tableBills = repo.tableDiningBills;
    final roomBills = repo.roomFolioBills;
    final hallBills = repo.hallBookingBills;

    List<PosBillRecord> displayedBills;
    switch (_registerFilter) {
      case 'table_dining':
        displayedBills = tableBills;
        break;
      case 'room_folio':
        displayedBills = roomBills;
        break;
      case 'hall_booking':
        displayedBills = hallBills;
        break;
      default:
        displayedBills = allBills;
    }

    if (_registerSearchController.text.trim().isNotEmpty) {
      final q = _registerSearchController.text.trim().toLowerCase();
      displayedBills = displayedBills.where((b) {
        return b.billNumber.toLowerCase().contains(q) ||
            (b.tableNumber != null && b.tableNumber!.toLowerCase().contains(q)) ||
            (b.roomNumber != null && b.roomNumber!.toLowerCase().contains(q)) ||
            (b.hallName != null && b.hallName!.toLowerCase().contains(q)) ||
            (b.guestName != null && b.guestName!.toLowerCase().contains(q)) ||
            (b.hostName != null && b.hostName!.toLowerCase().contains(q));
      }).toList();
    }

    return Column(
      children: [
        // Filter Sub-Ribbon
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: Color(0xFFEAEDED),
            border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
          ),
          child: Row(
            children: [
              _registerFilterChip('All Invoices (${allBills.length})', 'all'),
              const SizedBox(width: 4),
              _registerFilterChip('🍽️ Table Dining (${tableBills.length})', 'table_dining'),
              const SizedBox(width: 4),
              _registerFilterChip('🛎️ Room Folio (${roomBills.length})', 'room_folio'),
              const SizedBox(width: 4),
              _registerFilterChip('🏛️ Hall Bookings (${hallBills.length})', 'hall_booking'),

              const Spacer(),

              // Search Box
              ClassicErpSearchField(
                controller: _registerSearchController,
                hintText: 'Search Bill #, Room, Table, Host...',
                width: 240,
                height: 26,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // Spreadsheet Table Header
        Container(
          height: 24,
          color: ClassicErpTheme.gridHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Row(
            children: [
              SizedBox(width: 125, child: Text('BILL NO', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              SizedBox(width: 105, child: Text('DATE & TIME', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              SizedBox(width: 125, child: Text('BILLING STREAM', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              SizedBox(width: 135, child: Text('DESTINATION', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              Expanded(child: Text('CUSTOMER / HOST / SERVER', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              SizedBox(width: 90, child: Text('SUBTOTAL', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              SizedBox(width: 75, child: Text('GST TAX', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              SizedBox(width: 95, child: Text('NET TOTAL', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              SizedBox(width: 110, child: Center(child: Text('STATUS', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)))),
              SizedBox(width: 80, child: Center(child: Text('ACTION', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),

        // Spreadsheet Rows
        Expanded(
          child: displayedBills.isEmpty
              ? const Center(
                  child: Text('No POS bills found for the selected category.', style: TextStyle(color: ClassicErpTheme.textMuted)),
                )
              : ListView.builder(
                  itemCount: displayedBills.length,
                  itemBuilder: (context, index) {
                    final bill = displayedBills[index];
                    final isEven = index % 2 == 0;

                    String destination;
                    String customer;
                    Color streamBadgeColor;

                    switch (bill.billingType) {
                      case PosBillingType.tableDining:
                        destination = bill.tableNumber ?? 'Dine-In Table';
                        customer = 'Waiter: ${bill.waiterName ?? "General"} (${bill.covers ?? 1} Covers)';
                        streamBadgeColor = const Color(0xFF1B4F72);
                        break;
                      case PosBillingType.roomFolio:
                        destination = 'Room ${bill.roomNumber ?? "-"}';
                        customer = 'Guest: ${bill.guestName ?? "In-House"}';
                        streamBadgeColor = const Color(0xFF2980B9);
                        break;
                      case PosBillingType.hallBooking:
                        destination = bill.hallName ?? 'Banquet Hall';
                        customer = 'Host: ${bill.hostName ?? "Event Organizer"} (${bill.paxCount ?? 0} Pax)';
                        streamBadgeColor = const Color(0xFF6C3483);
                        break;
                    }

                    Color statusBg;
                    String statusLabel;
                    if (bill.paymentStatus == 'paid') {
                      statusBg = const Color(0xFF27AE60);
                      statusLabel = 'PAID & SETTLED';
                    } else if (bill.paymentStatus == 'posted_to_folio') {
                      statusBg = const Color(0xFF2980B9);
                      statusLabel = 'POSTED TO FOLIO';
                    } else {
                      statusBg = const Color(0xFFD35400);
                      statusLabel = 'ADVANCE RECEIVED';
                    }

                    return Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF7F9F9),
                        border: const Border(bottom: BorderSide(color: Color(0xFFEAEDED), width: 0.8)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 125,
                            child: Text(
                              bill.billNumber,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                            ),
                          ),
                          SizedBox(
                            width: 105,
                            child: Text(
                              DateFormat('dd-MMM HH:mm').format(bill.createdAt),
                              style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
                            ),
                          ),
                          SizedBox(
                            width: 125,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: streamBadgeColor.withValues(alpha: 0.1)),
                                  child: Text(
                                    '${bill.billingType.iconEmoji} ${bill.billingType.label}',
                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: streamBadgeColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 135,
                            child: Text(
                              destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              customer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMain),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(currency.format(bill.subtotal), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right),
                          ),
                          SizedBox(
                            width: 75,
                            child: Text(currency.format(bill.taxAmount), style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted), textAlign: TextAlign.right),
                          ),
                          SizedBox(
                            width: 95,
                            child: Text(
                              currency.format(bill.totalAmount),
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(2)),
                                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: InkWell(
                                onTap: () => _showBillInvoicePreview(context, repo, bill, currency),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFF1B4F72), width: 1),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.print_rounded, size: 10, color: Color(0xFF1B4F72)),
                                      SizedBox(width: 2),
                                      Text('View', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _registerFilterChip(String label, String code) {
    final isSelected = _registerFilter == code;
    return InkWell(
      onTap: () => setState(() => _registerFilter = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.borderDark, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 5. PRINTABLE INVOICE DOCUMENTS
  // ═════════════════════════════════════════════════════════════════════════════
  void _showBillInvoicePreview(
    BuildContext context,
    HotelRepository repo,
    PosBillRecord bill,
    NumberFormat currency,
  ) {
    Widget doc;
    String title;

    switch (bill.billingType) {
      case PosBillingType.tableDining:
        title = 'Tax Invoice — ${bill.billNumber} (${bill.tableNumber ?? "Table"})';
        doc = _buildTableDiningBillDoc(repo, bill, currency);
        break;
      case PosBillingType.roomFolio:
        title = 'In-Room Dining Voucher — ${bill.billNumber} (Room ${bill.roomNumber ?? ""})';
        doc = _buildRoomFolioBillDoc(repo, bill, currency);
        break;
      case PosBillingType.hallBooking:
        title = 'Banquet Tax Invoice — ${bill.billNumber} (${bill.hallName ?? "Hall"})';
        doc = _buildBanquetHallBillDoc(repo, bill, currency);
        break;
    }

    PrintPreviewDialog.show(context, title: title, content: doc);
  }

  // Document 1: Table Dining Tax Invoice
  Widget _buildTableDiningBillDoc(HotelRepository repo, PosBillRecord bill, NumberFormat currency) {
    final dateStr = DateFormat('dd MMM yyyy  HH:mm').format(bill.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHotelHeader(repo),
        const Divider(thickness: 1.5, color: Color(0xFF1B4F72), height: 16),
        const Center(
          child: Text(
            'TAX INVOICE — RESTAURANT DINE-IN BILL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice #: ${bill.billNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Date: $dateStr', style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Table: ${bill.tableNumber ?? "Table"} • Covers: ${bill.covers ?? 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
            Text('Steward: ${bill.waiterName ?? "General"}', style: const TextStyle(fontSize: 9.5)),
          ],
        ),
        const SizedBox(height: 10),

        _buildItemsTable(bill.items, currency),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 10)),
            Text(currency.format(bill.subtotal), style: const TextStyle(fontSize: 10)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('F&B GST (${repo.foodGstRate.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 10)),
            Text(currency.format(bill.taxAmount), style: const TextStyle(fontSize: 10)),
          ],
        ),
        const Divider(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('NET AMOUNT PAID:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
            Text(currency.format(bill.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72))),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Settled via: ${bill.paymentMethod}', style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic)),
            const Text('[ PAID IN FULL ]', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(),
        const Center(
          child: Text('Thank You for Dining with Us! Please Visit Again.',
              style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: ClassicErpTheme.textMuted)),
        ),
      ],
    );
  }

  // Document 2: Room Folio Voucher
  Widget _buildRoomFolioBillDoc(HotelRepository repo, PosBillRecord bill, NumberFormat currency) {
    final dateStr = DateFormat('dd MMM yyyy  HH:mm').format(bill.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHotelHeader(repo),
        const Divider(thickness: 1.5, color: Color(0xFF2980B9), height: 16),
        const Center(
          child: Text(
            'IN-ROOM DINING SERVICE VOUCHER',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF2980B9)),
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Voucher #: ${bill.billNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Date: $dateStr', style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Room Number: ${bill.roomNumber ?? "-"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2980B9))),
            Text('Guest Name: ${bill.guestName ?? "In-House Guest"}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Delivered By: ${bill.deliverySteward ?? "Room Service"}', style: const TextStyle(fontSize: 9.5)),
            Text('Folio ID: ${bill.folioId ?? "-"}', style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 10),

        _buildItemsTable(bill.items, currency),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Room Service Subtotal:', style: TextStyle(fontSize: 10)),
            Text(currency.format(bill.subtotal), style: const TextStyle(fontSize: 10)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('F&B GST (${repo.foodGstRate.toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 10)),
            Text(currency.format(bill.taxAmount), style: const TextStyle(fontSize: 10)),
          ],
        ),
        const Divider(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL POSTED TO FOLIO:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2980B9))),
            Text(currency.format(bill.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2980B9))),
          ],
        ),
        const SizedBox(height: 14),

        // Guest Signature Acknowledgment Box
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acknowledgment: I confirm receipt of the above food & beverage items and authorize the amount to be charged to my Room Master Folio.',
                style: TextStyle(fontSize: 8.5, fontStyle: FontStyle.italic, color: ClassicErpTheme.textMuted),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Steward Signature: _______________', style: TextStyle(fontSize: 9)),
                  Text('Guest Signature: _______________________', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Document 3: Banquet & Hall Booking Tax Invoice
  Widget _buildBanquetHallBillDoc(HotelRepository repo, PosBillRecord bill, NumberFormat currency) {
    final dateStr = DateFormat('dd MMM yyyy  HH:mm').format(bill.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHotelHeader(repo),
        const Divider(thickness: 1.5, color: Color(0xFF6C3483), height: 16),
        const Center(
          child: Text(
            'TAX INVOICE — BANQUET HALL & EVENT CATERING',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF6C3483)),
          ),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice #: ${bill.billNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Date: $dateStr', style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hall: ${bill.hallName ?? "Banquet Hall"}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6C3483))),
            Text('Slot: ${bill.eventSlot ?? "Evening"}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Event: ${bill.eventName ?? "-"}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('Expected Pax: ${bill.paxCount ?? 0} Guests', style: const TextStyle(fontSize: 9.5)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Host / Client: ${bill.hostName ?? "-"}', style: const TextStyle(fontSize: 9.5)),
            Text('Phone: ${bill.hostPhone ?? "-"}', style: const TextStyle(fontSize: 9.5)),
          ],
        ),
        const SizedBox(height: 10),

        _buildItemsTable(bill.items, currency),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hall Hire / Venue Rental:', style: TextStyle(fontSize: 10)),
            Text(currency.format(bill.hallRentAmount ?? 0.0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('F&B Catering Subtotal:', style: TextStyle(fontSize: 10)),
            Text(currency.format(bill.cateringAmount ?? 0.0), style: const TextStyle(fontSize: 10)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GST (18% Venue + 5% F&B Catering):', style: TextStyle(fontSize: 10)),
            Text(currency.format(bill.taxAmount), style: const TextStyle(fontSize: 10)),
          ],
        ),
        const Divider(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL BANQUET CHARGE:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF6C3483))),
            Text(currency.format(bill.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF6C3483))),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Advance Deposit Paid (${bill.paymentMethod}):', style: const TextStyle(fontSize: 10, color: Color(0xFF27AE60))),
            Text(currency.format(bill.advancePaid ?? 0.0), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BALANCE PAYABLE AT FUNCTION:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
            Text(currency.format(bill.balanceDue ?? 0.0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 14),

        // Signatures
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Banquet Sales Manager: _______________', style: TextStyle(fontSize: 9)),
              Text('Host / Authorized Signatory: _______________', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: Hotel Header for Printable Bills
  Widget _buildHotelHeader(HotelRepository repo) {
    return Center(
      child: Column(
        children: [
          HotelLogoWidget(repo: repo, width: 44, height: 44),
          const SizedBox(height: 4),
          Text(
            repo.clientBusinessName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B4F72)),
          ),
          Text(
            '${repo.activeBranch.name} • ${repo.activeBranch.city}',
            style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
          ),
          Text(
            'GSTIN: ${repo.activeBranch.taxIdentifier} | Phone: ${repo.activeBranch.phone}',
            style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMain),
          ),
        ],
      ),
    );
  }

  // Helper: Items Table for Invoices
  Widget _buildItemsTable(List<PosOrderItem> items, NumberFormat currency) {
    return Table(
      border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(40),
        2: FixedColumnWidth(65),
        3: FixedColumnWidth(70),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFF1B4F72)),
          children: [
            Padding(padding: EdgeInsets.all(4), child: Text('ITEM / SERVICE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(4), child: Text('QTY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Padding(padding: EdgeInsets.all(4), child: Text('RATE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            Padding(padding: EdgeInsets.all(4), child: Text('AMOUNT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ],
        ),
        ...items.map((item) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(4), child: Text(item.name, style: const TextStyle(fontSize: 9))),
                Padding(padding: const EdgeInsets.all(4), child: Text('${item.quantity}', style: const TextStyle(fontSize: 9), textAlign: TextAlign.center)),
                Padding(padding: const EdgeInsets.all(4), child: Text(currency.format(item.price), style: const TextStyle(fontSize: 9), textAlign: TextAlign.right)),
                Padding(padding: const EdgeInsets.all(4), child: Text(currency.format(item.subtotal), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            )),
      ],
    );
  }

  // Helper: Kitchen Order Ticket (KOT)
  Widget _buildKotDoc(HotelRepository repo, String destination, String stream, List<PosOrderItem> items) {
    final now = DateFormat('dd MMM yyyy  HH:mm').format(DateTime.now());
    final kotNo = 'KOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text('KITCHEN ORDER TICKET (KOT) — $kotNo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ),
        Text('Dispatch Time: $now', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        Text('Stream: $stream • Destination: $destination', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
        const Divider(thickness: 1.5),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text('${item.quantity}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            )),
        const Divider(),
        const Center(
          child: Text('Chef Dispatch Copy • Send immediately to Executive Kitchen', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ── Menu Tile ──────────────────────────────────────────────────────────────
  Widget _buildClassicMenuTile(PosMenuItemModel item, NumberFormat currency) {
    return InkWell(
      onTap: () {
        setState(() {
          final existing = _cart.where((i) => i.menuItemId == item.id).firstOrNull;
          if (existing != null) {
            existing.quantity++;
          } else {
            _cart.add(PosOrderItem(
              menuItemId: item.id,
              name: item.name,
              price: item.price,
              quantity: 1,
              taxRate: 5.0, // 5% F&B GST
            ));
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 1)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.isVeg ? const Color(0xFF27AE60) : const Color(0xFFC0392B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(fontSize: 8, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
            ),
            const Spacer(),
            Text(
              currency.format(item.price),
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
            ),
          ],
        ),
      ),
    );
  }
}
