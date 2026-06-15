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
}

final List<TransactionModel> mockTransactions = [
  TransactionModel(
    id: 't1',
    vendor: 'Apple',
    category: 'Subscription',
    amount: 999.0,
    type: TransactionType.debit,
    date: DateTime.now().subtract(const Duration(hours: 2)),
    icon: Icons.apple,
    iconColor: Colors.white,
  ),
  TransactionModel(
    id: 't2',
    vendor: 'Swiggy',
    category: 'Food',
    amount: 350.0,
    type: TransactionType.debit,
    date: DateTime.now().subtract(const Duration(hours: 5)),
    icon: Icons.fastfood,
    iconColor: Colors.white,
  ),
  TransactionModel(
    id: 't3',
    vendor: 'Apple',
    category: 'Refund',
    amount: 15000.0,
    type: TransactionType.credit,
    date: DateTime.now().subtract(const Duration(days: 1)),
    icon: Icons.apple,
    iconColor: Colors.white,
  ),
  TransactionModel(
    id: 't4',
    vendor: 'Zerodha',
    category: 'Investment',
    amount: 5000.0,
    type: TransactionType.debit,
    date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    icon: Icons.trending_up,
    iconColor: const Color(0xFF5B8FF9),
  ),
  TransactionModel(
    id: 't5',
    vendor: 'Spotify',
    category: 'Music',
    amount: 119.0,
    type: TransactionType.debit,
    date: DateTime.now().subtract(const Duration(days: 2)),
    icon: Icons.music_note,
    iconColor: const Color(0xFF3EE07F),
  ),
  TransactionModel(
    id: 't6',
    vendor: 'Netflix',
    category: 'Entertainment',
    amount: 499.0,
    type: TransactionType.debit,
    date: DateTime.now().subtract(const Duration(days: 3)),
    icon: Icons.play_circle_fill,
    iconColor: Colors.red,
  ),
  TransactionModel(
    id: 't7',
    vendor: 'Zomato',
    category: 'Food',
    amount: 420.0,
    type: TransactionType.debit,
    date: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
    icon: Icons.delivery_dining,
    iconColor: const Color(0xFFFF9A3E),
  ),
  TransactionModel(
    id: 't8',
    vendor: 'Salary',
    category: 'Income',
    amount: 85000.00,
    type: TransactionType.credit,
    date: DateTime.now().subtract(const Duration(days: 5)),
    icon: Icons.account_balance,
    iconColor: const Color(0xFF3DFFC4),
  ),
];
