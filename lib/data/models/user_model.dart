// =====================================================================
// HOTELPRO — APP USER MODEL WITH ROLE-BASED PERMISSIONS
// =====================================================================

enum AppUserRole {
  developer(
    'Developer (iSecure)',
    'developer',
    'Full root whitelabel access, licensing, and all branch nodes.',
    permissions: {
      'developer_setup', 'master_settings', 'user_management', 'staff_management',
      'front_desk', 'housekeeping', 'pos', 'folio', 'reservations',
      'analytics', 'night_audit', 'reports', 'whitelabel_config',
    },
  ),
  superAdmin(
    'Super Admin',
    'super_admin',
    'Full access to all branches, all settings, billing, and system config.',
    permissions: {
      'master_settings', 'user_management', 'staff_management',
      'front_desk', 'housekeeping', 'pos', 'folio', 'reservations',
      'analytics', 'night_audit', 'reports',
    },
  ),
  generalManager(
    'General Manager',
    'general_manager',
    'Full branch access. Can view reports, approve discounts, manage staff.',
    permissions: {
      'front_desk', 'housekeeping', 'pos', 'folio', 'reservations',
      'analytics', 'night_audit', 'reports', 'staff_management',
    },
  ),
  frontDeskAgent(
    'Front Desk Agent',
    'front_desk_agent',
    'Check-in, check-out, reservations, room assignment. No billing edits.',
    permissions: {'front_desk', 'reservations', 'folio_view'},
  ),
  frontDeskSupervisor(
    'Front Desk Supervisor',
    'front_desk_supervisor',
    'All front desk tasks + can apply discounts and manage folios.',
    permissions: {'front_desk', 'reservations', 'folio', 'reports'},
  ),
  hkSupervisor(
    'Housekeeping Supervisor',
    'hk_supervisor',
    'Assign tasks, inspect rooms, manage housekeeping team.',
    permissions: {'housekeeping', 'room_status'},
  ),
  hkStaff(
    'Housekeeping Staff',
    'hk_staff',
    'View assigned tasks, update room status, mark clean.',
    permissions: {'housekeeping_tasks'},
  ),
  fbCaptain(
    'F&B Captain',
    'fb_captain',
    'Manage restaurant orders, tables, KOT, settlement.',
    permissions: {'pos', 'kot', 'table_management'},
  ),
  fbWaiter(
    'F&B Waiter',
    'fb_waiter',
    'Take orders, view KOT, mark served.',
    permissions: {'kot', 'order_entry'},
  ),
  accountant(
    'Accountant',
    'accountant',
    'View all folios, generate reports, settlement records.',
    permissions: {'folio', 'reports', 'analytics'},
  ),
  securityStaff(
    'Security Staff',
    'security_staff',
    'Visitor log, guest verification, room access.',
    permissions: {'visitor_log'},
  );

  final String label;
  final String code;
  final String description;
  final Set<String> permissions;

  const AppUserRole(
    this.label,
    this.code,
    this.description, {
    required this.permissions,
  });

  bool hasPermission(String permission) => permissions.contains(permission);

  static AppUserRole fromCode(String code) {
    return AppUserRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppUserRole.frontDeskAgent,
    );
  }
}

class AppUserModel {
  final String id;
  final String? staffId; // linked to staff profile
  final String username;
  final String displayName;
  final AppUserRole role;
  final List<String> branchAccess; // list of branch IDs
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  const AppUserModel({
    required this.id,
    this.staffId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.branchAccess,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
  });

  bool hasPermission(String permission) => role.hasPermission(permission);
  bool get isDeveloper => role == AppUserRole.developer || username == 'isecure';
  bool get isSuperAdmin => role == AppUserRole.superAdmin;
  bool hasAccessToBranch(String branchId) =>
      role == AppUserRole.superAdmin || role == AppUserRole.developer || branchAccess.contains(branchId);

  AppUserModel copyWith({
    String? username,
    String? displayName,
    AppUserRole? role,
    List<String>? branchAccess,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return AppUserModel(
      id: id,
      staffId: staffId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      branchAccess: branchAccess ?? this.branchAccess,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt,
    );
  }

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    List<String> branches = ['branch-mum-01'];
    final rawBranches = json['branch_access'];
    if (rawBranches is List) {
      branches = rawBranches.map((e) => e.toString()).toList();
    }
    return AppUserModel(
      id: json['id'] as String,
      staffId: json['staff_id'] as String?,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      role: AppUserRole.fromCode(json['role'] as String? ?? 'front_desk_agent'),
      branchAccess: branches,
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'staff_id': staffId,
        'username': username,
        'display_name': displayName,
        'role': role.code,
        'branch_access': branchAccess,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

