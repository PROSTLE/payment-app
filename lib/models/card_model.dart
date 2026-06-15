import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CardModel {
  final String id;
  final String label;
  final String last4;
  final double balance;
  final List<Color> gradient;
  final String type; // 'visa' | 'mastercard'
  bool isFrozen;

  CardModel({
    required this.id,
    required this.label,
    required this.last4,
    required this.balance,
    required this.gradient,
    required this.type,
    this.isFrozen = false,
  });
}

final List<CardModel> mockCards = [
  CardModel(
    id: 'c1',
    label: 'Digital card',
    last4: '7642',
    balance: 7854.43,
    gradient: kCardYellow,
    type: 'visa',
  ),
  CardModel(
    id: 'c2',
    label: 'Digital card',
    last4: '5123',
    balance: 2340.00,
    gradient: kCardMint,
    type: 'mastercard',
  ),
  CardModel(
    id: 'c3',
    label: 'Digital card',
    last4: '3413',
    balance: 890.50,
    gradient: kCardBlue,
    type: 'visa',
  ),
];
