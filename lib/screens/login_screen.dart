import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';
import 'signup_screen.dart';
import 'forgot_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  String _pin = '';
  int _step = 0; // 0 = identifier, 1 = PIN
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _continueToPin() async {
    final id = _identifierCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _errorMsg = 'Please enter your phone number or email');
      return;
    }
    final isEmail = id.contains('@');
    final isPhone = !isEmail && id.replaceAll(RegExp(r'\D'), '').length >= 10;
    if (!isEmail && !isPhone) {
      setState(() => _errorMsg = 'Enter a valid phone number or email');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    final exists = await AuthService.instance.identifierExists(id);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!exists) {
      // Show popup: not registered
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'No Account Found 👀',
            style: GoogleFonts.inter(
              color: const Color(0xFFE2E8F0),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'We couldn\'t find an account with "$id".\nWould you like to create one?',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Create Account',
                  style: GoogleFonts.inter(
                      color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _step = 1;
      _pin = '';
      _errorMsg = null;
    });
  }

  void _onPinKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      _login();
    }
  }

  void _onPinDelete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _login() async {
    setState(() { _loading = true; _errorMsg = null; });
    final success = await AuthService.instance.loginWithPin(
      _identifierCtrl.text.trim(),
      _pin,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const NavigationWrapper(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMsg = 'Incorrect PIN. Please try again.';
        _pin = '';
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 28),
                    if (_step == 0) _buildIdentifierForm(),
                    if (_step == 1) _buildPinDots(),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      _buildError(),
                    ],
                    const SizedBox(height: 24),
                    if (_step == 0) _buildContinueButton(),
                  ],
                ),
              ),
            ),
            if (_step == 1) _buildKeypad(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        if (_step == 1) ...[
          GestureDetector(
            onTap: () => setState(() { _step = 0; _pin = ''; _errorMsg = null; }),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kSurface1,
                shape: BoxShape.circle,
                border: Border.all(color: kDivider),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: kTextSecondary, size: 16),
            ),
          ),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: kCardMint),
            boxShadow: greenGlow(blur: 16),
          ),
          child: const Icon(Icons.bolt, color: Colors.black, size: 24),
        ),
        const SizedBox(width: 10),
        Text(
          'PayFlow',
          style: GoogleFonts.inter(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _step == 0 ? 'Welcome back 👋' : 'Enter your PIN 🔐',
          style: GoogleFonts.inter(
            color: kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ).animate(key: ValueKey(_step)).fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 6),
        Text(
          _step == 0
              ? 'Sign in with your phone number or email'
              : 'Enter your 4-digit PayFlow PIN',
          style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
        ).animate(key: ValueKey('sub$_step')).fadeIn(),
      ],
    );
  }

  Widget _buildIdentifierForm() {
    return TextField(
      controller: _identifierCtrl,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Phone number or email',
        hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
        prefixIcon: const Icon(Icons.person_outline, color: kTextMuted, size: 20),
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
      onSubmitted: (_) => _continueToPin(),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildPinDots() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final filled = i < _pin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? kGreen : Colors.transparent,
              border: Border.all(
                color: filled ? kGreen : kTextMuted,
                width: 2,
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn();
  }

  Widget _buildError() {
    return Container(
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
            child: Text(_errorMsg!,
                style: GoogleFonts.inter(color: kRed, fontSize: 12)),
          ),
        ],
      ),
    ).animate().shake(hz: 3, offset: const Offset(4, 0));
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _continueToPin,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text('Continue',
                style: GoogleFonts.inter(
                    color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildKeypad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Container(
      color: kBgDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kGreen)),
            )
          else
            ...rows.map((row) => Padding(
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
            )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ForgotPinScreen(mode: ForgotMode.pin)),
                ),
                child: Text('Forgot PIN?',
                    style: GoogleFonts.inter(
                        color: kTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('·',
                    style: GoogleFonts.inter(color: kTextMuted, fontSize: 13)),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          const ForgotPinScreen(mode: ForgotMode.password)),
                ),
                child: Text('Forgot Password?',
                    style: GoogleFonts.inter(
                        color: kTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Create one',
                    style: GoogleFonts.inter(
                        color: kGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}
