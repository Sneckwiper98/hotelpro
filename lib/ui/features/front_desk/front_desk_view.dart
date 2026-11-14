import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/security_service.dart';
import '../../core/classic/classic_form_widgets.dart';
import '../../core/classic/dialogs/maintenance_work_orders_dialog.dart';

/// Classic Windows Desktop Front Desk & Room Matrix
/// High-density room grid, crisp 1px borders, Win32 filter bar and dialogs.
class FrontDeskView extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const FrontDeskView({super.key, required this.onNavigateToTab});

  @override
  State<FrontDeskView> createState() => _FrontDeskViewState();
}

class _FrontDeskViewState extends State<FrontDeskView> {
  String _selectedFloor = 'all';
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final rooms = repo.activeBranchRooms;

    // Active maintenance tickets
    final activeDefects = repo.activeBranchMaintenanceTickets
        .where((t) => t.status != MaintenanceStatus.resolved)
        .toList();
    final defectRoomIds = activeDefects.map((t) => t.roomId).toSet();

    // Live counts for quick-filter pills
    final totalCount = rooms.length;
    final availableCleanCount = rooms.where((r) => r.status == RoomStatus.availableClean || r.status == RoomStatus.cleanInspected).length;
    final occupiedCount = rooms.where((r) => r.status == RoomStatus.occupied).length;
    final dirtyCount = rooms.where((r) => r.status == RoomStatus.dirtyVacant).length;
    final inCleaningCount = rooms.where((r) => r.status == RoomStatus.cleaningInProgress).length;
    final defectCount = defectRoomIds.length;

    // Filter rooms
    final filteredRooms = rooms.where((r) {
      if (_selectedFloor != 'all' && r.floorNumber.toString() != _selectedFloor) {
        return false;
      }
      if (_selectedStatus != 'all') {
        if (_selectedStatus == 'defect') {
          if (!defectRoomIds.contains(r.id)) return false;
        } else if (_selectedStatus == RoomStatus.availableClean.code) {
          if (r.status != RoomStatus.availableClean && r.status != RoomStatus.cleanInspected) {
            return false;
          }
        } else if (r.status.code != _selectedStatus) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesRoom = r.roomNumber.toLowerCase().contains(q);
        final matchesGuest = r.currentGuestName?.toLowerCase().contains(q) ?? false;
        final matchesType = r.roomTypeName.toLowerCase().contains(q);
        if (!matchesRoom && !matchesGuest && !matchesType) return false;
      }
      return true;
    }).toList();

    // Available floors in active branch
    final floors = rooms.map((r) => r.floorNumber).toSet().toList()..sort();

    return Container(
      color: ClassicErpTheme.windowBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Classic Filter & Search Ribbon Bar ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
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
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: ClassicErpTheme.mdiHeaderActive.withOpacity(0.1),
                                borderRadius: ClassicErpTheme.radiusSm,
                              ),
                              child: const Icon(Icons.grid_view_rounded, size: 16, color: ClassicErpTheme.mdiHeaderActive),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Live Room Matrix & Operations',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: ClassicErpTheme.textMain,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: ClassicErpTheme.radiusSm,
                                border: Border.all(color: ClassicErpTheme.borderLight),
                              ),
                              child: Text(
                                '${repo.activeBranch.name.toUpperCase()} • $totalCount ROOMS',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ClassicErpTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Search Input Box
                        ClassicErpSearchField(
                          hintText: 'Search room, guest, type...',
                          width: 240,
                          height: 28,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── 2. Interactive Status Filter Pills & Floor Filter ─────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Floor:', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  _buildFloorPill('All Floors', 'all'),
                  for (final floor in floors) ...[
                    const SizedBox(width: 4),
                    _buildFloorPill('Floor $floor', floor.toString()),
                  ],

                  const SizedBox(width: 14),
                  Container(width: 1, height: 20, color: ClassicErpTheme.borderLight),
                  const SizedBox(width: 14),

                  const Text('Filter:', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  _buildStatusPill('All Rooms', 'all', totalCount, const Color(0xFF0F3A60)),
                  const SizedBox(width: 5),
                  _buildStatusPill('🟢 Ready', RoomStatus.availableClean.code, availableCleanCount, const Color(0xFF059669)),
                  const SizedBox(width: 5),
                  _buildStatusPill('🔴 Occupied', RoomStatus.occupied.code, occupiedCount, const Color(0xFFDC2626)),
                  const SizedBox(width: 5),
                  _buildStatusPill('🟠 Dirty', RoomStatus.dirtyVacant.code, dirtyCount, const Color(0xFFD97706)),
                  const SizedBox(width: 5),
                  _buildStatusPill('🔵 In Cleaning', RoomStatus.cleaningInProgress.code, inCleaningCount, const Color(0xFF2563EB)),
                  const SizedBox(width: 5),
                  _buildStatusPill(
                    '🔧 Defect Alert',
                    'defect',
                    defectCount,
                    defectCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    isAlert: defectCount > 0,
                  ),
                ],
              ),
            ),
          ),

          // ── 3. High-Density Modern Room Grid ─────────────────────────────
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text(
                          'No rooms match your filter criteria.',
                          style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: ClassicErpTheme.windowBg,
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 156,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final room = filteredRooms[index];
                        final hasDefect = defectRoomIds.contains(room.id);
                        return _buildModernRoomCard(context, room, repo, hasDefect);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPill(String label, String value) {
    final isSelected = _selectedFloor == value;
    return InkWell(
      borderRadius: ClassicErpTheme.radiusSm,
      onTap: () => setState(() => _selectedFloor = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE2E8F0) : Colors.white,
          borderRadius: ClassicErpTheme.radiusSm,
          border: Border.all(
            color: isSelected ? const Color(0xFF0F3A60) : ClassicErpTheme.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0F3A60) : ClassicErpTheme.textMain,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, String value, int count, Color accentColor, {bool isAlert = false}) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      borderRadius: ClassicErpTheme.radiusSm,
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.12)
              : (isAlert ? const Color(0xFFFEF2F2) : Colors.white),
          borderRadius: ClassicErpTheme.radiusSm,
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isAlert ? const Color(0xFFFCA5A5) : ClassicErpTheme.borderLight),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : (isAlert ? const Color(0xFFB91C1C) : ClassicErpTheme.textMain),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : ClassicErpTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRoomCard(BuildContext context, RoomModel room, HotelRepository repo, bool hasDefect) {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (room.status) {
      case RoomStatus.availableClean:
      case RoomStatus.cleanInspected:
        statusColor = const Color(0xFF059669);
        statusTitle = 'READY';
        statusIcon = Icons.check_circle_outline;
        break;
      case RoomStatus.occupied:
        statusColor = const Color(0xFFDC2626);
        statusTitle = 'OCCUPIED';
        statusIcon = Icons.person_outline;
        break;
      case RoomStatus.dirtyVacant:
        statusColor = const Color(0xFFD97706);
        statusTitle = 'DIRTY';
        statusIcon = Icons.cleaning_services_outlined;
        break;
      case RoomStatus.cleaningInProgress:
        statusColor = const Color(0xFF2563EB);
        statusTitle = 'CLEANING';
        statusIcon = Icons.autorenew_rounded;
        break;
      case RoomStatus.reserved:
        statusColor = const Color(0xFF7C3AED);
        statusTitle = 'RESERVED';
        statusIcon = Icons.bookmark_border_rounded;
        break;
      case RoomStatus.outOfOrder:
        statusColor = const Color(0xFF475569);
        statusTitle = 'O.O.O.';
        statusIcon = Icons.block_rounded;
        break;
    }

    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ClassicErpTheme.radiusSm,
        border: Border.all(
          color: hasDefect ? const Color(0xFFEF4444) : ClassicErpTheme.borderLight,
          width: hasDefect ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar: Room Number & Status Tag
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 5),
                Text(
                  'ROOM ${room.roomNumber}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                if (hasDefect) ...[
                  InkWell(
                    onTap: () {
                      MaintenanceWorkOrdersDialog.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_rounded, size: 9, color: Colors.white),
                          SizedBox(width: 2),
                          Text('DEFECT', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    statusTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // Room Details & Rate
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.roomTypeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F3A60),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      currency.format(room.basePrice),
                      style: const TextStyle(
                        color: ClassicErpTheme.textMain,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Floor ${room.floorNumber} • ₹${room.basePrice.toStringAsFixed(0)}/night',
                  style: const TextStyle(color: ClassicErpTheme.textMuted, fontSize: 9.5),
                ),
              ],
            ),
          ),

          // Occupancy or Operational State
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ClassicErpTheme.borderLight),
            ),
            child: room.status == RoomStatus.occupied
                ? Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          room.currentGuestName ?? 'In-House Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                        ),
                      ),
                      if (room.currentGuestVip != null)
                        Text(
                          '★ ${room.currentGuestVip!.label}',
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        room.status == RoomStatus.dirtyVacant ? Icons.cleaning_services_rounded : Icons.check_circle_outline_rounded,
                        size: 12,
                        color: room.status == RoomStatus.dirtyVacant ? const Color(0xFFD97706) : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room.status == RoomStatus.dirtyVacant ? 'Housekeeping Required' : 'Ready for Check-In',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: room.status == RoomStatus.dirtyVacant ? const Color(0xFFD97706) : const Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),

          const Spacer(),

          // Inline Quick Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
              border: Border(top: BorderSide(color: ClassicErpTheme.borderLight)),
            ),
            child: Row(
              children: [
                if (room.status == RoomStatus.occupied) ...[
                  Expanded(
                    child: _inlineCardBtn('Folio', Icons.receipt_long_rounded, () {
                      widget.onNavigateToTab(1);
                    }, color: const Color(0xFF0F3A60)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _inlineCardBtn('Details', Icons.open_in_new_rounded, () {
                      _showRoomDetailsModal(context, room, repo);
                    }, color: const Color(0xFF475569)),
                  ),
                ] else if (room.status == RoomStatus.dirtyVacant || room.status == RoomStatus.cleaningInProgress) ...[
                  Expanded(
                    child: _inlineCardBtn('Mark Clean', Icons.done_all_rounded, () {
                      repo.updateRoomStatus(room.id, RoomStatus.cleanInspected);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Room ${room.roomNumber} marked inspected and clean.'),
                          backgroundColor: const Color(0xFF059669),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }, color: const Color(0xFF059669)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _inlineCardBtn('Details', Icons.open_in_new_rounded, () {
                      _showRoomDetailsModal(context, room, repo);
                    }, color: const Color(0xFF475569)),
                  ),
                ] else ...[
                  Expanded(
                    child: _inlineCardBtn('Check In', Icons.login_rounded, () {
                      _showExpressCheckInDialog(context, room, repo);
                    }, color: const Color(0xFF0F3A60)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _inlineCardBtn('Details', Icons.open_in_new_rounded, () {
                      _showRoomDetailsModal(context, room, repo);
                    }, color: const Color(0xFF475569)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineCardBtn(String label, IconData icon, VoidCallback onTap, {required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Room Details & Actions Modal
  void _showRoomDetailsModal(BuildContext context, RoomModel room, HotelRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) {
        final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return Dialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: ClassicErpTheme.panelBg,
              border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Title Bar
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFF1B4F72),
                  child: Row(
                    children: [
                      const Icon(Icons.hotel_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Room ${room.roomNumber} - Operations & Folio Management',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          color: const Color(0xFFC0392B),
                          child: const Icon(Icons.close, size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Box
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Room Type: ${room.roomTypeName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Floor Number: ${room.floorNumber} | Base Rate: ${currency.format(room.basePrice)}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              color: const Color(0xFF1B4F72),
                              child: Text(room.status.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (room.status == RoomStatus.occupied) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: Color(0xFF1B4F72)),
                                  const SizedBox(width: 6),
                                  Text(
                                    room.currentGuestName ?? 'In-House Guest',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  if (room.currentGuestVip != null)
                                    Text('★ ${room.currentGuestVip!.label}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD35400))),
                                ],
                              ),
                              if (room.notes != null) ...[
                                const SizedBox(height: 4),
                                Text('Notes: ${room.notes}', style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            _classicModalButton('Master Folio', () {
                              Navigator.pop(ctx);
                              widget.onNavigateToTab(1);
                            }),
                            const SizedBox(width: 6),
                            _classicModalButton('Room Service POS', () {
                              Navigator.pop(ctx);
                              widget.onNavigateToTab(2);
                            }),
                            const Spacer(),
                            _classicModalButton('Express Check-Out', () {
                              repo.checkOutGuest(roomId: room.id);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Room ${room.roomNumber} checked out. Marked dirty for turnover.'),
                                  backgroundColor: ClassicErpTheme.mdiHeaderActive,
                                ),
                              );
                            }, color: const Color(0xFFC0392B), textColor: Colors.white),
                          ],
                        ),
                      ] else if (room.status == RoomStatus.availableClean || room.status == RoomStatus.cleanInspected) ...[
                        const Text(
                          'Room is clean and available. Click below to execute immediate check-in.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF27AE60), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _classicModalButton('Express Check-In (< 60s)', () {
                              Navigator.pop(ctx);
                              _showExpressCheckInDialog(context, room, repo);
                            }, color: const Color(0xFF1B4F72), textColor: Colors.white),
                            const SizedBox(width: 6),
                            _classicModalButton('Mark Out of Order', () {
                              repo.updateRoomStatus(room.id, RoomStatus.outOfOrder);
                              Navigator.pop(ctx);
                            }),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Room status is ${room.status.label}. Cleaning task is assigned to housekeeping.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFD35400), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _classicModalButton('Approve & Mark Clean', () {
                              repo.updateRoomStatus(room.id, RoomStatus.cleanInspected);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Room ${room.roomNumber} marked inspected and clean.'), backgroundColor: const Color(0xFF27AE60)),
                              );
                            }, color: const Color(0xFF27AE60), textColor: Colors.white),
                            const SizedBox(width: 6),
                            _classicModalButton('Open Housekeeping', () {
                              Navigator.pop(ctx);
                              widget.onNavigateToTab(3);
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _classicModalButton(String label, VoidCallback onTap, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color ?? ClassicErpTheme.buttonBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? ClassicErpTheme.textMain,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Express Check-In Dialog
  void _showExpressCheckInDialog(BuildContext context, RoomModel room, HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idNumberCtrl = TextEditingController();
    final advanceCtrl = TextEditingController(text: room.basePrice.toStringAsFixed(0));
    String idType = 'Aadhaar Card';
    int nights = 1;
    VipTier selectedVip = VipTier.regular;
    PaymentMethod paymentMethod = PaymentMethod.creditCard;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              width: 520,
              decoration: BoxDecoration(
                color: ClassicErpTheme.panelBg,
                border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF1B4F72),
                    child: Row(
                      children: [
                        const Icon(Icons.how_to_reg_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Express Check-In & KYC Registration: Room ${room.roomNumber}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            color: const Color(0xFFC0392B),
                            child: const Icon(Icons.close, size: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _classicFormField('Guest Full Name *', nameCtrl),
                        const SizedBox(height: 8),
                        _classicFormField('Mobile Phone / WhatsApp *', phoneCtrl),
                        const SizedBox(height: 8),

                        // KYC Government ID Verification
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ClassicErpDropdown<String>(
                                label: 'Govt. Photo ID Type',
                                value: idType,
                                height: 28,
                                items: ['Aadhaar Card', 'Passport', 'Driving License', 'Voter ID Card', 'PAN Card'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => idType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _classicFormField('ID Doc Number *', idNumberCtrl),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ClassicErpDropdown<VipTier>(
                                label: 'VIP Club Tier',
                                value: selectedVip,
                                height: 28,
                                items: VipTier.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedVip = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClassicErpDropdown<int>(
                                label: 'Nights',
                                value: nights,
                                height: 28,
                                items: [1, 2, 3, 4, 5, 7, 14].map((n) => DropdownMenuItem(value: n, child: Text('$n Night(s)'))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => nights = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _classicFormField('Advance Deposit (₹)', advanceCtrl),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClassicErpDropdown<PaymentMethod>(
                                label: 'Payment Mode',
                                value: paymentMethod,
                                height: 28,
                                items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => paymentMethod = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(8),
                          color: const Color(0xFFD4E6F1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Total (Tariff + 18% GST):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${((room.basePrice * nights) * 1.18).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _classicModalButton('Cancel', () => Navigator.pop(ctx)),
                            const SizedBox(width: 8),
                            _classicModalButton('Confirm Check-In', () {
                              if (nameCtrl.text.isEmpty) return;
                              final adv = double.tryParse(advanceCtrl.text) ?? 0.0;

                              repo.checkInGuest(
                                roomId: room.id,
                                guestName: nameCtrl.text,
                                guestPhone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : '+91 98000 00000',
                                vipTier: selectedVip,
                                roomTypeName: room.roomTypeName,
                                ratePerNight: room.basePrice,
                                numberOfNights: nights,
                                advancePayment: adv,
                                advanceMethod: paymentMethod,
                              );

                              repo.logSecurityEvent(
                                action: 'GUEST_CHECKIN_EXECUTED',
                                category: 'Front Desk',
                                severity: 'info',
                                details: 'Guest ${nameCtrl.text} checked into Room ${room.roomNumber} for $nights night(s). KYC ID: $idType [${SecurityService.maskAadhaar(idNumberCtrl.text)}]',
                                entityId: 'Room ${room.roomNumber}',
                              );

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Guest ${nameCtrl.text} checked into Room ${room.roomNumber}! Master Folio generated.'),
                                  backgroundColor: const Color(0xFF27AE60),
                                ),
                              );
                            }, color: const Color(0xFF1B4F72), textColor: Colors.white),
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

  Widget _classicFormField(String label, TextEditingController controller) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();
    return ClassicErpInput(
      label: cleanLabel,
      isRequired: isReq,
      controller: controller,
      height: 28,
      isNumeric: label.contains('₹') || label.toLowerCase().contains('phone') || label.toLowerCase().contains('advance'),
    );
  }
}
