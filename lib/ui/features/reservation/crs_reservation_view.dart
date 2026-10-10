import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_form_widgets.dart';

/// Classic Windows Desktop Central Reservation System (CRS) View
/// High-density reservation spreadsheet, Win32 filter bar, and booking creation dialog.
class CrsReservationView extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const CrsReservationView({super.key, required this.onNavigateToTab});

  @override
  State<CrsReservationView> createState() => _CrsReservationViewState();
}

class _CrsReservationViewState extends State<CrsReservationView> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final reservations = repo.activeBranchReservations;

    final filtered = reservations.where((r) {
      if (_statusFilter != 'all' && r.bookingStatus.code != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      color: ClassicErpTheme.windowBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Ribbon & Filter Bar ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 16, color: ClassicErpTheme.mdiHeaderActive),
                            SizedBox(width: 6),
                            Text(
                              'Central Reservation System (CRS) — Multi-Property Bookings',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Status Filter
                            const Text('Status Filter: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ClassicErpDropdown<String>(
                              value: _statusFilter,
                              height: 26,
                              isExpanded: false,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Booking Status')),
                                DropdownMenuItem(value: 'confirmed', child: Text('Confirmed (Due In)')),
                                DropdownMenuItem(value: 'checked_in', child: Text('Checked-In (In House)')),
                                DropdownMenuItem(value: 'checked_out', child: Text('Checked-Out')),
                              ],
                              onChanged: (val) => setState(() => _statusFilter = val ?? 'all'),
                            ),

                            const SizedBox(width: 8),

                            // New Reservation Button
                            InkWell(
                              onTap: () => _showNewReservationDialog(context, repo),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4F72),
                                  border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'New Reservation [F3]',
                                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
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

          // ── 2. High-Density Spreadsheet Table Header ─────────────────────
          Container(
            height: 24,
            color: ClassicErpTheme.gridHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Row(
              children: [
                SizedBox(width: 110, child: Text('BOOKING REF', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 150, child: Text('GUEST NAME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 110, child: Text('MOBILE / VIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 80, child: Text('ROOM NO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(child: Text('ROOM CATEGORY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 95, child: Text('CHECK-IN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 95, child: Text('CHECK-OUT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 100, child: Text('STATUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                SizedBox(width: 95, child: Align(alignment: Alignment.centerRight, child: Text('TARIFF / NIGHT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),

          // ── 3. Table Rows ────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No reservations found matching filter.', style: TextStyle(color: ClassicErpTheme.textMuted)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final res = filtered[index];
                      Color statusBadgeColor;
                      switch (res.bookingStatus) {
                        case ReservationStatus.checkedIn:
                          statusBadgeColor = const Color(0xFF27AE60);
                          break;
                        case ReservationStatus.confirmed:
                          statusBadgeColor = const Color(0xFF1B4F72);
                          break;
                        case ReservationStatus.checkedOut:
                          statusBadgeColor = const Color(0xFF7F8C8D);
                          break;
                        default:
                          statusBadgeColor = const Color(0xFFC0392B);
                      }

                      return Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: index.isEven ? Colors.white : const Color(0xFFF4F6F7),
                          border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                res.bookingReference,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: Text(
                                res.guestName,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Text(
                                res.guestPhone,
                                style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'RM ${res.roomNumber}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                res.roomTypeName,
                                style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 95,
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(res.checkInDate),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            SizedBox(
                              width: 95,
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(res.checkOutDate),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                color: statusBadgeColor.withValues(alpha: 0.15),
                                child: Text(
                                  res.bookingStatus.label.toUpperCase(),
                                  style: TextStyle(color: statusBadgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 95,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  currency.format(res.ratePerNight),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
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
      ),
    );
  }

  // New Reservation Modal Dialog
  void _showNewReservationDialog(BuildContext context, HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roomTypes = repo.activeBranchRoomTypes;

    RoomTypeModel? selectedType = roomTypes.isNotEmpty ? roomTypes.first : null;
    int nights = 2;
    VipTier vipTier = VipTier.regular;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalEstimated = selectedType != null ? ((selectedType!.basePrice * nights) * 1.18) : 0.0;

          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Container(
              width: 480,
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
                        const Icon(Icons.bookmark_add_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Create New CRS Room Booking',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                        _classicInput('Guest Full Name *', nameCtrl),
                        const SizedBox(height: 8),
                        _classicInput('Mobile Phone / WhatsApp *', phoneCtrl),
                        const SizedBox(height: 8),

                        // Room Category
                        ClassicErpDropdown<RoomTypeModel>(
                          label: 'Select Room Category',
                          value: selectedType,
                          height: 28,
                          items: roomTypes.map((t) {
                            return DropdownMenuItem(value: t, child: Text('${t.name} (₹${t.basePrice.toStringAsFixed(0)}/night)'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedType = val);
                          },
                        ),
                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ClassicErpDropdown<int>(
                                label: 'Stay Duration',
                                value: nights,
                                height: 28,
                                items: [1, 2, 3, 4, 5, 7, 10, 14].map((n) => DropdownMenuItem(value: n, child: Text('$n Night(s)'))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => nights = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClassicErpDropdown<VipTier>(
                                label: 'Guest VIP Status',
                                value: vipTier,
                                height: 28,
                                items: VipTier.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => vipTier = val);
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
                              const Text('Estimated Tariff (Inc 18% GST):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${totalEstimated.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _classicDialogBtn('Cancel', () => Navigator.pop(ctx)),
                            const SizedBox(width: 6),
                            _classicDialogBtn('Confirm Booking', () {
                              if (nameCtrl.text.isEmpty || selectedType == null) return;

                              final checkIn = DateTime.now();
                              final checkOut = checkIn.add(Duration(days: nights));

                              repo.createReservation(
                                guestName: nameCtrl.text,
                                guestPhone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : '+91 98000 00000',
                                vipTier: vipTier,
                                roomTypeId: selectedType!.id,
                                roomTypeName: selectedType!.name,
                                checkInDate: checkIn,
                                checkOutDate: checkOut,
                                ratePerNight: selectedType!.basePrice,
                              );

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reservation created for ${nameCtrl.text}! Assigned to ${selectedType!.name}.'),
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

  Widget _classicInput(String label, TextEditingController controller) {
    final isReq = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();
    return ClassicErpInput(
      label: cleanLabel,
      isRequired: isReq,
      controller: controller,
      height: 28,
      isNumeric: label.contains('₹') || label.toLowerCase().contains('phone'),
    );
  }

  Widget _classicDialogBtn(String label, VoidCallback onTap, {Color? color, Color? textColor}) {
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
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: textColor ?? ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }
}
