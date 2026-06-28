import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/colors.dart';
import '../models/contact_model.dart';
import '../models/saved_card_model.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../widgets/swipe_to_pay_slider.dart';
import 'success_screen.dart';

// A fallback demo card used when user hasn't added any real cards
final SavedCardModel _demoCard = SavedCardModel(
  id: 'demo',
  cardholderName: 'PayFlow User',
  last4: '4242',
  expiryMonth: '12',
  expiryYear: '28',
  brand: 'visa',
  gradient: kCardYellow,
  isDefault: true,
);

class CalculatorSendScreen extends StatefulWidget {
  final ContactModel recipient;
  final String? upiId;
  final double? prefilledAmount;

  const CalculatorSendScreen({
    super.key,
    required this.recipient,
    this.upiId,
    this.prefilledAmount,
  });

  @override
  State<CalculatorSendScreen> createState() => _CalculatorSendScreenState();
}

class _CalculatorSendScreenState extends State<CalculatorSendScreen> {
  String _display = '0';
  String _op = '';
  double _firstNum = 0;
  bool _newEntry = false;
  String _activeTab = 'Send';
  List<SavedCardModel> _cards = [];
  int _selectedCardIndex = 0;
  bool _loading = true;

  // UPI mode
  final TextEditingController _upiCtrl = TextEditingController();
  bool _upiMode = false;
  String? _upiError;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAmount != null && widget.prefilledAmount! > 0) {
      _display = widget.prefilledAmount!.toStringAsFixed(0);
    }
    if (widget.upiId != null) {
      _upiCtrl.text = widget.upiId!;
      _upiMode = false;
    }
    _loadCards();
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await AuthService.instance.getSavedCards();
    setState(() {
      _cards = cards.isEmpty ? [_demoCard] : cards;
      _loading = false;
    });
  }

  void _onNumber(String n) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_newEntry || _display == '0') {
        _display = n;
        _newEntry = false;
      } else {
        if (_display.length < 8) _display += n;
      }
    });
  }

  void _onDot() {
    if (_display.contains('.')) return;
    setState(() => _display += '.');
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_display.length <= 1) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  void _onOperator(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_op.isNotEmpty && !_newEntry) {
        final second = double.tryParse(_display) ?? 0;
        double result = _firstNum;
        switch (_op) {
          case '+':
            result = _firstNum + second;
            break;
          case '−':
            result = _firstNum - second;
            break;
          case '×':
            result = _firstNum * second;
            break;
          case '÷':
            result = second != 0 ? _firstNum / second : 0;
            break;
        }
        _display = result % 1 == 0
            ? result.toStringAsFixed(0)
            : result.toStringAsFixed(2);
        _firstNum = result;
      } else {
        _firstNum = double.tryParse(_display) ?? 0;
      }
      _op = op;
      _newEntry = true;
    });
  }

  double get _amount => double.tryParse(_display) ?? 0;

  // ─── Show confirmation sheet ────────────────────────────────────────────────

  void _showConfirmationSheet() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter an amount first',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final balance = AuthService.instance.balance;
    if (_amount > balance) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Insufficient balance. Available: ₹${balance.toStringAsFixed(0)}',
                  style:
                      GoogleFonts.inter(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: kRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final card = _cards[_selectedCardIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentConfirmSheet(
        amount: _amount,
        recipient: widget.recipient,
        card: card,
        upiId: _upiMode ? _upiCtrl.text.trim() : widget.upiId,
        onConfirmed: _showPinDialog,
      ),
    );
  }

  /// Shows the PIN entry dialog (instead of Razorpay).
  void _showPinDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _PinEntrySheet(
        onPinEntered: (pin) {
          Navigator.pop(ctx);
          if (AuthService.instance.verifyPin(pin)) {
            _processPayment();
          } else {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Incorrect PIN. Please try again.',
                    style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: kRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _loading = true);

    final success = await AuthService.instance.deductBalance(_amount);
    if (!success) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance.',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Record the transaction
    await AuthService.instance.recordTransaction(
      vendor: widget.recipient.name,
      amount: _amount,
      type: TransactionType.debit,
      category: 'Transfer',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    final txId = 'TX${DateTime.now().millisecondsSinceEpoch}';
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => SuccessScreen(
          amount: _amount,
          recipient: widget.recipient,
          txId: txId,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_loading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: kGreen)))
            else
              Expanded(
                child: Column(
                  children: [
                    _buildRecipientInfo(),
                    if (_upiMode)
                      _buildUpiEntry()
                    else ...[
                      _buildAmountDisplay(),
                      _buildOperatorRow(),
                      const Divider(color: Color(0xFFE0E0E0), height: 1),
                      _buildKeypad(),
                    ],
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: SwipeToPaySlider(
                        onConfirmed: _showConfirmationSheet,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.black54, size: 24),
          ),
          const Spacer(),
          if (widget.upiId == null) ...[
            _TabButton(
              label: 'Send',
              active: _activeTab == 'Send',
              onTap: () => setState(() {
                _activeTab = 'Send';
                _upiMode = false;
              }),
            ),
            const SizedBox(width: 4),
            _TabButton(
              label: 'UPI ID',
              active: _activeTab == 'UPI ID',
              onTap: () => setState(() {
                _activeTab = 'UPI ID';
                _upiMode = true;
              }),
            ),
            const SizedBox(width: 4),
            _TabButton(
              label: 'Request',
              active: _activeTab == 'Request',
              onTap: () => setState(() {
                _activeTab = 'Request';
                _upiMode = false;
              }),
            ),
            const Spacer(),
          ] else ...[
            Text(
              'Pay to Contact',
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildRecipientInfo() {
    final card = _cards[_selectedCardIndex];
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() =>
                _selectedCardIndex = (_selectedCardIndex + 1) % _cards.length);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.recipient.name}  •  ',
                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: card.gradient),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${card.brand.toUpperCase()} ···· ${card.last4}',
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (_cards.length > 1)
                  const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.black38),
              ],
            ),
          ),
        ),
        if (widget.upiId != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.upiId!,
            style: GoogleFonts.inter(
              color: Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpiEntry() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter UPI ID',
              style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: name@upi or number@bank',
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _upiCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'e.g. priya@okaxis',
                hintStyle:
                    GoogleFonts.inter(color: Colors.black38, fontSize: 15),
                prefixIcon: const Icon(Icons.alternate_email,
                    color: Colors.black38, size: 20),
                filled: true,
                fillColor: const Color(0xFFECECEC),
                errorText: _upiError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() => _upiError = null),
            ),
            const SizedBox(height: 24),
            Text(
              'Amount (₹)',
              style: GoogleFonts.inter(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.inter(
                    color: Colors.black26,
                    fontSize: 32,
                    fontWeight: FontWeight.w700),
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 28,
                    fontWeight: FontWeight.w600),
                filled: true,
                fillColor: const Color(0xFFECECEC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (v) =>
                  setState(() => _display = v.isEmpty ? '0' : v),
            ),
            const Spacer(),
            Text(
              'Common UPI handles',
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '@okaxis',
                '@okicici',
                '@okhdfcbank',
                '@oksbi',
                '@ybl',
                '@ibl',
                '@apl'
              ]
                  .map((h) => GestureDetector(
                        onTap: () {
                          final base = _upiCtrl.text.split('@')[0];
                          _upiCtrl.text = '$base$h';
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECECEC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(h,
                              style: GoogleFonts.inter(
                                  color: Colors.black54, fontSize: 12)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '₹$_display',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.recipient.avatarColor,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                widget.recipient.initials[0],
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorRow() {
    const ops = ['+', '−', '×', '÷'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ops.map((op) {
          final active = _op == op;
          return GestureDetector(
            onTap: () => _onOperator(op),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                color: active ? Colors.black : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  op,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: active ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeypad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: rows.map((row) {
            return Expanded(
              child: Row(
                children: row.map((k) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (k == '⌫') {
                          _onDelete();
                        } else if (k == '.') {
                          _onDot();
                        } else {
                          _onNumber(k);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: k == '⌫'
                              ? const Icon(Icons.backspace_outlined,
                                  size: 22, color: Colors.black87)
                              : Text(
                                  k,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── PIN Entry Bottom Sheet ────────────────────────────────────────────────────

class _PinEntrySheet extends StatefulWidget {
  final void Function(String pin) onPinEntered;

  const _PinEntrySheet({required this.onPinEntered});

  @override
  State<_PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends State<_PinEntrySheet> {
  final List<String> _pin = [];

  void _onKey(String key) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.add(key));
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onPinEntered(_pin.join());
      });
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF252D37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          const Icon(Icons.lock_outline_rounded, color: kGreen, size: 32),
          const SizedBox(height: 12),
          Text(
            'Enter PIN to confirm',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Use your PayFlow PIN to authorise this payment',
            style: GoogleFonts.inter(
                color: const Color(0xFF9BA3AE), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: filled ? 18 : 16,
                height: filled ? 18 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? kGreen : Colors.transparent,
                  border: Border.all(
                    color: filled ? kGreen : const Color(0xFF5A6373),
                    width: 1.5,
                  ),
                  boxShadow: filled ? greenGlow(blur: 12) : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          // Keypad
          ...keys.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((key) {
                    if (key.isEmpty) {
                      return const SizedBox(width: 72, height: 64);
                    }
                    if (key == 'del') {
                      return _PinKey(
                        onTap: _onDelete,
                        child: const Icon(Icons.backspace_outlined,
                            color: Colors.white70, size: 22),
                      );
                    }
                    return _PinKey(
                      onTap: () => _onKey(key),
                      child: Text(key,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w400)),
                    );
                  }).toList(),
                ),
              )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: const Color(0xFF9BA3AE), fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PinKey({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Payment Confirmation Bottom Sheet ────────────────────────────────────────

double _carbonGrams(double amount, String category) {
  const factors = {
    'Food': 0.8,
    'Transport': 1.2,
    'Entertainment': 0.4,
    'Subscription': 0.3,
    'Investment': 0.1,
    'Music': 0.3,
  };
  final factor = factors[category] ?? 0.5;
  return amount * factor;
}

class _PaymentConfirmSheet extends StatefulWidget {
  final double amount;
  final ContactModel recipient;
  final SavedCardModel card;
  final String? upiId;
  final String category;
  final VoidCallback onConfirmed;

  const _PaymentConfirmSheet({
    required this.amount,
    required this.recipient,
    required this.card,
    this.upiId,
    this.category = 'Transfer',
    required this.onConfirmed,
  });

  @override
  State<_PaymentConfirmSheet> createState() => _PaymentConfirmSheetState();
}

class _PaymentConfirmSheetState extends State<_PaymentConfirmSheet> {
  bool _offsetAdded = false;

  @override
  Widget build(BuildContext context) {
    final txRef = 'PF${DateTime.now().millisecondsSinceEpoch % 100000}';
    final carbonG = _carbonGrams(widget.amount, widget.category);
    final carbonDisplay = carbonG >= 1000
        ? '${(carbonG / 1000).toStringAsFixed(2)} kg'
        : '${carbonG.toStringAsFixed(0)} g';
    final offsetCost = ((carbonG / 1000).ceil() * 10).clamp(1, 999);
    final totalAmount = widget.amount + (_offsetAdded ? offsetCost : 0);

    // Inline insufficient balance check
    final balance = AuthService.instance.balance;
    final hasEnoughBalance = totalAmount <= balance;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF252D37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirm Payment',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          // Amount hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasEnoughBalance
                  ? kGreen.withValues(alpha: 0.12)
                  : kRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: hasEnoughBalance
                      ? kGreen.withValues(alpha: 0.25)
                      : kRed.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  '₹ ${totalAmount.toStringAsFixed(totalAmount % 1 == 0 ? 0 : 2)}',
                  style: GoogleFonts.inter(
                    color: hasEnoughBalance ? kGreen : kRed,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.recipient.avatarColor,
                      ),
                      child: Center(
                        child: Text(
                          widget.recipient.initials[0],
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'to ${widget.recipient.name}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                // Insufficient balance banner inside sheet
                if (!hasEnoughBalance) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: kRed, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Insufficient balance (₹${balance.toStringAsFixed(0)} available)',
                          style: GoogleFonts.inter(
                              color: kRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 20),
          _DetailRow(
            label: 'To',
            value: widget.upiId ?? widget.recipient.username,
          ),
          _DetailRow(
            label: 'From',
            value:
                '${widget.card.brand.toUpperCase()} ···· ${widget.card.last4}',
          ),
          _DetailRow(
            label: 'Ref. No.',
            value: txRef,
          ),
          _DetailRow(
            label: 'Status',
            value: 'Instant Transfer',
            valueColor: kGreen,
          ),
          const SizedBox(height: 12),
          // ── Carbon Intelligence ──
          GestureDetector(
            onTap: () => setState(() => _offsetAdded = !_offsetAdded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _offsetAdded
                    ? const Color(0xFF1A3A2A)
                    : const Color(0xFF1A2A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _offsetAdded
                      ? kGreen.withValues(alpha: 0.6)
                      : kGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '~$carbonDisplay CO₂ estimated',
                          style: GoogleFonts.inter(
                              color: kGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _offsetAdded
                              ? 'Offset added ✓ +₹$offsetCost'
                              : 'Tap to offset for +₹$offsetCost',
                          style: GoogleFonts.inter(
                              color: _offsetAdded
                                  ? kGreen
                                  : const Color(0xFF5A6373),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _offsetAdded ? kGreen : Colors.transparent,
                      border: Border.all(
                          color: _offsetAdded
                              ? kGreen
                              : const Color(0xFF5A6373),
                          width: 1.5),
                    ),
                    child: _offsetAdded
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.black)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasEnoughBalance
                  ? () {
                      Navigator.pop(context); // close sheet
                      widget.onConfirmed();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: kGreen.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${totalAmount.toStringAsFixed(totalAmount % 1 == 0 ? 0 : 2)} with PIN',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                  color: const Color(0xFF9BA3AE), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                color: const Color(0xFF5A6373), fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.black54,
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
