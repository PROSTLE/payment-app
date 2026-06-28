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
  })  : upiId = upiId ?? _generateUpiId(phone),
        password = password ?? '';

  /// Generates a UPI ID from a phone number.
  /// e.g. "+916203771988" → "6203771988@upi"
  static String _generateUpiId(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '${digits.substring(2)}@upi';
    }
    return '$digits@upi';
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
    final phone = json['phone'] as String? ?? '';
    final rawUpi = json['upiId'] as String? ?? '';
    // Migrate old @payflow format to the new [phone]@upi format
    final upiId = (rawUpi.isEmpty || rawUpi.endsWith('@payflow'))
        ? _generateUpiId(phone)
        : rawUpi;

    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: fullName,
      phone: phone,
      email: json['email'] as String? ?? '',
      pin: json['pin'] as String? ?? '',
      password: json['password'] as String? ?? '',
      upiId: upiId,
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
