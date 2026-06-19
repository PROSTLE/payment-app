import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'add_card_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;
  static const int _totalSteps = 2; // Step 0: info, Step 1: PIN

  // Step 0 fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 1 PIN
  String _pin = '';
  String _confirmPin = '';
  bool _settingConfirm = false;

  String? _formError;
  bool _loading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() { _step++; _formError = null; });
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() { _step--; _formError = null; });
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStep0() {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _formError = 'Enter your full name (at least 2 characters)');
      return false;
    }
    if (_phoneCtrl.text.trim().length < 10) {
      setState(() => _formError = 'Enter a valid 10-digit phone number');
      return false;
    }
    if (!_emailCtrl.text.trim().contains('@')) {
      setState(() => _formError = 'Enter a valid email address');
      return false;
    }
    return true;
  }

  void _onPinKey(String digit) {
    setState(() {
      if (!_settingConfirm) {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _settingConfirm = true);
          });
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _checkPinMatch();
      }
    });
  }

  void _onPinDelete() {
    setState(() {
      if (!_settingConfirm) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _checkPinMatch() {
    if (_pin == _confirmPin) {
      HapticFeedback.lightImpact();
      _completeSignup();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _confirmPin = '';
        _formError = 'PINs do not match. Try again.';
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _formError = null);
        });
      });
    }
  }

  Future<void> _completeSignup() async {
    setState(() => _loading = true);
    try {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _nameCtrl.text.trim(),
        phone: '+91${_phoneCtrl.text.trim()}',
        email: _emailCtrl.text.trim(),
        pin: _pin,
      );
      await AuthService.instance.register(user);
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const AddCardScreen(isOnboarding: true),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _pin = '';
        _confirmPin = '';
        _settingConfirm = false;
        _formError = 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0Info(),
                  _buildStep1Pin(),
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
            onTap: _prevStep,
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
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: kCardMint),
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            'PayFlow',
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i <= _step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive ? kGreen : kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep0Info() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create account ✨',
            style: GoogleFonts.inter(
              color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          const SizedBox(height: 6),
          Text('Fill in your details to get started',
              style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14))
              .animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 28),

          _buildLabel('Full Name'),
          _buildTextField(
            controller: _nameCtrl,
            hint: 'e.g. Aditya Kumar',
            icon: Icons.person_outline,
            inputType: TextInputType.name,
          ),
          const SizedBox(height: 16),

          _buildLabel('Mobile Number'),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '10-digit number',
              hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Text('+91',
                    style: GoogleFonts.inter(
                        color: kTextSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              filled: true,
              fillColor: kSurface1,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kDivider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kGreen, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Email Address'),
          _buildTextField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            inputType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          if (_formError != null) _buildError(),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () {
                      if (_validateStep0()) _nextStep();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Continue',
                  style: GoogleFonts.inter(
                      color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildStep1Pin() {
    final currentPin = _settingConfirm ? _confirmPin : _pin;
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              Text(
                _settingConfirm ? 'Confirm your PIN 🔐' : 'Set your PIN 🔑',
                style: GoogleFonts.inter(
                    color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.w700),
              ).animate(key: ValueKey(_settingConfirm)).fadeIn(),
              const SizedBox(height: 6),
              Text(
                _settingConfirm
                    ? 'Re-enter your 4-digit PIN to confirm'
                    : 'Choose a secure 4-digit PIN for PayFlow',
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? kGreen : Colors.transparent,
                      border: Border.all(
                          color: filled ? kGreen : kTextMuted, width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_formError != null) _buildError(),
            ],
          ),
        ),
        const Spacer(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: kGreen, strokeWidth: 2),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: row.map((k) {
                    if (k.isEmpty) return const Expanded(child: SizedBox());
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (k == '⌫') _onPinDelete();
                          else _onPinKey(k);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          height: 60,
                          decoration: BoxDecoration(
                            color: kSurface1,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kDivider),
                          ),
                          child: Center(
                            child: k == '⌫'
                                ? const Icon(Icons.backspace_outlined,
                                    color: kTextPrimary, size: 22)
                                : Text(k,
                                    style: GoogleFonts.inter(
                                      color: kTextPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )).toList(),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.inter(
              color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
        prefixIcon: Icon(icon, color: kTextMuted, size: 20),
        filled: true,
        fillColor: kSurface1,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kDivider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kGreen, width: 1.5)),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_formError!,
                  style: GoogleFonts.inter(color: kRed, fontSize: 12))),
        ],
      ),
    ).animate().shake(hz: 3, offset: const Offset(4, 0));
  }
}
