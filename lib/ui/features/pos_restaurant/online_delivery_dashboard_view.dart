import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/aggregator_channel_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_config_storage.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../../core/classic/utils/report_utils.dart';

/// Classic Windows Desktop Online Food Delivery & Rider Assignment Dashboard
/// Connects real-time with customer mobile app orders and 3rd-party aggregators
/// (Zomato, Swiggy, Magicpin, ONDC, UrbanPiper, Petpooja).
class OnlineDeliveryDashboardView extends StatefulWidget {
  final bool isEmbedded;

  const OnlineDeliveryDashboardView({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<OnlineDeliveryDashboardView> createState() => _OnlineDeliveryDashboardViewState();
}

class _OnlineDeliveryDashboardViewState extends State<OnlineDeliveryDashboardView> {
  // Navigation Tabs: 0 = In-House Dispatch Terminal, 1 = Aggregator Channels Hub
  int _mainTab = 0;

  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';
  CustomerFoodOrderModel? _selectedOrder;

  // Aggregator tab states
  String _selectedAggregatorPlatform = 'ALL';
  CustomerFoodOrderModel? _selectedAggregatorOrder;
  List<AggregatorChannelModel> _channels = AggregatorChannelModel.defaultChannels();

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  final ScrollController _ordersHorizontalScrollController = ScrollController();
  final ScrollController _aggregatorHorizontalScrollController = ScrollController();

  @override
  void dispose() {
    _ordersHorizontalScrollController.dispose();
    _aggregatorHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAggregatorChannels();
  }

  Future<void> _loadSavedAggregatorChannels() async {
    final saved = await HotelConfigStorage.loadAggregatorChannels();
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        final defs = AggregatorChannelModel.defaultChannels();
        _channels = defs.map((def) {
          final match = saved.firstWhere((s) => s['id'] == def.id, orElse: () => <String, dynamic>{});
          if (match.isNotEmpty) {
            return AggregatorChannelModel.fromJson(match, brandColor: def.brandColor, icon: def.icon);
          }
          return def;
        }).toList();
      });
    }
  }

  Future<void> _saveChannelsState() async {
    await HotelConfigStorage.saveAggregatorChannels(_channels.map((c) => c.toJson()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final allOrders = repo.customerOrders;

    // Filter orders based on status & search
    final filteredOrders = allOrders.where((order) {
      if (_selectedStatusFilter != 'ALL') {
        if (_selectedStatusFilter == 'PLACED' && order.orderStatus != CustomerOrderStatus.placed) return false;
        if (_selectedStatusFilter == 'KITCHEN' && order.orderStatus != CustomerOrderStatus.kitchenPreparing) return false;
        if (_selectedStatusFilter == 'OUT_FOR_DELIVERY' && order.orderStatus != CustomerOrderStatus.outForDelivery) return false;
        if (_selectedStatusFilter == 'DELIVERED' && order.orderStatus != CustomerOrderStatus.delivered) return false;
        if (_selectedStatusFilter == 'CANCELLED' && order.orderStatus != CustomerOrderStatus.cancelled) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesId = order.id.toLowerCase().contains(q);
        final matchesCust = order.customerName.toLowerCase().contains(q);
        final matchesPhone = order.customerPhone.toLowerCase().contains(q);
        final matchesAddr = order.deliveryAddress.fullAddress.toLowerCase().contains(q);
        final matchesRider = (order.riderName ?? '').toLowerCase().contains(q);
        if (!matchesId && !matchesCust && !matchesPhone && !matchesAddr && !matchesRider) {
          return false;
        }
      }
      return true;
    }).toList();

    // If selected order is null or not in list, default to first filtered order
    if (filteredOrders.isNotEmpty) {
      if (_selectedOrder == null || !filteredOrders.any((o) => o.id == _selectedOrder!.id)) {
        _selectedOrder = filteredOrders.first;
      } else {
        // Keep updated instance
        _selectedOrder = filteredOrders.firstWhere((o) => o.id == _selectedOrder!.id);
      }
    } else {
      _selectedOrder = null;
    }

    // Metric counts
    final totalCount = allOrders.length;
    final placedCount = allOrders.where((o) => o.orderStatus == CustomerOrderStatus.placed).length;
    final kitchenCount = allOrders.where((o) => o.orderStatus == CustomerOrderStatus.kitchenPreparing).length;
    final outCount = allOrders.where((o) => o.orderStatus == CustomerOrderStatus.outForDelivery).length;
    final deliveredCount = allOrders.where((o) => o.orderStatus == CustomerOrderStatus.delivered).length;
    final totalRevenue = allOrders
        .where((o) => o.orderStatus != CustomerOrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.grandTotal);

    return Material(
      color: ClassicErpTheme.windowBg,
      child: Container(
        color: ClassicErpTheme.windowBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Top Ribbon & Live Metrics Header ─────────────────────────
            _buildTopMetricsBar(
              context: context,
              repo: repo,
              totalCount: totalCount,
              placedCount: placedCount,
              kitchenCount: kitchenCount,
              outCount: outCount,
              deliveredCount: deliveredCount,
              totalRevenue: totalRevenue,
            ),

            if (_mainTab == 0) ...[
              // ── 2. Filter Tabs & Search Bar (In-House) ──────────────────────
              _buildFilterAndSearchRibbon(
                context: context,
                repo: repo,
                totalCount: totalCount,
                placedCount: placedCount,
                kitchenCount: kitchenCount,
                outCount: outCount,
                deliveredCount: deliveredCount,
              ),

              // ── 3. Main Workspace: Orders Table (Left) + Dispatch Console (Right)
              Expanded(
                child: filteredOrders.isEmpty
                    ? _buildEmptyState(repo)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final consoleWidth = (constraints.maxWidth * 0.35).clamp(320.0, 370.0);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: Data Grid Table (Takes all remaining width)
                              Expanded(
                                child: _buildOrdersTable(repo, filteredOrders),
                              ),

                              // Divider
                              Container(
                                width: 4,
                                color: ClassicErpTheme.borderDark,
                              ),

                              // Right: Dispatch Console & Inspector (Ergonomic width)
                              SizedBox(
                                width: consoleWidth,
                                child: _selectedOrder != null
                                    ? _buildDispatchConsole(context, repo, _selectedOrder!)
                                    : const Center(child: Text('Select an order to view dispatch details')),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ] else ...[
              // ── 4. Aggregator Channels & Middleware Hub ──────────────────────
              Expanded(
                child: _buildAggregatorHubView(context, repo),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 1. TOP METRICS HEADER
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildTopMetricsBar({
    required BuildContext context,
    required HotelRepository repo,
    required int totalCount,
    required int placedCount,
    required int kitchenCount,
    required int outCount,
    required int deliveredCount,
    required double totalRevenue,
  }) {
    final aggregatorOrders = repo.customerOrders.where((o) => o.channel != 'Direct App').toList();
    final aggGross = aggregatorOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
    final aggNet = aggregatorOrders.fold(0.0, (sum, o) => sum + o.netPayout);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFEAECEE),
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delivery_dining_rounded, size: 22, color: Color(0xFF1B4F72)),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ONLINE FOOD DELIVERY & RIDER DISPATCH TERMINAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ClassicErpTheme.textMain,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Zomato / Swiggy / ONDC / Direct Mobile App Integration Hub',
                    style: TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Main Tab Navigation Switcher
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: ClassicErpTheme.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _mainNavTab(
                      index: 0,
                      icon: Icons.delivery_dining_rounded,
                      label: '🛵 In-House Dispatch',
                      count: repo.customerOrders.where((o) => o.channel == 'Direct App').length,
                    ),
                    Container(width: 1, height: 20, color: ClassicErpTheme.borderDark),
                    _mainNavTab(
                      index: 1,
                      icon: Icons.hub_rounded,
                      label: '🌐 Aggregator Hub (Zomato • Swiggy • Magicpin • ONDC)',
                      count: aggregatorOrders.length,
                      highlightColor: const Color(0xFFC0392B),
                    ),
                  ],
                ),
              ),
            ],
          );

          final metricsAndActions = _mainTab == 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _kpiPill('New Placed', placedCount.toString(), placedCount > 0 ? const Color(0xFFD35400) : Colors.grey, isAlert: placedCount > 0),
                    const SizedBox(width: 6),
                    _kpiPill('In Kitchen', kitchenCount.toString(), const Color(0xFF2980B9)),
                    const SizedBox(width: 6),
                    _kpiPill('Out for Delivery', outCount.toString(), const Color(0xFF8E44AD)),
                    const SizedBox(width: 6),
                    _kpiPill('Delivered', deliveredCount.toString(), const Color(0xFF27AE60)),
                    const SizedBox(width: 6),
                    _kpiPill('Online Sales', _currency.format(totalRevenue), const Color(0xFF1B4F72)),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _simulateIncomingAppOrder(context, repo),
                      icon: const Icon(Icons.flash_on_rounded, size: 14, color: Colors.white),
                      label: const Text(
                        '+ Simulate App Order',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _kpiPill('Aggregator Orders', aggregatorOrders.length.toString(), const Color(0xFFC0392B)),
                    const SizedBox(width: 6),
                    _kpiPill('Gross Sales', _currency.format(aggGross), const Color(0xFF1B4F72)),
                    const SizedBox(width: 6),
                    _kpiPill('Net Receivable', _currency.format(aggNet), const Color(0xFF27AE60)),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _simulateAggregatorOrder(context, repo, 'Zomato'),
                      icon: const Icon(Icons.delivery_dining_rounded, size: 14, color: Colors.white),
                      label: const Text('+ Test Zomato', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCB202D),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () => _simulateAggregatorOrder(context, repo, 'Swiggy'),
                      icon: const Icon(Icons.moped_rounded, size: 14, color: Colors.white),
                      label: const Text('+ Test Swiggy', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC8019),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ],
                );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleWidget,
                  const SizedBox(width: 16),
                  metricsAndActions,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mainNavTab({
    required int index,
    required IconData icon,
    required String label,
    required int count,
    Color? highlightColor,
  }) {
    final isSelected = _mainTab == index;
    final activeBg = highlightColor ?? const Color(0xFF1B4F72);

    return InkWell(
      onTap: () => setState(() => _mainTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : (highlightColor ?? ClassicErpTheme.textMain)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : ClassicErpTheme.textMain,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (highlightColor ?? const Color(0xFF1B4F72)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiPill(String label, String value, Color color, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAlert) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            '$label: ',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 2. FILTER & SEARCH RIBBON
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildFilterAndSearchRibbon({
    required BuildContext context,
    required HotelRepository repo,
    required int totalCount,
    required int placedCount,
    required int kitchenCount,
    required int outCount,
    required int deliveredCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabs = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter Tabs
              _filterTab('ALL', 'All Orders ($totalCount)'),
              const SizedBox(width: 4),
              _filterTab('PLACED', '🟡 New Placed ($placedCount)'),
              const SizedBox(width: 4),
              _filterTab('KITCHEN', '🔵 Kitchen Preparing ($kitchenCount)'),
              const SizedBox(width: 4),
              _filterTab('OUT_FOR_DELIVERY', '🟣 On Route ($outCount)'),
              const SizedBox(width: 4),
              _filterTab('DELIVERED', '🟢 Delivered ($deliveredCount)'),
            ],
          );

          final searchAndActions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Box
              SizedBox(
                width: 240,
                height: 26,
                child: TextField(
                  style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                  decoration: InputDecoration(
                    hintText: 'Search Order #, Customer, Phone, Address...',
                    hintStyle: const TextStyle(fontSize: 10.5, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),

              // Print Run-Sheet Button
              InkWell(
                onTap: () => _showBatchRunSheetDialog(context, repo),
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: ClassicErpTheme.borderDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_rounded, size: 13, color: Color(0xFF1B4F72)),
                      SizedBox(width: 4),
                      Text('Print Run-Sheet', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    ],
                  ),
                ),
              ),
            ],
          );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  tabs,
                  const SizedBox(width: 16),
                  searchAndActions,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterTab(String key, String title) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4F72) : Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? const Color(0xFF154360) : ClassicErpTheme.borderDark,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 3. ORDERS DATA GRID TABLE (LEFT PANE)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildOrdersTable(HotelRepository repo, List<CustomerFoodOrderModel> orders) {
    const double minTableWidth = 840.0;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

          return Scrollbar(
            controller: _ordersHorizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _ordersHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: effectiveWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      height: 28,
                      color: const Color(0xFF2C3E50),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 105, child: Text('ORDER / CHANNEL', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 65, child: Text('TIME', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 130, child: Text('CUSTOMER', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('DELIVERY ADDRESS', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 75, child: Text('ITEMS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 105, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 120, child: Text('ASSIGNED RIDER', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Table Rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (context, _) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final isSelected = _selectedOrder?.id == order.id;
                          final timeStr = DateFormat('hh:mm a').format(order.createdAt);
                          final itemsCount = order.items.fold(0, (sum, i) => sum + i.quantity);

                          return InkWell(
                            onTap: () => setState(() => _selectedOrder = order),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                              color: isSelected ? const Color(0xFFD6EAF8) : (index.isEven ? Colors.white : const Color(0xFFF9FAFB)),
                              child: Row(
                                children: [
                                  // Order No & Channel
                                  SizedBox(
                                    width: 105,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.id,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (order.channel != 'Direct App') ...[
                                              _buildChannelBadge(order.channel, fontSize: 7.5),
                                              const SizedBox(width: 4),
                                            ],
                                            Expanded(
                                              child: Text(
                                                order.paymentMethod.name.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 8.0, color: Colors.grey, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Time
                                  SizedBox(
                                    width: 65,
                                    child: Text(
                                      timeStr,
                                      style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                                    ),
                                  ),

                                  // Customer
                                  SizedBox(
                                    width: 130,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.customerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          order.customerPhone,
                                          style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Delivery Address
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.shade100,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                order.deliveryAddress.label.toUpperCase(),
                                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                                              ),
                                            ),
                                            Text(
                                              '${order.deliveryAddress.distanceKmFromHotel.toStringAsFixed(1)} km',
                                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          order.deliveryAddress.fullAddress,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Items
                                  SizedBox(
                                    width: 75,
                                    child: Center(
                                      child: Text(
                                        '$itemsCount items',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),

                                  // Total
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      _currency.format(order.grandTotal),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                    ),
                                  ),

                                  // Status Badge
                                  SizedBox(
                                    width: 105,
                                    child: Center(child: _statusBadge(order.orderStatus)),
                                  ),

                                  // Assigned Rider
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.two_wheeler_rounded, size: 13, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            order.riderName ?? 'Unassigned',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: order.riderName != null ? Colors.black87 : Colors.red.shade700,
                                            ),
                                          ),
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(CustomerOrderStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case CustomerOrderStatus.placed:
        bg = const Color(0xFFFEF9E7);
        fg = const Color(0xFFB7950B);
        label = '🟡 PLACED';
        break;
      case CustomerOrderStatus.kitchenPreparing:
        bg = const Color(0xFFEBF5FB);
        fg = const Color(0xFF2980B9);
        label = '🔵 KITCHEN';
        break;
      case CustomerOrderStatus.outForDelivery:
        bg = const Color(0xFFF5EEF8);
        fg = const Color(0xFF8E44AD);
        label = '🟣 IN TRANSIT';
        break;
      case CustomerOrderStatus.delivered:
        bg = const Color(0xFFEAFAF1);
        fg = const Color(0xFF27AE60);
        label = '🟢 DELIVERED';
        break;
      case CustomerOrderStatus.cancelled:
        bg = const Color(0xFFFDEDEC);
        fg = const Color(0xFFC0392B);
        label = '🔴 CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 4. DISPATCH CONSOLE & ORDER INSPECTOR (RIGHT PANE)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildDispatchConsole(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    final availableRiders = repo.deliveryRiders;

    return Container(
      color: const Color(0xFFF4F6F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF1B4F72),
            child: Row(
              children: [
                const Icon(Icons.manage_accounts_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'DISPATCH CONSOLE — ${order.id}',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: () => _printSingleOrderChallan(context, order, repo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Print Challan', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // ── Customer Card ──
                _consoleCard(
                  title: 'CUSTOMER INFORMATION',
                  icon: Icons.person_pin_circle_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF1B4F72)),
                              const SizedBox(width: 4),
                              Text(order.customerPhone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${order.deliveryAddress.label.toUpperCase()} — ${order.deliveryAddress.fullAddress}',
                        style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                      ),
                      if (order.deliveryAddress.landmark.isNotEmpty)
                        Text(
                          'Landmark: ${order.deliveryAddress.landmark}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          border: Border.all(color: const Color(0xFFA3E4D7)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'Distance: ${order.deliveryAddress.distanceKmFromHotel.toStringAsFixed(1)} km (Within 10 km Geofence) • Est. Delivery Time: ${order.estimatedDeliveryMinutes} mins',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF117A65), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Delivery Rider Assignment Section ──
                _consoleCard(
                  title: 'DELIVERY BOY ASSIGNMENT',
                  icon: Icons.sports_motorsports_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF1B4F72),
                            child: const Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.riderName ?? 'No Rider Assigned Yet',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${order.riderPhone ?? "No contact"} • ${order.riderVehicleNo ?? "No Vehicle No"}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (order.riderRating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 11, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    order.riderRating!.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Rider Selection Dropdown & Assign Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ClassicErpTheme.borderDark),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<DeliveryRiderModel>(
                                  isExpanded: true,
                                  hint: const Text('Select Rider from Fleet', style: TextStyle(fontSize: 10.5)),
                                  items: availableRiders.map((r) {
                                    return DropdownMenuItem<DeliveryRiderModel>(
                                      value: r,
                                      child: Text(
                                        '🛵 ${r.name} (${r.vehicleNo}) — ${r.phone}',
                                        style: const TextStyle(fontSize: 10.5),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (selectedRider) {
                                    if (selectedRider != null) {
                                      repo.assignDeliveryRider(order.id, selectedRider);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Rider ${selectedRider.name} assigned to order ${order.id}'),
                                          backgroundColor: const Color(0xFF1B4F72),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Lifecycle Action Toolbar ──
                _consoleCard(
                  title: 'ORDER LIFECYCLE CONTROLS',
                  icon: Icons.sync_alt_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Current Stage: ${order.orderStatus.name.toUpperCase()}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // 1. Send to Kitchen
                          ElevatedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.kitchenPreparing);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.id} sent to Kitchen KOT'), duration: const Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.soup_kitchen_rounded, size: 13),
                            label: const Text('🍳 1. Kitchen KOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2980B9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),

                          // 2. Dispatch to Rider
                          ElevatedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.outForDelivery);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.id} handed to rider (Out for Delivery)'), duration: const Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.two_wheeler_rounded, size: 13),
                            label: const Text('🛵 2. Handover & Dispatch', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E44AD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),

                          // 3. Mark Delivered
                          ElevatedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.delivered);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.id} marked DELIVERED'), duration: const Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 13),
                            label: const Text('✅ 3. Mark Delivered', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),

                          // 4. Cancel
                          OutlinedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.cancelled);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.id} Cancelled'), duration: const Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.cancel_rounded, size: 13, color: Colors.red),
                            label: const Text('Cancel Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              side: const BorderSide(color: Colors.red, width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Ordered Food Items ──
                _consoleCard(
                  title: 'ORDERED ITEMS (${order.items.length})',
                  icon: Icons.fastfood_rounded,
                  child: Column(
                    children: [
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.isVeg ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${item.name} x ${item.quantity}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                _currency.format(item.subtotal),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 12),
                      _financeRow('Item Subtotal', _currency.format(order.itemTotal)),
                      _financeRow('GST (5%)', _currency.format(order.gstAmount)),
                      _financeRow('Delivery Fee', order.deliveryFee == 0 ? 'FREE' : _currency.format(order.deliveryFee)),
                      _financeRow('Packaging Charge', _currency.format(order.packagingCharge)),
                      if (order.discountAmount > 0)
                        _financeRow('Discount (${order.couponCodeApplied ?? ""})', '- ${_currency.format(order.discountAmount)}', isGreen: true),
                      const Divider(height: 8),
                      _financeRow('GRAND TOTAL', _currency.format(order.grandTotal), isBold: true),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Payment Mode: ${order.paymentMethod.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'TXN: ${order.transactionId}',
                              style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  Widget _consoleCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 0.8),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFFEAEDED),
            child: Row(
              children: [
                Icon(icon, size: 13, color: const Color(0xFF1B4F72)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72), letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _financeRow(String label, String value, {bool isBold = false, bool isGreen = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 11.5 : 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isRed
                  ? const Color(0xFFC0392B)
                  : (isGreen ? const Color(0xFF27AE60) : ClassicErpTheme.textMain),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 12 : 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isRed
                  ? const Color(0xFFC0392B)
                  : (isGreen
                      ? const Color(0xFF27AE60)
                      : (isBold ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HotelRepository repo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delivery_dining_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No Online Orders Found for Selected Filter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
          ),
          const SizedBox(height: 6),
          const Text(
            'Customer app orders will appear here automatically in real time.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _simulateIncomingAppOrder(context, repo),
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Simulate New Customer Order'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72)),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // SIMULATE LIVE CUSTOMER ORDER
  // ═════════════════════════════════════════════════════════════════════════════
  void _simulateIncomingAppOrder(BuildContext context, HotelRepository repo) {
    final sampleNames = ['Rohan Kulkarni', 'Sneha Kapoor', 'Manish Agrawal', 'Ananya Sengupta', 'Deepak Patil'];
    final sampleAddresses = [
      'Flat 402, Neelkanth Heights, Andheri West, Mumbai',
      'Row House 12, Silver Oaks, Lokhandwala Complex, Mumbai',
      'B-501, Orchid Enclave, JVLR Link Road, Mumbai',
      'Office 304, Pinnacle Business Park, Mahakali Caves Road, Mumbai',
    ];
    final samplePhones = ['+91 98200 44321', '+91 98191 88765', '+91 99302 11445', '+91 98700 99881'];

    final randomIdx = DateTime.now().millisecond % sampleNames.length;
    final orderId = 'ORD-HP-${1000 + repo.customerOrders.length + 1}';

    final order = CustomerFoodOrderModel(
      id: orderId,
      branchId: repo.activeBranch.id,
      branchName: repo.activeBranch.name,
      customerId: 'cust-${100 + randomIdx}',
      customerName: sampleNames[randomIdx],
      customerPhone: samplePhones[randomIdx % samplePhones.length],
      deliveryAddress: CustomerAddressModel(
        id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
        label: randomIdx.isEven ? 'Home' : 'Work',
        fullAddress: sampleAddresses[randomIdx % sampleAddresses.length],
        latitude: 19.1136 + (randomIdx * 0.003),
        longitude: 72.8697 + (randomIdx * 0.002),
        distanceKmFromHotel: 2.5 + (randomIdx * 0.8),
      ),
      items: [
        CustomerCartItem(
          menuItemId: 'mi-1',
          name: 'Royal Murgh Dum Biryani',
          price: 580,
          isVeg: false,
          quantity: 2,
          category: 'Royal Biryani',
        ),
        CustomerCartItem(
          menuItemId: 'mi-9',
          name: 'Butter Naan Basket (3 Pcs)',
          price: 180,
          isVeg: true,
          quantity: 1,
          category: 'Tandoor & Breads',
        ),
      ],
      itemTotal: 1340.0,
      gstAmount: 67.0,
      deliveryFee: 0.0,
      packagingCharge: 30.0,
      grandTotal: 1437.0,
      paymentMethod: OnlinePaymentMethod.upiGpay,
      paymentStatus: OnlinePaymentStatus.success,
      transactionId: 'UPI-${DateTime.now().millisecondsSinceEpoch}',
      orderStatus: CustomerOrderStatus.placed,
      riderName: repo.deliveryRiders.first.name,
      riderPhone: repo.deliveryRiders.first.phone,
      riderVehicleNo: repo.deliveryRiders.first.vehicleNo,
      createdAt: DateTime.now(),
    );

    // Insert directly into repo customer orders
    repo.addSimulatedCustomerOrder(order);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.yellow),
            const SizedBox(width: 8),
            Text('🔔 New Online Food Delivery Order Placed: $orderId from ${order.customerName}!'),
          ],
        ),
        backgroundColor: const Color(0xFF0C2461),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // PRINTING UTILITIES
  // ═════════════════════════════════════════════════════════════════════════════
  void _printSingleOrderChallan(BuildContext context, CustomerFoodOrderModel order, HotelRepository repo) {
    final printableWidget = Container(
      width: 500,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repo.clientBusinessName.toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                  ),
                  Text(repo.clientTagline, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('${repo.activeBranch.name} • Tel: ${repo.activeBranch.phone}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  Text('GSTIN: ${repo.activeBranch.taxIdentifier}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: const Color(0xFF1B4F72),
                    child: const Text('DELIVERY CHALLAN & TAX INVOICE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text('Order: ${order.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Date: ${DateFormat('dd-MMM-yyyy hh:mm a').format(order.createdAt)}', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          const Divider(thickness: 1.5, height: 20),

          // Customer Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CUSTOMER & DELIVERY DETAILS:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(order.customerName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      Text('Phone: ${order.customerPhone}', style: const TextStyle(fontSize: 10)),
                      Text('Address: ${order.deliveryAddress.fullAddress}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DISPATCH & RIDER DETAILS:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Rider: ${order.riderName ?? "Unassigned"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Vehicle: ${order.riderVehicleNo ?? "-"}', style: const TextStyle(fontSize: 10)),
                      Text('Phone: ${order.riderPhone ?? "-"}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: Colors.grey.shade300,
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('Sr.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Item Description', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 40, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 60, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 70, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Items
          ...order.items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('$idx', style: const TextStyle(fontSize: 10))),
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                  SizedBox(width: 40, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                  SizedBox(width: 60, child: Text(_currency.format(item.price), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10))),
                  SizedBox(width: 70, child: Text(_currency.format(item.subtotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          const Divider(thickness: 1),

          // Totals
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 200,
              child: Column(
                children: [
                  _financeRow('Item Subtotal:', _currency.format(order.itemTotal)),
                  _financeRow('GST (5%):', _currency.format(order.gstAmount)),
                  _financeRow('Delivery Fee:', _currency.format(order.deliveryFee)),
                  _financeRow('Packaging:', _currency.format(order.packagingCharge)),
                  if (order.discountAmount > 0)
                    _financeRow('Discount:', '- ${_currency.format(order.discountAmount)}', isGreen: true),
                  const Divider(thickness: 1),
                  _financeRow('Grand Total:', _currency.format(order.grandTotal), isBold: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Signature / OTP:', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                  SizedBox(height: 25),
                  Text('____________________', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('For ${repo.clientBusinessName}:', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                  const SizedBox(height: 25),
                  const Text('Authorized Dispatch Steward', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    PrintPreviewDialog.show(
      context,
      title: 'Delivery_Challan_${order.id}',
      content: printableWidget,
    );
  }

  void _showBatchRunSheetDialog(BuildContext context, HotelRepository repo) {
    final activeOrders = repo.customerOrders
        .where((o) => o.orderStatus != CustomerOrderStatus.delivered && o.orderStatus != CustomerOrderStatus.cancelled)
        .toList();

    final runSheetWidget = Container(
      width: 600,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY DELIVERY DISPATCH RUN-SHEET',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
              ),
              Text(DateFormat('dd-MMM-yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Text('Outlet: ${repo.activeBranch.name} • Active Dispatches: ${activeOrders.length}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const Divider(thickness: 1.2, height: 16),

          // Header
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(6),
            child: const Row(
              children: [
                SizedBox(width: 80, child: Text('Order No', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 110, child: Text('Customer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Address', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 90, child: Text('Rider', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 65, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          ...activeOrders.map((o) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(o.id, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                        Text(o.customerPhone, style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(o.deliveryAddress.fullAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5)),
                  ),
                  SizedBox(width: 90, child: Text(o.riderName ?? 'Unassigned', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600))),
                  SizedBox(width: 65, child: Text(_currency.format(o.grandTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
        ],
      ),
    );

    PrintPreviewDialog.show(
      context,
      title: 'Delivery_RunSheet_${DateFormat("yyyyMMdd").format(DateTime.now())}',
      content: runSheetWidget,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // AGGREGATOR CHANNELS & MIDDLEWARE HUB (Zomato, Swiggy, Magicpin, ONDC, UrbanPiper)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildChannelBadge(String channel, {double fontSize = 9.0}) {
    Color bg;
    Color fg = Colors.white;
    IconData icon;

    switch (channel.toLowerCase()) {
      case 'zomato':
        bg = const Color(0xFFCB202D);
        icon = Icons.delivery_dining_rounded;
        break;
      case 'swiggy':
        bg = const Color(0xFFFC8019);
        icon = Icons.moped_rounded;
        break;
      case 'magicpin':
        bg = const Color(0xFF7B1FA2);
        icon = Icons.local_offer_rounded;
        break;
      case 'ondc':
        bg = const Color(0xFF0D47A1);
        icon = Icons.public_rounded;
        break;
      case 'urbanpiper':
      case 'urbanpiper gateway':
        bg = const Color(0xFF00897B);
        icon = Icons.hub_rounded;
        break;
      default:
        bg = const Color(0xFF1B4F72);
        icon = Icons.phone_android_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 1, color: fg),
          const SizedBox(width: 3),
          Text(
            channel.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatorHubView(BuildContext context, HotelRepository repo) {
    // Aggregator orders only
    final allAggregatorOrders = repo.customerOrders.where((o) => o.channel != 'Direct App').toList();

    // Filter by selected aggregator platform if != 'ALL'
    final filteredOrders = allAggregatorOrders.where((order) {
      if (_selectedAggregatorPlatform != 'ALL') {
        if (order.channel.toLowerCase() != _selectedAggregatorPlatform.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesId = order.id.toLowerCase().contains(q);
        final matchesAggId = (order.aggregatorOrderId ?? '').toLowerCase().contains(q);
        final matchesCust = order.customerName.toLowerCase().contains(q);
        final matchesPhone = order.customerPhone.contains(q);
        final matchesRider = (order.riderName ?? '').toLowerCase().contains(q);
        if (!matchesId && !matchesAggId && !matchesCust && !matchesPhone && !matchesRider) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort descending by order time
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Ensure selected order is valid or defaults
    if (_selectedAggregatorOrder != null && !filteredOrders.any((o) => o.id == _selectedAggregatorOrder!.id)) {
      _selectedAggregatorOrder = filteredOrders.isNotEmpty ? filteredOrders.first : null;
    } else if (_selectedAggregatorOrder == null && filteredOrders.isNotEmpty) {
      _selectedAggregatorOrder = filteredOrders.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Live Webhook Middleware Strip
        _buildAggregatorMiddlewareStrip(context, repo),

        // 2. Aggregator Channel Health & Toggles Strip
        _buildAggregatorChannelsGrid(context, repo),

        // 3. Channel Filters & Financial Reconciliation Ribbon
        _buildAggregatorReconciliationRibbon(repo, allAggregatorOrders),

        // 4. Main Data Grid Table + Order Inspector Split
        Expanded(
          child: filteredOrders.isEmpty
              ? _buildAggregatorEmptyState(context, repo)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final consoleWidth = (constraints.maxWidth * 0.36).clamp(340.0, 420.0);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Aggregator Orders Table
                        Expanded(
                          child: _buildAggregatorOrdersTable(repo, filteredOrders),
                        ),

                        // Classic Divider
                        Container(
                          width: 4,
                          color: ClassicErpTheme.borderDark,
                        ),

                        // Right: Aggregator Order Inspector & Handover Panel
                        SizedBox(
                          width: consoleWidth,
                          child: _selectedAggregatorOrder != null
                              ? _buildAggregatorOrderInspector(context, repo, _selectedAggregatorOrder!)
                              : const Center(
                                  child: Text('Select an aggregator order to view full details'),
                                ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAggregatorMiddlewareStrip(BuildContext context, HotelRepository repo) {
    final ip = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
    final webhookUrl = 'http://$ip:8088/api/aggregator/webhook';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1C2833), // Dark Navy Slate
        border: Border(bottom: BorderSide(color: Color(0xFF34495E), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF27AE60), width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded, size: 13, color: Color(0xFF2ECC71)),
                SizedBox(width: 5),
                Text(
                  'AGGREGATOR WEBHOOK LISTENER ACTIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2ECC71),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.white24, width: 0.6),
              ),
              child: Row(
                children: [
                  const Text(
                    'ENDPOINT: ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Expanded(
                    child: SelectableText(
                      webhookUrl,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'Consolas',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1C40F),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: webhookUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Webhook URL copied to clipboard! Configure this in UrbanPiper / Aggregator Portal.'),
                          duration: Duration(seconds: 3),
                          backgroundColor: Color(0xFF1B4F72),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 12, color: Colors.white70),
                        SizedBox(width: 4),
                        Text('Copy URL', style: TextStyle(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _showWebhookGuideDialog(context),
            icon: const Icon(Icons.integration_instructions_rounded, size: 13, color: Colors.white),
            label: const Text('API & cURL Testing Guide', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatorChannelsGrid(BuildContext context, HotelRepository repo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F4),
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _channels.map((channel) {
            final channelOrders = repo.customerOrders.where((o) => o.channel.toLowerCase() == channel.name.toLowerCase()).toList();
            final activeCount = channelOrders.where((o) => o.orderStatus != CustomerOrderStatus.delivered && o.orderStatus != CustomerOrderStatus.cancelled).length;

            return Container(
              width: 220,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: channel.isEnabled ? channel.brandColor.withValues(alpha: 0.5) : Colors.grey.shade300,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: channel.brandColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(channel.icon, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: channel.isEnabled ? channel.brandColor : Colors.grey,
                              ),
                            ),
                            Text(
                              channel.id == 'urbanpiper'
                                  ? 'Middleware Gateway'
                                  : 'Commission: ${channel.commissionPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.65,
                        child: Switch(
                          value: channel.isEnabled,
                          activeThumbColor: channel.brandColor,
                          onChanged: (val) {
                            setState(() {
                              channel.isEnabled = val;
                            });
                            _saveChannelsState();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 14, color: Colors.grey),
                        tooltip: 'Configure Channel Credentials & Commission',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showAggregatorChannelConfigDialog(context, channel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: activeCount > 0 ? const Color(0xFFC0392B).withValues(alpha: 0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'Live Orders: $activeCount',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: activeCount > 0 ? const Color(0xFFC0392B) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (channel.id != 'urbanpiper')
                        InkWell(
                          onTap: () => _simulateAggregatorOrder(context, repo, channel.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: channel.brandColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: channel.brandColor.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 11, color: channel.brandColor),
                                const SizedBox(width: 2),
                                Text(
                                  'Test Order',
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: channel.brandColor),
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
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAggregatorReconciliationRibbon(HotelRepository repo, List<CustomerFoodOrderModel> aggregatorOrders) {
    final filteredByChannel = _selectedAggregatorPlatform == 'ALL'
        ? aggregatorOrders
        : aggregatorOrders.where((o) => o.channel.toLowerCase() == _selectedAggregatorPlatform.toLowerCase()).toList();

    final gross = filteredByChannel.fold(0.0, (sum, o) => sum + o.grandTotal);
    final commission = filteredByChannel.fold(0.0, (sum, o) => sum + o.commissionAmount);
    final net = filteredByChannel.fold(0.0, (sum, o) => sum + o.netPayout);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filterChips = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _aggChannelFilterChip('ALL', 'All Aggregators (${aggregatorOrders.length})', null),
              const SizedBox(width: 4),
              _aggChannelFilterChip('Zomato', 'Zomato (${aggregatorOrders.where((o) => o.channel.toLowerCase() == "zomato").length})', const Color(0xFFCB202D)),
              const SizedBox(width: 4),
              _aggChannelFilterChip('Swiggy', 'Swiggy (${aggregatorOrders.where((o) => o.channel.toLowerCase() == "swiggy").length})', const Color(0xFFFC8019)),
              const SizedBox(width: 4),
              _aggChannelFilterChip('Magicpin', 'Magicpin (${aggregatorOrders.where((o) => o.channel.toLowerCase() == "magicpin").length})', const Color(0xFF7B1FA2)),
              const SizedBox(width: 4),
              _aggChannelFilterChip('ONDC', 'ONDC (${aggregatorOrders.where((o) => o.channel.toLowerCase() == "ondc").length})', const Color(0xFF0D47A1)),
            ],
          );

          final summaryKpis = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _kpiPill('Gross Sales', _currency.format(gross), const Color(0xFF1B4F72)),
              const SizedBox(width: 6),
              _kpiPill('Comm. Deducted', '-${_currency.format(commission)}', const Color(0xFFC0392B)),
              const SizedBox(width: 6),
              _kpiPill('Net Hotel Payout', _currency.format(net), const Color(0xFF27AE60)),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                height: 26,
                child: TextField(
                  style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                  decoration: InputDecoration(
                    hintText: 'Search Orders...',
                    hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 14, color: ClassicErpTheme.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: ClassicErpTheme.borderDark)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: ClassicErpTheme.borderDark)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ],
          );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  filterChips,
                  const SizedBox(width: 12),
                  summaryKpis,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _aggChannelFilterChip(String channelCode, String label, Color? brandColor) {
    final isSelected = _selectedAggregatorPlatform == channelCode;
    final activeColor = brandColor ?? const Color(0xFF1B4F72);

    return InkWell(
      onTap: () => setState(() => _selectedAggregatorPlatform = channelCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: isSelected ? activeColor : ClassicErpTheme.borderDark, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }

  Widget _buildAggregatorOrdersTable(HotelRepository repo, List<CustomerFoodOrderModel> orders) {
    const double minTableWidth = 980.0;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

          return Scrollbar(
            controller: _aggregatorHorizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _aggregatorHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: effectiveWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
          // Header Row
          Container(
            height: 28,
            color: ClassicErpTheme.gridHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Row(
              children: [
                SizedBox(width: 90, child: Text('CHANNEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 110, child: Text('ORDER / AGG ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 130, child: Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                Expanded(child: Text('ITEMS & INSTRUCTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 120, child: Text('RIDER & OTP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 75, child: Text('GROSS', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 75, child: Text('COMMISSION', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 80, child: Text('NET PAYOUT', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)))),
                SizedBox(width: 95, child: Center(child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))),
                SizedBox(width: 90, child: Center(child: Text('ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: ClassicErpTheme.borderDark),

          // Scrollable Table Body
          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1, thickness: 0.5, color: ClassicErpTheme.borderLight),
              itemBuilder: (context, index) {
                final order = orders[index];
                final isSelected = _selectedAggregatorOrder?.id == order.id;

                final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
                final specialNote = order.specialInstructions ?? '';

                return InkWell(
                  onTap: () => setState(() => _selectedAggregatorOrder = order),
                  child: Container(
                    height: 52,
                    color: isSelected
                        ? const Color(0xFFD4E6F1)
                        : (index.isEven ? Colors.white : const Color(0xFFFDFEFE)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Channel
                        SizedBox(
                          width: 90,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildChannelBadge(order.channel, fontSize: 8.5),
                          ),
                        ),

                        // Order ID & Time
                        SizedBox(
                          width: 110,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.aggregatorOrderId ?? order.id,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('hh:mm a').format(order.createdAt),
                                style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        // Customer
                        SizedBox(
                          width: 130,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                order.customerPhone,
                                style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        // Items & Special Instructions
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemsSummary,
                                style: const TextStyle(fontSize: 9.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (specialNote.isNotEmpty)
                                Text(
                                  'Note: $specialNote',
                                  style: const TextStyle(fontSize: 8.5, color: Color(0xFFC0392B), fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Rider & OTP
                        SizedBox(
                          width: 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.riderName ?? 'Rider Assigning...',
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (order.otp != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF9E7),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: const Color(0xFFF1C40F), width: 0.6),
                                  ),
                                  child: Text(
                                    'OTP: ${order.otp}',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFB7950B)),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Gross
                        SizedBox(
                          width: 75,
                          child: Text(
                            _currency.format(order.grandTotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Commission
                        SizedBox(
                          width: 75,
                          child: Text(
                            '-${_currency.format(order.commissionAmount)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFFC0392B), fontWeight: FontWeight.w600),
                          ),
                        ),

                        // Net Payout
                        SizedBox(
                          width: 80,
                          child: Text(
                            _currency.format(order.netPayout),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                          ),
                        ),

                        // Status Badge
                        SizedBox(
                          width: 95,
                          child: Center(child: _statusBadge(order.orderStatus)),
                        ),

                        // Actions
                        SizedBox(
                          width: 90,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (order.orderStatus == CustomerOrderStatus.placed)
                                IconButton(
                                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF27AE60)),
                                  tooltip: 'Accept & Send to Kitchen',
                                  onPressed: () {
                                    repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.kitchenPreparing);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order ${order.aggregatorOrderId ?? order.id} Accepted & Sent to KOT!')),
                                    );
                                  },
                                ),
                              if (order.orderStatus == CustomerOrderStatus.kitchenPreparing)
                                IconButton(
                                  icon: const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFF2980B9)),
                                  tooltip: 'Food Ready (Notify Rider)',
                                  onPressed: () {
                                    repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.outForDelivery);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Food Ready! Rider notified for handover.')),
                                    );
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 15, color: Color(0xFF1B4F72)),
                                tooltip: 'Print Aggregator Payout Slip',
                                onPressed: () => _printAggregatorPayoutSlip(context, repo, order),
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
          ),
        ],
      ),
    ),
    ),
    );
    },
    ),
    );
  }

  Widget _buildAggregatorOrderInspector(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    Color brandColor = const Color(0xFF1B4F72);
    if (order.channel.toLowerCase() == 'zomato') brandColor = const Color(0xFFCB202D);
    if (order.channel.toLowerCase() == 'swiggy') brandColor = const Color(0xFFFC8019);
    if (order.channel.toLowerCase() == 'magicpin') brandColor = const Color(0xFF7B1FA2);
    if (order.channel.toLowerCase() == 'ondc') brandColor = const Color(0xFF0D47A1);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Platform Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: brandColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildChannelBadge(order.channel, fontSize: 9.5),
                    const SizedBox(width: 8),
                    Text(
                      order.aggregatorOrderId ?? order.id,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                _statusBadge(order.orderStatus),
              ],
            ),
          ),

          // Scrollable details body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rider Pickup & OTP Verification Alert Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9E7),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFFF1C40F), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.delivery_dining_rounded, size: 16, color: Color(0xFFB7950B)),
                                SizedBox(width: 5),
                                Text(
                                  'PLATFORM RIDER PICKUP',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB7950B)),
                                ),
                              ],
                            ),
                            if (order.otp != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB7950B),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'OTP: ${order.otp}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rider: ${order.riderName ?? "Waiting for platform rider assignment..."}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                        ),
                        if (order.riderPhone != null && order.riderPhone!.isNotEmpty)
                          Text(
                            'Phone: ${order.riderPhone} • Vehicle: ${order.riderVehicleNo ?? "Bike"}',
                            style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                          ),
                        const SizedBox(height: 4),
                        const Text(
                          '⚠️ Check OTP with delivery partner before handing over food parcel.',
                          style: TextStyle(fontSize: 8.5, fontStyle: FontStyle.italic, color: Color(0xFF7D6608)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Special Cooking / Delivery Instructions
                  if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEDEC),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, size: 15, color: Color(0xFFC0392B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SPECIAL COOKING INSTRUCTIONS:',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.specialInstructions!,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Customer Details
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClassicErpTheme.panelBg,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CUSTOMER & DELIVERY LOCATION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(order.customerName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Phone: ${order.customerPhone}', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(order.deliveryAddress.fullAddress, style: const TextStyle(fontSize: 9.5)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Items List
                  const Text('ORDER ITEMS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      children: order.items.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}x',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item.name, style: const TextStyle(fontSize: 10)),
                              ),
                              Text(
                                _currency.format(item.price * item.quantity),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Financial Settlement Breakdown
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F9),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'AGGREGATOR PAYOUT RECONCILIATION',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                        const Divider(height: 10, thickness: 0.8),
                        _financeRow('Food Subtotal', _currency.format(order.itemTotal)),
                        _financeRow('GST & Taxes', _currency.format(order.gstAmount)),
                        _financeRow('Packaging Charges', _currency.format(order.packagingCharge)),
                        const Divider(height: 8, thickness: 0.5),
                        _financeRow('Gross Customer Bill', _currency.format(order.grandTotal), isBold: true),
                        _financeRow('Platform Commission Deducted', '-${_currency.format(order.commissionAmount)}', isRed: true, isBold: true),
                        const Divider(height: 10, thickness: 1, color: Color(0xFF27AE60)),
                        _financeRow('Net Restaurant Receivable', _currency.format(order.netPayout), isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      if (order.orderStatus == CustomerOrderStatus.placed)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.kitchenPreparing);
                              setState(() {
                                _selectedAggregatorOrder = repo.customerOrders.firstWhere((o) => o.id == order.id, orElse: () => order);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.aggregatorOrderId ?? order.id} Accepted! KOT generated.')),
                              );
                            },
                            icon: const Icon(Icons.check, size: 14, color: Colors.white),
                            label: const Text('Accept & KOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ),
                      if (order.orderStatus == CustomerOrderStatus.kitchenPreparing)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.outForDelivery);
                              setState(() {
                                _selectedAggregatorOrder = repo.customerOrders.firstWhere((o) => o.id == order.id, orElse: () => order);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Food Marked Ready & Handed over to Platform Rider!')),
                              );
                            },
                            icon: const Icon(Icons.delivery_dining_rounded, size: 15, color: Colors.white),
                            label: const Text('Handover to Rider', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2980B9),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ),
                      if (order.orderStatus == CustomerOrderStatus.outForDelivery)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              repo.updateCustomerOrderStatus(order.id, CustomerOrderStatus.delivered);
                              setState(() {
                                _selectedAggregatorOrder = repo.customerOrders.firstWhere((o) => o.id == order.id, orElse: () => order);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Aggregator Order marked as Delivered successfully!')),
                              );
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 15, color: Colors.white),
                            label: const Text('Mark Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _printAggregatorPayoutSlip(context, repo, order),
                        icon: const Icon(Icons.print_rounded, size: 14, color: ClassicErpTheme.textMain),
                        label: const Text('Slip', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatorEmptyState(BuildContext context, HotelRepository repo) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_download_outlined, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Aggregator Orders Yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
          ),
          const SizedBox(height: 4),
          const Text(
            'Orders placed on Zomato, Swiggy, Magicpin, ONDC, or UrbanPiper\nwill appear here in real-time via webhook.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _simulateAggregatorOrder(context, repo, 'Zomato'),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('+ Simulate Zomato', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCB202D)),
              ),
              ElevatedButton.icon(
                onPressed: () => _simulateAggregatorOrder(context, repo, 'Swiggy'),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('+ Simulate Swiggy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC8019)),
              ),
              ElevatedButton.icon(
                onPressed: () => _simulateAggregatorOrder(context, repo, 'Magicpin'),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('+ Simulate Magicpin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
              ),
              ElevatedButton.icon(
                onPressed: () => _simulateAggregatorOrder(context, repo, 'ONDC'),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('+ Simulate ONDC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _simulateAggregatorOrder(BuildContext context, HotelRepository repo, String platformName) {
    final sampleCustomers = [
      {'name': 'Aarav Sharma', 'phone': '+91 98201 12345', 'address': 'Flat 402, Sea Crest Towers, Worli, Mumbai'},
      {'name': 'Pooja Verma', 'phone': '+91 98192 67890', 'address': 'B-12, Palm Meadows, Powai, Mumbai'},
      {'name': 'Rohan Deshmukh', 'phone': '+91 99304 55443', 'address': 'Shop 4, Sunrise Arcade, Andheri East, Mumbai'},
      {'name': 'Neha Kulkarni', 'phone': '+91 98701 88992', 'address': 'House 21, Greenfield Colony, Vashi, Navi Mumbai'},
    ];

    final sampleRiders = [
      {'name': 'Ramesh Kumar', 'phone': '+91 98200 11223', 'vehicle': 'MH 02 AB 1234'},
      {'name': 'Sunil Jadhav', 'phone': '+91 98190 22334', 'vehicle': 'MH 03 CD 5678'},
      {'name': 'Deepak Shinde', 'phone': '+91 99300 33445', 'vehicle': 'MH 04 EF 9012'},
    ];

    final randomIdx = DateTime.now().millisecond % sampleCustomers.length;
    final riderIdx = (DateTime.now().microsecond ~/ 1000) % sampleRiders.length;
    final randNum = 10000 + (DateTime.now().millisecond * 9) % 89999;

    String aggCode = 'ZOM';
    if (platformName.toLowerCase() == 'swiggy') aggCode = 'SWG';
    if (platformName.toLowerCase() == 'magicpin') aggCode = 'MGC';
    if (platformName.toLowerCase() == 'ondc') aggCode = 'ONDC';
    final aggOrderId = '$aggCode-$randNum';

    final channelMatch = _channels.firstWhere(
      (c) => c.name.toLowerCase() == platformName.toLowerCase(),
      orElse: () => AggregatorChannelModel(
        id: platformName.toLowerCase(),
        name: platformName,
        code: aggCode,
        storeId: 'REST-$randNum',
        brandColor: Colors.teal,
        icon: Icons.hub,
        commissionPercentage: 18.0,
      ),
    );

    final itemOptions = [
      CustomerCartItem(menuItemId: 'agg-1', name: 'Paneer Butter Masala (Special)', price: 340, isVeg: true, quantity: 1, category: 'Main Course'),
      CustomerCartItem(menuItemId: 'agg-2', name: 'Butter Garlic Naan (2 Pcs)', price: 140, isVeg: true, quantity: 2, category: 'Tandoor'),
      CustomerCartItem(menuItemId: 'agg-3', name: 'Dum Hyderabadi Biryani', price: 420, isVeg: false, quantity: 1, category: 'Biryani'),
      CustomerCartItem(menuItemId: 'agg-4', name: 'Gulab Jamun (2 Pcs)', price: 110, isVeg: true, quantity: 1, category: 'Dessert'),
    ];

    final selectedItems = [itemOptions[0], itemOptions[1]];
    if (randomIdx.isOdd) selectedItems.add(itemOptions[2]);

    final subtotal = selectedItems.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    final gst = (subtotal * 0.05).roundToDouble();
    final packaging = 30.0;
    final grandTotal = subtotal + gst + packaging;
    final commission = (grandTotal * (channelMatch.commissionPercentage / 100)).roundToDouble();

    final fourDigitOtp = '${(1000 + (DateTime.now().microsecond % 9000))}';

    final newOrder = CustomerFoodOrderModel(
      id: 'ORD-AGG-${DateTime.now().millisecondsSinceEpoch % 100000}',
      branchId: repo.activeBranch.id,
      branchName: repo.activeBranch.name,
      customerId: 'agg-cust-$randNum',
      customerName: sampleCustomers[randomIdx]['name']!,
      customerPhone: sampleCustomers[randomIdx]['phone']!,
      deliveryAddress: CustomerAddressModel(
        id: 'addr-$randNum',
        label: 'Home',
        fullAddress: sampleCustomers[randomIdx]['address']!,
        distanceKmFromHotel: 3.2,
      ),
      items: selectedItems,
      itemTotal: subtotal,
      gstAmount: gst,
      deliveryFee: 0.0,
      packagingCharge: packaging,
      grandTotal: grandTotal,
      paymentMethod: OnlinePaymentMethod.upiGpay,
      paymentStatus: OnlinePaymentStatus.success,
      transactionId: 'TXN-$aggCode-$randNum',
      orderStatus: channelMatch.autoAcceptOrders ? CustomerOrderStatus.kitchenPreparing : CustomerOrderStatus.placed,
      riderName: '${sampleRiders[riderIdx]['name']} ($platformName Fleet)',
      riderPhone: sampleRiders[riderIdx]['phone'],
      riderVehicleNo: sampleRiders[riderIdx]['vehicle'],
      channel: platformName,
      aggregatorOrderId: aggOrderId,
      commissionAmount: commission,
      otp: fourDigitOtp,
      specialInstructions: randomIdx.isEven ? 'Make food less spicy. Extra paper napkins please.' : 'Ring bell twice upon arrival.',
      createdAt: DateTime.now(),
    );

    repo.addSimulatedCustomerOrder(newOrder);

    setState(() {
      _selectedAggregatorOrder = newOrder;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: channelMatch.brandColor,
        content: Row(
          children: [
            Icon(channelMatch.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚡ Incoming $platformName Order ($aggOrderId) — ${_currency.format(grandTotal)} (Net: ${_currency.format(newOrder.netPayout)})',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showAggregatorChannelConfigDialog(BuildContext context, AggregatorChannelModel channel) {
    final merchantCtrl = TextEditingController(text: channel.storeId);
    final keyCtrl = TextEditingController(text: channel.apiKey);
    final commCtrl = TextEditingController(text: channel.commissionPercentage.toStringAsFixed(1));
    bool isEnabled = channel.isEnabled;
    bool autoAccept = channel.autoAcceptOrders;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: channel.brandColor, borderRadius: BorderRadius.circular(3)),
                child: Icon(channel.icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                '${channel.name} Channel Configuration',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogTextField(merchantCtrl, 'Merchant / Store ID', hint: 'e.g. REST-99812'),
                  const SizedBox(height: 10),
                  _dialogTextField(keyCtrl, 'API Secret / Webhook Auth Token', hint: 'Bearer Token or Secret Key'),
                  const SizedBox(height: 10),
                  _dialogTextField(commCtrl, 'Platform Commission Rate (%)', hint: 'e.g. 18.0', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text('Store Online Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Accept live orders on this channel', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    value: isEnabled,
                    activeThumbColor: channel.brandColor,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => isEnabled = val),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-Accept Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Instantly send accepted orders directly to kitchen KOT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    value: autoAccept,
                    activeThumbColor: channel.brandColor,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => autoAccept = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              onPressed: () {
                final double? parsedComm = double.tryParse(commCtrl.text.trim());
                setState(() {
                  channel.storeId = merchantCtrl.text.trim();
                  channel.apiKey = keyCtrl.text.trim();
                  if (parsedComm != null) channel.commissionPercentage = parsedComm;
                  channel.isEnabled = isEnabled;
                  channel.autoAcceptOrders = autoAccept;
                });
                _saveChannelsState();
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${channel.name} configuration saved successfully!')),
                );
              },
              child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWebhookGuideDialog(BuildContext context) {
    final ip = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
    final webhookUrl = 'http://$ip:8088/api/aggregator/webhook';

    final curlExample = '''curl -X POST "$webhookUrl" \\
  -H "Content-Type: application/json" \\
  -d '{
    "channel": "Zomato",
    "order_id": "ZOM-99881",
    "customer": {
      "name": "Sameer Khan",
      "phone": "+91 98200 88776",
      "address": "Tower 2, Flat 1104, Hiranandani, Mumbai"
    },
    "items": [
      {"name": "Paneer Tikka Masala", "price": 320, "qty": 1},
      {"name": "Butter Roti", "price": 35, "qty": 3}
    ],
    "subtotal": 425.0,
    "tax": 21.25,
    "packaging": 25.0,
    "grand_total": 471.25,
    "commission_amount": 84.82,
    "rider": {
      "name": "Amit Solanki",
      "phone": "+91 98191 00998",
      "vehicle": "MH 01 AZ 7788"
    },
    "otp": "6642",
    "instructions": "Leave at door. Do not ring bell."
  }' ''';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: const Row(
          children: [
            Icon(Icons.integration_instructions_rounded, size: 20, color: Color(0xFF1B4F72)),
            SizedBox(width: 8),
            Text(
              'Aggregator Middleware & Webhook Architecture Guide',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How Orders Flow From Zomato / Swiggy Into Your Software:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FB),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF2980B9).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '[Customer Order] ➔ [Zomato / Swiggy / ONDC Cloud]\n'
                    '        ▼\n'
                    '[UrbanPiper / Aggregator Hub / Cloud Webhook]\n'
                    '        ▼ (HTTP POST JSON payload)\n'
                    '[Your Windows HotelPro HTTP Server : Port 8088]\n'
                    '        ▼ (Realtime SSE Broadcast)\n'
                    '[Online Delivery Terminal: Instant Beep & KOT Print]',
                    style: TextStyle(fontSize: 10, fontFamily: 'Consolas', height: 1.3, color: Color(0xFF1B4F72)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Live Webhook URL to paste in Aggregator Dashboard:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  color: Colors.black.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          webhookUrl,
                          style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: webhookUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied Webhook URL!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Test with cURL from Terminal / Command Prompt:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2833),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: SelectableText(
                    curlExample,
                    style: const TextStyle(fontSize: 9.5, fontFamily: 'Consolas', color: Color(0xFF58D68D)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72)),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close Guide', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _printAggregatorPayoutSlip(BuildContext context, HotelRepository repo, CustomerFoodOrderModel order) {
    Color brandColor = const Color(0xFF1B4F72);
    if (order.channel.toLowerCase() == 'zomato') brandColor = const Color(0xFFCB202D);
    if (order.channel.toLowerCase() == 'swiggy') brandColor = const Color(0xFFFC8019);
    if (order.channel.toLowerCase() == 'magicpin') brandColor = const Color(0xFF7B1FA2);
    if (order.channel.toLowerCase() == 'ondc') brandColor = const Color(0xFF0D47A1);

    final slipWidget = Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              repo.clientBusinessName.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              repo.activeBranch.name,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
          const Divider(thickness: 1, height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: brandColor.withValues(alpha: 0.1),
            child: Center(
              child: Text(
                '${order.channel.toUpperCase()} DISPATCH & PAYOUT SLIP',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Aggregator ID: ${order.aggregatorOrderId ?? order.id}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
              Text(DateFormat('dd-MMM hh:mm a').format(order.createdAt), style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          Text('Internal POS Order: ${order.id}', style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
          if (order.otp != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              color: const Color(0xFFFEF9E7),
              child: Text(
                'RIDER PICKUP OTP: ${order.otp}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB7950B)),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('Rider: ${order.riderName ?? "Aggregator Rider"}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
          Text('Customer: ${order.customerName} (${order.customerPhone})', style: const TextStyle(fontSize: 9)),
          const Divider(thickness: 0.8, height: 10),
          const Text('ORDER ITEMS:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  children: [
                    Text('${item.quantity}x ', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(item.name, style: const TextStyle(fontSize: 9))),
                    Text(_currency.format(item.price * item.quantity), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(thickness: 0.8, height: 10),
          _financeRow('Gross Food Bill', _currency.format(order.grandTotal)),
          _financeRow('Platform Comm. Deducted', '-${_currency.format(order.commissionAmount)}', isRed: true),
          const Divider(thickness: 1, height: 8),
          _financeRow('Net Restaurant Receivable', _currency.format(order.netPayout), isBold: true),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kitchen Steward: _________', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
              Text('Rider Sign: _________', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );

    PrintPreviewDialog.show(
      context,
      title: 'Aggregator_Payout_${order.id}',
      content: slipWidget,
    );
  }

  Widget _dialogTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: ClassicErpTheme.borderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: ClassicErpTheme.borderDark)),
            ),
          ),
        ),
      ],
    );
  }
}

