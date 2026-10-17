import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/hotel_repository.dart';
import '../dialogs/user_function_rights_dialog.dart';

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
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F72),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF5DADE2)),
                  ),
                  onPressed: () => UserFunctionRightsDialog.show(context),
                  icon: const Icon(Icons.shield_rounded, color: AppTheme.imperialGold, size: 16),
                  label: const Text(
                    'Function Rights Master',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (canCreateUser)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.imperialGold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _showAddUserDialog(context, repo),
                    icon: const Icon(Icons.person_add_rounded, color: Colors.black, size: 16),
                    label: const Text('Add User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Create login credentials for Windows ERP and Android Mobile Apps with passwords and granular function rights.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),

            // User Table
            Expanded(
              child: LayoutBuilder(
                builder: (context, tableConstraints) {
                  const minWidth = 780.0;
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
                                Expanded(flex: 2, child: Text('User / Name', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text('Username & Password', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text('Role', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                                Expanded(flex: 3, child: Text('Allowed Apps / Platforms', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                                SizedBox(width: 60, child: Text('Status', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
                                SizedBox(width: 124, child: Text('Actions', style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700))),
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
              const Text('Read-only reference for default role access levels.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
                u.displayName.isNotEmpty ? u.displayName.substring(0, 1).toUpperCase() : 'U',
                style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  u.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  u.branchAccess.join(', '),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${u.username}',
                  style: const TextStyle(color: AppTheme.champagneAccent, fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 10, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      u.password.isNotEmpty ? '••••••••' : 'No Password',
                      style: TextStyle(
                        color: u.password.isNotEmpty ? AppTheme.statusClean : AppTheme.statusOccupied,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(u.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                u.role.label,
                style: TextStyle(color: _roleColor(u.role), fontSize: 10.5, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 3,
              runSpacing: 2,
              children: [
                if (u.canAccessApp('windows_erp'))
                  _appBadge('Win ERP', const Color(0xFF2980B9)),
                if (u.canAccessApp('waiter_pos'))
                  _appBadge('Waiter', const Color(0xFF27AE60)),
                if (u.canAccessApp('delivery_boy'))
                  _appBadge('Rider', const Color(0xFFE67E22)),
                if (u.canAccessApp('housekeeping'))
                  _appBadge('HK', const Color(0xFF8E44AD)),
                if (u.canAccessApp('manager_mis'))
                  _appBadge('MIS', const Color(0xFFC0392B)),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: (u.isActive ? AppTheme.statusClean : AppTheme.statusDirty).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(u.isActive ? 'Active' : 'Off',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: u.isActive ? AppTheme.statusClean : AppTheme.statusDirty,
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: 124,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Configure Function Rights Master',
                  icon: const Icon(Icons.shield_rounded, size: 16, color: AppTheme.imperialGold),
                  onPressed: () => UserFunctionRightsDialog.show(context, user: u),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  tooltip: 'Edit User Account & Password',
                  icon: const Icon(Icons.edit_rounded, size: 15, color: Colors.white70),
                  onPressed: () => _showEditUserDialog(context, repo, u),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  tooltip: u.isActive ? 'Deactivate User' : 'Activate User',
                  icon: Icon(u.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                      size: 15, color: u.isActive ? AppTheme.statusDirty : AppTheme.statusClean),
                  onPressed: () => repo.updateUser(u.id, isActive: !u.isActive),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  tooltip: 'Delete User',
                  icon: const Icon(Icons.delete_rounded, size: 15, color: AppTheme.statusOccupied),
                  onPressed: () {
                    if (u.role != AppUserRole.superAdmin && !u.isDeveloper) {
                      repo.removeUser(u.id);
                    }
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

  Widget _appBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w700),
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
      case AppUserRole.deliveryBoy: return const Color(0xFFE67E22);
    }
  }

  void _showAddUserDialog(BuildContext context, HotelRepository repo) {
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Admin@123');
    bool obscurePass = true;
    AppUserRole role = AppUserRole.frontDeskAgent;
    final branches = repo.branches;
    final selectedBranches = <String>[repo.activeBranch.id];
    final currentUser = repo.currentErpUser;

    // Default app access based on role
    final allowedApps = <String>{'windows_erp'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppTheme.imperialGold),
              SizedBox(width: 8),
              Text('Create User (Windows & Android)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Display Name (Full Name) *', nameCtrl),
                  const SizedBox(height: 10),
                  _field('Username (Login ID) *', userCtrl),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Login Password *',
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted, size: 18),
                        onPressed: () => setS(() => obscurePass = !obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AppUserRole>(
                    initialValue: role,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Role / Access Level'),
                    items: AppUserRole.values
                        .where((r) => currentUser.isDeveloper || r != AppUserRole.developer)
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setS(() {
                          role = v;
                          allowedApps.clear();
                          allowedApps.addAll(v.defaultAppAccess);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // App Access Matrix
                  const Text('Platform & Mobile App Authority *', style: TextStyle(color: AppTheme.imperialGold, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.obsidianBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.slateBorder),
                    ),
                    child: Column(
                      children: [
                        _appCheckboxTile('Windows Desktop ERP Software', 'windows_erp', allowedApps, setS),
                        _appCheckboxTile('Staff Waiter & Captain POS App', 'waiter_pos', allowedApps, setS),
                        _appCheckboxTile('Delivery Boy & Rider Partner App', 'delivery_boy', allowedApps, setS),
                        _appCheckboxTile('Housekeeping & Inspection App', 'housekeeping', allowedApps, setS),
                        _appCheckboxTile('Manager & Owner Live MIS App', 'manager_mis', allowedApps, setS),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text('Branch Access:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...branches.map((b) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: selectedBranches.contains(b.id),
                      onChanged: (v) => setS(() {
                        if (v == true) { selectedBranches.add(b.id); }
                        else if (selectedBranches.length > 1) { selectedBranches.remove(b.id); }
                      }),
                      title: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                      activeColor: AppTheme.imperialGold,
                      checkColor: Colors.black,
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.imperialGold),
              onPressed: () {
                if (userCtrl.text.isEmpty || nameCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields including password.'), backgroundColor: AppTheme.statusOccupied),
                  );
                  return;
                }
                repo.addAppUser(
                  username: userCtrl.text.trim(),
                  displayName: nameCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: role,
                  branchAccess: selectedBranches,
                  appAccess: allowedApps,
                  functionRights: role.permissions,
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
    final nameCtrl = TextEditingController(text: u.displayName);
    final passCtrl = TextEditingController(text: u.password);
    bool obscurePass = true;
    AppUserRole role = u.role;
    final branches = repo.branches;
    final selectedBranches = List<String>.from(u.branchAccess);
    final allowedApps = Set<String>.from(u.appAccess);
    final currentUser = repo.currentErpUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.slateCardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
          title: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: AppTheme.imperialGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Edit: ${u.displayName} (@${u.username})',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Display Name *', nameCtrl),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Change Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted, size: 18),
                        onPressed: () => setS(() => obscurePass = !obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AppUserRole>(
                    initialValue: role,
                    dropdownColor: AppTheme.slateCard,
                    decoration: const InputDecoration(labelText: 'Role / Access Level'),
                    items: AppUserRole.values
                        .where((r) => currentUser.isDeveloper || r != AppUserRole.developer)
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (u.role == AppUserRole.superAdmin && !currentUser.isDeveloper)
                        ? null
                        : (v) => setS(() => role = v ?? role),
                  ),
                  const SizedBox(height: 14),

                  // App Authority Checkboxes
                  const Text('Platform & Mobile App Authority', style: TextStyle(color: AppTheme.imperialGold, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.obsidianBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.slateBorder),
                    ),
                    child: Column(
                      children: [
                        _appCheckboxTile('Windows Desktop ERP Software', 'windows_erp', allowedApps, setS),
                        _appCheckboxTile('Staff Waiter & Captain POS App', 'waiter_pos', allowedApps, setS),
                        _appCheckboxTile('Delivery Boy & Rider Partner App', 'delivery_boy', allowedApps, setS),
                        _appCheckboxTile('Housekeeping & Inspection App', 'housekeeping', allowedApps, setS),
                        _appCheckboxTile('Manager & Owner Live MIS App', 'manager_mis', allowedApps, setS),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Function Rights Master Trigger
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4F72).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2980B9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: AppTheme.imperialGold, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Granular Function Rights Master',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.imperialGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            UserFunctionRightsDialog.show(context, user: u);
                          },
                          child: const Text('Configure Rights', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text('Branch Access:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...branches.map((b) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: selectedBranches.contains(b.id),
                      onChanged: (v) => setS(() {
                        if (v == true) { selectedBranches.add(b.id); }
                        else if (selectedBranches.length > 1) { selectedBranches.remove(b.id); }
                      }),
                      title: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                      activeColor: AppTheme.imperialGold,
                      checkColor: Colors.black,
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.imperialGold),
              onPressed: () {
                repo.updateAppUserDetails(
                  u.id,
                  displayName: nameCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: role,
                  branchAccess: selectedBranches,
                  appAccess: allowedApps,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User ${nameCtrl.text} updated successfully!'), backgroundColor: AppTheme.statusClean),
                );
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appCheckboxTile(String title, String appCode, Set<String> allowedApps, StateSetter setS) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: allowedApps.contains(appCode),
      onChanged: (val) {
        setS(() {
          if (val == true) {
            allowedApps.add(appCode);
          } else {
            allowedApps.remove(appCode);
          }
        });
      },
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5)),
      activeColor: AppTheme.imperialGold,
      checkColor: Colors.black,
    );
  }

  Widget _field(String label, TextEditingController ctrl) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(labelText: label),
  );
}
