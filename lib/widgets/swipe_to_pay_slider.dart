import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SwipeToPaySlider extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String label;

  const SwipeToPaySlider({
    super.key,
    required this.onConfirmed,
    this.label = 'Swipe right to confirm',
  });

  @override
  State<SwipeToPaySlider> createState() => _SwipeToPaySliderState();
}

class _SwipeToPaySliderState extends State<SwipeToPaySlider>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _confirmed = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnim;

  static const double _thumbSize = 52;
  static const double _trackHeight = 60;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_confirmed) return;
    setState(() {
      _dragPosition =
          (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_confirmed) return;
    if (_dragPosition >= maxDrag * 0.85) {
      setState(() {
        _dragPosition = maxDrag;
        _confirmed = true;
      });
      Future.delayed(const Duration(milliseconds: 200), widget.onConfirmed);
    } else {
      // Animate back
      _resetAnim = Tween<double>(begin: _dragPosition, end: 0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
      )..addListener(() {
          setState(() => _dragPosition = _resetAnim.value);
        });
      _resetController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final double maxDrag =
          constraints.maxWidth - _thumbSize - 8;

      return Container(
        height: _trackHeight,
        decoration: BoxDecoration(
          color: kSurface1,
          borderRadius: BorderRadius.circular(_trackHeight / 2),
          border: Border.all(color: kDivider),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Fill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              margin: const EdgeInsets.all(4),
              width: _dragPosition + _thumbSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kGreen.withOpacity(0.25),
                    kGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(_trackHeight / 2),
              ),
            ),
            // Label
            Center(
              child: AnimatedOpacity(
                opacity: _dragPosition > 30 ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_ios,
                        color: kTextMuted, size: 12),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        color: kTextSecondary, size: 12),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        color: kTextPrimary, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: 4 + _dragPosition,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
                onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _confirmed ? kGreenDeep : kSurface2,
                    boxShadow: [
                      BoxShadow(
                        color: kGreen.withOpacity(0.4),
                        blurRadius: _confirmed ? 20 : 8,
                        spreadRadius: _confirmed ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _confirmed ? Icons.check : Icons.chevron_right,
                    color: _confirmed ? Colors.white : kGreen,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
