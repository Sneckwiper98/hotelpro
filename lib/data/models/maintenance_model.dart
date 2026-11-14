import 'package:flutter/material.dart';

enum MaintenancePriority {
  urgent('Urgent', Color(0xFFC0392B), Icons.crisis_alert_rounded),
  high('High', Color(0xFFE67E22), Icons.priority_high_rounded),
  medium('Medium', Color(0xFF2980B9), Icons.low_priority_rounded),
  low('Low', Color(0xFF27AE60), Icons.check_circle_outline_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const MaintenancePriority(this.label, this.color, this.icon);

  static MaintenancePriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'urgent': return MaintenancePriority.urgent;
      case 'high': return MaintenancePriority.high;
      case 'low': return MaintenancePriority.low;
      default: return MaintenancePriority.medium;
    }
  }
}

enum MaintenanceStatus {
  reported('Reported', Color(0xFFE74C3C)),
  inProgress('In Progress', Color(0xFFF39C12)),
  resolved('Resolved', Color(0xFF27AE60)),
  cancelled('Cancelled', Color(0xFF7F8C8D));

  final String label;
  final Color color;
  const MaintenanceStatus(this.label, this.color);

  static MaintenanceStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'in_progress':
      case 'inprogress': return MaintenanceStatus.inProgress;
      case 'resolved': return MaintenanceStatus.resolved;
      case 'cancelled': return MaintenanceStatus.cancelled;
      default: return MaintenanceStatus.reported;
    }
  }
}

class MaintenanceTicketModel {
  final String id;
  final String ticketNumber;
  final String branchId;
  final String roomId;
  final String roomNumber;
  final String category; // Plumbing, Electrical, HVAC / AC, Carpentry, Electronics, Painting, Other
  final MaintenancePriority priority;
  final String issueDescription;
  final String reportedBy;
  final DateTime reportedAt;
  final String? assignedTo;
  final MaintenanceStatus status;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final double costIncurred;

  const MaintenanceTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.branchId,
    required this.roomId,
    required this.roomNumber,
    required this.category,
    required this.priority,
    required this.issueDescription,
    required this.reportedBy,
    required this.reportedAt,
    this.assignedTo,
    required this.status,
    this.resolvedAt,
    this.resolutionNotes,
    this.costIncurred = 0.0,
  });

  MaintenanceTicketModel copyWith({
    String? id,
    String? ticketNumber,
    String? branchId,
    String? roomId,
    String? roomNumber,
    String? category,
    MaintenancePriority? priority,
    String? issueDescription,
    String? reportedBy,
    DateTime? reportedAt,
    String? assignedTo,
    MaintenanceStatus? status,
    DateTime? resolvedAt,
    String? resolutionNotes,
    double? costIncurred,
  }) {
    return MaintenanceTicketModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      branchId: branchId ?? this.branchId,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      issueDescription: issueDescription ?? this.issueDescription,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedAt: reportedAt ?? this.reportedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      costIncurred: costIncurred ?? this.costIncurred,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'branch_id': branchId,
      'room_id': roomId,
      'room_number': roomNumber,
      'category': category,
      'priority': priority.name,
      'issue_description': issueDescription,
      'reported_by': reportedBy,
      'reported_at': reportedAt.toIso8601String(),
      'assigned_to': assignedTo,
      'status': status.name,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
      'cost_incurred': costIncurred,
    };
  }

  factory MaintenanceTicketModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceTicketModel(
      id: map['id']?.toString() ?? '',
      ticketNumber: map['ticket_number']?.toString() ?? 'WO-0001',
      branchId: map['branch_id']?.toString() ?? '',
      roomId: map['room_id']?.toString() ?? '',
      roomNumber: map['room_number']?.toString() ?? '',
      category: map['category']?.toString() ?? 'General',
      priority: MaintenancePriority.fromString(map['priority']?.toString()),
      issueDescription: map['issue_description']?.toString() ?? '',
      reportedBy: map['reported_by']?.toString() ?? 'Staff',
      reportedAt: DateTime.tryParse(map['reported_at']?.toString() ?? '') ?? DateTime.now(),
      assignedTo: map['assigned_to']?.toString(),
      status: MaintenanceStatus.fromString(map['status']?.toString()),
      resolvedAt: map['resolved_at'] != null ? DateTime.tryParse(map['resolved_at'].toString()) : null,
      resolutionNotes: map['resolution_notes']?.toString(),
      costIncurred: (map['cost_incurred'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

