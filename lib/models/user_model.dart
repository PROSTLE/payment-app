import '../models/contact_model.dart';

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  String pin;
  bool contactsSynced;
  double balance;
  List<ContactModel> syncedContacts;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.pin,
    this.contactsSynced = false,
    this.balance = 50000.00,
    this.syncedContacts = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'pin': pin,
        'contactsSynced': contactsSynced,
        'balance': balance,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        fullName: json['fullName'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        pin: json['pin'] ?? '',
        contactsSynced: json['contactsSynced'] ?? false,
        balance: (json['balance'] as num?)?.toDouble() ?? 50000.00,
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
