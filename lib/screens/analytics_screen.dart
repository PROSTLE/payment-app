import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';

import '../screens/split_bill_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;


  // Spending data per bar
  final List<double> _monthData = [
    1200, 850, 2100, 1600, 900, 1800, 1300, 2400, 1100, 700, 1950, 1385
  ];
  final List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildChart()),
            SliverToBoxAdapter(child: _buildSummaryCards()),
            SliverToBoxAdapter(child: _buildCategoryBreakdown()),
            SliverToBoxAdapter(child: _buildSplitBillEntry()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        'Analytics',
        style: GoogleFonts.inter(
          color: kTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    ).animate().fadeIn();
  }



  Widget _buildChart() {
    final maxVal = _monthData.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: kSurface1,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_monthData.length, (i) {
                  final fraction = _monthData[i] / maxVal;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _barController,
                        builder: (ctx, _) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 120 *
                                    fraction *
                                    _barController.value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: i == 11
                                        ? kCardMint
                                        : [kSurface2, kSurface2],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                  _monthLabels.length,
                  (i) => Expanded(
                        child: Center(
                          child: Text(
                            _monthLabels[i],
                            style: GoogleFonts.inter(
                              color: i == 11
                                  ? kTextSecondary
                                  : kTextMuted,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      )),
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn();
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Total Spent',
            value: '₹1,385',
            icon: Icons.trending_up,
            color: kGreen,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'Avg / Day',
            value: '₹44.7',
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF5B8FF9),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _buildCategoryBreakdown() {
    final categories = [
      _Cat('Subscriptions', 0.35, kCardBlue[0]),
      _Cat('Food & Dining', 0.25, kCardMint[0]),
      _Cat('Entertainment', 0.20, kCardYellow[0]),
      _Cat('Transport', 0.12, kCardPurple[0]),
      _Cat('Other', 0.08, kTextMuted),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Category',
            style: GoogleFonts.inter(
              color: kTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.name,
                          style: GoogleFonts.inter(
                              color: kTextPrimary, fontSize: 13)),
                      Text(
                          '${(cat.fraction * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                              color: kTextSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _barController,
                      builder: (ctx, _) {
                        return LinearProgressIndicator(
                          value: cat.fraction * _barController.value,
                          backgroundColor: kSurface1,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(cat.color),
                          minHeight: 6,
                        );
                      },
                    ),
                  ),
                ],
              ).animate(delay: (i * 60 + 300).ms).fadeIn(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSplitBillEntry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SplitBillScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2540), Color(0xFF1C2A4A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kCardBlue[0].withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: kCardBlue),
                ),
                child: const Icon(Icons.people_alt_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Split Bill',
                        style: GoogleFonts.inter(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('Divide expenses with friends',
                        style: GoogleFonts.inter(
                            color: kTextMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: kTextMuted, size: 16),
            ],
          ),
        ),
      ).animate(delay: 500.ms).fadeIn(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                color: kTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Cat {
  final String name;
  final double fraction;
  final Color color;
  _Cat(this.name, this.fraction, this.color);
}
