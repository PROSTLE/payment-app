import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/contact_model.dart';
import 'navigation_wrapper.dart';

class SuccessScreen extends StatelessWidget {
  final double amount;
  final ContactModel recipient;
  final String? txId;

  const SuccessScreen({
    super.key,
    required this.amount,
    required this.recipient,
    this.txId,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = txId != null
        ? txId!.substring(txId!.length > 8 ? txId!.length - 8 : 0)
        : '--------';
    final now = DateTime.now();
    final timeStr =
        '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C0E10), Color(0xFF0F1F14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // ── Animated checkmark ──────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGreen.withOpacity(0.15),
                  border: Border.all(color: kGreen, width: 2),
                  boxShadow: greenGlow(blur: 40),
                ),
                child: const Icon(Icons.check_rounded,
                    color: kGreen, size: 52),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0, 0),
                      duration: 500.ms,
                      curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 20),
              Text(
                'Payment Successful',
                style: GoogleFonts.inter(
                  color: kGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 12),

              // ── Amount ──────────────────────────────────────────────────
              Text(
                '₹ ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 6),
              Text(
                'Sent to ${recipient.name}',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ).animate(delay: 400.ms).fadeIn(),

              const SizedBox(height: 36),

              // ── Receipt card ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161A1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF252D37)),
                  ),
                  child: Column(
                    children: [
                      _ReceiptRow(
                        label: 'To',
                        value: recipient.username,
                      ),
                      Divider(
                          color: const Color(0xFF252D37), height: 1),
                      _ReceiptRow(
                        label: 'Date & Time',
                        value: timeStr,
                      ),
                      Divider(
                          color: const Color(0xFF252D37), height: 1),
                      _ReceiptRow(
                        label: 'Transaction ID',
                        value: shortId,
                        trailing: GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: txId ?? shortId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied!',
                                    style:
                                        GoogleFonts.inter(color: Colors.white)),
                                backgroundColor: kGreen,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_outlined,
                              color: Color(0xFF5A6373), size: 16),
                        ),
                      ),
                      Divider(
                          color: const Color(0xFF252D37), height: 1),
                      _ReceiptRow(
                        label: 'Status',
                        value: 'Completed',
                        valueColor: kGreen,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const Spacer(),

              // ── Bottom actions ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF252D37), width: 1.5),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Share',
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .pushAndRemoveUntil(
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            pageBuilder: (_, __, ___) =>
                                const NavigationWrapper(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                          ),
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 700.ms).fadeIn(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m];
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                color: const Color(0xFF5A6373), fontSize: 13),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: valueColor ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
