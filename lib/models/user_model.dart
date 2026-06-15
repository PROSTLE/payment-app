class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  String pin;
  bool contactsSynced;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.pin,
    this.contactsSynced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'pin': pin,
        'contactsSynced': contactsSynced,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        fullName: json['fullName'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        pin: json['pin'] ?? '',
        contactsSynced: json['contactsSynced'] ?? false,
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
