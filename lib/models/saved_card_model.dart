import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SavedCardModel {
  final String id;
  final String cardholderName;
  final String last4;
  final String expiryMonth;
  final String expiryYear;
  final String brand; // 'visa' | 'mastercard' | 'rupay' | 'amex'
  final List<Color> gradient;
  bool isDefault;

  SavedCardModel({
    required this.id,
    required this.cardholderName,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.brand,
    required this.gradient,
    this.isDefault = false,
  });

  String get maskedNumber => '•••• •••• •••• $last4';
  String get expiry => '$expiryMonth/$expiryYear';

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardholderName': cardholderName,
        'last4': last4,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'brand': brand,
        'isDefault': isDefault,
      };

  factory SavedCardModel.fromJson(Map<String, dynamic> json) {
    final brand = json['brand'] ?? 'visa';
    return SavedCardModel(
      id: json['id'] ?? '',
      cardholderName: json['cardholderName'] ?? '',
      last4: json['last4'] ?? '0000',
      expiryMonth: json['expiryMonth'] ?? '01',
      expiryYear: json['expiryYear'] ?? '29',
      brand: brand,
      gradient: gradientForBrand(brand),
      isDefault: json['isDefault'] ?? false,
    );
  }

  static List<Color> gradientForBrand(String brand) {
    switch (brand) {
      case 'mastercard': return kCardMint;
      case 'rupay': return kCardBlue;
      case 'amex': return kCardPurple;
      default: return kCardYellow; // visa
    }
  }

  static String detectBrand(String cardNumber) {
    final n = cardNumber.replaceAll(' ', '');
    if (n.startsWith('4')) return 'visa';
    if (n.startsWith('5') || n.startsWith('2')) return 'mastercard';
    if (n.startsWith('6')) return 'rupay';
    if (n.startsWith('3')) return 'amex';
    return 'visa';
  }
}
