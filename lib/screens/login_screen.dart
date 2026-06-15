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
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  OtpMethod _selectedMethod = OtpMethod.sms;
  bool _otpSent = false;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _showMockOtpDialog(String target, String method, String code) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurface1,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kGreen.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: kGreen.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    method == 'WhatsApp' ? Icons.chat : Icons.email,
                    color: kGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'OTP Received!',
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulated $method OTP for preview:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: kTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kDivider),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.inter(
                      color: kGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _otpCtrl.text = code;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Copy & Auto-fill',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendOtp() {
    final method = _selectedMethod;
    String target = '';

    if (method == OtpMethod.email) {
      target = _emailCtrl.text.trim();
      if (!target.contains('@')) {
        setState(() => _errorMsg = 'Enter a valid email address');
        return;
      }
    } else {
      final phone = _phoneCtrl.text.trim();
      if (phone.length < 10) {
        setState(() => _errorMsg = 'Enter a valid phone number');
        return;
      }
      target = '+91$phone';
    }

    setState(() { _loading = true; _errorMsg = null; });

    AuthService.instance.sendOtp(
      target,
      method: method,
      codeSent: (verId) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _otpSent = true;
        });
        if (method != OtpMethod.sms) {
          final code = AuthService.instance.localOtpCode ?? '000000';
          _showMockOtpDialog(
            target,
            method == OtpMethod.whatsapp ? 'WhatsApp' : 'Email',
            code,
          );
        }
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMsg = e.message ?? 'Failed to send OTP';
        });
      },
    );
  }

  Future<void> _verifyOtp() async {
    // Strip ALL non-digit characters before comparing (handles spaces, dashes, newlines from paste)
    final otp = _otpCtrl.text.replaceAll(RegExp(r'[^\d]'), '').trim();
    if (otp.length < 6) {
      setState(() => _errorMsg = 'Enter the complete 6-digit OTP');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    final success = await AuthService.instance.verifyOtp(otp, method: _selectedMethod);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      if (AuthService.instance.currentUser != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const NavigationWrapper(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        setState(() {
          _errorMsg = 'No account found. Please sign up.';
          _otpSent = false;
        });
      }
    } else {
      setState(() => _errorMsg = 'Invalid OTP. Please try again.');
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMethodSelector(),
              _buildLoginForm(),
              const SizedBox(height: 16),
              if (_errorMsg != null) _buildError(),
              const SizedBox(height: 20),
              _buildLoginButton(),
              const SizedBox(height: 16),
              _buildForgotPin(),
              const SizedBox(height: 12),
              _buildAdminLogin(),
              const SizedBox(height: 16),
              _buildSignupPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        if (_otpSent) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                _otpSent = false;
                _otpCtrl.clear();
                _errorMsg = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
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
    String desc = 'Sign in to your account with Phone OTP';
    if (_otpSent) {
      desc = _selectedMethod == OtpMethod.email
          ? 'Enter the 6-digit OTP sent to your email'
          : 'Enter the 6-digit OTP sent to your ${_selectedMethod == OtpMethod.whatsapp ? "WhatsApp" : "phone"}';
    } else {
      if (_selectedMethod == OtpMethod.whatsapp) {
        desc = 'Sign in using your WhatsApp number';
      } else if (_selectedMethod == OtpMethod.email) {
        desc = 'Sign in using your email address';
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back 👋',
          style: GoogleFonts.inter(
            color: kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 6),
        Text(
          desc,
          style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
        ).animate(delay: 150.ms).fadeIn(),
      ],
    );
  }

  Widget _buildMethodSelector() {
    if (_otpSent) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        children: [
          _buildMethodTab(OtpMethod.sms, 'SMS', Icons.sms),
          _buildMethodTab(OtpMethod.whatsapp, 'WhatsApp', Icons.chat),
          _buildMethodTab(OtpMethod.email, 'Email', Icons.email),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildMethodTab(OtpMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethod = method;
            _errorMsg = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? kGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : kTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black : kTextSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        if (!_otpSent) ...[
          if (_selectedMethod == OtpMethod.email)
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
                prefixIcon: const Icon(Icons.email_outlined, color: kTextMuted, size: 20),
                filled: true,
                fillColor: kSurface1,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kDivider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)),
              ),
            )
          else
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
              decoration: InputDecoration(
                counterText: '',
                hintText: '10-digit mobile number',
                hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text('+91',
                      style: GoogleFonts.inter(color: kTextSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                filled: true,
                fillColor: kSurface1,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kDivider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)),
              ),
            ),
        ] else
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              OtpInputFormatter(),
            ],
            style: GoogleFonts.inter(
                color: kTextPrimary, fontSize: 22,
                letterSpacing: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            autofocus: true,
            onChanged: (v) {
              // Auto-verify when 6 clean digits are entered
              final digits = v.replaceAll(RegExp(r'[^\d]'), '');
              if (digits.length == 6) {
                _verifyOtp();
              }
            },
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
              hintStyle: GoogleFonts.inter(
                  color: kTextMuted, fontSize: 18, letterSpacing: 8),
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
                  borderSide: const BorderSide(color: kGreen, width: 2)),
            ),
          ),
        // Resend OTP button (only shown after OTP was sent)
        if (_otpSent)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Didn\'t receive it? ',
                    style: GoogleFonts.inter(
                        color: kTextMuted, fontSize: 13)),
                GestureDetector(
                  onTap: _loading
                      ? null
                      : () {
                          setState(() {
                            _otpSent = false;
                            _otpCtrl.clear();
                            _errorMsg = null;
                          });
                        },
                  child: Text(
                    'Change / Resend',
                    style: GoogleFonts.inter(
                        color: kGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1, end: 0);
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
            child: Text(
              _errorMsg!,
              style: GoogleFonts.inter(color: kRed, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate().shake(hz: 3, offset: const Offset(4, 0));
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Text(
                _otpSent ? 'Verify OTP' : 'Send OTP',
                style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildForgotPin() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ForgotPinScreen()),
        ),
        child: Text(
          'Forgot PIN?',
          style: GoogleFonts.inter(
            color: kTextMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ).animate(delay: 380.ms).fadeIn();
  }

  Future<void> _loginAsAdmin() async {
    setState(() => _loading = true);
    await AuthService.instance.loginAsAdmin();
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const NavigationWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildAdminLogin() {
    return Center(
      child: GestureDetector(
        onTap: _loginAsAdmin,
        child: Text(
          'Login as Admin (Bypass OTP)',
          style: GoogleFonts.inter(
            color: kGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate(delay: 410.ms).fadeIn();
  }

  Widget _buildSignupPrompt() {
    return Center(
      child: GestureDetector(
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
                style: GoogleFonts.inter(color: kGreen, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 450.ms).fadeIn();
  }
}

class OtpInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final cleanDigits = digits.length > 6 ? digits.substring(0, 6) : digits;
    return TextEditingValue(
      text: cleanDigits,
      selection: TextSelection.collapsed(offset: cleanDigits.length),
    );
  }
}
