class User {
  final int? id;
  final String name;
  final String email;
  final String? avatar;
  final bool isAdmin;
  final String createdAt;
  final String? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.isAdmin = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'isAdmin': isAdmin ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatar: map['avatar'],
      isAdmin: map['isAdmin'] == 1,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    bool? isAdmin,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
