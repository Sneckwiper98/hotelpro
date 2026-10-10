import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

class UserRolesTab extends StatelessWidget {
  const UserRolesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final users = repo.appUsers;
    final currentUser = repo.currentErpUser;
    final canCreateUser = currentUser.isDeveloper || currentUser.role == AppUserRole.superAdmin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 960;

        final userTable = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'App Users & Access Control',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                if (canCreateUser)
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(context, repo),
                    icon: const Icon(Icons.person_add_rounded, color: Colors.black, size: 16),
                    label: const Text('Add User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Create login credentials and assign roles to control system access.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),

            // User Table
            Expanded(
              child: LayoutBuilder(
                builder: (context, tableConstraints) {
                  const minWidth = 640.0;
                  final width = tableConstraints.maxWidth < minWidth ? minWidth : tableConstraints.maxWidth;

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
                                SizedBox(width: 42),
                                Expanded(flex: 2, child: Text('User', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text('Username', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                                Expanded(flex: 3, child: Text('Role', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                                SizedBox(width: 65, child: Text('Status', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                                SizedBox(width: 96, child: Text('Actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
                              ],
                            ),
                          ),

                          Expanded(
                            child: users.isEmpty
                                ? const Center(child: Text('No users yet.', style: TextStyle(color: AppTheme.textMuted)))
                                : ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (ctx, i) {
                                      final u = users[i];
                                      return _buildUserRow(ctx, u, repo, i);
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

        final roleMatrix = SizedBox(
          width: isNarrow ? double.infinity : 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role Permission Matrix', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Read-only reference for role access levels.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 14),

              Expanded(
                child: ListView(
                  children: AppUserRole.values.map((role) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.slateCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.slateBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: _roleColor(role),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(role.label,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(role.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4, runSpacing: 4,
                            children: role.permissions.take(4).map((perm) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _roleColor(role).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _roleColor(role).withValues(alpha: 0.3)),
                                ),
                                child: Text(perm.replaceAll('_', ' '),
                                    style: TextStyle(color: _roleColor(role), fontSize: 9, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(24),
          child: isNarrow
              ? Column(
                  children: [
                    Expanded(flex: 3, child: userTable),
                    const SizedBox(height: 16),
                    Expanded(flex: 2, child: roleMatrix),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: userTable),
                    const SizedBox(width: 20),
                    roleMatrix,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildUserRow(BuildContext context, AppUserModel u, HotelRepository repo, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: i.isEven ? AppTheme.slateCard : AppTheme.obsidianBg,
        border: Border(
          left: BorderSide(color: _roleColor(u.role).withValues(alpha: 0.5), width: 2),
          right: const BorderSide(color: AppTheme.slateBorder),
          bottom: const BorderSide(color: AppTheme.slateBorder),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _roleColor(u.role).withValues(alpha: 0.2),
              child: Text(
                u.displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(u.displayName,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(u.username,
              style: const TextStyle(color: AppTheme.textMuted, fontFamily: 'monospace', fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(u.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(u.role.label,
                  style: TextStyle(color: _roleColor(u.role), fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          SizedBox(
            width: 65,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: (u.isActive ? AppTheme.statusClean : AppTheme.statusDirty).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(u.isActive ? 'Active' : 'Off',
                  style: TextStyle(
                      color: u.isActive ? AppTheme.statusClean : AppTheme.statusDirty,
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: 96,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 15, color: AppTheme.imperialGold),
                  onPressed: () => _showEditUserDialog(context, repo, u),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  icon: Icon(u.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                      size: 15, color: u.isActive ? AppTheme.statusDirty : AppTheme.statusClean),
                  onPressed: () => repo.updateUser(u.id, isActive: !u.isActive),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 15, color: AppTheme.statusOccupied),
                  onPressed: () {
                    if (u.role != AppUserRole.superAdmin) repo.removeUser(u.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(AppUserRole role) {
    switch (role) {
      case AppUserRole.developer: return const Color(0xFF006266);
      case AppUserRole.superAdmin: return const Color(0xFFFF6B6B);
      case AppUserRole.generalManager: return AppTheme.imperialGold;
      case AppUserRole.frontDeskSupervisor:
      case AppUserRole.frontDeskAgent: return AppTheme.statusClean;
      case AppUserRole.hkSupervisor:
      case AppUserRole.hkStaff: return AppTheme.statusCleaning;
      case AppUserRole.fbCaptain:
      case AppUserRole.fbWaiter: return AppTheme.champagneAccent;
      case AppUserRole.accountant: return const Color(0xFF4ECDC4);
      case AppUserRole.securityStaff: return AppTheme.statusInspected;
    }
  }

  void _showAddUserDialog(BuildContext context, HotelRepository repo) {
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    AppUserRole role = AppUserRole.frontDeskAgent;
    final branches = repo.branches;
    final selectedBranches = <String>[repo.activeBranch.id];
    final currentUser = repo.currentErpUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: const Text('Create New App User', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('Display Name (Full Name) *', nameCtrl),
                  const SizedBox(height: 10),
                  _field('Username (login ID) *', userCtrl),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AppUserRole>(
                    initialValue: role,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Role / Access Level'),
                    items: AppUserRole.values
                        .where((r) => currentUser.isDeveloper || r != AppUserRole.developer)
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setS(() => role = v ?? role),
                  ),
                  const SizedBox(height: 10),
                  const Text('Branch Access:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...branches.map((b) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: selectedBranches.contains(b.id),
                      onChanged: (v) => setS(() {
                        if (v == true) { selectedBranches.add(b.id); }
                        else { selectedBranches.remove(b.id); }
                      }),
                      title: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                      activeColor: AppTheme.imperialGold,
                      checkColor: Colors.black,
                    );
                  }),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.obsidianBg, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Password "hotel@123" set by default. User can change it on first login.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                if (userCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                repo.addUser(
                  username: userCtrl.text.trim(),
                  displayName: nameCtrl.text.trim(),
                  role: role,
                  branchAccess: selectedBranches,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User ${nameCtrl.text} created successfully!'), backgroundColor: AppTheme.statusClean),
                );
              },
              child: const Text('Create User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, HotelRepository repo, AppUserModel u) {
    AppUserRole role = u.role;
    final branches = repo.branches;
    final selectedBranches = List<String>.from(u.branchAccess);
    final currentUser = repo.currentErpUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: Text('Edit: ${u.displayName}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AppUserRole>(
                  initialValue: role,
                  dropdownColor: AppTheme.slateCard,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: AppUserRole.values
                      .where((r) => currentUser.isDeveloper || r != AppUserRole.developer)
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: u.role == AppUserRole.superAdmin ? null : (v) => setS(() => role = v ?? role),
                ),
                const SizedBox(height: 10),
                ...branches.map((b) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: selectedBranches.contains(b.id),
                    onChanged: (v) => setS(() {
                      if (v == true) { selectedBranches.add(b.id); }
                      else { selectedBranches.remove(b.id); }
                    }),
                    title: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                    activeColor: AppTheme.imperialGold,
                    checkColor: Colors.black,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () {
                repo.updateUser(u.id, role: role, branchAccess: selectedBranches);
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
