import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/saved_card_model.dart';
import '../services/auth_service.dart';
import 'contact_sync_screen.dart';

class AddCardScreen extends StatefulWidget {
  final bool isOnboarding;
  const AddCardScreen({super.key, this.isOnboarding = false});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _processing = false;

  // Form controllers
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  String _brand = 'visa';
  String? _numberError;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _brand = SavedCardModel.detectBrand(digits);
      _numberError = null;
    });
  }

  String _formatCardNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  void _linkCard() async {
    final number = _numberCtrl.text.replaceAll(' ', '');
    if (number.length < 13) {
      setState(() => _numberError = 'Enter a valid card number');
      return;
    }

    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // simulate network

    final user = AuthService.instance.currentUser;
    final last4 = number.length >= 4 ? number.substring(number.length - 4) : '0000';
    final parts = _expiryCtrl.text.split('/');
    final newCard = SavedCardModel(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      cardholderName: _nameCtrl.text.trim().isEmpty
          ? (user?.fullName ?? 'CARDHOLDER')
          : _nameCtrl.text.trim().toUpperCase(),
      last4: last4,
      expiryMonth: parts.isNotEmpty ? parts[0].trim() : '12',
      expiryYear: parts.length > 1 ? parts[1].trim() : '29',
      brand: _brand,
      gradient: SavedCardModel.gradientForBrand(_brand),
      isDefault: true,
    );

    await AuthService.instance.saveCard(newCard);

    if (!mounted) return;
    setState(() => _processing = false);

    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ContactSyncScreen()),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  void _skip() {
    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ContactSyncScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isOnboarding)
                GestureDetector(
                  onTap: _skip,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: kSurface1,
                      shape: BoxShape.circle,
                      border: Border.all(color: kDivider),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: kTextSecondary, size: 16),
                  ),
                ),
              if (widget.isOnboarding) const SizedBox(height: 24),

              // ── Live card preview ───────────────────────────────────────
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 300,
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: SavedCardModel.gradientForBrand(_brand),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: SavedCardModel.gradientForBrand(_brand)[0]
                            .withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _brandLabel(_brand),
                              style: GoogleFonts.inter(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const Icon(Icons.contactless_rounded,
                                color: Colors.black54, size: 22),
                          ],
                        ),
                        Text(
                          _previewNumber(_numberCtrl.text),
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _nameCtrl.text.isEmpty
                                  ? 'CARDHOLDER NAME'
                                  : _nameCtrl.text.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _expiryCtrl.text.isEmpty
                                  ? 'MM/YY'
                                  : _expiryCtrl.text,
                              style: GoogleFonts.inter(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
              ),

              const SizedBox(height: 32),

              Text(
                'Add Debit / Credit Card',
                style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ).animate(delay: 150.ms).fadeIn().slideX(),
              const SizedBox(height: 6),
              Text(
                'Your card details are stored securely on-device.',
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 28),

              // Card number
              _buildLabel('Card Number'),
              const SizedBox(height: 8),
              TextField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 18,
                    letterSpacing: 2),
                decoration: _inputDeco(
                  hint: '0000 0000 0000 0000',
                  errorText: _numberError,
                  suffix: Icon(
                    _brandIcon(_brand),
                    color: kTextSecondary,
                    size: 22,
                  ),
                ),
                onChanged: (v) {
                  _onCardNumberChanged(v);
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),

              // Cardholder name
              _buildLabel('Name on Card'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
                decoration: _inputDeco(hint: 'JOHN DOE'),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Expiry'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _expiryCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryFormatter(),
                          ],
                          style: GoogleFonts.inter(
                              color: kTextPrimary, fontSize: 15),
                          decoration: _inputDeco(hint: 'MM/YY'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CVV'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cvvCtrl,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: GoogleFonts.inter(
                              color: kTextPrimary, fontSize: 15),
                          decoration: _inputDeco(hint: '•••'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _processing ? null : _linkCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    disabledBackgroundColor: kGreen.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : Text(
                          'Add Card',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              if (widget.isOnboarding)
                Center(
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      "I'll do this later",
                      style: GoogleFonts.inter(
                        color: kTextMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ).animate(delay: 450.ms).fadeIn(),

              const SizedBox(height: 24),

              // Security badge
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, color: kTextMuted, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Secured & stored on-device only',
                      style: GoogleFonts.inter(
                          color: kTextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            color: kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3),
      );

  InputDecoration _inputDeco({
    required String hint,
    String? errorText,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 14),
        errorText: errorText,
        errorStyle:
            GoogleFonts.inter(color: kRed, fontSize: 11),
        suffixIcon: suffix,
        filled: true,
        fillColor: kSurface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  String _previewNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    final padded = digits.padRight(16, '•');
    return '${padded.substring(0, 4)} ${padded.substring(4, 8)} ${padded.substring(8, 12)} ${padded.substring(12, 16)}';
  }

  String _brandLabel(String brand) {
    switch (brand) {
      case 'mastercard': return 'MASTERCARD';
      case 'rupay': return 'RUPAY';
      case 'amex': return 'AMEX';
      default: return 'VISA';
    }
  }

  IconData _brandIcon(String brand) {
    switch (brand) {
      case 'mastercard': return Icons.credit_card;
      case 'rupay': return Icons.account_balance_rounded;
      case 'amex': return Icons.credit_score;
      default: return Icons.credit_card_rounded;
    }
  }
}

// ─── Text formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    String s = digits;
    if (digits.length >= 2) {
      s = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return next.copyWith(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}
