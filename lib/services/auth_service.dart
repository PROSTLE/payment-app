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
    // 1. Check Firebase Auth first
    final fUser = _auth.currentUser;
    if (fUser != null) {
      await _loadUserData(fUser.uid);
      if (_currentUserData != null) {
        _mockUid = fUser.uid;
        await _persistMockUid(fUser.uid);
        return true;
      }
    }

    // 2. Check persisted _mockUid (for PIN-only users who aren't in Firebase Auth)
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('current_user_uid');
    if (savedUid != null && savedUid.isNotEmpty) {
      await _loadUserData(savedUid);
      if (_currentUserData != null) {
        _mockUid = savedUid;
        return true;
      }
    }

    return false;
  }

  Future<void> _persistMockUid(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_uid', uid);
    } catch (_) {}
  }

  Future<void> _clearPersistedUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_uid');
    } catch (_) {}
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

  /// Queries Firestore to find a user document matching [identifier] (email or phone).
  /// If found, caches it locally in SharedPreferences.
  Future<void> _ensureUserCached(String identifier) async {
    try {
      final id = identifier.toLowerCase().trim();
      final phoneDigits = identifier.replaceAll(RegExp(r'\D'), '');

      // Check if already cached in local memory
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_user_'));
      for (final key in keys) {
        final userStr = prefs.getString(key);
        if (userStr == null) continue;
        try {
          final userData = jsonDecode(userStr) as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);
          final userPhoneDigits = user.phone.replaceAll(RegExp(r'\D'), '');
          final matchesEmail = user.email.toLowerCase() == id;
          final matchesPhone = phoneDigits.isNotEmpty &&
              userPhoneDigits.isNotEmpty &&
              (userPhoneDigits == phoneDigits ||
                  userPhoneDigits.endsWith(phoneDigits) ||
                  phoneDigits.endsWith(userPhoneDigits));
          if (matchesEmail || matchesPhone) {
            return; // Already cached locally
          }
        } catch (_) {}
      }

      // If not cached, query Firestore
      if (id.contains('@')) {
        final snap = await _firestore
            .collection('users')
            .where('email', isEqualTo: id)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final user = UserModel.fromJson(snap.docs.first.data());
          await _saveUserLocally(user.id, user);
          return;
        }
      }

      if (phoneDigits.isNotEmpty) {
        final candidates = [
          phoneDigits,
          '+91$phoneDigits',
          if (phoneDigits.startsWith('91') && phoneDigits.length > 10)
            '+' + phoneDigits,
        ];
        for (final candidate in candidates) {
          final snap = await _firestore
              .collection('users')
              .where('phone', isEqualTo: candidate)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            final user = UserModel.fromJson(snap.docs.first.data());
            await _saveUserLocally(user.id, user);
            return;
          }
        }
      }
    } catch (e) {
      print('Error checking Firestore for caching: $e');
    }
  }

  // ─── PIN-based Login ────────────────────────────────────────────────────────

  /// Login with phone number (digits only) or email + 4-digit PIN.
  /// Checks local cache first, then Firestore.
  Future<bool> loginWithPin(String identifier, String pin) async {
    await _ensureUserCached(identifier);
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
            // Persist so we stay logged in on cold restart
            await _persistMockUid(_mockUid!);
            return true;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// Returns true if an account with this identifier (email or phone) exists in local cache or Firestore.
  /// Used to detect unregistered users at login and show "create account" prompt.
  Future<bool> identifierExists(String identifier) async {
    await _ensureUserCached(identifier);
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
          if (matchesEmail || matchesPhone) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// Read-only: checks if identifier + password is correct.
  Future<bool> validateIdentifierPassword(String identifier, String password) async {
    await _ensureUserCached(identifier);
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
          if ((matchesEmail || matchesPhone) && user.password == password) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// Read-only: checks if identifier + PIN is correct.
  Future<bool> validateIdentifierPin(String identifier, String pin) async {
    await _ensureUserCached(identifier);
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
          if ((matchesEmail || matchesPhone) && user.pin == pin) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ─── Registration & Profile ───────────────────────────────────────────────────────

  Future<void> register(UserModel user) async {
    final fUser = _auth.currentUser;
    final uid = fUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

    final finalUser = UserModel(
      id: uid,
      fullName: user.fullName,
      phone: user.phone,
      email: user.email,
      pin: user.pin,
      password: user.password,
      contactsSynced: user.contactsSynced,
      balance: 50000.00, // Default starting balance
      // upiId is auto-generated from fullName
    );

    _currentUserData = finalUser;
    _mockUid = uid;
    await _saveUserLocally(uid, finalUser);
    // Persist UID so user stays logged in
    await _persistMockUid(uid);

    if (fUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(fUser.uid)
            .set(finalUser.toJson());
      } catch (_) {}
    } else {
      // Also try to write to Firestore with the generated uid
      try {
        await _firestore.collection('users').doc(uid).set(finalUser.toJson());
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

  /// Reset PIN using password: verifies identifier + password, then sets new PIN.
  Future<void> resetPinByPassword(String identifier, String password, String newPin) async {
    await _ensureUserCached(identifier);
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
        final id = identifier.toLowerCase().trim();
        final phoneDigits = identifier.replaceAll(RegExp(r'\D'), '');
        final userPhoneDigits = user.phone.replaceAll(RegExp(r'\D'), '');
        final matchesEmail = user.email.toLowerCase() == id;
        final matchesPhone = phoneDigits.isNotEmpty &&
            userPhoneDigits.isNotEmpty &&
            (userPhoneDigits == phoneDigits ||
                userPhoneDigits.endsWith(phoneDigits) ||
                phoneDigits.endsWith(userPhoneDigits));
        if ((matchesEmail || matchesPhone) && user.password == password) {
          matched = user;
          matchedUid = key.replaceFirst('cached_user_', '');
          break;
        }
      } catch (_) {}
    }
    if (matched == null || matchedUid == null) {
      throw Exception('Incorrect password or account not found.');
    }
    matched.pin = newPin;
    _currentUserData = matched;
    _mockUid = matchedUid;
    await _saveUserLocally(matchedUid, matched);
    await _persistMockUid(matchedUid);
    try {
      await _firestore.collection('users').doc(matchedUid).update({'pin': newPin});
    } catch (_) {}
  }

  /// Reset PASSWORD using PIN: verifies identifier + PIN, then sets new password.
  Future<void> resetPasswordByPin(String identifier, String pin, String newPassword) async {
    await _ensureUserCached(identifier);
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
          matched = user;
          matchedUid = key.replaceFirst('cached_user_', '');
          break;
        }
      } catch (_) {}
    }
    if (matched == null || matchedUid == null) {
      throw Exception('Incorrect PIN or account not found.');
    }
    matched.password = newPassword;
    _currentUserData = matched;
    _mockUid = matchedUid;
    await _saveUserLocally(matchedUid, matched);
    await _persistMockUid(matchedUid);
    try {
      await _firestore.collection('users').doc(matchedUid).update({'password': newPassword});
    } catch (_) {}
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
    } else {
      try {
        await _firestore.collection('users').doc(uid).update({
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

    // Also persist to Firestore
    try {
      await _firestore.collection('users').doc(uid).update({
        'balance': _currentUserData!.balance,
      });
    } catch (_) {}
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
    } else {
      try {
        final cardsRef = _firestore.collection('users').doc(uid).collection('cards');
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

  /// Fetches all other PayFlow users from Firestore (and local cache) to show
  /// as potential send/split recipients.
  Future<List<ContactModel>> getPayFlowContacts() async {
    final myUid = _auth.currentUser?.uid ?? _currentUserData?.id ?? _mockUid;
    final List<ContactModel> contacts = [];

    // Build a palette for avatar colors
    const palette = [
      Color(0xFF5B8FF9),
      Color(0xFFFF6B6B),
      Color(0xFF52C41A),
      Color(0xFFFFAA00),
      Color(0xFFCB72FF),
      Color(0xFF3DFFC4),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
    ];

    // 1. Try Firestore first
    try {
      final snapshot = await _firestore.collection('users').get();
      int colorIndex = 0;
      for (final doc in snapshot.docs) {
        if (doc.id == myUid) continue; // skip self
        try {
          final user = UserModel.fromJson(doc.data());
          final color = palette[colorIndex % palette.length];
          colorIndex++;
          contacts.add(ContactModel(
            id: doc.id,
            name: user.fullName,
            username: user.upiId,
            bank: 'PayFlow',
            avatarColor: color,
            initials: user.initials,
            isPayFlowUser: true,
            payflowUpiId: user.upiId,
            phone: user.phone,
          ));
        } catch (_) {}
      }
    } catch (_) {}

    // 2. Fall back to local cache if Firestore empty
    if (contacts.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((k) => k.startsWith('cached_user_'));
        int colorIndex = 0;
        for (final key in keys) {
          final uid = key.replaceFirst('cached_user_', '');
          if (uid == myUid) continue;
          final userStr = prefs.getString(key);
          if (userStr == null) continue;
          try {
            final user = UserModel.fromJson(
                jsonDecode(userStr) as Map<String, dynamic>);
            final color = palette[colorIndex % palette.length];
            colorIndex++;
            contacts.add(ContactModel(
              id: uid,
              name: user.fullName,
              username: user.upiId,
              bank: 'PayFlow',
              avatarColor: color,
              initials: user.initials,
              isPayFlowUser: true,
              payflowUpiId: user.upiId,
              phone: user.phone,
            ));
          } catch (_) {}
        }
      } catch (_) {}
    }

    return contacts;
  }

  // ─── Transactions ──────────────────────────────────────────────────────────

  /// Returns the user's transaction history (most recent first).
  Future<List<TransactionModel>> getTransactions() async {
    final uid = _auth.currentUser?.uid ?? _currentUserData?.id ?? _mockUid;
    if (uid == null) return [];

    // Try Firestore first
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final txList = snapshot.docs
            .map((d) => TransactionModel.fromJson(d.data()))
            .toList();
        // Cache locally
        await _saveTransactionsLocally(uid, txList);
        return txList;
      }
    } catch (_) {}

    // Fall back to local cache
    return await _loadTransactionsLocally(uid);
  }

  Future<void> _saveTransactionsLocally(
      String uid, List<TransactionModel> txList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = txList.map((t) => t.toJson()).toList();
      await prefs.setString('cached_txs_$uid', jsonEncode(encoded));
    } catch (_) {}
  }

  Future<List<TransactionModel>> _loadTransactionsLocally(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_txs_$uid');
      if (str != null) {
        final List<dynamic> decoded = jsonDecode(str) as List<dynamic>;
        return decoded
            .map((item) =>
                TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Records a transaction for the current user (in-memory + local + Firestore).
  Future<void> recordTransaction({
    required String vendor,
    required double amount,
    required TransactionType type,
    String category = 'Transfer',
  }) async {
    final uid = _auth.currentUser?.uid ?? _currentUserData?.id ?? _mockUid;
    if (uid == null) return;

    final txId = 'TX${DateTime.now().millisecondsSinceEpoch}';
    final tx = TransactionModel(
      id: txId,
      vendor: vendor,
      category: type == TransactionType.debit ? category : 'Credit',
      amount: amount,
      type: type,
      date: DateTime.now(),
      icon: type == TransactionType.debit
          ? Icons.send_rounded
          : Icons.south_west_rounded,
      iconColor: type == TransactionType.debit
          ? kGreen
          : const Color(0xFF5B8FF9),
    );

    // Load existing, prepend new
    final existing = await _loadTransactionsLocally(uid);
    existing.insert(0, tx);
    await _saveTransactionsLocally(uid, existing);

    // Save to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(txId)
          .set(tx.toJson());
    } catch (_) {}
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
    await _clearPersistedUid();
    _currentUserData = null;
    _mockUid = null;
  }
}
