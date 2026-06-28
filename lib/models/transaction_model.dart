import 'package:flutter/material.dart';

enum TransactionType { debit, credit, pending }

class TransactionModel {
  final String id;
  final String vendor;
  final String category;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final IconData icon;
  final Color iconColor;

  TransactionModel({
    required this.id,
    required this.vendor,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.icon,
    required this.iconColor,
  });

  bool get isCredit => type == TransactionType.credit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor': vendor,
        'category': category,
        'amount': amount,
        'type': type.name,
        'date': date.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'debit';
    final type = TransactionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TransactionType.debit,
    );
    final category = json['category'] as String? ?? 'Transfer';
    return TransactionModel(
      id: json['id'] as String? ?? '',
      vendor: json['vendor'] as String? ?? '',
      category: category,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: type,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      icon: _iconForCategory(category, type),
      iconColor: _colorForCategory(category, type),
    );
  }

  static IconData _iconForCategory(String category, TransactionType type) {
    if (type == TransactionType.credit) {
      switch (category) {
        case 'Income':
          return Icons.account_balance;
        case 'Add Money':
          return Icons.add_circle_outline;
        default:
          return Icons.south_west_rounded;
      }
    }
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Entertainment':
        return Icons.play_circle_fill;
      case 'Music':
        return Icons.music_note;
      case 'Investment':
        return Icons.trending_up;
      case 'Subscription':
        return Icons.subscriptions_outlined;
      case 'Split':
        return Icons.people_outline;
      default:
        return Icons.send_rounded;
    }
  }

  static Color _colorForCategory(String category, TransactionType type) {
    if (type == TransactionType.credit) {
      return const Color(0xFF3DFFC4);
    }
    switch (category) {
      case 'Food':
        return const Color(0xFFFF9A3E);
      case 'Entertainment':
        return Colors.red;
      case 'Music':
        return const Color(0xFF3EE07F);
      case 'Investment':
        return const Color(0xFF5B8FF9);
      case 'Split':
        return const Color(0xFFCB72FF);
      default:
        return Colors.white;
    }
  }
}
