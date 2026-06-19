import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;

  // Step 0 – Identity verification
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 1 – New PIN
  String _pin = '';
  String _confirmPin = '';
  bool _confirmingPin = false;

  bool _loading = false;
  String? _formError;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _goPage(int page) {
    setState(() {
      _step = page;
      _formError = null;
    });
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      _goPage(_step - 1);
    }
  }

  // ─── Step 0: Verify Identity ───────────────────────────────────────────────

  Future<void> _verifyIdentity() async {
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (phone.length < 10) {
      setState(() => _formError = 'Enter a valid 10-digit mobile number');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _formError = 'Enter a valid email address');
      return;
    }

    setState(() { _loading = true; _formError = null; });
    // Use the async lookup to check if a matching account exists
    final exists = await AuthService.instance.checkUserExists(email, phone);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!exists) {
      setState(() => _formError = 'No account found with these details. Please check and try again.');
      return;
    }

    _goPage(1);
  }

  // ─── Step 1: PIN Entry ─────────────────────────────────────────────────────

  void _onPinKey(String digit) {
    setState(() {
      if (!_confirmingPin) {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _confirmingPin = true);
          });
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _checkPins();
      }
    });
  }

  void _onPinDelete() {
    setState(() {
      if (!_confirmingPin) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _checkPins() {
    if (_pin == _confirmPin) {
      _saveNewPin();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _confirmPin = '';
        _formError = 'PINs do not match. Try again.';
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _formError = null);
      });
    }
  }

  Future<void> _saveNewPin() async {
    setState(() => _loading = true);
    try {
      // Load the matched user into the session first
      final email = _emailCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      await AuthService.instance.resetPinByIdentity(email, phone, _pin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const NavigationWrapper(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _formError = 'Failed to save PIN. Please try again.';
      });
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepVerify(),
                  _buildStepPin(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kSurface1,
                shape: BoxShape.circle,
                border: Border.all(color: kDivider),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: kTextSecondary, size: 16),
            ),
          ),
          const Spacer(),
          Text(
            'Step ${_step + 1} of 2',
            style: GoogleFonts.inter(color: kTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(2, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i <= _step ? kGreen : kSurface2,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 0: Identity Verification ────────────────────────────────────────

  Widget _buildStepVerify() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGreen.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.lock_reset, color: kGreen, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'Reset Your PIN 🔑',
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email and mobile number\nto verify your identity.',
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),

          _label('Mobile Number'),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              counterText: '',
              hintText: '10-digit mobile number',
              hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Text(
                  '+91',
                  style: GoogleFonts.inter(
                    color: kTextSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              filled: true,
              fillColor: kSurface1,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kDivider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kGreen, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),

          _label('Email Address'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Enter your registered email',
              hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
              prefixIcon: const Icon(Icons.email_outlined, color: kTextMuted, size: 20),
              filled: true,
              fillColor: kSurface1,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kDivider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kGreen, width: 1.5)),
            ),
          ),

          if (_formError != null) ...[
            const SizedBox(height: 16),
            _errorWidget(_formError!),
          ],
          const SizedBox(height: 32),
          _primaryButton(
            _loading ? null : _verifyIdentity,
            'Verify & Continue',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  // ─── Step 1: New PIN Setup ─────────────────────────────────────────────────

  Widget _buildStepPin() {
    final current = _confirmingPin ? _confirmPin : _pin;
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGreen.withValues(alpha: 0.15),
                ),
                child: Icon(
                  _confirmingPin ? Icons.check_circle_outline : Icons.pin,
                  color: kGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _confirmingPin ? 'Confirm New PIN 🔁' : 'Set New PIN 🔐',
                style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _confirmingPin
                    ? 'Re-enter the PIN to confirm'
                    : 'Choose a 4-digit PIN to secure your account',
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < current.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: filled ? 18 : 16,
              height: filled ? 18 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? kGreen : Colors.transparent,
                border: Border.all(
                  color: filled ? kGreen : kTextMuted,
                  width: 1.5,
                ),
                boxShadow: filled ? greenGlow(blur: 12) : null,
              ),
            );
          }),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(
            _formError!,
            style: GoogleFonts.inter(color: kRed, fontSize: 13),
          ),
        ],
        const Spacer(),
        if (_loading)
          const CircularProgressIndicator(color: kGreen)
        else
          _buildPinKeypad(),
        const SizedBox(height: 28),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _buildPinKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 64);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (k == 'del') {
                    _onPinDelete();
                  } else {
                    _onPinKey(k);
                  }
                },
                child: Container(
                  width: 72,
                  height: 64,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kSurface1,
                  ),
                  child: Center(
                    child: k == 'del'
                        ? const Icon(Icons.backspace_outlined,
                            color: kTextSecondary, size: 22)
                        : Text(
                            k,
                            style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // ─── Shared Helpers ────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          color: kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _errorWidget(String msg) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: kRed, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(color: kRed, fontSize: 12)),
            ),
          ],
        ),
      ).animate().shake(hz: 3, offset: const Offset(4, 0));

  Widget _primaryButton(VoidCallback? onTap, String label) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
