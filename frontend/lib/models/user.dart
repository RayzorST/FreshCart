class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'], 
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}