import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';

class ContactSyncScreen extends StatefulWidget {
  const ContactSyncScreen({super.key});

  @override
  State<ContactSyncScreen> createState() => _ContactSyncScreenState();
}

class _ContactSyncScreenState extends State<ContactSyncScreen> {
  bool _syncing = false;

  Future<void> _syncContacts() async {
    setState(() => _syncing = true);
    
    // Mock contacts fetch for Web/Demo
    await Future.delayed(const Duration(seconds: 1));
    await AuthService.instance.markContactsSynced();
    
    if (!mounted) return;
    setState(() => _syncing = false);
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const NavigationWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kSurface1,
                        border: Border.all(color: kDivider),
                      ),
                    ),
                    const Icon(Icons.group_add_rounded, size: 56, color: kTextPrimary)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds),
                  ],
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
              ),
              const SizedBox(height: 40),
              
              Text(
                'Find Friends 👥',
                style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ).animate(delay: 200.ms).fadeIn().slideX(),
              const SizedBox(height: 12),
              Text(
                'Sync your contacts to easily send and request money from friends who already use PayFlow.',
                style: GoogleFonts.inter(
                  color: kTextSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ).animate(delay: 300.ms).fadeIn(),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _syncing ? null : _syncContacts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _syncing
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text(
                          'Sync Contacts',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Not right now',
                    style: GoogleFonts.inter(
                      color: kTextMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).animate(delay: 500.ms).fadeIn(),
                
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
