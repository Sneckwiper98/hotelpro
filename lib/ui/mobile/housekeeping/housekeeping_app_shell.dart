import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../../../data/services/app_update_service.dart';
import '../components/mobile_app_scaffold.dart';
import '../components/mobile_staff_login_view.dart';

class HousekeepingAppShell extends StatefulWidget {
  final VoidCallback? onBackToGateway;
  final Function(MobileAppRole role)? onSwitchRole;

  const HousekeepingAppShell({
    super.key,
    this.onBackToGateway,
    this.onSwitchRole,
  });

  @override
  State<HousekeepingAppShell> createState() => _HousekeepingAppShellState();
}

class _HousekeepingAppShellState extends State<HousekeepingAppShell> {
  StaffProfileAuth? _authenticatedStaff;



  String _selectedFloorFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _searchRoomQuery = '';
  String get _staffMember => _authenticatedStaff?.name ?? 'Sunita Sharma';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndPrompt(context, targetApp: AppTarget.housekeeping, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;
    final allRooms = repo.activeBranchRooms;

    // ── Authentication Gate ───────────────────────────────────────────────
    if (_authenticatedStaff == null) {
      return MobileStaffLoginView(
        role: MobileAppRole.housekeeping,
        appTitle: 'Housekeeping & Inspection',
        appSubtitle: 'Room Cleanliness, Sanitization & Maintenance Inspection',
        onAuthenticate: (profile) {
          setState(() {
            _authenticatedStaff = profile;
          });
        },
        onBackToGateway: widget.onBackToGateway,
      );
    }

    // Filters
    final dirtyCount = allRooms.where((r) => r.status == RoomStatus.dirtyVacant).length;
    final inProgressCount = allRooms.where((r) => r.status == RoomStatus.cleaningInProgress).length;
    final cleanCount = allRooms.where((r) => r.status == RoomStatus.availableClean || r.status == RoomStatus.cleanInspected).length;
    final oooCount = allRooms.where((r) => r.status == RoomStatus.outOfOrder).length;

    final filteredRooms = allRooms.where((room) {
      if (_selectedFloorFilter != 'All' && 'Floor ${room.floorNumber}' != _selectedFloorFilter) {
        return false;
      }
      if (_selectedStatusFilter == 'Dirty' && room.status != RoomStatus.dirtyVacant) {
        return false;
      }
      if (_selectedStatusFilter == 'In Progress' && room.status != RoomStatus.cleaningInProgress) {
        return false;
      }
      if (_selectedStatusFilter == 'Clean' &&
          room.status != RoomStatus.availableClean &&
          room.status != RoomStatus.cleanInspected) {
        return false;
      }
      if (_selectedStatusFilter == 'Out of Order' && room.status != RoomStatus.outOfOrder) {
        return false;
      }
      if (_searchRoomQuery.isNotEmpty && !room.roomNumber.contains(_searchRoomQuery)) {
        return false;
      }
      return true;
    }).toList();

    return MobileAppScaffold(
      title: 'Housekeeping & Inspection',
      subtitle: '${activeBranch.name} • ${_authenticatedStaff!.name}',
      currentRole: MobileAppRole.housekeeping,
      onBack: widget.onBackToGateway,
      onSwitchRole: widget.onSwitchRole,
      operatorName: _authenticatedStaff!.name,
      operatorRole: _authenticatedStaff!.role,
      operatorEmoji: _authenticatedStaff!.avatarEmoji,
      onLogout: () => setState(() => _authenticatedStaff = null),
      body: Column(
        children: [
          // Top Metrics Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusMetricCard('Dirty', '$dirtyCount', const Color(0xFFC0392B), 'Dirty'),
                _statusMetricCard('Cleaning', '$inProgressCount', const Color(0xFFD35400), 'In Progress'),
                _statusMetricCard('Clean / Ready', '$cleanCount', const Color(0xFF27AE60), 'Clean'),
                _statusMetricCard('Out of Order', '$oooCount', Colors.grey.shade700, 'Out of Order'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Floor & Search Ribbon
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Row(
              children: [
                // Floor Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFloorFilter,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Floors')),
                        DropdownMenuItem(value: 'Floor 1', child: Text('Floor 1')),
                        DropdownMenuItem(value: 'Floor 2', child: Text('Floor 2')),
                        DropdownMenuItem(value: 'Floor 3', child: Text('Floor 3')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFloorFilter = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Search Room
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchRoomQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search Room No...',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Room List
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No rooms matching filters', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filteredRooms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _buildRoomCard(ctx, repo, filteredRooms[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusMetricCard(String title, String count, Color color, String filterKey) {
    final isSelected = _selectedStatusFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatusFilter = isSelected ? 'All' : filterKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, HotelRepository repo, RoomModel room) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (room.status) {
      case RoomStatus.dirtyVacant:
        statusColor = const Color(0xFFC0392B);
        statusLabel = 'DIRTY (VACANT)';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case RoomStatus.cleaningInProgress:
        statusColor = const Color(0xFFD35400);
        statusLabel = 'CLEANING IN PROGRESS';
        statusIcon = Icons.cleaning_services_rounded;
        break;
      case RoomStatus.cleanInspected:
        statusColor = const Color(0xFF27AE60);
        statusLabel = 'INSPECTED (VIP READY)';
        statusIcon = Icons.verified_rounded;
        break;
      case RoomStatus.availableClean:
        statusColor = const Color(0xFF2ECC71);
        statusLabel = 'CLEAN & READY';
        statusIcon = Icons.check_circle_rounded;
        break;
      case RoomStatus.outOfOrder:
        statusColor = Colors.grey.shade700;
        statusLabel = 'OUT OF ORDER';
        statusIcon = Icons.build_rounded;
        break;
      case RoomStatus.occupied:
        statusColor = const Color(0xFF2980B9);
        statusLabel = 'OCCUPIED';
        statusIcon = Icons.hotel_rounded;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusLabel = room.status.label.toUpperCase();
        statusIcon = Icons.meeting_room_rounded;
        break;
    }

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Room Number + Floor + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C3483).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ROOM ${room.roomNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C3483),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Floor ${room.floorNumber} • ${room.roomTypeName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Guest / Notes
          if (room.currentGuestName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Color(0xFF2980B9)),
                  const SizedBox(width: 4),
                  Text(
                    'In-House Guest: ${room.currentGuestName}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                  ),
                ],
              ),
            ),
          if (room.notes != null && room.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Note: ${room.notes}',
                style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontStyle: FontStyle.italic),
              ),
            ),

          const Divider(height: 12),

          // Action Buttons
          Row(
            children: [
              if (room.status == RoomStatus.dirtyVacant)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD35400),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      repo.updateRoomHousekeepingStatus(
                        roomId: room.id,
                        newStatus: RoomStatus.cleaningInProgress,
                        staffName: _staffMember,
                      );
                      HotelSyncBridgeService.instance.sendHousekeepingUpdateToWindowsErp(
                        roomId: room.id,
                        newStatus: RoomStatus.cleaningInProgress,
                        staffName: _staffMember,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Room ${room.roomNumber} set to Cleaning in Progress')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start Cleaning', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (room.status == RoomStatus.cleaningInProgress || room.status == RoomStatus.dirtyVacant) ...[
                if (room.status == RoomStatus.dirtyVacant) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showInspectionChecklistSheet(context, repo, room),
                    icon: const Icon(Icons.checklist_rounded, size: 16),
                    label: const Text('Inspect & Clean', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              if (room.status == RoomStatus.availableClean || room.status == RoomStatus.cleanInspected) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Color(0xFFC0392B)),
                    ),
                    onPressed: () {
                      repo.updateRoomHousekeepingStatus(
                        roomId: room.id,
                        newStatus: RoomStatus.dirtyVacant,
                        staffName: _staffMember,
                      );
                      HotelSyncBridgeService.instance.sendHousekeepingUpdateToWindowsErp(
                        roomId: room.id,
                        newStatus: RoomStatus.dirtyVacant,
                        staffName: _staffMember,
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Mark Dirty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3483),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showInspectionChecklistSheet(context, repo, room),
                    icon: const Icon(Icons.verified_rounded, size: 14),
                    label: const Text('Re-Inspect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.build_rounded, size: 16, color: Colors.grey),
                tooltip: 'Report Defect / Maintenance',
                onPressed: () => _showMaintenanceReportDialog(context, repo, room),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Inspection Checklist Modal ────────────────────────────────────────────
  void _showInspectionChecklistSheet(BuildContext context, HotelRepository repo, RoomModel room) {
    final checklist = [
      {'title': 'Bed linen, pillows & duvet replaced with fresh laundry', 'checked': true},
      {'title': 'Bathroom scrubbed, sanitised & 4 fresh towels placed', 'checked': true},
      {'title': 'Complimentary toiletries & dental kits restocked', 'checked': true},
      {'title': 'Mini-bar checked & 2 packaged water bottles replenished', 'checked': true},
      {'title': 'Air Conditioner cooling & remote control functional', 'checked': true},
      {'title': 'Smart TV, cable channels & Wi-Fi signal verified', 'checked': true},
      {'title': 'Dustbins emptied & carpets/floor vacuumed & mopped', 'checked': true},
    ];

    final TextEditingController notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.roomNumber} Inspection Checklist',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6C3483)),
                      ),
                      Text('Floor ${room.floorNumber} • ${room.roomTypeName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text('VIP AUDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6C3483))),
                  ),
                ],
              ),
              const Divider(height: 18),
              ...checklist.map((item) => CheckboxListTile(
                    value: item['checked'] as bool,
                    onChanged: (val) {
                      setSheetState(() {
                        item['checked'] = val ?? false;
                      });
                    },
                    title: Text(item['title'] as String, style: const TextStyle(fontSize: 12)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF27AE60),
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Supervisor Inspection Notes (Optional)',
                  hintText: 'e.g. Room pristine & fragranced. Ready for check-in.',
                  hintStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    repo.updateRoomHousekeepingStatus(
                      roomId: room.id,
                      newStatus: RoomStatus.cleanInspected,
                      staffName: _staffMember,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Inspected & Approved by $_staffMember',
                    );
                    HotelSyncBridgeService.instance.sendHousekeepingUpdateToWindowsErp(
                      roomId: room.id,
                      newStatus: RoomStatus.cleanInspected,
                      staffName: _staffMember,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Inspected & Approved by $_staffMember',
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Room ${room.roomNumber} approved as VIP Clean & Ready!')),
                    );
                  },
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('APPROVE & MARK VIP READY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Report Maintenance Issue Dialog ───────────────────────────────────────
  void _showMaintenanceReportDialog(BuildContext context, HotelRepository repo, RoomModel room) {
    final descCtrl = TextEditingController();
    String category = 'Air Conditioning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.build_rounded, color: Color(0xFFC0392B), size: 20),
              const SizedBox(width: 8),
              Text('Report Issue: Room ${room.roomNumber}', style: const TextStyle(fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DEFECT CATEGORY:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Air Conditioning', child: Text('Air Conditioning (AC)')),
                  DropdownMenuItem(value: 'Plumbing & Water', child: Text('Plumbing / Water Leakage')),
                  DropdownMenuItem(value: 'Electrical & Lighting', child: Text('Electrical & Lighting')),
                  DropdownMenuItem(value: 'Smart TV & Cable', child: Text('Smart TV / Wi-Fi Issue')),
                  DropdownMenuItem(value: 'Door Lock / RFID Key', child: Text('Door Lock / Keycard RFID')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => category = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Defect Description',
                  hintText: 'e.g. AC compressor tripping; water dripping near balcony',
                  hintStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                backgroundColor: const Color(0xFFC0392B),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final issue = '$category: ${descCtrl.text.trim()}';
                repo.reportRoomMaintenanceIssue(
                  roomId: room.id,
                  issueDescription: issue,
                  reportedBy: _staffMember,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Room ${room.roomNumber} set to Out of Order for maintenance')),
                );
              },
              child: const Text('Mark Out of Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
