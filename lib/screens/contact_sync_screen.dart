import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../constants/colors.dart';
import '../models/contact_model.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';

class ContactSyncScreen extends StatefulWidget {
  const ContactSyncScreen({super.key});

  @override
  State<ContactSyncScreen> createState() => _ContactSyncScreenState();
}

class _ContactSyncScreenState extends State<ContactSyncScreen> {
  bool _syncing = false;
  int _syncedCount = 0;
  String? _errorMsg;

  Future<void> _syncContacts() async {
    setState(() { _syncing = true; _errorMsg = null; });

    try {
      // Request contact permission
      final status = await Permission.contacts.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        // On web or if denied, fall back to mock contacts
        await Future.delayed(const Duration(milliseconds: 800));
        await AuthService.instance.markContactsSynced();
        if (!mounted) return;
        setState(() { _syncing = false; _syncedCount = 0; });
        _finishOnboarding();
        return;
      }

      // Fetch device contacts
      final deviceContacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Convert to ContactModel — only include contacts with phone numbers
      final colors = [
        const Color(0xFF5B8FF9), const Color(0xFFFF6B6B),
        const Color(0xFF52C41A), const Color(0xFFFFAA00),
        const Color(0xFFCB72FF), const Color(0xFF3DFFC4),
        const Color(0xFFF97316), const Color(0xFF8B5CF6),
      ];

      final contactModels = <ContactModel>[];
      int colorIdx = 0;

      for (final c in deviceContacts) {
        if (c.phones.isEmpty) continue;
        final phone = c.phones.first.number.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
        final name = c.displayName.trim();
        if (name.isEmpty) continue;

        final parts = name.split(' ');
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : name[0].toUpperCase();

        contactModels.add(ContactModel(
          id: 'device_${phone.hashCode}',
          name: name,
          username: '@${name.toLowerCase().replaceAll(' ', '')}',
          bank: 'PayFlow',
          avatarColor: colors[colorIdx % colors.length],
          initials: initials,
        ));
        colorIdx++;
      }

      AuthService.instance.setSyncedContacts(contactModels);
      await AuthService.instance.markContactsSynced();

      if (!mounted) return;
      setState(() {
        _syncing = false;
        _syncedCount = contactModels.length;
      });

      // Show brief success then navigate
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      _finishOnboarding();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _errorMsg = 'Could not access contacts. Continuing without sync.';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _finishOnboarding();
    }
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

              if (_syncedCount > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: kGreen, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '$_syncedCount contacts synced!',
                        style: GoogleFonts.inter(
                          color: kGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ],

              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: kRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: GoogleFonts.inter(color: kRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(
                              'Syncing contacts...',
                              style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
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
