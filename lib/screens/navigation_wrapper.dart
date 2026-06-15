import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import 'dashboard_screen.dart';
import 'cards_screen.dart';
import 'analytics_screen.dart';
import 'receive_qr_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => NavigationWrapperState();
}

class NavigationWrapperState extends State<NavigationWrapper>
    with TickerProviderStateMixin {
  int _currentIndex = 1;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = const [
    ReceiveQrScreen(),
    DashboardScreen(),
    CardsScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      _NavItem(icon: Icons.qr_code_scanner, label: 'Scan'),
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.credit_card_rounded, label: 'Cards'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
    ];

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: kBgCard,
        border: Border(top: BorderSide(color: kDivider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == _currentIndex;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? kGreen.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      size: 24,
                      color: selected ? kGreen : kTextMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: selected ? kGreen : kTextMuted,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
