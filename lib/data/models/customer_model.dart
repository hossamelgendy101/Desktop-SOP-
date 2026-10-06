class CustomerModel {
  final int? id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final double balance;
  final double creditLimit;
  final int loyaltyPoints;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  CustomerModel({
    this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.balance = 0,
    this.creditLimit = 0,
    this.loyaltyPoints = 0,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      code: map['code'] as String?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0,
      loyaltyPoints: (map['loyalty_points'] as int?) ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'balance': balance,
      'credit_limit': creditLimit,
      'loyalty_points': loyaltyPoints,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
