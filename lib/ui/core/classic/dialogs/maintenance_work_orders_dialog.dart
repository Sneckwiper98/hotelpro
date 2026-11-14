import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/models/maintenance_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

/// HotelPro Enterprise Maintenance & Room Engineering Work Orders
class MaintenanceWorkOrdersDialog extends StatefulWidget {
  const MaintenanceWorkOrdersDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const MaintenanceWorkOrdersDialog(),
    );
  }

  @override
  State<MaintenanceWorkOrdersDialog> createState() => _MaintenanceWorkOrdersDialogState();
}

class _MaintenanceWorkOrdersDialogState extends State<MaintenanceWorkOrdersDialog> {
  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final allTickets = repo.activeBranchMaintenanceTickets;

    final filteredTickets = allTickets.where((t) {
      if (_statusFilter != 'all' && t.status.name != _statusFilter) return false;
      if (_categoryFilter != 'all' && t.category != _categoryFilter) return false;
      return true;
    }).toList();

    final urgentCount = allTickets.where((t) => t.priority == MaintenancePriority.urgent && t.status != MaintenanceStatus.resolved).length;
    final inProgressCount = allTickets.where((t) => t.status == MaintenanceStatus.inProgress).length;
    final reportedCount = allTickets.where((t) => t.status == MaintenanceStatus.reported).length;

    return Dialog(
      backgroundColor: ClassicErpTheme.panelBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 960,
        height: 600,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          children: [
            // ── 1. Classic Windows Dialog Title Bar ───────────────────────────
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_circle_rounded, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Engineering & Room Maintenance Desk — [${repo.activeBranch.name.toUpperCase()}]',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 16,
                      height: 14,
                      color: const Color(0xFFC0392B),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. KPI & Action Ribbon ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  _kpiBadge('Reported', reportedCount, const Color(0xFFE74C3C)),
                  const SizedBox(width: 8),
                  _kpiBadge('In Progress', inProgressCount, const Color(0xFFF39C12)),
                  const SizedBox(width: 8),
                  _kpiBadge('Urgent Rush', urgentCount, const Color(0xFFC0392B)),
                  const SizedBox(width: 16),

                  // Status Filter
                  const Text('Status: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'reported', child: Text('Reported')),
                          DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _statusFilter = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Category: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryFilter,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Categories')),
                          DropdownMenuItem(value: 'HVAC / AC', child: Text('HVAC / AC')),
                          DropdownMenuItem(value: 'Plumbing', child: Text('Plumbing')),
                          DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                          DropdownMenuItem(value: 'Carpentry', child: Text('Carpentry')),
                          DropdownMenuItem(value: 'Electronics / TV', child: Text('Electronics / TV')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _categoryFilter = val);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Create Work Order Button
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTicketModal(context, repo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 14),
                    label: const Text('Log Maintenance Defect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // ── 3. High-Density Spreadsheet ────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderDark),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                      child: Row(
                        children: [
                          _headerCell('Ticket #', 110),
                          _headerCell('Room', 70),
                          _headerCell('Category', 110),
                          _headerCell('Priority', 90),
                          _headerCell('Reported By', 130),
                          _headerCell('Assigned Tech', 120),
                          _headerCell('Status', 90),
                          Expanded(child: _headerCell('Issue Description & Scope', null)),
                          _headerCell('Actions', 140),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredTickets.isEmpty
                          ? const Center(
                              child: Text('No maintenance tickets recorded for this branch.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            )
                          : ListView.builder(
                              itemCount: filteredTickets.length,
                              itemBuilder: (ctx, idx) {
                                final ticket = filteredTickets[idx];
                                final isAlt = idx % 2 == 1;

                                return Container(
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isAlt ? const Color(0xFFF8FAFC) : Colors.white,
                                    border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      _dataCell(ticket.ticketNumber, 110, isBold: true, isMono: true),
                                      _dataCell('Room ${ticket.roomNumber}', 70, isBold: true),
                                      _dataCell(ticket.category, 110),
                                      Container(
                                        width: 90,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: ticket.priority.color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(2),
                                            border: Border.all(color: ticket.priority.color, width: 0.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            ticket.priority.label.toUpperCase(),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ticket.priority.color),
                                          ),
                                        ),
                                      ),
                                      _dataCell(ticket.reportedBy, 130),
                                      _dataCell(ticket.assignedTo ?? 'Unassigned', 120),
                                      Container(
                                        width: 90,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          ticket.status.label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: ticket.status.color,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _dataCell(ticket.issueDescription, null, tooltip: ticket.issueDescription),
                                      ),
                                      Container(
                                        width: 140,
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          children: [
                                            if (ticket.status == MaintenanceStatus.reported)
                                              InkWell(
                                                onTap: () {
                                                  repo.updateMaintenanceTicketStatus(
                                                    ticketId: ticket.id,
                                                    newStatus: MaintenanceStatus.inProgress,
                                                    assignedTo: 'Duty Technician',
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  color: const Color(0xFFF39C12),
                                                  child: const Text('Start Work', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            if (ticket.status == MaintenanceStatus.inProgress)
                                              InkWell(
                                                onTap: () {
                                                  repo.updateMaintenanceTicketStatus(
                                                    ticketId: ticket.id,
                                                    newStatus: MaintenanceStatus.resolved,
                                                    resolutionNotes: 'Repaired and verified functional',
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  color: const Color(0xFF27AE60),
                                                  child: const Text('Resolve', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            if (ticket.status == MaintenanceStatus.resolved)
                                              const Text('✓ Cleared', style: TextStyle(fontSize: 10, color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
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
            ),

            // ── 4. Bottom Ribbon ──────────────────────────────────────────────
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFE2E8F0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  Text(
                    'Active Engineering Defects: ${allTickets.where((t) => t.status != MaintenanceStatus.resolved).length}  •  Urgent defects automatically block room availability in Front Desk.',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 12, color: Color(0xFF475569)),
                    label: const Text('Close [Esc]', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.bold)),
          Text('$count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double? width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: ClassicErpTheme.borderLight, width: 0.5))),
      child: Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
    );
  }

  Widget _dataCell(String text, double? width, {bool isBold = false, bool isMono = false, String? tooltip}) {
    final child = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: isMono ? 'Consolas' : null,
        color: const Color(0xFF1E293B),
      ),
    );
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFF1F5F9), width: 0.5))),
      child: tooltip != null ? Tooltip(message: tooltip, child: child) : child,
    );
  }

  void _showCreateTicketModal(BuildContext context, HotelRepository repo) {
    final rooms = repo.activeBranchRooms;
    String selectedRoomId = rooms.isNotEmpty ? rooms.first.id : '';
    String selectedCategory = 'HVAC / AC';
    MaintenancePriority selectedPriority = MaintenancePriority.high;
    final descCtrl = TextEditingController();
    final techCtrl = TextEditingController(text: 'Duty Technician');

    final categories = ['HVAC / AC', 'Plumbing', 'Electrical', 'Carpentry', 'Electronics / TV', 'Civil / Tile', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: ClassicErpTheme.panelBg,
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
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF1B4F72),
                    child: const Row(
                      children: [
                        Icon(Icons.build_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Log New Room Maintenance Defect', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room selection
                        const Text('Target Room Number:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark), color: Colors.white),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedRoomId,
                              isExpanded: true,
                              items: rooms.map((r) {
                                return DropdownMenuItem(
                                  value: r.id,
                                  child: Text('Room ${r.roomNumber} (${r.roomTypeName}) • Floor ${r.floorNumber}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedRoomId = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Category & Priority
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Defect Category:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark), color: Colors.white),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCategory,
                                        isExpanded: true,
                                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => selectedCategory = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Urgency / Priority:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark), color: Colors.white),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<MaintenancePriority>(
                                        value: selectedPriority,
                                        isExpanded: true,
                                        items: MaintenancePriority.values.map((p) {
                                          return DropdownMenuItem(
                                            value: p,
                                            child: Text(p.label, style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setModalState(() => selectedPriority = val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Issue description
                        const Text('Defect Description / Scope of Work:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark), color: Colors.white),
                          child: TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(8),
                              border: InputBorder.none,
                              hintText: 'Describe issue (e.g. Geyser water not heating, bathroom tile broken)...',
                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Assigned tech
                        const Text('Assign To Technician / Contractor:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: ClassicErpTheme.borderDark), color: Colors.white),
                          child: TextField(
                            controller: techCtrl,
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                              child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (descCtrl.text.trim().isEmpty) return;
                                final room = rooms.firstWhere((r) => r.id == selectedRoomId, orElse: () => rooms.first);

                                repo.createMaintenanceTicket(
                                  roomId: room.id,
                                  roomNumber: room.roomNumber,
                                  category: selectedCategory,
                                  priority: selectedPriority,
                                  issueDescription: descCtrl.text.trim(),
                                  assignedTo: techCtrl.text.trim(),
                                );
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F72),
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              icon: const Icon(Icons.save_rounded, size: 14),
                              label: const Text('Save Work Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
}

