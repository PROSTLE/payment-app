import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';

import '../models/transaction_model.dart';
import '../models/contact_model.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/cash_flow_forecast_widget.dart';
import 'recipients_screen.dart';
import 'receive_qr_screen.dart';
import '../models/saved_card_model.dart';
import '../services/auth_service.dart';
import 'navigation_wrapper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  List<SavedCardModel> _userCards = [];
  bool _loadingCards = true;
  double _balance = 0;
  double _spending = 0;

  @override
  void initState() {
    super.initState();
    _loadUserCards();
    _loadBalanceData();
  }

  Future<void> _loadUserCards() async {
    final cards = await AuthService.instance.getSavedCards();
    if (mounted) {
      setState(() {
        _userCards = cards;
        _loadingCards = false;
      });
    }
  }

  void _loadBalanceData() {
    if (mounted) {
      final user = AuthService.instance.currentUser;
      final now = DateTime.now();
      double spending = 0;
      for (final tx in mockTransactions) {
        if (!tx.isCredit && tx.date.month == now.month && tx.date.year == now.year) {
          spending += tx.amount;
        }
      }
      setState(() {
        _balance = user?.balance ?? 0;
        _spending = spending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildBalanceSection()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: _buildSpendingSection()),
              SliverToBoxAdapter(
                child: CashFlowForecastWidget(transactions: mockTransactions),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 360)),
            ],
          ),
          // Bottom sliding transactions sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.38,
            maxChildSize: 0.85,
            controller: _sheetController,
            builder: (ctx, scrollCtrl) =>
                _buildTransactionsSheet(scrollCtrl),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: kCardMint),
              ),
              child: const Icon(Icons.person, color: Colors.black, size: 22),
            ),
            Stack(
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: kTextSecondary, size: 26),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBalanceSection() {
    final wholeRupees = _balance.floor();
    final paiseStr = ((_balance - wholeRupees) * 100).round().toString().padLeft(2, '0');
    final formattedWhole = wholeRupees.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total balance',
            style: GoogleFonts.inter(
              color: kTextSecondary,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ $formattedWhole',
                style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '.$paiseStr',
                  style: GoogleFonts.inter(
                    color: kTextSecondary,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCardStrip(),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCardStrip() {
    if (_loadingCards) {
      return SizedBox(
        height: 52,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 16,
            height: 16,
            child: const CircularProgressIndicator(strokeWidth: 2, color: kGreen),
          ),
        ),
      );
    }

    if (_userCards.isEmpty) {
      return GestureDetector(
        onTap: () {
          context.findAncestorStateOfType<NavigationWrapperState>()?.setIndex(2);
        },
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: kSurface2.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withValues(alpha: 0.4)),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, color: kGreen, size: 20),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        context.findAncestorStateOfType<NavigationWrapperState>()?.setIndex(2);
      },
      child: SizedBox(
        height: 52,
        child: Stack(
          children: List.generate(_userCards.length, (i) {
            // Render from back (first added) to front (last added)
            final cardIndex = _userCards.length - 1 - i;
            final card = _userCards[cardIndex];
            return Positioned(
              right: i * 28.0,
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: card.gradient),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: cardShadow(),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          _ActionButton(
            label: 'Send',
            icon: Icons.send_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const RecipientsScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            label: 'Request',
            icon: Icons.south_west_rounded,
            outlined: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ReceiveQrScreen()),
            ),
          ),
          const Spacer(),
          // Spending contacts
          _buildSpendingAvatars(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSpendingAvatars() {
    final contacts = mockContacts.take(4).toList();
    return SizedBox(
      width: 90,
      height: 36,
      child: Stack(
        children: List.generate(contacts.length, (i) {
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: contacts[i].avatarColor,
                border: Border.all(color: kBgDark, width: 2),
              ),
              child: Center(
                child: Text(
                  contacts[i].initials[0],
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSpendingSection() {
    final spendingStr = _spending >= 1000
        ? '₹${(_spending / 1000).toStringAsFixed(1)}K'
        : '₹${_spending.toStringAsFixed(0)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending',
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  spendingStr,
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [65, 90, 45, 75, 55, 100, 70]
                  .map((h) => Container(
                        width: 6,
                        height: h * 0.5,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: h == 100 ? kGreen : kSurface2,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTransactionsSheet(ScrollController scrollCtrl) {
    // Group transactions by date
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in mockTransactions) {
      final label = _dateLabel(tx.date);
      grouped.putIfAbsent(label, () => []).add(tx);
    }

    return Container(
      decoration: BoxDecoration(
        color: kBgSheet,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(children: [
                  const Icon(Icons.search, color: kTextSecondary, size: 22),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kSurface1,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Filter',
                        style: GoogleFonts.inter(
                            color: kTextMuted, fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // List with date groups
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: grouped.entries.length,
              itemBuilder: (ctx, gi) {
                final entry = grouped.entries.elementAt(gi);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      child: Text(
                        entry.key,
                        style: GoogleFonts.inter(
                            color: kTextMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5),
                      ),
                    ),
                    ...entry.value.map((tx) => _TransactionTile(tx: tx)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'TODAY';
    if (d == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]}';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : kGreen,
          borderRadius: BorderRadius.circular(24),
          border: outlined ? Border.all(color: kDivider, width: 1.5) : null,
          boxShadow: outlined ? null : greenGlow(blur: 16),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: outlined ? kTextSecondary : Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: outlined ? kTextPrimary : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kSurface1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tx.icon, color: tx.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.vendor,
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  tx.category,
                  style: GoogleFonts.inter(
                    color: kTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'} ₹${tx.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: tx.isCredit ? kGreen : kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
