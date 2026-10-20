import 'package:flutter/foundation.dart';

enum AdminRole {
  superAdmin('Super Admin'),
  interviewer('Interviewer'),
  trainer('Trainer'),
  supervisor('Supervisor');

  const AdminRole(this.label);
  final String label;

  static AdminRole fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('interview')) return AdminRole.interviewer;
    if (normalized.contains('trainer')) return AdminRole.trainer;
    if (normalized.contains('supervisor')) return AdminRole.supervisor;
    return AdminRole.superAdmin;
  }
}

@immutable
class AdminSession {
  const AdminSession({
    required this.phone,
    required this.displayName,
    required this.role,
    required this.adminId,
  });

  final String phone;
  final String displayName;
  final AdminRole role;
  final String adminId;
}
