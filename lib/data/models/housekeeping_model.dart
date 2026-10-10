import '../../config/app_constants.dart';

class HousekeepingTaskModel {
  final String id;
  final String branchId;
  final String roomId;
  final String roomNumber;
  final int floorNumber;
  final String taskType; // Checkout Deep Clean, Daily Stayover, Turndown, Inspection
  final HousekeepingPriority priority;
  final String status; // 'pending', 'in_progress', 'cleaned', 'inspected_approved'
  final String assignedStaff;
  final String? inspectionNotes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const HousekeepingTaskModel({
    required this.id,
    required this.branchId,
    required this.roomId,
    required this.roomNumber,
    required this.floorNumber,
    required this.taskType,
    this.priority = HousekeepingPriority.normal,
    this.status = 'pending',
    this.assignedStaff = 'Staff Member',
    this.inspectionNotes,
    required this.createdAt,
    this.completedAt,
  });

  HousekeepingTaskModel copyWith({
    String? status,
    String? assignedStaff,
    String? inspectionNotes,
    DateTime? completedAt,
  }) {
    return HousekeepingTaskModel(
      id: id,
      branchId: branchId,
      roomId: roomId,
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      taskType: taskType,
      priority: priority,
      status: status ?? this.status,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      inspectionNotes: inspectionNotes ?? this.inspectionNotes,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory HousekeepingTaskModel.fromJson(Map<String, dynamic> json) => HousekeepingTaskModel(
    id: json['id'] as String,
    branchId: json['branch_id'] as String? ?? '',
    roomId: json['room_id'] as String? ?? '',
    roomNumber: json['room_number'] as String? ?? '',
    floorNumber: (json['floor_number'] as num?)?.toInt() ?? 1,
    taskType: json['task_type'] as String? ?? 'Daily Stayover Clean',
    priority: HousekeepingPriority.fromCode(json['priority'] as String? ?? 'normal'),
    status: json['status'] as String? ?? 'pending',
    assignedStaff: json['assigned_staff_name'] as String? ?? 'Staff Member',
    inspectionNotes: json['inspection_notes'] as String?,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
  );
}
