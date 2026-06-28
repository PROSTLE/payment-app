import 'package:flutter/material.dart';

class ContactModel {
  final String id;
  final String name;
  final String username;
  final String bank;
  final Color avatarColor;
  final String initials;
  final String? accountSuffix;
  final bool isPayFlowUser;
  final String? payflowUpiId;
  final String? phone;

  ContactModel({
    required this.id,
    required this.name,
    required this.username,
    required this.bank,
    required this.avatarColor,
    required this.initials,
    this.accountSuffix,
    this.isPayFlowUser = false,
    this.payflowUpiId,
    this.phone,
  });
}
