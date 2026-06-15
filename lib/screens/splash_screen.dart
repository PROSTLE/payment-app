import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'pin_lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            loggedIn ? const PinLockScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: kCardMint,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: greenGlow(blur: 40),
              ),
              child: const Icon(Icons.bolt, color: Colors.black, size: 48),
            )
                .animate()
                .scale(
                    begin: const Offset(0, 0),
                    duration: 700.ms,
                    curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'PayFlow',
              style: GoogleFonts.inter(
                color: kTextPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              'Smart payments, instantly.',
              style: GoogleFonts.inter(
                color: kTextMuted,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ).animate(delay: 500.ms).fadeIn(),
            const SizedBox(height: 60),
            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen,
                  ),
                )
                    .animate(
                      delay: Duration(milliseconds: 800 + i * 150),
                      onPlay: (ctrl) => ctrl.repeat(reverse: true),
                    )
                    .scaleXY(end: 1.6, duration: 400.ms)
                    .fadeOut(duration: 400.ms);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
