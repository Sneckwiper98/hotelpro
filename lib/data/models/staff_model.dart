// =====================================================================
// HOTELPRO — STAFF MODEL
// =====================================================================

enum StaffDepartment {
  frontDesk('Front Desk', 'front_desk', '🛎️'),
  housekeeping('Housekeeping', 'housekeeping', '🧹'),
  fnb('Food & Beverage', 'fnb', '🍽️'),
  kitchen('Kitchen', 'kitchen', '👨‍🍳'),
  security('Security', 'security', '🔒'),
  maintenance('Engineering & Maintenance', 'maintenance', '🔧'),
  accounts('Accounts & Finance', 'accounts', '💰'),
  management('Management', 'management', '👔'),
  spa('Spa & Wellness', 'spa', '💆');

  final String label;
  final String code;
  final String emoji;
  const StaffDepartment(this.label, this.code, this.emoji);

  static StaffDepartment fromCode(String code) {
    return StaffDepartment.values.firstWhere(
      (e) => e.code == code,
      orElse: () => StaffDepartment.frontDesk,
    );
  }
}

enum StaffRole {
  // Front Desk
  frontDeskAgent('Front Desk Agent', 'front_desk_agent', StaffDepartment.frontDesk),
  frontDeskSupervisor('Front Desk Supervisor', 'front_desk_supervisor', StaffDepartment.frontDesk),
  // Housekeeping
  hkStaff('Housekeeping Attendant', 'hk_staff', StaffDepartment.housekeeping),
  hkSupervisor('Housekeeping Supervisor', 'hk_supervisor', StaffDepartment.housekeeping),
  // F&B
  waiter('Waiter / Server', 'waiter', StaffDepartment.fnb),
  captain('F&B Captain', 'captain', StaffDepartment.fnb),
  barista('Barista', 'barista', StaffDepartment.fnb),
  // Kitchen
  chef('Chef', 'chef', StaffDepartment.kitchen),
  kitchenHelper('Kitchen Helper', 'kitchen_helper', StaffDepartment.kitchen),
  // Security
  securityGuard('Security Guard', 'security_guard', StaffDepartment.security),
  // Maintenance
  technician('Technician', 'technician', StaffDepartment.maintenance),
  // Accounts
  accountant('Accountant', 'accountant', StaffDepartment.accounts),
  // Management
  generalManager('General Manager', 'general_manager', StaffDepartment.management),
  deputyManager('Deputy Manager', 'deputy_manager', StaffDepartment.management);

  final String label;
  final String code;
  final StaffDepartment department;
  const StaffRole(this.label, this.code, this.department);

  static StaffRole fromCode(String code) {
    return StaffRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => StaffRole.frontDeskAgent,
    );
  }
}

enum StaffShift {
  morning('Morning Shift (6AM-2PM)', 'morning'),
  evening('Evening Shift (2PM-10PM)', 'evening'),
  night('Night Shift (10PM-6AM)', 'night'),
  general('General Shift (9AM-6PM)', 'general');

  final String label;
  final String code;
  const StaffShift(this.label, this.code);

  static StaffShift fromCode(String code) {
    return StaffShift.values.firstWhere(
      (e) => e.code == code || e.name == code,
      orElse: () => StaffShift.morning,
    );
  }
}

class StaffModel {
  final String id;
  final String branchId;
  final String fullName;
  final String phone;
  final String? email;
  final StaffDepartment department;
  final StaffRole role;
  final StaffShift shift;
  final bool isActive;
  final DateTime joinedDate;
  final String? photoUrl;
  final String? idNumber; // Aadhaar / PAN

  const StaffModel({
    required this.id,
    required this.branchId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.department,
    required this.role,
    required this.shift,
    this.isActive = true,
    required this.joinedDate,
    this.photoUrl,
    this.idNumber,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  StaffModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    StaffDepartment? department,
    StaffRole? role,
    StaffShift? shift,
    bool? isActive,
    String? photoUrl,
    String? idNumber,
  }) {
    return StaffModel(
      id: id,
      branchId: branchId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      shift: shift ?? this.shift,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate,
      photoUrl: photoUrl ?? this.photoUrl,
      idNumber: idNumber ?? this.idNumber,
    );
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      branchId: json['branch_id'] as String? ?? 'branch-mum-01',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      department: StaffDepartment.fromCode(json['department'] as String? ?? 'front_desk'),
      role: StaffRole.fromCode(json['role'] as String? ?? 'front_desk_agent'),
      shift: StaffShift.fromCode(json['shift'] as String? ?? 'morning'),
      isActive: json['is_active'] as bool? ?? true,
      joinedDate: json['joined_date'] != null
          ? DateTime.tryParse(json['joined_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      photoUrl: json['photo_url'] as String?,
      idNumber: json['id_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_id': branchId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'department': department.code,
        'role': role.code,
        'shift': shift.code,
        'is_active': isActive,
        'joined_date': joinedDate.toIso8601String().substring(0, 10),
        'photo_url': photoUrl,
        'id_number': idNumber,
      };
}

