import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' show Color, Icons;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/saved_card_model.dart';
import '../models/contact_model.dart';
import '../models/transaction_model.dart';
import '../constants/colors.dart' show kGreen;

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUserData;
  UserModel? get currentUser => _currentUserData;

  String? _mockUid;

  // ─── Auth State ────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
      return _currentUserData != null;
    }
    if (_mockUid != null) {
      await _loadUserData(_mockUid!);
      return _currentUserData != null;
    }
    return false;
  }

  Future<void> _saveUserLocally(String uid, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_$uid', jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<UserModel?> _loadUserLocally(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('cached_user_$uid');
      if (userStr != null) {
        return UserModel.fromJson(jsonDecode(userStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveCardsLocally(String uid, List<SavedCardModel> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsList = cards.map((c) => c.toJson()).toList();
      await prefs.setString('cached_cards_$uid', jsonEncode(cardsList));
    } catch (_) {}
  }

  Future<List<SavedCardModel>> _loadCardsLocally(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsStr = prefs.getString('cached_cards_$uid');
      if (cardsStr != null) {
        final List<dynamic> decoded = jsonDecode(cardsStr) as List<dynamic>;
        return decoded
            .map((item) => SavedCardModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUserData = UserModel.fromJson(doc.data()!);
        await _saveUserLocally(uid, _currentUserData!);
      } else {
        _currentUserData = await _loadUserLocally(uid);
      }
    } catch (e) {
      _currentUserData = await _loadUserLocally(uid);
    }
  }

  // ─── PIN-based Login ────────────────────────────────────────────────────────

  /// Login with phone number (digits only) or email + 4-digit PIN.
  /// Checks local cache first, then Firestore.
  Future<bool> loginWithPin(String identifier, String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_user_'));

      for (final key in keys) {
        final userStr = prefs.getString(key);
        if (userStr == null) continue;
        try {
          final userData = jsonDecode(userStr) as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);
          final id = identifier.toLowerCase().trim();
          final phoneDigits = identifier.replaceAll(RegExp(r'\D'), '');
          final userPhoneDigits = user.phone.replaceAll(RegExp(r'\D'), '');

          final matchesEmail = user.email.toLowerCase() == id;
          final matchesPhone = phoneDigits.isNotEmpty &&
              userPhoneDigits.isNotEmpty &&
              (userPhoneDigits == phoneDigits ||
                  userPhoneDigits.endsWith(phoneDigits) ||
                  phoneDigits.endsWith(userPhoneDigits));

          if ((matchesEmail || matchesPhone) && user.pin == pin) {
            _currentUserData = user;
            _mockUid = key.replaceFirst('cached_user_', '');
            return true;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ─── Registration & Profile ────────────────────────────────────────────────

  Future<void> register(UserModel user) async {
    final fUser = _auth.currentUser;

    final finalUser = UserModel(
      id: fUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: user.fullName,
      phone: user.phone,
      email: user.email,
      pin: user.pin,
      contactsSynced: user.contactsSynced,
      balance: 50000.00, // Default starting balance
    );

    _currentUserData = finalUser;
    final uid = fUser?.uid ?? finalUser.id;
    await _saveUserLocally(uid, finalUser);
    _mockUid = uid;

    if (fUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(fUser.uid)
            .set(finalUser.toJson());
      } catch (_) {}
    }
  }

  // ─── PIN ───────────────────────────────────────────────────────────────────

  Future<void> updatePin(String pin) async {
    final fUser = _auth.currentUser;
    if (_currentUserData == null) return;

    _currentUserData!.pin = pin;
    final uid = fUser?.uid ?? _currentUserData!.id;
    await _saveUserLocally(uid, _currentUserData!);

    if (fUser != null) {
      try {
        await _firestore.collection('users').doc(fUser.uid).update({'pin': pin});
      } catch (_) {}
    }
  }

  bool verifyPin(String pin) {
    return _currentUserData?.pin == pin;
  }

  /// Checks if a user with [email] and [phone] exists in local cache.
  Future<bool> checkUserExists(String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cached_user_'));
    for (final key in keys) {
      final userStr = prefs.getString(key);
      if (userStr == null) continue;
      try {
        final userData = jsonDecode(userStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
        final userPhoneDigits = user.phone.replaceAll(RegExp(r'\D'), '');
        final emailMatch = user.email.toLowerCase() == email.toLowerCase().trim();
        final phoneMatch = phoneDigits.isNotEmpty &&
            userPhoneDigits.isNotEmpty &&
            (userPhoneDigits == phoneDigits ||
                userPhoneDigits.endsWith(phoneDigits) ||
                phoneDigits.endsWith(userPhoneDigits));
        if (emailMatch && phoneMatch) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Verifies that a user with [email] + [phone] exists in local cache,
  /// loads them into the session, then updates their PIN.
  /// Throws if no matching user is found.
  Future<void> resetPinByIdentity(String email, String phone, String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cached_user_'));

    UserModel? matched;
    String? matchedUid;

    for (final key in keys) {
      final userStr = prefs.getString(key);
      if (userStr == null) continue;
      try {
        final userData = jsonDecode(userStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
        final userPhoneDigits = user.phone.replaceAll(RegExp(r'\D'), '');
        final emailMatch = user.email.toLowerCase() == email.toLowerCase().trim();
        final phoneMatch = phoneDigits.isNotEmpty &&
            userPhoneDigits.isNotEmpty &&
            (userPhoneDigits == phoneDigits ||
                userPhoneDigits.endsWith(phoneDigits) ||
                phoneDigits.endsWith(userPhoneDigits));
        if (emailMatch && phoneMatch) {
          matched = user;
          matchedUid = key.replaceFirst('cached_user_', '');
          break;
        }
      } catch (_) {}
    }

    if (matched == null || matchedUid == null) {
      throw Exception('No account found with these details.');
    }

    // Load into session
    _currentUserData = matched;
    _mockUid = matchedUid;

    // Update PIN
    matched.pin = newPin;
    await _saveUserLocally(matchedUid, matched);

    final fUser = _auth.currentUser;
    if (fUser != null) {
      try {
        await _firestore.collection('users').doc(fUser.uid).update({'pin': newPin});
      } catch (_) {}
    }
  }

  // ─── Balance ───────────────────────────────────────────────────────────────

  double get balance => _currentUserData?.balance ?? 0.0;

  /// Returns true on success, false if insufficient funds.
  Future<bool> deductBalance(double amount) async {
    if (_currentUserData == null) return false;
    if (_currentUserData!.balance < amount) return false;

    _currentUserData!.balance -= amount;
    final uid = _auth.currentUser?.uid ?? _currentUserData!.id;
    await _saveUserLocally(uid, _currentUserData!);

    final fUser = _auth.currentUser;
    if (fUser != null) {
      try {
        await _firestore.collection('users').doc(fUser.uid).update({
          'balance': _currentUserData!.balance,
        });
      } catch (_) {}
    }
    return true;
  }

  Future<void> addBalance(double amount) async {
    if (_currentUserData == null) return;
    _currentUserData!.balance += amount;
    final uid = _auth.currentUser?.uid ?? _currentUserData!.id;
    await _saveUserLocally(uid, _currentUserData!);
  }

  // ─── Cards ─────────────────────────────────────────────────────────────────

  Future<List<SavedCardModel>> getSavedCards() async {
    final fUser = _auth.currentUser;
    final uid = fUser?.uid ?? _currentUserData?.id ?? _mockUid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cards')
          .get();

      final cards = snapshot.docs.map((doc) => SavedCardModel.fromJson(doc.data())).toList();
      await _saveCardsLocally(uid, cards);
      return cards;
    } catch (e) {
      return await _loadCardsLocally(uid);
    }
  }

  Future<void> saveCard(SavedCardModel card) async {
    final fUser = _auth.currentUser;
    final uid = fUser?.uid ?? _currentUserData?.id ?? _mockUid;
    if (uid == null) return;

    final cards = await getSavedCards();
    if (cards.isEmpty) card.isDefault = true;

    final existingIndex = cards.indexWhere((c) => c.id == card.id);
    if (existingIndex >= 0) {
      cards[existingIndex] = card;
    } else {
      cards.add(card);
    }

    await _saveCardsLocally(uid, cards);

    if (fUser != null) {
      try {
        final cardsRef = _firestore.collection('users').doc(fUser.uid).collection('cards');
        await cardsRef.doc(card.id).set(card.toJson());
      } catch (_) {}
    }
  }

  Future<void> deleteCard(String cardId) async {
    final fUser = _auth.currentUser;
    final uid = fUser?.uid ?? _currentUserData?.id ?? _mockUid;
    if (uid == null) return;

    final cards = await getSavedCards();
    cards.removeWhere((c) => c.id == cardId);
    await _saveCardsLocally(uid, cards);

    if (fUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(fUser.uid)
            .collection('cards')
            .doc(cardId)
            .delete();
      } catch (_) {}
    }
  }

  Future<void> setDefaultCard(String cardId) async {
    final fUser = _auth.currentUser;
    final uid = fUser?.uid ?? _currentUserData?.id ?? _mockUid;
    if (uid == null) return;

    final cards = await getSavedCards();
    for (var card in cards) {
      card.isDefault = (card.id == cardId);
    }
    await _saveCardsLocally(uid, cards);

    if (fUser != null) {
      try {
        final cardsRef = _firestore.collection('users').doc(fUser.uid).collection('cards');
        final snapshot = await cardsRef.get();

        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'isDefault': doc.id == cardId});
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  // ─── Contacts Sync ─────────────────────────────────────────────────────────

  Future<void> markContactsSynced() async {
    final fUser = _auth.currentUser;
    if (_currentUserData == null) return;

    _currentUserData!.contactsSynced = true;
    final uid = fUser?.uid ?? _currentUserData!.id;
    await _saveUserLocally(uid, _currentUserData!);

    if (fUser != null) {
      try {
        await _firestore.collection('users').doc(fUser.uid).update({'contactsSynced': true});
      } catch (_) {}
    }
  }

  void setSyncedContacts(List<ContactModel> contacts) {
    _currentUserData?.syncedContacts = contacts;
  }

  List<ContactModel> getSyncedContacts() {
    return _currentUserData?.syncedContacts ?? [];
  }

  // ─── Transactions ──────────────────────────────────────────────────────────

  void recordTransaction({
    required String vendor,
    required double amount,
    required TransactionType type,
  }) {
    final txId = 'TX${DateTime.now().millisecondsSinceEpoch}';
    mockTransactions.insert(
      0,
      TransactionModel(
        id: txId,
        vendor: vendor,
        category: type == TransactionType.debit ? 'Transfer' : 'Credit',
        amount: amount,
        type: type,
        date: DateTime.now(),
        icon: type == TransactionType.debit
            ? Icons.send_rounded
            : Icons.south_west_rounded,
        iconColor: type == TransactionType.debit
            ? kGreen
            : const Color(0xFF5B8FF9),
      ),
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
    _currentUserData = null;
    _mockUid = null;
  }
}
