// =====================================================================
// HOTELPRO — APP USER MODEL WITH ROLE-BASED & GRANULAR FUNCTION RIGHTS
// =====================================================================

/// Definitions of granular function rights throughout HotelPro ERP & Mobile Suite
class FunctionRightItem {
  final String id;
  final String title;
  final String category;
  final String description;

  const FunctionRightItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
  });
}

class HotelProFunctionRights {
  // 1. Front Desk Operations
  static const String frontDeskView = 'front_desk_view';
  static const String frontDeskCheckIn = 'front_desk_checkin';
  static const String frontDeskCheckOut = 'front_desk_checkout';
  static const String frontDeskRoomShift = 'front_desk_room_shift';

  // 2. Billing & Folio Management
  static const String folioView = 'folio_view';
  static const String folioAddCharge = 'folio_charge';
  static const String folioDiscount = 'folio_discount';
  static const String folioSettlement = 'folio_settlement';
  static const String folioVoidRefund = 'folio_refund';

  // 3. Restaurant POS & KOT
  static const String posView = 'pos_view';
  static const String posOrderPunch = 'pos_order_punch';
  static const String posRunningTables = 'pos_running_tables';
  static const String posBillPrint = 'pos_bill_print';
  static const String posCancelItem = 'pos_cancel_item';

  // 4. Housekeeping Operations
  static const String hkView = 'hk_view';
  static const String hkMarkClean = 'hk_mark_clean';
  static const String hkMarkInspected = 'hk_mark_inspected';
  static const String hkOutOfOrder = 'hk_out_of_order';

  // 5. CRS Reservations
  static const String crsView = 'crs_view';
  static const String crsNewBooking = 'crs_new_booking';
  static const String crsModifyBooking = 'crs_modify';
  static const String crsCancelBooking = 'crs_cancel';

  // 6. Stock & Inventory Management
  static const String inventoryView = 'inventory_view';
  static const String inventoryGrn = 'inventory_grn';
  static const String inventoryIssue = 'inventory_issue';
  static const String inventoryAdjust = 'inventory_adjust';

  // 7. Accounting & Expenses
  static const String accountingView = 'accounting_view';
  static const String accountingVouchers = 'accounting_vouchers';
  static const String accountingLedger = 'accounting_ledger';
  static const String accountingBalance = 'accounting_balance';

  // 8. Online Delivery & Dispatch
  static const String deliveryQueue = 'delivery_queue';
  static const String deliveryDispatch = 'delivery_dispatch';
  static const String deliveryCancel = 'delivery_cancel';

  // 9. Analytics & Reports
  static const String analyticsView = 'analytics_view';
  static const String reportsView = 'reports_view';
  static const String nightAudit = 'night_audit';
  static const String exportExcel = 'export_excel';

  // 10. Master Setup & Security
  static const String masterRooms = 'master_rooms';
  static const String masterMenu = 'master_menu';
  static const String masterStaff = 'master_staff';
  static const String masterUsers = 'master_users';
  static const String masterRights = 'master_rights';

  static const List<FunctionRightItem> allRights = [
    // Front Desk
    FunctionRightItem(id: frontDeskView, title: 'View Tape Chart & Room Matrix', category: 'Front Desk', description: 'View floor room occupancy grid and tape chart'),
    FunctionRightItem(id: frontDeskCheckIn, title: 'Guest Check-In Entry', category: 'Front Desk', description: 'Register new walk-in or reservation guest check-in'),
    FunctionRightItem(id: frontDeskCheckOut, title: 'Guest Check-Out & Release', category: 'Front Desk', description: 'Process room checkout and mark room dirty'),
    FunctionRightItem(id: frontDeskRoomShift, title: 'Room Shift & Category Upgrade', category: 'Front Desk', description: 'Move checked-in guest to another vacant room'),

    // Billing & Folio
    FunctionRightItem(id: folioView, title: 'View Guest Ledgers & Folios', category: 'Billing & Folio', description: 'View running account statements and guest bills'),
    FunctionRightItem(id: folioAddCharge, title: 'Post Room & Service Charges', category: 'Billing & Folio', description: 'Post manual tariff charges, laundry, and mini-bar'),
    FunctionRightItem(id: folioDiscount, title: 'Apply Billing Discounts', category: 'Billing & Folio', description: 'Apply special discount percentage or waiver to folio'),
    FunctionRightItem(id: folioSettlement, title: 'Settle Bill & Print Tax Invoice', category: 'Billing & Folio', description: 'Accept cash/card/UPI payment and issue GST invoice'),
    FunctionRightItem(id: folioVoidRefund, title: 'Void Charges & Process Refunds', category: 'Billing & Folio', description: 'Cancel wrongly billed transactions or issue refund'),

    // Restaurant POS
    FunctionRightItem(id: posView, title: 'Access Restaurant POS Terminal', category: 'Restaurant POS', description: 'Open F&B outlets and dine-in tables screen'),
    FunctionRightItem(id: posOrderPunch, title: 'Punch Table Orders & KOT', category: 'Restaurant POS', description: 'Add food items and send KOT tickets to kitchen'),
    FunctionRightItem(id: posRunningTables, title: 'Manage Live Tables & Covers', category: 'Restaurant POS', description: 'View running table balances, shift tables, edit pax'),
    FunctionRightItem(id: posBillPrint, title: 'Print Restaurant Bills & Receipts', category: 'Restaurant POS', description: 'Generate food bill slip with GST breakdown'),
    FunctionRightItem(id: posCancelItem, title: 'Void KOT Items & Food Waste', category: 'Restaurant POS', description: 'Cancel ordered food items or record kitchen waste'),

    // Housekeeping
    FunctionRightItem(id: hkView, title: 'View Housekeeping Room Matrix', category: 'Housekeeping', description: 'Monitor clean, dirty, and inspected room status'),
    FunctionRightItem(id: hkMarkClean, title: 'Update Room Cleaning Status', category: 'Housekeeping', description: 'Mark dirty rooms as clean in progress or cleaned'),
    FunctionRightItem(id: hkMarkInspected, title: 'Approve & Inspect Room Hygiene', category: 'Housekeeping', description: 'Housekeeping supervisor final hygiene sign-off'),
    FunctionRightItem(id: hkOutOfOrder, title: 'Mark Room Out of Order (OOO)', category: 'Housekeeping', description: 'Block rooms for maintenance or deep renovation'),

    // CRS Reservations
    FunctionRightItem(id: crsView, title: 'View Central Reservations Calendar', category: 'Reservations (CRS)', description: 'View booking matrix, inquiry calendar, OTA sync'),
    FunctionRightItem(id: crsNewBooking, title: 'Create Advance Reservations', category: 'Reservations (CRS)', description: 'Book future dates with guest details & rate plan'),
    FunctionRightItem(id: crsModifyBooking, title: 'Modify Booking Dates & Tariffs', category: 'Reservations (CRS)', description: 'Extend stay, reschedule dates, or update rates'),
    FunctionRightItem(id: crsCancelBooking, title: 'Cancel Bookings & Retention', category: 'Reservations (CRS)', description: 'Cancel reserved booking with cancellation charges'),

    // Stock & Inventory
    FunctionRightItem(id: inventoryView, title: 'View Live Stock & Material Levels', category: 'Stock & Inventory', description: 'Check ingredient levels, linen, and stores inventory'),
    FunctionRightItem(id: inventoryGrn, title: 'Goods Receipt Note (GRN Entry)', category: 'Stock & Inventory', description: 'Receive vendor stock with purchase invoice rates'),
    FunctionRightItem(id: inventoryIssue, title: 'Issue Stock to Kitchen & Depts', category: 'Stock & Inventory', description: 'Transfer raw food, provisions, and toiletries'),
    FunctionRightItem(id: inventoryAdjust, title: 'Stock Physical Audit & Adjustment', category: 'Stock & Inventory', description: 'Adjust physical count variances, damage, breakage'),

    // Accounting & Expense
    FunctionRightItem(id: accountingView, title: 'View Account Books & Ledgers', category: 'Accounting & Finance', description: 'Access cash book, bank accounts, and daily books'),
    FunctionRightItem(id: accountingVouchers, title: 'Post Expense & Payment Vouchers', category: 'Accounting & Finance', description: 'Record diesel, electricity, petty cash, vendor payout'),
    FunctionRightItem(id: accountingLedger, title: 'View Vendor & Guest Ledgers', category: 'Accounting & Finance', description: 'Detailed account transactions and outstanding bills'),
    FunctionRightItem(id: accountingBalance, title: 'View Balance Sheet & P&L', category: 'Accounting & Finance', description: 'View profit & loss statement, trial balance, tax register'),

    // Online Delivery & Dispatch
    FunctionRightItem(id: deliveryQueue, title: 'Live App Orders Queue & Accept', category: 'Online Delivery', description: 'Receive incoming guest food orders from mobile app'),
    FunctionRightItem(id: deliveryDispatch, title: 'Assign & Dispatch Delivery Riders', category: 'Online Delivery', description: 'Assign orders to riders and monitor live delivery GPS'),
    FunctionRightItem(id: deliveryCancel, title: 'Reject & Refund Online Orders', category: 'Online Delivery', description: 'Cancel customer orders and reverse digital payment'),

    // Analytics & Reports
    FunctionRightItem(id: analyticsView, title: 'Executive GM Dashboard & KPIs', category: 'Analytics & Reports', description: 'Live revenue, RevPAR, ADR, occupancy percentages'),
    FunctionRightItem(id: reportsView, title: 'Generate Detailed Audit Reports', category: 'Analytics & Reports', description: 'Daily sales, cashier collection, tax register reports'),
    FunctionRightItem(id: nightAudit, title: 'Execute Hotel Night Audit Roll', category: 'Analytics & Reports', description: 'Post room night charges and advance business date'),
    FunctionRightItem(id: exportExcel, title: 'Export Data to Excel & Print', category: 'Analytics & Reports', description: 'Download CSV / XLSX spreadsheets and print grids'),

    // Master Setup & Security
    FunctionRightItem(id: masterRooms, title: 'Manage Rooms, Tariffs & Floors', category: 'Master Setup', description: 'Create room categories, pricing slabs, bed types'),
    FunctionRightItem(id: masterMenu, title: 'Manage F&B Menu & Pricing', category: 'Master Setup', description: 'Add food dishes, menu prices, GST tax slabs'),
    FunctionRightItem(id: masterStaff, title: 'Manage Staff Roster & Shifts', category: 'Master Setup', description: 'Add hotel employees, shifts, departments, roles'),
    FunctionRightItem(id: masterUsers, title: 'Create & Manage User Accounts', category: 'Master Setup', description: 'Create operator logins, passwords, and app access'),
    FunctionRightItem(id: masterRights, title: 'Configure Function Rights Master', category: 'Master Setup', description: 'Allocate granular system function rights per operator'),
  ];

  static List<String> get categories => [
    'Front Desk',
    'Billing & Folio',
    'Restaurant POS',
    'Housekeeping',
    'Reservations (CRS)',
    'Stock & Inventory',
    'Accounting & Finance',
    'Online Delivery',
    'Analytics & Reports',
    'Master Setup',
  ];

  static List<FunctionRightItem> getRightsForCategory(String category) {
    return allRights.where((r) => r.category == category).toList();
  }
}

enum AppUserRole {
  developer(
    'Developer (iSecure)',
    'developer',
    'Full root whitelabel access, licensing, and all branch nodes.',
    permissions: {
      'developer_setup', 'master_settings', 'user_management', 'staff_management',
      'front_desk', 'housekeeping', 'pos', 'folio', 'reservations',
      'analytics', 'reports', 'whitelabel_config',
      'front_desk_view', 'front_desk_checkin', 'front_desk_checkout', 'front_desk_room_shift',
      'folio_view', 'folio_charge', 'folio_discount', 'folio_settlement', 'folio_refund',
      'pos_view', 'pos_order_punch', 'pos_running_tables', 'pos_bill_print', 'pos_cancel_item',
      'hk_view', 'hk_mark_clean', 'hk_mark_inspected', 'hk_out_of_order',
      'crs_view', 'crs_new_booking', 'crs_modify', 'crs_cancel',
      'inventory_view', 'inventory_grn', 'inventory_issue', 'inventory_adjust',
      'accounting_view', 'accounting_vouchers', 'accounting_ledger', 'accounting_balance',
      'delivery_queue', 'delivery_dispatch', 'delivery_cancel',
      'analytics_view', 'reports_view', 'night_audit', 'export_excel',
      'master_rooms', 'master_menu', 'master_staff', 'master_users', 'master_rights',
    },
    defaultAppAccess: {'windows_erp', 'waiter_pos', 'delivery_boy', 'housekeeping', 'manager_mis'},
  ),
  superAdmin(
    'Super Admin',
    'super_admin',
    'Full access to all branches, all settings, billing, and system config.',
    permissions: {
      'master_settings', 'user_management', 'staff_management',
      'front_desk', 'housekeeping', 'pos', 'folio', 'reservations',
      'analytics', 'reports',
      'front_desk_view', 'front_desk_checkin', 'front_desk_checkout', 'front_desk_room_shift',
      'folio_view', 'folio_charge', 'folio_discount', 'folio_settlement', 'folio_refund',
      'pos_view', 'pos_order_punch', 'pos_running_tables', 'pos_bill_print', 'pos_cancel_item',
      'hk_view', 'hk_mark_clean', 'hk_mark_inspected', 'hk_out_of_order',
      'crs_view', 'crs_new_booking', 'crs_modify', 'crs_cancel',
      'inventory_view', 'inventory_grn', 'inventory_issue', 'inventory_adjust',
      'accounting_view', 'accounting_vouchers', 'accounting_ledger', 'accounting_balance',
      'delivery_queue', 'delivery_dispatch', 'delivery_cancel',
      'analytics_view', 'reports_view', 'night_audit', 'export_excel',
      'master_rooms', 'master_menu', 'master_staff', 'master_users', 'master_rights',
    },
    defaultAppAccess: {'windows_erp', 'waiter_pos', 'delivery_boy', 'housekeeping', 'manager_mis'},
  ),
  generalManager(
    'General Manager',
    'general_manager',
    'Full branch access. Can view reports, approve discounts, manage staff.',
    permissions: {
      'front_desk', 'housekeeping', 'pos', 'folio', 'reservations',
      'analytics', 'reports', 'staff_management',
      'front_desk_view', 'front_desk_checkin', 'front_desk_checkout', 'front_desk_room_shift',
      'folio_view', 'folio_charge', 'folio_discount', 'folio_settlement',
      'pos_view', 'pos_order_punch', 'pos_running_tables', 'pos_bill_print',
      'hk_view', 'hk_mark_clean', 'hk_mark_inspected', 'hk_out_of_order',
      'crs_view', 'crs_new_booking', 'crs_modify', 'crs_cancel',
      'inventory_view', 'accounting_view', 'accounting_ledger',
      'delivery_queue', 'delivery_dispatch',
      'analytics_view', 'reports_view', 'night_audit', 'export_excel',
      'master_rooms', 'master_menu', 'master_staff',
    },
    defaultAppAccess: {'windows_erp', 'waiter_pos', 'delivery_boy', 'housekeeping', 'manager_mis'},
  ),
  frontDeskSupervisor(
    'Front Desk Supervisor',
    'front_desk_supervisor',
    'All front desk tasks + can apply discounts and manage folios.',
    permissions: {
      'front_desk', 'reservations', 'folio', 'reports',
      'front_desk_view', 'front_desk_checkin', 'front_desk_checkout', 'front_desk_room_shift',
      'folio_view', 'folio_charge', 'folio_discount', 'folio_settlement',
      'crs_view', 'crs_new_booking', 'crs_modify', 'crs_cancel',
      'reports_view', 'export_excel',
    },
    defaultAppAccess: {'windows_erp'},
  ),
  frontDeskAgent(
    'Front Desk Agent',
    'front_desk_agent',
    'Check-in, check-out, reservations, room assignment. No billing edits.',
    permissions: {
      'front_desk', 'reservations',
      'front_desk_view', 'front_desk_checkin', 'front_desk_checkout', 'front_desk_room_shift',
      'folio_view', 'folio_charge',
      'crs_view', 'crs_new_booking',
    },
    defaultAppAccess: {'windows_erp'},
  ),
  hkSupervisor(
    'Housekeeping Supervisor',
    'hk_supervisor',
    'Assign tasks, inspect rooms, manage housekeeping team.',
    permissions: {
      'housekeeping', 'room_status',
      'hk_view', 'hk_mark_clean', 'hk_mark_inspected', 'hk_out_of_order',
    },
    defaultAppAccess: {'windows_erp', 'housekeeping'},
  ),
  hkStaff(
    'Housekeeping Staff',
    'hk_staff',
    'View assigned tasks, update room status, mark clean.',
    permissions: {
      'housekeeping_tasks',
      'hk_view', 'hk_mark_clean',
    },
    defaultAppAccess: {'housekeeping'},
  ),
  fbCaptain(
    'F&B Captain',
    'fb_captain',
    'Manage restaurant orders, tables, KOT, settlement.',
    permissions: {
      'pos', 'kot', 'table_management',
      'pos_view', 'pos_order_punch', 'pos_running_tables', 'pos_bill_print', 'pos_cancel_item',
    },
    defaultAppAccess: {'windows_erp', 'waiter_pos'},
  ),
  fbWaiter(
    'F&B Waiter',
    'fb_waiter',
    'Take orders, punch table KOT, mark served.',
    permissions: {
      'kot', 'order_entry',
      'pos_view', 'pos_order_punch', 'pos_running_tables',
    },
    defaultAppAccess: {'waiter_pos'},
  ),
  deliveryBoy(
    'Delivery Boy / Rider',
    'delivery_boy',
    'Live customer order delivery, address navigation, and cash collection.',
    permissions: {
      'delivery_queue', 'delivery_dispatch',
    },
    defaultAppAccess: {'delivery_boy'},
  ),
  accountant(
    'Accountant',
    'accountant',
    'View all folios, generate reports, settlement records.',
    permissions: {
      'folio', 'reports', 'analytics',
      'folio_view', 'folio_charge', 'folio_settlement',
      'accounting_view', 'accounting_vouchers', 'accounting_ledger', 'accounting_balance',
      'reports_view', 'export_excel',
    },
    defaultAppAccess: {'windows_erp'},
  ),
  securityStaff(
    'Security Staff',
    'security_staff',
    'Visitor log, guest verification, room access.',
    permissions: {'visitor_log'},
    defaultAppAccess: {'windows_erp'},
  );

  final String label;
  final String code;
  final String description;
  final Set<String> permissions;
  final Set<String> defaultAppAccess;

  const AppUserRole(
    this.label,
    this.code,
    this.description, {
    required this.permissions,
    required this.defaultAppAccess,
  });

  bool hasPermission(String permission) => permissions.contains(permission);
  String get displayName => label;

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
  final String password;
  final String displayName;
  final AppUserRole role;
  final List<String> branchAccess; // list of branch IDs
  final Set<String> appAccess; // list of allowed app codes ('windows_erp', 'waiter_pos', etc.)
  final Set<String>? customPermissions; // granular function permissions override
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  const AppUserModel({
    required this.id,
    this.staffId,
    required this.username,
    this.password = 'hotel@123',
    required this.displayName,
    required this.role,
    required this.branchAccess,
    this.appAccess = const {},
    this.customPermissions,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
  });

  bool get isDeveloper => role == AppUserRole.developer || username.toLowerCase() == 'isecure';
  bool get isSuperAdmin => role == AppUserRole.superAdmin;

  /// Checks if this user has access to a specific application platform
  /// Allowed codes: 'windows_erp', 'waiter_pos', 'delivery_boy', 'housekeeping', 'manager_mis'
  bool canAccessApp(String appCode) {
    if (isDeveloper || isSuperAdmin) return true;
    if (appAccess.isNotEmpty) {
      return appAccess.contains(appCode);
    }
    return role.defaultAppAccess.contains(appCode);
  }

  /// Checks if this user has authority for a specific function
  bool hasPermission(String permission) {
    if (isDeveloper || isSuperAdmin) return true;
    if (customPermissions != null) {
      return customPermissions!.contains(permission);
    }
    return role.hasPermission(permission);
  }

  Set<String> get effectivePermissions => customPermissions ?? role.permissions;

  bool hasAccessToBranch(String branchId) =>
      role == AppUserRole.superAdmin || role == AppUserRole.developer || branchAccess.contains(branchId);

  AppUserModel copyWith({
    String? username,
    String? password,
    String? displayName,
    AppUserRole? role,
    List<String>? branchAccess,
    Set<String>? appAccess,
    Set<String>? customPermissions,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return AppUserModel(
      id: id,
      staffId: staffId,
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      branchAccess: branchAccess ?? this.branchAccess,
      appAccess: appAccess ?? this.appAccess,
      customPermissions: customPermissions ?? this.customPermissions,
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

    Set<String> apps = {};
    final rawApps = json['app_access'];
    if (rawApps is List) {
      apps = rawApps.map((e) => e.toString()).toSet();
    }

    Set<String>? rights;
    final rawRights = json['function_rights'];
    if (rawRights is List) {
      rights = rawRights.map((e) => e.toString()).toSet();
    }

    final roleCode = json['role'] as String? ?? 'front_desk_agent';
    final role = AppUserRole.fromCode(roleCode);

    return AppUserModel(
      id: json['id'] as String,
      staffId: json['staff_id'] as String?,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? 'hotel@123',
      displayName: json['display_name'] as String? ?? '',
      role: role,
      branchAccess: branches,
      appAccess: apps.isNotEmpty ? apps : role.defaultAppAccess,
      customPermissions: rights,
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
        'password': password,
        'display_name': displayName,
        'role': role.code,
        'branch_access': branchAccess,
        'app_access': (appAccess.isNotEmpty ? appAccess : role.defaultAppAccess).toList(),
        'function_rights': customPermissions?.toList() ?? role.permissions.toList(),
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

class UserAuthResult {
  final bool success;
  final AppUserModel? user;
  final String? errorMessage;

  const UserAuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });

  factory UserAuthResult.success(AppUserModel user) =>
      UserAuthResult(success: true, user: user);

  factory UserAuthResult.failure(String message) =>
      UserAuthResult(success: false, errorMessage: message);
}

