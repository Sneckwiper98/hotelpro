import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_constants.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';

class FloorRoomBedTab extends StatefulWidget {
  const FloorRoomBedTab({super.key});

  @override
  State<FloorRoomBedTab> createState() => _FloorRoomBedTabState();
}

class _FloorRoomBedTabState extends State<FloorRoomBedTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _subTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: AppTheme.imperialGold.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: AppTheme.imperialGold, width: 2)),
            ),
            dividerColor: AppTheme.slateBorder,
            labelColor: AppTheme.imperialGold,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(child: Row(children: [Icon(Icons.layers_rounded, size: 15), SizedBox(width: 6), Text('Floor Management')])),
              Tab(child: Row(children: [Icon(Icons.meeting_room_rounded, size: 15), SizedBox(width: 6), Text('Room Management')])),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _subTabController,
              children: [
                _buildFloorTab(context),
                _buildRoomTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorTab(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final floors = repo.activeBranchFloors;
    final rooms = repo.activeBranchRooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${repo.activeBranch.name} — Floors',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddFloorDialog(context, repo),
              icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
              label: const Text('Add Floor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: floors.isEmpty
              ? _empty('No floors configured. Add your first floor.')
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 130,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: floors.length,
                  itemBuilder: (ctx, i) {
                    final f = floors[i];
                    final floorNum = f['floor_number'] as int;
                    final roomCount = rooms.where((r) => r.floorNumber == floorNum).length;
                    final hasRooms = roomCount > 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.slateCardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.slateBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.imperialGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  floorNum == 0 ? 'G' : '$floorNum',
                                  style: const TextStyle(color: AppTheme.imperialGold, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(f['label'] as String,
                                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('$roomCount Room${roomCount != 1 ? 's' : ''}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!hasRooms)
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 16, color: AppTheme.statusOccupied),
                                  onPressed: () {
                                    repo.deleteFloor(floorNum);
                                  },
                                  tooltip: 'Delete Floor',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                )
                              else
                                const Text('Has rooms', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
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

  Widget _buildRoomTab(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final rooms = repo.activeBranchRooms;
    final roomTypes = repo.activeBranchRoomTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${rooms.length} rooms configured',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddRoomDialog(context, repo, roomTypes),
              icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
              label: const Text('Add Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minWidth = 750.0;
              final width = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.slateCardElevated,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          border: Border.all(color: AppTheme.slateBorder),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 80, child: Text('Room No.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            SizedBox(width: 80, child: Text('Floor', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            Expanded(child: Text('Room Type', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            SizedBox(width: 120, child: Text('Bed Type', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            SizedBox(width: 100, child: Text('Tariff', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            SizedBox(width: 80, child: Text('Status', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            SizedBox(width: 80, child: Text('Actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),

                      Expanded(
                        child: rooms.isEmpty
                            ? _empty('No rooms found. Add rooms to this branch.')
                            : ListView.builder(
                                itemCount: rooms.length,
                                itemBuilder: (ctx, i) {
                                  final r = rooms[i];
                                  Color statusColor;
                                  switch (r.status) {
                                    case RoomStatus.availableClean: statusColor = AppTheme.statusClean; break;
                                    case RoomStatus.occupied: statusColor = AppTheme.statusOccupied; break;
                                    case RoomStatus.dirtyVacant:
                                    case RoomStatus.cleaningInProgress: statusColor = AppTheme.statusDirty; break;
                                    default: statusColor = AppTheme.textMuted;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: i.isEven ? AppTheme.slateCard : AppTheme.obsidianBg,
                                      border: const Border(
                                        left: BorderSide(color: AppTheme.slateBorder),
                                        right: BorderSide(color: AppTheme.slateBorder),
                                        bottom: BorderSide(color: AppTheme.slateBorder),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(r.roomNumber,
                                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text('Floor ${r.floorNumber}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                        ),
                                        Expanded(
                                          child: Text(r.roomTypeName,
                                              style: const TextStyle(color: AppTheme.champagneAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(r.bedType,
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text(currency.format(r.basePrice),
                                              style: const TextStyle(color: AppTheme.textGold, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              r.status.label.split(' ').first,
                                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.imperialGold),
                                                onPressed: () => _showEditRoomDialog(context, repo, r),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              ),
                                              if (r.status != RoomStatus.occupied)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_rounded, size: 15, color: AppTheme.statusOccupied),
                                                  onPressed: () => repo.deleteRoom(r.id),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddFloorDialog(BuildContext context, HotelRepository repo) {
    int floorNumber = 1;
    final labelCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: const Text('Add New Floor', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: floorNumber,
                dropdownColor: AppTheme.slateCard,
                decoration: const InputDecoration(labelText: 'Floor Number (0 = Ground)'),
                items: List.generate(20, (i) => i).map((n) {
                  return DropdownMenuItem(value: n, child: Text(n == 0 ? 'Ground Floor (G)' : 'Floor $n'));
                }).toList(),
                onChanged: (v) => setS(() => floorNumber = v ?? floorNumber),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Floor Label (e.g. Floor 1 - Deluxe)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                repo.addFloor(floorNumber, label: labelCtrl.text.isNotEmpty ? labelCtrl.text : null);
                Navigator.pop(ctx);
              },
              child: const Text('Add Floor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context, HotelRepository repo, List roomTypes) {
    if (roomTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle Room Type add karein!'), backgroundColor: AppTheme.statusDirty),
      );
      return;
    }

    final roomNumCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    int floorNumber = 1;
    String roomTypeId = roomTypes.first.id;
    String bedType = 'King Size';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: const Text('Add New Room', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roomNumCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Room Number (e.g. 101, 201A)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: floorNumber,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Floor'),
                    items: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) {
                      return DropdownMenuItem(value: n, child: Text(n == 0 ? 'Ground Floor' : 'Floor $n'));
                    }).toList(),
                    onChanged: (v) => setS(() => floorNumber = v ?? floorNumber),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: roomTypeId,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Room Type'),
                    items: roomTypes.map<DropdownMenuItem<String>>((rt) {
                      return DropdownMenuItem(value: rt.id as String, child: Text(rt.name as String));
                    }).toList(),
                    onChanged: (v) {
                      setS(() {
                        roomTypeId = v ?? roomTypeId;
                        final rt = roomTypes.firstWhere((r) => r.id == roomTypeId);
                        priceCtrl.text = rt.basePrice.toStringAsFixed(0);
                        bedType = rt.bedType;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: bedType,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Bed Type'),
                    items: ['King Size', 'Queen Size', 'Twin Beds', 'Double Bed', 'Single Bed', 'Bunk Bed']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setS(() => bedType = v ?? bedType),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Custom Tariff (₹) — leave blank for room type default'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                if (roomNumCtrl.text.isEmpty) return;
                final rt = roomTypes.firstWhere((r) => r.id == roomTypeId);
                repo.addRoom(
                  roomNumber: roomNumCtrl.text.trim(),
                  floorNumber: floorNumber,
                  roomTypeId: roomTypeId,
                  basePrice: double.tryParse(priceCtrl.text) ?? rt.basePrice as double,
                  bedType: bedType,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Add Room', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomDialog(BuildContext context, HotelRepository repo, dynamic room) {
    final priceCtrl = TextEditingController(text: room.basePrice.toStringAsFixed(0));
    String bedType = room.bedType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: Text('Edit Room ${room.roomNumber}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: bedType,
                dropdownColor: AppTheme.slateCard,
                decoration: const InputDecoration(labelText: 'Bed Type'),
                items: ['King Size', 'Queen Size', 'Twin Beds', 'Double Bed', 'Single Bed']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setS(() => bedType = v ?? bedType),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Tariff / Night (₹)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                repo.updateRoom(room.id as String, basePrice: double.tryParse(priceCtrl.text), bedType: bedType);
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.layers_rounded, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      ],
    ),
  );
}
