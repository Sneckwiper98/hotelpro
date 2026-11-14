import 'package:uuid/uuid.dart';
import '../services/security_service.dart';

/// HotelPro Enterprise Cryptographic Audit Trail Model
/// Records all financial, access control, and operational mutations.
class SecurityAuditLogModel {
  final String id;
  final DateTime timestamp;
  final String userId;
  final String username;
  final String userRole;
  final String action;
  final String category; // Authentication, Billing & Cash, Front Desk, POS, System, Maintenance
  final String severity; // info, warning, critical
  final String? entityId;
  final String details;
  final String terminalOrIp;
  final String tamperProofHash;

  const SecurityAuditLogModel({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.username,
    required this.userRole,
    required this.action,
    required this.category,
    required this.severity,
    this.entityId,
    required this.details,
    required this.terminalOrIp,
    required this.tamperProofHash,
  });

  /// Factory to construct a new cryptographically signed log entry
  factory SecurityAuditLogModel.create({
    required String userId,
    required String username,
    required String userRole,
    required String action,
    required String category,
    String severity = 'info',
    String? entityId,
    required String details,
    String terminalOrIp = 'Master Station #01',
  }) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final payloadToSign = '$id|$now|$userId|$username|$action|$category|$entityId|$details';
    final hash = SecurityService.generateTamperProofHash(payloadToSign);

    return SecurityAuditLogModel(
      id: id,
      timestamp: now,
      userId: userId,
      username: username,
      userRole: userRole,
      action: action,
      category: category,
      severity: severity,
      entityId: entityId,
      details: details,
      terminalOrIp: terminalOrIp,
      tamperProofHash: hash,
    );
  }

  /// Verifies whether the entry has been altered or tampered with
  bool get isTamperProofValid {
    final payloadToVerify = '$id|$timestamp|$userId|$username|$action|$category|$entityId|$details';
    return SecurityService.verifyTamperProofHash(payloadToVerify, tamperProofHash);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'username': username,
      'user_role': userRole,
      'action': action,
      'category': category,
      'severity': severity,
      'entity_id': entityId,
      'details': details,
      'terminal_ip': terminalOrIp,
      'tamper_hash': tamperProofHash,
    };
  }

  factory SecurityAuditLogModel.fromMap(Map<String, dynamic> map) {
    return SecurityAuditLogModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      userId: map['user_id']?.toString() ?? 'usr-sys',
      username: map['username']?.toString() ?? 'system',
      userRole: map['user_role']?.toString() ?? 'System',
      action: map['action']?.toString() ?? 'SYSTEM_EVENT',
      category: map['category']?.toString() ?? 'System',
      severity: map['severity']?.toString() ?? 'info',
      entityId: map['entity_id']?.toString(),
      details: map['details']?.toString() ?? '',
      terminalOrIp: map['terminal_ip']?.toString() ?? 'Terminal',
      tamperProofHash: map['tamper_hash']?.toString() ?? '',
    );
  }
}

