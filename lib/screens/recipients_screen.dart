import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';
import '../models/contact_model.dart';
import '../services/upi_parser.dart';
import '../services/auth_service.dart';
import 'calculator_send_screen.dart';

class RecipientsScreen extends StatefulWidget {
  const RecipientsScreen({super.key});

  @override
  State<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _upiQuickCtrl = TextEditingController();
  String _filter = '';
  String _tab = 'All';

  List<ContactModel> _contacts = [];
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await AuthService.instance.getPayFlowContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _loadingContacts = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _upiQuickCtrl.dispose();
    super.dispose();
  }

  List<ContactModel> get _filtered {
    return _contacts.where((c) {
      final q = _filter.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.username.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildUpiQuickSend(),
            if (!_loadingContacts && _contacts.isNotEmpty)
              _buildRecentGrid(),
            _buildDivider(),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(child: _buildContactList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: kTextSecondary, size: 20),
          ),
          Text(
            'Send Money',
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: _openQrScanner,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: kSurface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDivider),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: kTextPrimary, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _QrScannerPage(
          onScanned: (String rawCode) {
            Navigator.pop(ctx);
            final payload = UpiParser.parse(rawCode);
            if (payload == null || !payload.isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid QR code — not a UPI payment code',
                      style: GoogleFonts.inter(color: Colors.white)),
                  backgroundColor: kRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            final parts = payload.vpa.split('@');
            final name = payload.name.isNotEmpty
                ? payload.name
                : (parts[0].isNotEmpty
                    ? parts[0][0].toUpperCase() + parts[0].substring(1)
                    : 'UPI Recipient');
            final contact = ContactModel(
              id: payload.vpa,
              name: name,
              username: payload.vpa,
              bank: parts.length > 1 ? parts[1].toUpperCase() : 'UPI',
              initials: name[0].toUpperCase(),
              avatarColor: kCardMint[0],
            );
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (_, __, ___) => CalculatorSendScreen(
                  recipient: contact,
                  upiId: payload.vpa,
                  prefilledAmount: payload.amount,
                ),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUpiQuickSend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _upiQuickCtrl,
              style: GoogleFonts.inter(color: kTextPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter UPI ID  (e.g. name@bank)',
                hintStyle:
                    GoogleFonts.inter(color: kTextMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.alternate_email,
                    color: kTextMuted, size: 18),
                filled: true,
                fillColor: kSurface1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: kGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              final upiId = _upiQuickCtrl.text.trim();
              if (upiId.isEmpty || !upiId.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Enter a valid UPI ID',
                        style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final parts = upiId.split('@');
              final name = parts[0].isNotEmpty
                  ? parts[0][0].toUpperCase() + parts[0].substring(1)
                  : 'UPI';
              final receiver = ContactModel(
                id: upiId,
                name: name,
                username: upiId,
                bank: parts[1].toUpperCase(),
                initials: name[0].toUpperCase(),
                avatarColor: kCardMint[0],
              );
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 350),
                  pageBuilder: (_, __, ___) => CalculatorSendScreen(
                    recipient: receiver,
                    upiId: upiId,
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 1), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: greenGlow(blur: 12),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildRecentGrid() {
    final recent = _contacts.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.85,
        children: List.generate(recent.length, (i) {
          return GestureDetector(
            onTap: () => _navigateToSend(recent[i]),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recent[i].avatarColor,
                    border: Border.all(color: kDivider, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      recent[i].initials,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                    .animate(delay: (i * 60).ms)
                    .scale(begin: const Offset(0.7, 0.7))
                    .fadeIn(),
                const SizedBox(height: 6),
                Text(
                  recent[i].name.split(' ')[0],
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  recent[i].username,
                  style: GoogleFonts.inter(
                    color: kTextMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Divider(color: kDivider, height: 1),
      );

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _filter = v),
        style: GoogleFonts.inter(color: kTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: kTextMuted, size: 20),
          filled: true,
          fillColor: kSurface1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: ['All', 'PayFlow'].map((tab) {
          final selected = _tab == tab;
          return GestureDetector(
            onTap: () => setState(() => _tab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kSurface1 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab,
                style: GoogleFonts.inter(
                  color: selected ? kTextPrimary : kTextMuted,
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactList() {
    if (_loadingContacts) {
      return const Center(
        child: CircularProgressIndicator(color: kGreen, strokeWidth: 2),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, color: kTextMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'No PayFlow users yet',
              style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'You can send to any UPI ID above',
              style:
                  GoogleFonts.inter(color: kTextMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final list = _filtered;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final contact = list[i];
        return GestureDetector(
          onTap: () => _navigateToSend(contact),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: contact.avatarColor,
                  ),
                  child: Center(
                    child: Text(
                      contact.initials,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name,
                          style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          )),
                      Text(contact.username,
                          style: GoogleFonts.inter(
                              color: kTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (contact.isPayFlowUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: kGreen.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'PayFlow',
                      style: GoogleFonts.inter(
                          color: kGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  void _navigateToSend(ContactModel contact) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => CalculatorSendScreen(
          recipient: contact,
          upiId: contact.payflowUpiId,
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }
}

// ─── QR Scanner Page ──────────────────────────────────────────────────────────

class _QrScannerPage extends StatefulWidget {
  final void Function(String rawCode) onScanned;
  const _QrScannerPage({required this.onScanned});

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              if (_scanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _scanned = true;
              widget.onScanned(raw);
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Scan UPI QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _ctrl.toggleTorch(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flashlight_on,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.greenAccent, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Point camera at UPI QR code',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
