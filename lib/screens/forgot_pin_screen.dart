import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';

/// Two modes:
///   - [ForgotMode.pin]      → Forgot PIN, reset it using your password
///   - [ForgotMode.password] → Forgot Password, reset it using your PIN
enum ForgotMode { pin, password }

class ForgotPinScreen extends StatefulWidget {
  final ForgotMode mode;
  const ForgotPinScreen({super.key, this.mode = ForgotMode.pin});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;
  String? _formError;

  // Step 0 – Identifier
  final _identifierCtrl = TextEditingController();

  // Step 1 – Verify credential (PIN or password depending on mode)
  String _verifyPin = '';
  final _verifyPasswordCtrl = TextEditingController();
  bool _verifyPasswordVisible = false;

  // Step 2 – Set new value
  String _newPin = '';
  String _confirmPin = '';
  bool _confirmingPin = false;
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _identifierCtrl.dispose();
    _verifyPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _forgotPin => widget.mode == ForgotMode.pin;

  void _goPage(int page) {
    setState(() {
      _step = page;
      _formError = null;
    });
    _pageCtrl.animateToPage(page,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      _goPage(_step - 1);
    }
  }

  // ─── Step 0: Identifier ────────────────────────────────────────────────────

  Future<void> _verifyIdentifier() async {
    final id = _identifierCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _formError = 'Enter your phone number or email');
      return;
    }
    setState(() { _loading = true; _formError = null; });
    final exists = await AuthService.instance.identifierExists(id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!exists) {
      setState(() => _formError = 'No account found with this identifier.');
      return;
    }
    _goPage(1);
  }

  // ─── Step 1: Verify existing credential ───────────────────────────────────

  Future<void> _verifyCredential() async {
    final id = _identifierCtrl.text.trim();
    if (_forgotPin) {
      // Forgot PIN → verify with password (read-only check)
      final pw = _verifyPasswordCtrl.text;
      if (pw.isEmpty) {
        setState(() => _formError = 'Enter your current password');
        return;
      }
      setState(() { _loading = true; _formError = null; });
      final valid = await AuthService.instance.validateIdentifierPassword(id, pw);
      if (!mounted) return;
      setState(() => _loading = false);
      if (!valid) {
        setState(() => _formError = 'Incorrect password. Please try again.');
        return;
      }
      _goPage(2);
    } else {
      // Forgot Password → verify with PIN (read-only check)
      if (_verifyPin.length < 4) {
        setState(() => _formError = 'Enter your 4-digit PIN');
        return;
      }
      setState(() { _loading = true; _formError = null; });
      final valid = await AuthService.instance.validateIdentifierPin(id, _verifyPin);
      if (!mounted) return;
      setState(() => _loading = false);
      if (!valid) {
        HapticFeedback.heavyImpact();
        setState(() { _formError = 'Incorrect PIN.'; _verifyPin = ''; });
        return;
      }
      _goPage(2);
    }
  }

  // ─── Step 2: Set new value ─────────────────────────────────────────────────

  Future<void> _saveNewValue() async {
    final id = _identifierCtrl.text.trim();

    if (_forgotPin) {
      // Saving new PIN
      if (_newPin.length < 4) return;
      if (_newPin != _confirmPin) {
        setState(() => _formError = 'PINs do not match');
        return;
      }
      setState(() => _loading = true);
      try {
        final pw = _verifyPasswordCtrl.text;
        await AuthService.instance.resetPinByPassword(id, pw, _newPin);
        if (!mounted) return;
        _navigateHome();
      } catch (e) {
        if (!mounted) return;
        setState(() { _loading = false; _formError = 'Failed to update PIN.'; });
      }
    } else {
      // Saving new Password
      final np = _newPasswordCtrl.text;
      final cp = _confirmPasswordCtrl.text;
      if (np.isEmpty) {
        setState(() => _formError = 'Enter a new password');
        return;
      }
      if (np.length < 6) {
        setState(() => _formError = 'Password must be at least 6 characters');
        return;
      }
      if (np != cp) {
        setState(() => _formError = 'Passwords do not match');
        return;
      }
      setState(() => _loading = true);
      try {
        final pin = _verifyPin;
        await AuthService.instance.resetPasswordByPin(id, pin, np);
        if (!mounted) return;
        _navigateHome();
      } catch (e) {
        if (!mounted) return;
        setState(() { _loading = false; _formError = 'Failed to update password.'; });
      }
    }
  }

  void _navigateHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const NavigationWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  // ─── PIN key handlers ──────────────────────────────────────────────────────

  void _onVerifyPinKey(String digit) {
    if (_verifyPin.length >= 4) return;
    setState(() => _verifyPin += digit);
    if (_verifyPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _verifyCredential);
    }
  }

  void _onVerifyPinDelete() {
    if (_verifyPin.isNotEmpty) setState(() => _verifyPin = _verifyPin.substring(0, _verifyPin.length - 1));
  }

  void _onNewPinKey(String digit) {
    setState(() {
      if (!_confirmingPin) {
        if (_newPin.length < 4) _newPin += digit;
        if (_newPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _confirmingPin = true);
          });
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _saveNewValue();
      }
    });
  }

  void _onNewPinDelete() {
    setState(() {
      if (!_confirmingPin) {
        if (_newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalSteps = 3;
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(totalSteps),
            _buildProgressBar(totalSteps),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepIdentifier(),
                  _buildStepVerify(),
                  _buildStepSetNew(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int total) {
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
                  border: Border.all(color: kDivider)),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: kTextSecondary, size: 16),
            ),
          ),
          const Spacer(),
          Text('Step ${_step + 1} of $total',
              style: GoogleFonts.inter(color: kTextMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(total, (i) {
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

  // ─── Step 0: Enter identifier ──────────────────────────────────────────────

  Widget _buildStepIdentifier() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _modeIcon(),
          const SizedBox(height: 20),
          Text(
            _forgotPin ? 'Reset Your PIN 🔑' : 'Reset Password 🔓',
            style: GoogleFonts.inter(
                color: kTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            _forgotPin
                ? 'Enter your registered email or phone number to continue.'
                : 'Enter your registered email or phone number to continue.',
            style: GoogleFonts.inter(
                color: kTextSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          _label('Phone number or Email'),
          const SizedBox(height: 8),
          TextField(
            controller: _identifierCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            decoration: _inputDecoration(
                'e.g. 9876543210 or you@email.com', Icons.person_outline),
            onSubmitted: (_) => _verifyIdentifier(),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 16),
            _errorWidget(_formError!),
          ],
          const SizedBox(height: 32),
          _primaryButton(_loading ? null : _verifyIdentifier, 'Continue'),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  // ─── Step 1: Verify credential ─────────────────────────────────────────────

  Widget _buildStepVerify() {
    return _forgotPin ? _buildVerifyWithPassword() : _buildVerifyWithPin();
  }

  Widget _buildVerifyWithPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGreen.withValues(alpha: 0.15)),
            child: const Icon(Icons.lock_outline, color: kGreen, size: 28),
          ),
          const SizedBox(height: 20),
          Text('Enter Your Password 🔐',
              style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Enter your account password to verify identity.',
              style: GoogleFonts.inter(
                  color: kTextSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          _label('Current Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _verifyPasswordCtrl,
            obscureText: !_verifyPasswordVisible,
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            decoration: _inputDecoration('Enter password', Icons.lock_outline,
                suffix: GestureDetector(
                  onTap: () => setState(() => _verifyPasswordVisible = !_verifyPasswordVisible),
                  child: Icon(
                    _verifyPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: kTextMuted, size: 20,
                  ),
                )),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 16),
            _errorWidget(_formError!),
          ],
          const SizedBox(height: 32),
          _primaryButton(_loading ? null : _verifyCredential, 'Verify & Continue'),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _buildVerifyWithPin() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen.withValues(alpha: 0.15)),
                child: const Icon(Icons.pin, color: kGreen, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Enter Your PIN 🔢',
                  style: GoogleFonts.inter(
                      color: kTextPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Enter your current 4-digit PIN to verify identity.',
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 14, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _pinDots(_verifyPin),
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(_formError!,
              style: GoogleFonts.inter(color: kRed, fontSize: 13)),
        ],
        const Spacer(),
        if (_loading)
          const CircularProgressIndicator(color: kGreen)
        else
          _buildKeypad(_onVerifyPinKey, _onVerifyPinDelete),
        const SizedBox(height: 28),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  // ─── Step 2: Set new value ─────────────────────────────────────────────────

  Widget _buildStepSetNew() {
    return _forgotPin ? _buildSetNewPin() : _buildSetNewPassword();
  }

  Widget _buildSetNewPin() {
    final current = _confirmingPin ? _confirmPin : _newPin;
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen.withValues(alpha: 0.15)),
                child: Icon(
                  _confirmingPin ? Icons.check_circle_outline : Icons.pin,
                  color: kGreen, size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(_confirmingPin ? 'Confirm New PIN 🔁' : 'Set New PIN 🔐',
                  style: GoogleFonts.inter(
                      color: kTextPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(
                _confirmingPin
                    ? 'Re-enter to confirm'
                    : 'Choose a new 4-digit PIN',
                style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _pinDots(current),
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(_formError!,
              style: GoogleFonts.inter(color: kRed, fontSize: 13)),
        ],
        const Spacer(),
        if (_loading)
          const CircularProgressIndicator(color: kGreen)
        else
          _buildKeypad(_onNewPinKey, _onNewPinDelete),
        const SizedBox(height: 28),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  Widget _buildSetNewPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: kGreen.withValues(alpha: 0.15)),
            child: const Icon(Icons.lock_reset, color: kGreen, size: 28),
          ),
          const SizedBox(height: 20),
          Text('Set New Password 🔓',
              style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Choose a strong new password.',
              style: GoogleFonts.inter(color: kTextSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          _label('New Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordCtrl,
            obscureText: !_newPasswordVisible,
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            decoration: _inputDecoration('Min. 6 characters', Icons.lock_outline,
                suffix: GestureDetector(
                  onTap: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                  child: Icon(
                    _newPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: kTextMuted, size: 20,
                  ),
                )),
          ),
          const SizedBox(height: 16),
          _label('Confirm Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordCtrl,
            obscureText: !_confirmPasswordVisible,
            style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
            decoration: _inputDecoration('Re-enter password', Icons.lock_outline,
                suffix: GestureDetector(
                  onTap: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                  child: Icon(
                    _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: kTextMuted, size: 20,
                  ),
                )),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 16),
            _errorWidget(_formError!),
          ],
          const SizedBox(height: 32),
          _primaryButton(_loading ? null : _saveNewValue, 'Save Password'),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _modeIcon() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: kGreen.withValues(alpha: 0.15)),
      child: Icon(
        _forgotPin ? Icons.lock_reset : Icons.password_rounded,
        color: kGreen, size: 28,
      ),
    );
  }

  Widget _pinDots(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: filled ? 18 : 16,
          height: filled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? kGreen : Colors.transparent,
            border: Border.all(color: filled ? kGreen : kTextMuted, width: 1.5),
            boxShadow: filled ? greenGlow(blur: 12) : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(
      void Function(String) onKey, void Function() onDelete) {
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
                  if (k == 'del') onDelete();
                  else onKey(k);
                },
                child: Container(
                  width: 72, height: 64,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: kSurface1),
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

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
      prefixIcon: Icon(icon, color: kTextMuted, size: 20),
      suffixIcon: suffix,
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
    );
  }

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
            Expanded(
                child: Text(msg,
                    style: GoogleFonts.inter(color: kRed, fontSize: 12))),
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text(label,
                style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}
