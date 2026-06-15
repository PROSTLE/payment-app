import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/saved_card_model.dart';
import '../services/auth_service.dart';
import '../widgets/glassmorphic_card.dart';
import 'add_card_screen.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _expandedIndex = -1;
  List<SavedCardModel> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await AuthService.instance.getSavedCards();
    setState(() {
      _cards = cards;
      _loading = false;
    });
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
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kGreen))
                  : _cards.isEmpty
                      ? Center(
                          child: Text('No cards linked yet.', style: GoogleFonts.inter(color: kTextMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: _cards.length,
                          itemBuilder: (ctx, i) => _buildCardItem(i),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cards',
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCardScreen()),
              );
              if (result == true) _loadCards();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+ Add Card',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildCardItem(int index) {
    final card = _cards[index];
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () =>
          setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // Card visual
            Container(
              height: 175,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: card.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: cardShadow(),
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -20,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card.brand.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.black.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Default tag
                            if (card.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('DEFAULT',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          card.maskedNumber,
                          style: GoogleFonts.inter(
                            color: Colors.black.withValues(alpha: 0.8),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.cardholderName.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Expanded actions
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _CardAction(
                          icon: Icons.star_border,
                          label: 'Set Default',
                          onTap: () async {
                            await AuthService.instance.setDefaultCard(_cards[index].id);
                            _loadCards();
                          }),
                      _CardAction(
                          icon: Icons.delete_outline,
                          label: 'Remove',
                          onTap: () async {
                            await AuthService.instance.deleteCard(_cards[index].id);
                            _loadCards();
                          }),
                      _CardAction(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: () =>
                              _showCardCustomizer(context, index)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate(key: ValueKey(index)).fadeIn(delay: (index * 80).ms),
    );
  }

  void _showCardCustomizer(BuildContext context, int cardIndex) {
    final gradients = [kCardYellow, kCardMint, kCardBlue, kCardPurple];
    final names = ['Gold', 'Mint', 'Ocean', 'Violet'];
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Card Style',
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(gradients.length, (i) {
                  return GestureDetector(
                    onTap: () {
                        _cards[cardIndex].gradient.clear();
                        _cards[cardIndex].gradient.addAll(gradients[i]);
                        AuthService.instance.saveCard(_cards[cardIndex]); // just update the gradient
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: gradients[i]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(names[i],
                            style: GoogleFonts.inter(
                                color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CardAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kSurface2,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kTextSecondary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: kTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
