import 'package:flutter/material.dart';

class ContactModel {
  final String id;
  final String name;
  final String username;
  final String bank;
  final Color avatarColor;
  final String initials;
  final String? accountSuffix;

  ContactModel({
    required this.id,
    required this.name,
    required this.username,
    required this.bank,
    required this.avatarColor,
    required this.initials,
    this.accountSuffix,
  });
}

final List<ContactModel> mockContacts = [
  ContactModel(
    id: 'u1',
    name: 'Pavlo',
    username: '@designwitha...',
    bank: 'Chase',
    avatarColor: const Color(0xFF5B8FF9),
    initials: 'PA',
    accountSuffix: '298',
  ),
  ContactModel(
    id: 'u2',
    name: 'Sarah',
    username: '@sarahsdesi...',
    bank: 'Wells Fargo',
    avatarColor: const Color(0xFFFF6B6B),
    initials: 'SA',
    accountSuffix: '741',
  ),
  ContactModel(
    id: 'u3',
    name: 'Jordan',
    username: '@jordan.creat...',
    bank: 'Bank of America',
    avatarColor: const Color(0xFF52C41A),
    initials: 'JO',
    accountSuffix: '512',
  ),
  ContactModel(
    id: 'u4',
    name: 'Chris',
    username: '@chrisgraph...',
    bank: 'Citibank',
    avatarColor: const Color(0xFFFFAA00),
    initials: 'CH',
    accountSuffix: '883',
  ),
  ContactModel(
    id: 'u5',
    name: 'Emily',
    username: '@emilyartis...',
    bank: 'Chase',
    avatarColor: const Color(0xFFCB72FF),
    initials: 'EM',
    accountSuffix: '127',
  ),
  ContactModel(
    id: 'u6',
    name: 'Taylor',
    username: '@taylorcrea...',
    bank: 'US Bank',
    avatarColor: const Color(0xFF3DFFC4),
    initials: 'TA',
    accountSuffix: '445',
  ),
  ContactModel(
    id: 'u7',
    name: 'Gigi Hadid',
    username: '@gigi',
    bank: 'Chase',
    avatarColor: const Color(0xFFF97316),
    initials: 'GH',
    accountSuffix: '298',
  ),
  ContactModel(
    id: 'u8',
    name: 'Alex Rivera',
    username: '@alexr',
    bank: 'Ally Bank',
    avatarColor: const Color(0xFF8B5CF6),
    initials: 'AR',
    accountSuffix: '091',
  ),
];
