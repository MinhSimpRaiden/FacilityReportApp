import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/user_role.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isActive;

  factory AppUserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return AppUserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'STAFF'),
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'isActive': isActive,
    };
  }
}
