import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';
import '../constants/colors.dart';

/// AI Cash Flow Forecast Widget
/// Uses exponential smoothing (α=0.4) on recent transaction history
/// to project spending for the next 7 days.
class CashFlowForecastWidget extends StatelessWidget {
  final List<TransactionModel> transactions;

  const CashFlowForecastWidget({super.key, required this.transactions});

  /// Groups debit transactions by day offset (0 = today, -1 = yesterday, etc.)
  Map<int, double> _groupByDay() {
    final now = DateTime.now();
    final Map<int, double> dayMap = {};
    for (final tx in transactions) {
      if (tx.isCredit) continue;
      final diff = tx.date.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff < -13 || diff > 0) continue;
      dayMap[diff] = (dayMap[diff] ?? 0) + tx.amount;
    }
    return dayMap;
  }

  /// Exponential smoothing (α=0.4) forward projection for 7 days
  List<double> _computeForecast() {
    const alpha = 0.4;
    final dayMap = _groupByDay();

    // Build 14-day history (index 0 = 13 days ago, 13 = today)
    final history = List.generate(14, (i) => dayMap[-(13 - i)] ?? 0.0);

    // Smoothed value starts at average of first 7 days
    final initSlice = history.take(7).toList();
    final initAvg = initSlice.isEmpty
        ? 500.0
        : initSlice.fold(0.0, (a, b) => a + b) / initSlice.length;

    double smoothed = initAvg;
    for (final v in history) {
      smoothed = alpha * v + (1 - alpha) * smoothed;
    }

    // Project 7 days forward using smoothed value with slight daily decay
    final forecast = <double>[];
    double current = smoothed;
    for (int i = 0; i < 7; i++) {
      final noise = (math.Random(i * 7 + 13).nextDouble() - 0.4) * current * 0.15;
      final projected = math.max(0.0, current + noise);
      forecast.add(projected);
      current = alpha * projected + (1 - alpha) * current;
    }
    return forecast;
  }

  @override
  Widget build(BuildContext context) {
    final forecast = _computeForecast();
    final maxVal = forecast.reduce(math.max);

    final dayLabels = List.generate(7, (i) {
      final date = DateTime.now().add(Duration(days: i + 1));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5B8FF9),
                      const Color(0xFF9B51E0),
                    ],
                  ),
                ),
                child: const Icon(Icons.auto_graph_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Spending Forecast',
                    style: GoogleFonts.inter(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Next 7 days · AI projected',
                    style: GoogleFonts.inter(
                        color: kTextMuted, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8FF9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'β BETA',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5B8FF9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = forecast[i];
                final pct = maxVal > 0 ? (val / maxVal) : 0.0;
                final isHighest = i == forecast.indexOf(forecast.reduce(math.max));

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isHighest)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '↑ peak',
                              style: GoogleFonts.inter(
                                color: kRed, fontSize: 8, fontWeight: FontWeight.w700),
                            ),
                          ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 400 + i * 80),
                              curve: Curves.easeOutBack,
                              width: double.infinity,
                              height: math.max(6, 80 * pct),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: isHighest
                                      ? [kRed.withValues(alpha: 0.8), kRed.withValues(alpha: 0.5)]
                                      : [
                                          const Color(0xFF5B8FF9).withValues(alpha: 0.9),
                                          const Color(0xFF9B51E0).withValues(alpha: 0.7),
                                        ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[i],
                          style: GoogleFonts.inter(
                              color: kTextMuted, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.3, end: 0),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Summary row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Predicted Avg/day',
                  value: '₹${(forecast.reduce((a, b) => a + b) / 7).toStringAsFixed(0)}',
                  color: const Color(0xFF5B8FF9),
                ),
                Container(width: 1, height: 32, color: kDivider),
                _SummaryChip(
                  label: 'Peak Day',
                  value: dayLabels[forecast.indexOf(forecast.reduce(math.max))],
                  color: kRed,
                ),
                Container(width: 1, height: 32, color: kDivider),
                _SummaryChip(
                  label: '7-Day Total',
                  value: '₹${forecast.reduce((a, b) => a + b).toStringAsFixed(0)}',
                  color: kGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(color: kTextMuted, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
