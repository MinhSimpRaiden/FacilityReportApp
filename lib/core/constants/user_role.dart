enum UserRole {
  staff('STAFF'),
  manager('MANAGER');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.staff,
    );
  }
}
