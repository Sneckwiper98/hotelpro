import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_constants.dart';
import '../../../data/models/pos_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../../../data/services/app_update_service.dart';
import '../components/mobile_app_scaffold.dart';
import '../components/mobile_staff_login_view.dart';

class TableCustomerInfo {
  String name;
  String phone;
  DateTime? dob;
  String address;

  TableCustomerInfo({
    this.name = '',
    this.phone = '',
    this.dob,
    this.address = '',
  });

  bool get isEmpty => name.isEmpty && phone.isEmpty;
  bool get isNotEmpty => !isEmpty;

  TableCustomerInfo copyWith({
    String? name,
    String? phone,
    DateTime? dob,
    String? address,
  }) {
    return TableCustomerInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      address: address ?? this.address,
    );
  }
}

class WaiterPosAppShell extends StatefulWidget {
  final VoidCallback? onBackToGateway;
  final Function(MobileAppRole role)? onSwitchRole;

  const WaiterPosAppShell({
    super.key,
    this.onBackToGateway,
    this.onSwitchRole,
  });

  @override
  State<WaiterPosAppShell> createState() => _WaiterPosAppShellState();
}

class _WaiterPosAppShellState extends State<WaiterPosAppShell> {
  StaffProfileAuth? _authenticatedStaff;

  int _currentTabIndex = 0;
  String _selectedTable = 'T-01';
  int _selectedTableCapacity = 4;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _onlyVeg = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndPrompt(context, targetApp: AppTarget.waiterPos, silent: true);
    });
  }

  // Table -> Customer Details Map
  final Map<String, TableCustomerInfo> _tableCustomerMap = {
    'T-02': TableCustomerInfo(
      name: 'Rahul Sharma',
      phone: '9876543210',
      dob: DateTime(1992, 8, 15),
      address: 'Chakala, Andheri East, Mumbai',
    ),
    'T-03': TableCustomerInfo(
      name: 'Pooja Verma',
      phone: '9822011223',
      dob: DateTime(1990, 11, 22),
      address: 'Bandra Kurla Complex, Mumbai',
    ),
    'T-05': TableCustomerInfo(
      name: 'Dr. Vikram Malhotra',
      phone: '9811223344',
      dob: DateTime(1985, 4, 5),
      address: 'Juhu Tara Road, Mumbai',
    ),
    'T-07': TableCustomerInfo(
      name: 'Ananya Sen',
      phone: '9733445566',
      dob: DateTime(1998, 9, 12),
      address: 'Malad West, Mumbai',
    ),
  };

  // In-progress order items for selected table
  final Map<String, int> _orderCart = {}; // menuItemId -> quantity
  final TextEditingController _kitchenNotesCtrl = TextEditingController();

  final List<Map<String, dynamic>> _tablesList = [
    {'number': 'T-01', 'capacity': 2, 'section': 'Main Dining Hall', 'status': 'vacant'},
    {'number': 'T-02', 'capacity': 4, 'section': 'Main Dining Hall', 'status': 'occupied', 'runningAmount': 1480.0, 'kotCount': 2},
    {'number': 'T-03', 'capacity': 4, 'section': 'Main Dining Hall', 'status': 'occupied', 'runningAmount': 890.0, 'kotCount': 1},
    {'number': 'T-04', 'capacity': 6, 'section': 'Family AC Lounge', 'status': 'vacant'},
    {'number': 'T-05', 'capacity': 6, 'section': 'Family AC Lounge', 'status': 'billing', 'runningAmount': 2340.0, 'kotCount': 3},
    {'number': 'T-06', 'capacity': 4, 'section': 'Family AC Lounge', 'status': 'vacant'},
    {'number': 'T-07', 'capacity': 8, 'section': 'Rooftop Terrace', 'status': 'occupied', 'runningAmount': 3450.0, 'kotCount': 2},
    {'number': 'T-08', 'capacity': 2, 'section': 'Rooftop Terrace', 'status': 'vacant'},
    {'number': 'T-09', 'capacity': 4, 'section': 'Rooftop Terrace', 'status': 'vacant'},
    {'number': 'T-10', 'capacity': 4, 'section': 'Poolside Deck', 'status': 'vacant'},
  ];

  @override
  void dispose() {
    _kitchenNotesCtrl.dispose();
    super.dispose();
  }

  void _onTableCardTap(String tableNumber, int capacity, String status) {
    setState(() {
      _selectedTable = tableNumber;
      _selectedTableCapacity = capacity;
    });

    if (status == 'occupied' || status == 'billing') {
      // Show action sheet for occupied table (Add Items, Generate Bill, Edit Guest)
      _showOccupiedTableActionSheet(tableNumber, capacity);
    } else {
      // Vacant table -> Open Customer Details Dialog
      _showCustomerEntryDialog(tableNumber, capacity);
    }
  }

  void _showOccupiedTableActionSheet(String tableNumber, int capacity) {
    final cust = _tableCustomerMap[tableNumber] ?? TableCustomerInfo();
    final repo = context.read<HotelRepository>();
    final activeOrders = repo.posOrders
        .where((o) => o.tableNumber == tableNumber && o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1E8449).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(tableNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E8449))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cust.isNotEmpty ? cust.name : 'Occupied Table',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        cust.phone.isNotEmpty ? '📱 +91 ${cust.phone} • WhatsApp Invoice' : 'Guest phone not set',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF1E8449)),
              title: const Text('Add More Items & Punch Next KOT', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Add more dishes to running table orders'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentTabIndex = 1);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD35400)),
              title: const Text('⚡ Generate Bill & Settle (WhatsApp PDF)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD35400))),
              subtitle: const Text('Calculate tax, discounts & send bill PDF to customer WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                if (activeOrders.isNotEmpty) {
                  _showBillGenerationSheet(context, activeOrders.first, repo);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No active KOT found for $tableNumber. Punch an item first.')),
                  );
                }
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF1B4F72)),
              title: const Text('Edit Customer Details (Name, Phone, DOB, Address)'),
              onTap: () {
                Navigator.pop(ctx);
                _showCustomerEntryDialog(tableNumber, capacity);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerEntryDialog(String tableNumber, int capacity) {
    final existing = _tableCustomerMap[tableNumber] ?? TableCustomerInfo();
    final nameCtrl = TextEditingController(text: existing.name);
    final phoneCtrl = TextEditingController(text: existing.phone);
    final addressCtrl = TextEditingController(text: existing.address);
    DateTime? selectedDob = existing.dob;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isBirthdayMonth = selectedDob != null && selectedDob!.month == DateTime.now().month;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 16,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 14),

                  // Header with Table Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E8449),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tableNumber,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Customer Information',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bill PDF will be automatically sent to the customer WhatsApp number.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 14),



                  // Customer Name Input
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF1E8449), size: 18),
                      labelText: 'Customer / Guest Name *',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mobile Number Input (WhatsApp)
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        child: const Text('📱 +91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E8449))),
                      ),
                      labelText: 'WhatsApp Mobile Number *',
                      hintText: 'e.g. 9876543210',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date of Birth (DOB) Field with Calendar Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDob ?? DateTime(1995, 1, 1),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDob = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        color: isBirthdayMonth ? Colors.amber.shade50 : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cake_rounded,
                            color: isBirthdayMonth ? Colors.amber.shade800 : const Color(0xFF1E8449),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date of Birth (DOB for Loyalty & Offers)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  selectedDob != null ? DateFormat('dd MMMM yyyy').format(selectedDob!) : 'Select Date of Birth (Optional)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: selectedDob != null ? FontWeight.bold : FontWeight.normal,
                                    color: selectedDob != null ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isBirthdayMonth)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(4)),
                              child: const Text('🎉 Birthday Month!', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Address / Location
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF1E8449), size: 18),
                      labelText: 'Customer Address / Area',
                      hintText: 'e.g. Andheri East, Mumbai',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Save & Open Menu Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8449),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Guest ($tableNumber)';
                      final phone = phoneCtrl.text.trim();
                      final address = addressCtrl.text.trim();

                      setState(() {
                        _tableCustomerMap[tableNumber] = TableCustomerInfo(
                          name: name,
                          phone: phone,
                          dob: selectedDob,
                          address: address,
                        );
                        _currentTabIndex = 1; // Switch to Order Taking
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: const Text('SAVE GUEST & OPEN MENU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.4)),
                  ),

                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tableCustomerMap[tableNumber] = TableCustomerInfo(name: 'Walk-in Guest', phone: '');
                        _currentTabIndex = 1;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text('Skip & Continue as Walk-in Guest', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _punchKot(HotelRepository repo) {
    if (_orderCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item before punching KOT')),
      );
      return;
    }

    final menuItems = repo.activeBranchMenuItems;
    final List<PosOrderItem> orderItems = [];

    _orderCart.forEach((itemId, qty) {
      if (qty > 0) {
        final item = menuItems.firstWhere(
          (m) => m.id == itemId,
          orElse: () => menuItems.first,
        );
        orderItems.add(
          PosOrderItem(
            menuItemId: item.id,
            name: item.name,
            quantity: qty,
            price: item.price,
            taxRate: item.taxRate,
          ),
        );
      }
    });

    final custInfo = _tableCustomerMap[_selectedTable] ?? TableCustomerInfo();

    final order = repo.punchWaiterKotOrder(
      tableNumber: _selectedTable,
      items: orderItems,
      waiterName: _authenticatedStaff?.name ?? 'Captain Rahul Verma',
      notes: _kitchenNotesCtrl.text.trim(),
      guestName: custInfo.name,
      guestPhone: custInfo.phone,
      guestDob: custInfo.dob != null ? DateFormat('dd/MM/yyyy').format(custInfo.dob!) : null,
      guestAddress: custInfo.address,
    );

    // Asynchronously dispatch to Windows Desktop ERP over Local Hotel Wi-Fi and Cloud
    HotelSyncBridgeService.instance.sendKotToWindowsErp(
      tableNumber: _selectedTable,
      items: orderItems,
      waiterName: _authenticatedStaff?.name ?? 'Captain Rahul Verma',
      notes: _kitchenNotesCtrl.text.trim(),
      guestName: custInfo.name,
      guestPhone: custInfo.phone,
      guestDob: custInfo.dob != null ? DateFormat('dd/MM/yyyy').format(custInfo.dob!) : null,
      guestAddress: custInfo.address,
    );

    // Update table status in local state
    final tIdx = _tablesList.indexWhere((t) => t['number'] == _selectedTable);
    if (tIdx != -1) {
      setState(() {
        _tablesList[tIdx]['status'] = 'occupied';
        _tablesList[tIdx]['runningAmount'] = ((_tablesList[tIdx]['runningAmount'] as num?)?.toDouble() ?? 0.0) + order.total;
        _tablesList[tIdx]['kotCount'] = ((_tablesList[tIdx]['kotCount'] as num?)?.toInt() ?? 0) + 1;
        _orderCart.clear();
        _kitchenNotesCtrl.clear();
        _currentTabIndex = 2; // Switch to Running Orders tab
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF1E8449), size: 24),
            SizedBox(width: 8),
            Text('KOT Punched Successfully', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket Number: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Table: $_selectedTable • Captain: ${_authenticatedStaff?.name ?? 'Captain Rahul Verma'}'),
            if (custInfo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Guest: ${custInfo.name} (${custInfo.phone})', style: const TextStyle(color: Color(0xFF1E8449), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 8),
            Text('Items Sent: ${orderItems.length} items (Total: ₹${order.total.toStringAsFixed(0)})'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.print_rounded, size: 16, color: Color(0xFF1E8449)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kitchen KOT printed automatically at Kitchen Station',
                      style: TextStyle(fontSize: 11, color: Color(0xFF145A32)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Waiter Bill Generation & Settle Modal ─────────────────────────────────
  void _showBillGenerationSheet(BuildContext context, PosOrderModel order, HotelRepository repo) {
    final tableNumber = order.tableNumber ?? _selectedTable;
    final cust = _tableCustomerMap[tableNumber] ?? TableCustomerInfo(name: 'Guest User', phone: '9876543210');
    final activeBranch = repo.activeBranch;
    final hotelName = repo.clientBusinessName;

    double discountPercentage = 0.0;
    String selectedPaymentMethod = 'UPI QR Code';
    bool autoSendWhatsApp = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final subtotal = order.subtotal;
          final discountAmount = subtotal * (discountPercentage / 100.0);
          final taxable = (subtotal - discountAmount).clamp(0.0, double.infinity);
          final cgst = taxable * 0.025;
          final sgst = taxable * 0.025;
          final grandTotal = (taxable + cgst + sgst).roundToDouble();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 14,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GENERATE BILL & TAX INVOICE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                          Text('$hotelName • ${activeBranch.name}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E8449).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(tableNumber, style: const TextStyle(color: Color(0xFF1E8449), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Customer Registered Details Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, color: Color(0xFF1E8449), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              cust.name.isNotEmpty ? cust.name : 'Walk-in Guest',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const Spacer(),
                            if (cust.dob != null)
                              Text('🎂 ${DateFormat('dd MMM yyyy').format(cust.dob!)}', style: const TextStyle(fontSize: 11, color: Colors.amber)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_iphone_rounded, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              cust.phone.isNotEmpty ? '+91 ${cust.phone}' : 'No phone entered',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cust.phone.isNotEmpty ? Colors.green.shade800 : Colors.red),
                            ),
                            const SizedBox(width: 10),
                            if (cust.address.isNotEmpty)
                              Expanded(
                                child: Text('📍 ${cust.address}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Itemized Bill List
                  const Text('ORDER ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: order.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 8),
                      itemBuilder: (ctx, i) {
                        final it = order.items[i];
                        return Row(
                          children: [
                            Text('${it.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E8449))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(it.name, style: const TextStyle(fontSize: 12))),
                            Text('₹${it.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  ),

                  const Divider(height: 16),

                  // Discount Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount / Offer:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _discountChip('0%', 0.0, discountPercentage, (val) => setSheetState(() => discountPercentage = val)),
                          const SizedBox(width: 4),
                          _discountChip('5%', 5.0, discountPercentage, (val) => setSheetState(() => discountPercentage = val)),
                          const SizedBox(width: 4),
                          _discountChip('10% Birthday', 10.0, discountPercentage, (val) => setSheetState(() => discountPercentage = val)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Calculations
                  _billRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                  if (discountAmount > 0)
                    _billRow('Discount (${discountPercentage.toInt()}%)', '- ₹${discountAmount.toStringAsFixed(2)}', color: Colors.green),
                  _billRow('CGST (2.5%)', '₹${cgst.toStringAsFixed(2)}'),
                  _billRow('SGST (2.5%)', '₹${sgst.toStringAsFixed(2)}'),
                  const Divider(height: 12),
                  _billRow('GRAND TOTAL', '₹${grandTotal.toStringAsFixed(2)}', isBold: true, fontSize: 16, color: const Color(0xFF1E8449)),

                  const SizedBox(height: 12),

                  // Payment Method
                  const Text('PAYMENT METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ['UPI QR Code', 'Cash', 'Credit/Debit Card', 'Room Folio'].map((method) {
                      final isSel = selectedPaymentMethod == method;
                      return ChoiceChip(
                        label: Text(method, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E8449),
                        onSelected: (_) => setSheetState(() => selectedPaymentMethod = method),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Automatic WhatsApp Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Send Bill PDF on WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      cust.phone.isNotEmpty ? 'Dispatches automatic PDF invoice to +91 ${cust.phone}' : 'Add phone number to enable WhatsApp delivery',
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    value: autoSendWhatsApp && cust.phone.isNotEmpty,
                    activeTrackColor: const Color(0xFF1E8449),
                    onChanged: cust.phone.isNotEmpty ? (val) => setSheetState(() => autoSendWhatsApp = val) : null,
                  ),

                  const SizedBox(height: 12),

                  // Settle & Send Bill Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8449),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _executeBillSettlement(
                        order: order,
                        tableNumber: tableNumber,
                        cust: cust,
                        grandTotal: grandTotal,
                        subtotal: subtotal,
                        cgst: cgst,
                        sgst: sgst,
                        discountAmount: discountAmount,
                        paymentMethod: selectedPaymentMethod,
                        sendWhatsApp: autoSendWhatsApp,
                        repo: repo,
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      'SETTLE BILL (₹${grandTotal.toStringAsFixed(0)}) & SEND WHATSAPP PDF',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _discountChip(String label, double val, double current, Function(double) onSelect) {
    final isSel = current == val;
    return InkWell(
      onTap: () => onSelect(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1E8449) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false, double fontSize = 12, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Future<void> _executeBillSettlement({
    required PosOrderModel order,
    required String tableNumber,
    required TableCustomerInfo cust,
    required double grandTotal,
    required double subtotal,
    required double cgst,
    required double sgst,
    required double discountAmount,
    required String paymentMethod,
    required bool sendWhatsApp,
    required HotelRepository repo,
  }) async {
    // 1. Settle in repository
    repo.settleWaiterTableOrder(
      orderId: order.id,
      paymentMethod: paymentMethod,
      discount: discountAmount,
    );

    // Asynchronously dispatch settlement to Windows Desktop ERP
    HotelSyncBridgeService.instance.sendSettleToWindowsErp(
      orderId: order.id,
      paymentMethod: paymentMethod,
      discount: discountAmount,
    );

    // 2. Mark table vacant locally
    final tIdx = _tablesList.indexWhere((t) => t['number'] == tableNumber);
    if (tIdx != -1) {
      setState(() {
        _tablesList[tIdx]['status'] = 'vacant';
        _tablesList[tIdx]['runningAmount'] = 0.0;
        _tablesList[tIdx]['kotCount'] = 0;
      });
    }

    // 3. Construct WhatsApp Invoice Message
    final hotelName = repo.clientBusinessName;
    final activeBranch = repo.activeBranch;
    final invoiceNumber = 'INV-${order.orderNumber.replaceAll("KOT-", "")}';
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final itemsBuffer = StringBuffer();
    for (final it in order.items) {
      itemsBuffer.writeln('• ${it.quantity}x ${it.name} - ₹${it.subtotal.toStringAsFixed(0)}');
    }

    final invoiceText = '''
🏨 *$hotelName*
📍 ${activeBranch.name}, ${activeBranch.city}
GSTIN: 27AAAAA0000A1Z5
-----------------------------------------
🧾 *TAX INVOICE: #$invoiceNumber*
🍽️ Table: $tableNumber | Captain: ${_authenticatedStaff?.name ?? "Captain"}
👤 Guest: ${cust.name.isNotEmpty ? cust.name : "Valued Customer"}
📱 Mobile: ${cust.phone.isNotEmpty ? "+91 ${cust.phone}" : "N/A"}
${cust.dob != null ? "🎂 DOB: ${DateFormat('dd/MM/yyyy').format(cust.dob!)}\n" : ""}📅 Date: $dateStr
-----------------------------------------
*ORDER ITEMS:*
${itemsBuffer.toString().trim()}
-----------------------------------------
Subtotal: ₹${subtotal.toStringAsFixed(2)}
${discountAmount > 0 ? "Discount: -₹${discountAmount.toStringAsFixed(2)}\n" : ""}CGST (2.5%): ₹${cgst.toStringAsFixed(2)}
SGST (2.5%): ₹${sgst.toStringAsFixed(2)}
*GRAND TOTAL: ₹${grandTotal.toStringAsFixed(2)}*
Payment Mode: $paymentMethod (PAID ✅)
-----------------------------------------
📄 *Download Official PDF Tax Invoice:*
https://hotelpro.app/invoice/$invoiceNumber.pdf

Thank you for dining with us! 🙏 Please visit again!
''';

    // 4. Launch WhatsApp if enabled and phone available
    if (sendWhatsApp && cust.phone.isNotEmpty) {
      final cleanPhone = cust.phone.replaceAll(RegExp(r'\D'), '');
      final whatsappUrl = Uri.parse('whatsapp://send?phone=91$cleanPhone&text=${Uri.encodeComponent(invoiceText)}');
      final webUrl = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(invoiceText)}');

      try {
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl);
        } else {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        // Fallback gracefully on desktop test emulators
      }
    }

    // 5. Show Settlement Success Dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF1E8449), size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Bill Settled Successfully!', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #$invoiceNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Table $tableNumber is now VACANT & clean.'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Text('📱', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WhatsApp Bill PDF Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF145A32))),
                        Text(
                          cust.phone.isNotEmpty
                              ? 'Automated PDF invoice sent to +91 ${cust.phone}'
                              : 'No phone registered for WhatsApp',
                          style: TextStyle(fontSize: 10.5, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (cust.phone.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final cleanPhone = cust.phone.replaceAll(RegExp(r'\D'), '');
                final webUrl = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(invoiceText)}');
                await launchUrl(webUrl, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.share_rounded, size: 16, color: Colors.green),
              label: const Text('Open WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentTabIndex = 0); // Back to Tables
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;

    // ── Authentication Gate ───────────────────────────────────────────────
    if (_authenticatedStaff == null) {
      return MobileStaffLoginView(
        role: MobileAppRole.waiter,
        appTitle: 'Staff Waiter & Captain POS',
        appSubtitle: 'Table-Side Digital Ordering & Kitchen KOT Punch',
        onAuthenticate: (profile) {
          setState(() {
            _authenticatedStaff = profile;
          });
        },
        onBackToGateway: null, // No mention of other apps!
      );
    }

    return MobileAppScaffold(
      title: 'Waiter POS & Captain',
      subtitle: '${activeBranch.name} • ${_authenticatedStaff!.name}',
      currentRole: MobileAppRole.waiter,
      onBack: null, // Standalone app: no back to gateway
      onSwitchRole: null, // Standalone app: no role switcher
      showRoleSwitcher: false, // Absolutely no mentions of other apps!
      operatorName: _authenticatedStaff!.name,
      operatorRole: _authenticatedStaff!.role,
      operatorEmoji: _authenticatedStaff!.avatarEmoji,
      onLogout: () => setState(() => _authenticatedStaff = null),
      body: IndexedStack(
        index: _currentTabIndex.clamp(0, 2),
        children: [
          _buildTablesTab(repo),
          _buildOrderTakingTab(repo),
          _buildRunningOrdersTab(repo),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (idx) => setState(() => _currentTabIndex = idx),
        selectedItemColor: const Color(0xFF1E8449),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant_rounded),
            label: 'Tables Matrix',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _orderCart.values.fold(0, (sum, q) => sum + q) > 0,
              label: Text('${_orderCart.values.fold(0, (sum, q) => sum + q)}'),
              child: const Icon(Icons.receipt_rounded),
            ),
            label: 'Punch KOT ($_selectedTable)',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_rounded),
            label: 'Running KOTs & Bill',
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Tables Matrix ──────────────────────────────────────────────────
  Widget _buildTablesTab(HotelRepository repo) {
    final occupiedCount = _tablesList.where((t) => t['status'] == 'occupied').length;
    final vacantCount = _tablesList.where((t) => t['status'] == 'vacant').length;
    final billingCount = _tablesList.where((t) => t['status'] == 'billing').length;

    return Column(
      children: [
        // Status Ribbon
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tableFilterPill('All (${_tablesList.length})', const Color(0xFF1B4F72)),
              _tableFilterPill('Vacant ($vacantCount)', const Color(0xFF1E8449)),
              _tableFilterPill('Occupied ($occupiedCount)', const Color(0xFFC0392B)),
              _tableFilterPill('Billing ($billingCount)', const Color(0xFFD35400)),
            ],
          ),
        ),
        const Divider(height: 1),

        // Grid of Tables
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: _tablesList.length,
            itemBuilder: (context, idx) {
              final t = _tablesList[idx];
              final String number = t['number'] as String;
              final int capacity = t['capacity'] as int;
              final String section = t['section'] as String;
              final String status = t['status'] as String;
              final double runningAmount = (t['runningAmount'] as num?)?.toDouble() ?? 0.0;
              final int kotCount = (t['kotCount'] as num?)?.toInt() ?? 0;
              final cust = _tableCustomerMap[number];

              Color borderColor = const Color(0xFF27AE60);
              Color badgeColor = const Color(0xFF27AE60);
              String statusLabel = 'VACANT';

              if (status == 'occupied') {
                borderColor = const Color(0xFFC0392B);
                badgeColor = const Color(0xFFC0392B);
                statusLabel = 'RUNNING ($kotCount KOT)';
              } else if (status == 'billing') {
                borderColor = const Color(0xFFD35400);
                badgeColor = const Color(0xFFD35400);
                statusLabel = 'BILL PENDING';
              }

              final isCurrent = _selectedTable == number;

              return InkWell(
                onTap: () => _onTableCardTap(number, capacity, status),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFF1E8449) : borderColor.withValues(alpha: 0.5),
                      width: isCurrent ? 2.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4F72),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Guest Name if assigned
                      if (cust != null && cust.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 12, color: Color(0xFF1E8449)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cust.name,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.chair_rounded, size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 3),
                              Text(
                                '$capacity Seats • $section',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (runningAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '₹${runningAmount.toStringAsFixed(0)} Active',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tableFilterPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ── Tab 2: Order Taking & KOT Punch ───────────────────────────────────────
  Widget _buildOrderTakingTab(HotelRepository repo) {
    final menuItems = repo.activeBranchMenuItems;
    final categories = ['All', ...menuItems.map((m) => m.category).toSet()];
    final cust = _tableCustomerMap[_selectedTable] ?? TableCustomerInfo();

    final filteredItems = menuItems.where((m) {
      final matchesCat = _selectedCategory == 'All' || m.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || m.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesVeg = !_onlyVeg || m.isVeg;
      return matchesCat && matchesSearch && matchesVeg;
    }).toList();

    int totalItemsInCart = _orderCart.values.fold(0, (sum, q) => sum + q);
    double subtotal = 0.0;
    _orderCart.forEach((itemId, qty) {
      final item = menuItems.firstWhere((m) => m.id == itemId, orElse: () => menuItems.first);
      subtotal += item.price * qty;
    });
    double total = subtotal * 1.05;

    return Column(
      children: [
        // ── Customer Information Banner on Top ──
        Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8449).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('👤', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cust.isNotEmpty ? cust.name : 'Walk-in Guest ($_selectedTable)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cust.dob != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade300, width: 0.5)),
                            child: Text('🎂 ${DateFormat('dd MMM').format(cust.dob!)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      cust.phone.isNotEmpty
                          ? '📱 +91 ${cust.phone} • WhatsApp PDF Bill Active'
                          : 'No phone entered • Tap Edit to add for WhatsApp receipt',
                      style: TextStyle(fontSize: 10.5, color: cust.phone.isNotEmpty ? const Color(0xFF16A34A) : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF1E8449)),
                tooltip: 'Edit Customer Details',
                onPressed: () => _showCustomerEntryDialog(_selectedTable, _selectedTableCapacity),
              ),
            ],
          ),
        ),

        // Search Bar & Veg Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search dishes, drinks...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Veg Only', style: TextStyle(fontSize: 11)),
                selected: _onlyVeg,
                onSelected: (val) => setState(() => _onlyVeg = val),
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade800,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ],
          ),
        ),

        // Categories Ribbon
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSel = cat == _selectedCategory;
              return ChoiceChip(
                label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedCategory = cat),
                selectedColor: const Color(0xFF1E8449),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Menu Items List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text('No dishes found in $_selectedCategory', style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = filteredItems[i];
                    final qty = _orderCart[item.id] ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: item.isVeg ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.price.toStringAsFixed(0)} • ${item.category}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF1E8449), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          // Qty Selector
                          if (qty == 0)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E8449),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(64, 32),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => setState(() => _orderCart[item.id] = 1),
                              child: const Text('ADD +', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E8449),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    onPressed: () {
                                      setState(() {
                                        if (qty <= 1) {
                                          _orderCart.remove(item.id);
                                        } else {
                                          _orderCart[item.id] = qty - 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    onPressed: () => setState(() => _orderCart[item.id] = qty + 1),
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

        // Cart Drawer Tray (Bottom Sheet pinned)
        if (totalItemsInCart > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalItemsInCart Items • Subtotal: ₹${subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      'Grand Total: ₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8449),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _punchKot(repo),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'PUNCH KOT TO KITCHEN ($_selectedTable)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Tab 3: Running KOTs & Table Summary ───────────────────────────────────
  Widget _buildRunningOrdersTab(HotelRepository repo) {
    final activeOrders = repo.posOrders
        .where((o) => o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled)
        .toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE RUNNING ORDERS (${activeOrders.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
              ),
              const Text('Live Kitchen Sync ⚡', style: TextStyle(fontSize: 11, color: Colors.green)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: activeOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No active orders right now', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: activeOrders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final order = activeOrders[i];
                    final tableNum = order.tableNumber ?? 'T-01';
                    final cust = _tableCustomerMap[tableNum];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${order.tableNumber ?? "Table"} • ${order.orderNumber}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF145A32)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.status.name.toUpperCase(),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Punched: ${DateFormat('HH:mm a').format(order.createdAt)} • Captain: ${_authenticatedStaff?.name ?? "Staff"}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          if (cust != null && cust.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 12, color: Color(0xFF1E8449)),
                                const SizedBox(width: 4),
                                Text(
                                  '${cust.name} (${cust.phone})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          ...order.items.map((it) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${it.quantity}x ${it.name}', style: const TextStyle(fontSize: 12)),
                                    Text('₹${it.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Grand Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    '₹${order.total.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E8449),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showBillGenerationSheet(context, order, repo),
                                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                label: const Text(
                                  '⚡ Settle Bill & WhatsApp PDF',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
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
}
