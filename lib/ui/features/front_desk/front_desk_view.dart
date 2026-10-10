import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_form_widgets.dart';

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

    // Filter rooms
    final filteredRooms = rooms.where((r) {
      if (_selectedFloor != 'all' && r.floorNumber.toString() != _selectedFloor) {
        return false;
      }
      if (_selectedStatus != 'all' && r.status.code != _selectedStatus) {
        return false;
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: ClassicErpTheme.panelBg,
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
                            const Icon(Icons.table_rows_rounded, size: 16, color: ClassicErpTheme.mdiHeaderActive),
                            const SizedBox(width: 6),
                            const Text(
                              'Live Room Matrix & Tape Chart',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ClassicErpTheme.textMain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• [${repo.activeBranch.name.toUpperCase()} - ${rooms.length} Rooms]',
                              style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Search Input Box
                        ClassicErpSearchField(
                          hintText: 'Search room, guest...',
                          width: 220,
                          height: 26,
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

          // ── 2. Floor & Status Filter Chips ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F4),
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Floor:', style: TextStyle(color: ClassicErpTheme.textMain, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  _buildClassicFilterChip('All Floors', 'all', _selectedFloor, (val) => setState(() => _selectedFloor = val)),
                  for (final floor in floors) ...[
                    const SizedBox(width: 4),
                    _buildClassicFilterChip('Floor $floor', floor.toString(), _selectedFloor, (val) => setState(() => _selectedFloor = val)),
                  ],

                  const SizedBox(width: 14),
                  Container(width: 1, height: 16, color: ClassicErpTheme.borderLight),
                  const SizedBox(width: 14),

                  const Text('Status:', style: TextStyle(color: ClassicErpTheme.textMain, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  _buildClassicFilterChip('All Status', 'all', _selectedStatus, (val) => setState(() => _selectedStatus = val)),
                  const SizedBox(width: 4),
                  _buildClassicFilterChip('Available', RoomStatus.availableClean.code, _selectedStatus, (val) => setState(() => _selectedStatus = val), badgeColor: const Color(0xFF27AE60)),
                  const SizedBox(width: 4),
                  _buildClassicFilterChip('Occupied', RoomStatus.occupied.code, _selectedStatus, (val) => setState(() => _selectedStatus = val), badgeColor: const Color(0xFFC0392B)),
                  const SizedBox(width: 4),
                  _buildClassicFilterChip('Dirty', RoomStatus.dirtyVacant.code, _selectedStatus, (val) => setState(() => _selectedStatus = val), badgeColor: const Color(0xFFD35400)),
                  const SizedBox(width: 4),
                  _buildClassicFilterChip('Inspected', RoomStatus.cleanInspected.code, _selectedStatus, (val) => setState(() => _selectedStatus = val), badgeColor: const Color(0xFF16A085)),
                ],
              ),
            ),
          ),

          // ── 3. High-Density Room Grid Canvas ─────────────────────────────
          Expanded(
            child: filteredRooms.isEmpty
                ? const Center(
                    child: Text(
                      'No rooms match your filter criteria.',
                      style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 12),
                    ),
                  )
                : Container(
                    color: const Color(0xFFECEFF1),
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        mainAxisExtent: 140,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        final room = filteredRooms[index];
                        return _buildClassicRoomCard(context, room, repo);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicFilterChip(String label, String value, String currentSelected, Function(String) onSelect, {Color? badgeColor}) {
    final isSelected = currentSelected == value;

    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4E6F1) : ClassicErpTheme.buttonBg,
          border: Border.all(
            color: isSelected ? const Color(0xFF2980B9) : ClassicErpTheme.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(width: 7, height: 7, color: badgeColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicRoomCard(BuildContext context, RoomModel room, HotelRepository repo) {
    Color statusColor;
    switch (room.status) {
      case RoomStatus.availableClean:
        statusColor = const Color(0xFF27AE60);
        break;
      case RoomStatus.cleanInspected:
        statusColor = const Color(0xFF16A085);
        break;
      case RoomStatus.occupied:
        statusColor = const Color(0xFFC0392B);
        break;
      case RoomStatus.dirtyVacant:
        statusColor = const Color(0xFFD35400);
        break;
      case RoomStatus.cleaningInProgress:
        statusColor = const Color(0xFF2980B9);
        break;
      case RoomStatus.reserved:
        statusColor = const Color(0xFF8E44AD);
        break;
      case RoomStatus.outOfOrder:
        statusColor = const Color(0xFF7F8C8D);
        break;
    }

    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return InkWell(
      onTap: () => _showRoomDetailsModal(context, room, repo),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar: Room Number & Status Pill
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: statusColor,
              child: Row(
                children: [
                  Text(
                    'ROOM ${room.roomNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    room.status.label.split(' ').first.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Room Type & Floor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.roomTypeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF1B4F72), fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Floor ${room.floorNumber} • ${currency.format(room.basePrice)}/night',
                    style: const TextStyle(color: ClassicErpTheme.textMuted, fontSize: 9.5),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Guest Info or Availability Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: ClassicErpTheme.panelBg,
              child: room.status == RoomStatus.occupied
                  ? Row(
                      children: [
                        const Icon(Icons.person, size: 12, color: Color(0xFFC0392B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.currentGuestName ?? 'In-House Guest',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF27AE60)),
                        const SizedBox(width: 4),
                        const Text(
                          'Ready for Check-In',
                          style: TextStyle(fontSize: 9.5, color: Color(0xFF27AE60), fontWeight: FontWeight.bold),
                        ),
                      ],
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
    final advanceCtrl = TextEditingController(text: room.basePrice.toStringAsFixed(0));
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
              width: 500,
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
                            'Express Check-In: Room ${room.roomNumber}',
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
