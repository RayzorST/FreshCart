class UserEntity {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  UserEntity({
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else {
      return email;
    }
  }
}