import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/contact_model.dart';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _upiQuickCtrl.dispose();
    super.dispose();
  }

  List<ContactModel> get _filtered {
    return mockContacts.where((c) {
      final q = _filter.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.username.toLowerCase().contains(q);
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: kSurface1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kDivider),
            ),
            child: Text(
              '+ Add',
              style: GoogleFonts.inter(
                color: kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // UPI quick-send row: user types a UPI ID and goes straight to amount entry
  Widget _buildUpiQuickSend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _upiQuickCtrl,
              style:
                  GoogleFonts.inter(color: kTextPrimary, fontSize: 14),
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
    final recent = mockContacts.take(6).toList();
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
                  recent[i].name,
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
          hintStyle:
              GoogleFonts.inter(color: kTextMuted, fontSize: 14),
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
        children: ['All', 'My accounts'].map((tab) {
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) {
        final contact = _filtered[i];
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
                      Text(contact.bank,
                          style: GoogleFonts.inter(
                              color: kTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (contact.accountSuffix != null)
                  Text(
                    '${contact.bank} ${contact.accountSuffix}',
                    style: GoogleFonts.inter(
                        color: kTextMuted, fontSize: 12),
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
        pageBuilder: (_, __, ___) =>
            CalculatorSendScreen(recipient: contact),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }
}
