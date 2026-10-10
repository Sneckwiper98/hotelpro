import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/models/staff_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

class StaffManagementTab extends StatefulWidget {
  const StaffManagementTab({super.key});

  @override
  State<StaffManagementTab> createState() => _StaffManagementTabState();
}

class _StaffManagementTabState extends State<StaffManagementTab> {
  String _filterDept = 'all';
  String _filterShift = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final staffList = repo.activeBranchStaff.where((s) {
      if (_filterDept != 'all' && s.department.code != _filterDept) return false;
      if (_filterShift != 'all' && s.shift.code != _filterShift) return false;
      return true;
    }).toList();

    final activeCount = repo.activeBranchStaff.where((s) => s.isActive).length;
    final inactiveCount = repo.activeBranchStaff.length - activeCount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statChip('${repo.activeBranchStaff.length}', 'Total Staff', AppTheme.imperialGold),
                const SizedBox(width: 10),
                _statChip('$activeCount', 'Active', AppTheme.statusClean),
                const SizedBox(width: 10),
                _statChip('$inactiveCount', 'Inactive', AppTheme.statusDirty),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddStaffDialog(context, repo),
                  icon: const Icon(Icons.person_add_rounded, color: Colors.black, size: 16),
                  label: const Text('Add Staff', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Dept:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(width: 6),
                _filterChip('all', 'All', _filterDept, (v) => setState(() => _filterDept = v)),
                ...StaffDepartment.values.map((d) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _filterChip(d.code, '${d.emoji} ${d.label}', _filterDept, (v) => setState(() => _filterDept = v)),
                )),
                const SizedBox(width: 16),
                const Text('Shift:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(width: 6),
                _filterChip('all', 'All', _filterShift, (v) => setState(() => _filterShift = v)),
                ...StaffShift.values.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _filterChip(s.code, s.label.split('(').first.trim(), _filterShift, (v) => setState(() => _filterShift = v)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Responsive Staff Table
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minWidth = 880.0;
                final width = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.slateCardElevated,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            border: Border.all(color: AppTheme.slateBorder),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 48),
                              Expanded(flex: 3, child: Text('Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 2, child: Text('Department', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 120, child: Text('Shift', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 100, child: Text('Phone', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 70, child: Text('Status', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 80, child: Text('Actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ),

                        // Staff List
                        Expanded(
                          child: staffList.isEmpty
                              ? const Center(child: Text('No staff found for the selected filters.', style: TextStyle(color: AppTheme.textMuted)))
                              : ListView.builder(
                                  itemCount: staffList.length,
                                  itemBuilder: (ctx, i) {
                                    final s = staffList[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: i.isEven ? AppTheme.slateCard : AppTheme.obsidianBg,
                          border: Border(
                            left: BorderSide(
                              color: s.isActive ? s.department == StaffDepartment.housekeeping
                                  ? AppTheme.statusDirty : AppTheme.imperialGold.withValues(alpha: 0.3)
                                  : AppTheme.slateBorder,
                              width: s.isActive ? 2 : 1,
                            ),
                            right: const BorderSide(color: AppTheme.slateBorder),
                            bottom: const BorderSide(color: AppTheme.slateBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            SizedBox(
                              width: 48,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: s.isActive
                                    ? AppTheme.imperialGold.withValues(alpha: 0.2)
                                    : AppTheme.slateBorder,
                                child: Text(s.initials,
                                    style: TextStyle(
                                        color: s.isActive ? AppTheme.imperialGold : AppTheme.textMuted,
                                        fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            Expanded(flex: 3, child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.fullName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Since ${DateFormat('MMM yyyy').format(s.joinedDate)}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              ],
                            )),
                            Expanded(flex: 2, child: Row(
                              children: [
                                Text(s.department.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Expanded(child: Text(s.department.label,
                                    style: const TextStyle(color: AppTheme.champagneAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            )),
                            Expanded(flex: 2, child: Text(s.role.label,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 120, child: Text(
                              s.shift.label.split('(').first.trim(),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            )),
                            SizedBox(width: 100, child: Text(s.phone,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                            SizedBox(
                              width: 70,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (s.isActive ? AppTheme.statusClean : AppTheme.statusDirty).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.isActive ? 'Active' : 'Off',
                                  style: TextStyle(
                                      color: s.isActive ? AppTheme.statusClean : AppTheme.statusDirty,
                                      fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.imperialGold),
                                    onPressed: () => _showEditStaffDialog(context, repo, s),
                                    padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  IconButton(
                                    icon: Icon(s.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                                        size: 15, color: s.isActive ? AppTheme.statusDirty : AppTheme.statusClean),
                                    onPressed: () => repo.toggleStaffActive(s.id),
                                    tooltip: s.isActive ? 'Deactivate' : 'Activate',
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
),
);
}

  Widget _statChip(String count, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(count, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
    ]),
  );

  Widget _filterChip(String value, String label, String selected, Function(String) onTap) {
    final sel = selected == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? AppTheme.imperialGold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: sel ? AppTheme.imperialGold : AppTheme.slateBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? AppTheme.imperialGold : AppTheme.textSecondary,
                fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    StaffDepartment dept = StaffDepartment.frontDesk;
    StaffRole role = StaffRole.frontDeskAgent;
    StaffShift shift = StaffShift.general;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: const Text('Add New Staff Member', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Full Name *', nameCtrl),
                  const SizedBox(height: 10),
                  _field('Mobile Phone *', phoneCtrl),
                  const SizedBox(height: 10),
                  _field('Email (optional)', emailCtrl),
                  const SizedBox(height: 10),
                  _field('ID Number (Aadhaar/PAN)', idCtrl),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StaffDepartment>(
                    initialValue: dept,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: StaffDepartment.values.map((d) =>
                        DropdownMenuItem(value: d, child: Text('${d.emoji} ${d.label}'))).toList(),
                    onChanged: (v) {
                      setS(() {
                        dept = v ?? dept;
                        // Auto-set role based on dept
                        role = StaffRole.values.firstWhere((r) => r.department == dept, orElse: () => role);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StaffRole>(
                    initialValue: role,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Role / Designation'),
                    items: StaffRole.values
                        .where((r) => r.department == dept)
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                    onChanged: (v) => setS(() => role = v ?? role),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StaffShift>(
                    initialValue: shift,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Shift'),
                    items: StaffShift.values.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                    onChanged: (v) => setS(() => shift = v ?? shift),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                repo.addStaff(
                  fullName: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.isNotEmpty ? emailCtrl.text.trim() : null,
                  department: dept,
                  role: role,
                  shift: shift,
                  idNumber: idCtrl.text.isNotEmpty ? idCtrl.text.trim() : null,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${nameCtrl.text} added to staff!'), backgroundColor: AppTheme.statusClean),
                );
              },
              child: const Text('Add Staff Member', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, HotelRepository repo, StaffModel s) {
    StaffDepartment dept = s.department;
    StaffRole role = s.role;
    StaffShift shift = s.shift;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: Text('Edit: ${s.fullName}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StaffDepartment>(
                initialValue: dept,
                dropdownColor: AppTheme.slateCard,
                decoration: const InputDecoration(labelText: 'Department'),
                items: StaffDepartment.values.map((d) =>
                    DropdownMenuItem(value: d, child: Text('${d.emoji} ${d.label}'))).toList(),
                onChanged: (v) => setS(() {
                  dept = v ?? dept;
                  role = StaffRole.values.firstWhere((r) => r.department == dept, orElse: () => role);
                }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<StaffRole>(
                initialValue: role,
                dropdownColor: AppTheme.slateCard,
                decoration: const InputDecoration(labelText: 'Role'),
                items: StaffRole.values
                    .where((r) => r.department == dept)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                onChanged: (v) => setS(() => role = v ?? role),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<StaffShift>(
                initialValue: shift,
                dropdownColor: AppTheme.slateCard,
                decoration: const InputDecoration(labelText: 'Shift'),
                items: StaffShift.values.map((sh) =>
                    DropdownMenuItem(value: sh, child: Text(sh.label))).toList(),
                onChanged: (v) => setS(() => shift = v ?? shift),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                repo.updateStaff(s.id, department: dept, role: role, shift: shift);
                Navigator.pop(ctx);
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(labelText: label),
  );
}
