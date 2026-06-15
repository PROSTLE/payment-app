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
  static const int _totalSteps = 4;

  // Step 1
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  OtpMethod _selectedMethod = OtpMethod.sms;

  // Step 2 (OTP)
  final _otpCtrl = TextEditingController();

  // Step 3
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;

  // Step 4 (PIN)
  String _pin = '';
  String _confirmPin = '';
  bool _settingConfirm = false;

  String? _otpError;
  String? _formError;
  bool _loading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() { _step++; _formError = null; });
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
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

  void _sendOtpAndNext() {
    if (!_validateStep1()) return;
    setState(() { _loading = true; _formError = null; });

    final method = _selectedMethod;
    String target = '';
    if (method == OtpMethod.email) {
      target = _emailCtrl.text.trim();
    } else {
      target = '+91${_phoneCtrl.text.trim()}';
    }

    AuthService.instance.sendOtp(
      target,
      method: method,
      codeSent: (verId) {
        if (!mounted) return;
        setState(() => _loading = false);
        _nextStep();
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
          _formError = e.message ?? 'Failed to send OTP';
        });
      },
    );
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

  // ─── Validation ────────────────────────────────────────────────────────────

  bool _validateStep1() {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _formError = 'Enter your full name');
      return false;
    }
    if (_selectedMethod == OtpMethod.email) {
      if (!_emailCtrl.text.trim().contains('@')) {
        setState(() => _formError = 'Enter a valid email address');
        return false;
      }
    } else {
      if (_phoneCtrl.text.trim().length < 10) {
        setState(() => _formError = 'Enter a valid 10-digit phone number');
        return false;
      }
    }
    return true;
  }

  Future<void> _verifyOtpAndNext() async {
    final otp = _otpCtrl.text.replaceAll(RegExp(r'[^\d]'), '').trim();
    if (otp.length < 6) {
      setState(() => _otpError = 'Enter the complete 6-digit OTP');
      return;
    }

    setState(() { _loading = true; _otpError = null; });
    final success = await AuthService.instance.verifyOtp(otp, method: _selectedMethod);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _nextStep();
    } else {
      setState(() => _otpError = 'Invalid OTP. Please try again.');
      HapticFeedback.heavyImpact();
    }
  }

  bool _validateStep3() {
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _formError = 'Enter a valid email address');
      return false;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _formError = 'Password must be at least 6 characters');
      return false;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _formError = 'Passwords do not match');
      return false;
    }
    return true;
  }

  // ─── PIN input ─────────────────────────────────────────────────────────────

  void _onPinKey(String digit) {
    setState(() {
      if (!_settingConfirm) {
        if (_pin.length < 4) _pin += digit;
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() => _settingConfirm = true);
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
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() { _formError = null; });
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
        phone: _selectedMethod == OtpMethod.email ? '' : '+91${_phoneCtrl.text.trim()}',
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
        _formError = 'Registration failed: ${e.toString().replaceAll('Exception: ', '')}';
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
                  _buildStep1(),
                  _buildStep2Otp(),
                  _buildStep3Email(),
                  _buildStep4Pin(),
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
          const Spacer(),
          Text(
            'Step ${_step + 1} of $_totalSteps',
            style: GoogleFonts.inter(color: kTextMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(_totalSteps, (i) {
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

  // ─── Step 1: Name, Channel, and Identifier ─────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Your Details 📋',
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Let\'s set up your PayFlow account',
              style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          _label('Full Name'),
          const SizedBox(height: 8),
          _field(_nameCtrl, 'e.g. Arjun Sharma', Icons.person_outline),
          const SizedBox(height: 20),
          _label('Verification Method'),
          const SizedBox(height: 8),
          _buildMethodSelector(),
          const SizedBox(height: 12),
          if (_selectedMethod == OtpMethod.email) ...[
            _label('Email Address'),
            const SizedBox(height: 8),
            _field(_emailCtrl, 'you@example.com', Icons.email_outlined, type: TextInputType.emailAddress),
          ] else ...[
            _label('Phone Number'),
            const SizedBox(height: 8),
            _phoneField(),
          ],
          const SizedBox(height: 8),
          Text(
            _selectedMethod == OtpMethod.email 
                ? 'OTP will be sent to this email address' 
                : 'OTP will be sent to this number via ${_selectedMethod == OtpMethod.whatsapp ? "WhatsApp" : "SMS"}',
            style: GoogleFonts.inter(color: kTextMuted, fontSize: 11),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            _errorWidget(_formError!),
          ],
          const SizedBox(height: 32),
          _primaryButton('Continue', _loading ? () {} : _sendOtpAndNext),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _buildMethodSelector() {
    return Container(
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
    );
  }

  Widget _buildMethodTab(OtpMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethod = method;
            _formError = null;
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
                size: 15,
                color: isSelected ? Colors.black : kTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black : kTextSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 2: OTP ──────────────────────────────────────────────────────────

  Widget _buildStep2Otp() {
    String targetDesc = '';
    if (_selectedMethod == OtpMethod.email) {
      targetDesc = _emailCtrl.text.trim();
    } else {
      final phone = _phoneCtrl.text.trim();
      targetDesc = phone.length >= 10
          ? '+91 XXXXXX${phone.substring(phone.length - 4)}'
          : '+91 $phone';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Verify OTP 🔐',
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            _selectedMethod == OtpMethod.email 
                ? 'Enter the 6-digit OTP sent to\n$targetDesc'
                : 'Enter the 6-digit OTP sent via ${_selectedMethod == OtpMethod.whatsapp ? "WhatsApp" : "SMS"} to\n$targetDesc',
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              OtpInputFormatter(),
            ],
            onChanged: (v) {
              final digits = v.replaceAll(RegExp(r'[^\d]'), '');
              if (digits.length == 6) {
                _verifyOtpAndNext();
              }
            },
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 22, letterSpacing: 8),
              filled: true,
              fillColor: kSurface1,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kDivider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 2)),
            ),
          ),
          if (_otpError != null) ...[
            const SizedBox(height: 12),
            _errorWidget(_otpError!),
          ],
          const SizedBox(height: 32),
          _primaryButton('Verify OTP', _loading ? () {} : _verifyOtpAndNext),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _sendOtpAndNext,
              child: Text('Resend OTP',
                  style: GoogleFonts.inter(
                      color: kGreen, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  // ─── Step 3: Email & Password ──────────────────────────────────────────────

  Widget _buildStep3Email() {
    final showEmailField = _selectedMethod != OtpMethod.email;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Secure Account 🔒',
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Create your login credentials',
              style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          if (showEmailField) ...[
            _label('Email Address'),
            const SizedBox(height: 8),
            _field(_emailCtrl, 'you@example.com', Icons.email_outlined,
                type: TextInputType.emailAddress),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: kSurface1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kDivider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: kGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verified Email',
                            style: GoogleFonts.inter(color: kTextMuted, fontSize: 11)),
                        Text(_emailCtrl.text,
                            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          _label('Password'),
          const SizedBox(height: 8),
          _field(_passCtrl, 'Min. 6 characters', Icons.lock_outline,
              obscure: _obscurePass,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscurePass = !_obscurePass),
                child: Icon(
                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kTextMuted, size: 20,
                ),
              )),
          const SizedBox(height: 20),
          _label('Confirm Password'),
          const SizedBox(height: 8),
          _field(_confirmPassCtrl, 'Re-enter password', Icons.lock_outline,
              obscure: true),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            _errorWidget(_formError!),
          ],
          const SizedBox(height: 32),
          _primaryButton('Continue', () {
            if (_validateStep3()) _nextStep();
          }),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  // ─── Step 4: PIN Setup ────────────────────────────────────────────────────

  Widget _buildStep4Pin() {
    final currentPin = _settingConfirm ? _confirmPin : _pin;
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_settingConfirm ? 'Confirm PIN 🔁' : 'Set Your PIN 🔑',
                  style: GoogleFonts.inter(
                      color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                _settingConfirm
                    ? 'Re-enter your 4-digit PIN to confirm'
                    : 'This PIN will lock your app each session',
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < currentPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: filled ? 18 : 16,
              height: filled ? 18 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? kGreen : Colors.transparent,
                border: Border.all(
                    color: filled ? kGreen : kTextMuted, width: 1.5),
                boxShadow: filled ? greenGlow(blur: 12) : null,
              ),
            );
          }),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(_formError!,
              style: GoogleFonts.inter(color: kRed, fontSize: 13)),
        ],
        const Spacer(),
        if (_loading)
          const CircularProgressIndicator(color: kGreen)
        else
          _buildPinKeypad(),
        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _buildPinKeypad() {
    final keys = [
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kSurface1,
                  ),
                  child: Center(
                    child: k == 'del'
                        ? const Icon(Icons.backspace_outlined,
                            color: kTextSecondary, size: 22)
                        : Text(k,
                            style: GoogleFonts.inter(
                                color: kTextPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w400)),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500));

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
            Expanded(child: Text(msg,
                style: GoogleFonts.inter(color: kRed, fontSize: 12))),
          ],
        ),
      );

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
        prefixIcon: Icon(icon, color: kTextMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: kSurface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _phoneField() {
    return TextField(
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
          child: Text('+91',
              style: GoogleFonts.inter(
                  color: kTextSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        filled: true,
        fillColor: kSurface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
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
