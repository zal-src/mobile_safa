class User {
  final int? userId;
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String? idCard;
  final String? createdAt;

  User({
    this.userId,
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.idCard,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'id_card': idCard,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int?,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      phone: map['phone'] as String?,
      idCard: map['id_card'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}