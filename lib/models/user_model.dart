import '../models/contact_model.dart';

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  String pin;
  String password; // for "forgot PIN via password"
  String upiId;
  bool contactsSynced;
  double balance;
  List<ContactModel> syncedContacts;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.pin,
    String? password,
    String? upiId,
    this.contactsSynced = false,
    this.balance = 50000.00,
    this.syncedContacts = const [],
  })  : upiId = upiId ?? _generateUpiId(fullName),
        password = password ?? '';

  /// Generates a UPI ID from a full name.
  /// e.g. "Harshit Aryan" → "harshitaryan@payflow"
  static String _generateUpiId(String fullName) {
    final cleaned = fullName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$cleaned@payflow';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'pin': pin,
        'password': password,
        'upiId': upiId,
        'contactsSynced': contactsSynced,
        'balance': balance,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String? ?? '';
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: fullName,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      pin: json['pin'] as String? ?? '',
      password: json['password'] as String? ?? '',
      upiId: json['upiId'] as String? ?? _generateUpiId(fullName),
      contactsSynced: json['contactsSynced'] as bool? ?? false,
      balance: (json['balance'] as num?)?.toDouble() ?? 50000.00,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
