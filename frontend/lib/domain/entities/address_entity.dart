class AddressEntity {
  final int id;
  final String title;
  final String addressLine;
  final String city;
  final String? postalCode;
  final bool isDefault;
  final int userId;
  final DateTime createdAt;

  AddressEntity({
    required this.id,
    required this.title,
    required this.addressLine,
    required this.city,
    this.postalCode,
    required this.isDefault,
    required this.userId,
    required this.createdAt,
  });

  factory AddressEntity.fromJson(Map<String, dynamic> json) {
    return AddressEntity(
      id: json['id'] as int,
      title: json['title'] as String,
      addressLine: json['address_line'] as String,
      city: json['city'] as String,
      postalCode: json['postal_code'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address_line': addressLine,
      'city': city,
      'postal_code': postalCode,
      'is_default': isDefault,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullAddress {
    final parts = [addressLine];
    if (city.isNotEmpty) parts.add('г. $city');
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }
}