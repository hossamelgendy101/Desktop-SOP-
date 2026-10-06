class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? permissions;

  UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.permissions,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login'] as String) : null,
      permissions: map['permissions'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'permissions': permissions,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      permissions: permissions ?? this.permissions,
    );
  }
}
