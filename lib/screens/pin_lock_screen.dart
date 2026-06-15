import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';
import 'forgot_pin_screen.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _pin = [];

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.add(key));
    if (_pin.length == 4) _checkPin();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin.removeLast());
  }

  void _checkPin() {
    final entered = _pin.join();
    if (AuthService.instance.verifyPin(entered)) {
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
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 450), () {
        setState(() => _pin.clear());
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
            const Spacer(flex: 2),
            // Logo / App icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: kCardMint,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: greenGlow(blur: 30),
              ),
              child: const Icon(Icons.bolt, color: Colors.black, size: 38),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              'PayFlow',
              style: GoogleFonts.inter(
                color: kTextPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to continue',
              style: GoogleFonts.inter(
                color: kTextSecondary,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const Spacer(),
            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (ctx, child) {
                return Transform.translate(
                  offset: Offset(_shakeController.isAnimating
                      ? _shakeAnim.value *
                          ((_shakeController.value * 10).round().isEven
                              ? 1
                              : -1)
                      : 0, 0),
                  child: child,
                );
              },
              child: Row(
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
                        color: filled ? kGreen : kTextMuted,
                        width: 1.5,
                      ),
                      boxShadow: filled ? greenGlow(blur: 12) : null,
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            // Keypad
            _buildKeypad(),
            const SizedBox(height: 32),
            // Forgot PIN
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPinScreen()),
                );
              },
              child: Text(
                'Forgot PIN?',
                style: GoogleFonts.inter(color: kGreen, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
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
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 72, height: 72);
              if (key == 'del') {
                return _KeyButton(
                  onTap: _onDelete,
                  child: const Icon(Icons.backspace_outlined,
                      color: kTextSecondary, size: 22),
                );
              }
              return _KeyButton(
                onTap: () => _onKey(key),
                child: Text(
                  key,
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _KeyButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kSurface1,
        ),
        child: Center(child: child),
      ),
    );
  }
}
