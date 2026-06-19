import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/contact_model.dart';
import '../widgets/glassmorphic_card.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen>
    with SingleTickerProviderStateMixin {
  final _walletNameCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  double _total = 0;

  // Participants dragged into the squad
  final List<ContactModel> _squad = [];

  // Split mode: 0 = equal, 1 = custom
  int _splitMode = 0;

  // Custom split percentages per member (squad index → pct 0..1)
  final Map<int, double> _customPct = {};

  bool _isHoveringDrop = false;
  bool _squadSentSuccessfully = false;

  @override
  void dispose() {
    _walletNameCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  void _addToSquad(ContactModel c) {
    if (_squad.any((m) => m.id == c.id)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _squad.add(c);
      _customPct[_squad.length - 1] = 1 / _squad.length;
      _rebalancePct();
    });
  }

  void _removeFromSquad(int idx) {
    HapticFeedback.lightImpact();
    setState(() {
      _squad.removeAt(idx);
      _customPct.remove(idx);
      _rebalancePct();
    });
  }

  void _rebalancePct() {
    if (_squad.isEmpty) { _customPct.clear(); return; }
    final equalShare = 1.0 / _squad.length;
    for (int i = 0; i < _squad.length; i++) {
      _customPct[i] = equalShare;
    }
  }

  double _shareForMember(int idx) {
    if (_total <= 0 || _squad.isEmpty) return 0;
    if (_splitMode == 0) return _total / _squad.length;
    return _total * (_customPct[idx] ?? (1.0 / _squad.length));
  }

  void _sendRequests() {
    if (_squad.isEmpty || _total <= 0) return;
    setState(() => _squadSentSuccessfully = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _squadSentSuccessfully = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: kBgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Squad Wallet 💰',
          style: GoogleFonts.inter(
              color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_squad.isNotEmpty && _total > 0)
            GestureDetector(
              onTap: _sendRequests,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Send Requests',
                  style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Squad name
                  _buildSquadNameField(),
                  const SizedBox(height: 16),

                  // Total amount
                  _buildTotalInput(),
                  const SizedBox(height: 20),

                  // Drop zone for squad members
                  _buildDropZone(),
                  const SizedBox(height: 16),

                  // Split mode toggle (only shown if squad has members)
                  if (_squad.isNotEmpty) ...[
                    _buildSplitModeToggle(),
                    const SizedBox(height: 16),

                    // Per-member breakdown
                    _buildMemberBreakdown(),
                    const SizedBox(height: 16),
                  ],

                  // Success banner
                  if (_squadSentSuccessfully) _buildSuccessBanner(),

                  // Available contacts
                  _buildLabel('Drag friends into squad 👆'),
                  const SizedBox(height: 10),
                  _buildContactGrid(),
                ],
              ),
            ),
          ),

          // Summary footer
          if (_squad.isNotEmpty && _total > 0) _buildSummaryFooter(),
        ],
      ),
    );
  }

  Widget _buildSquadNameField() {
    return TextField(
      controller: _walletNameCtrl,
      style: GoogleFonts.inter(color: kTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Squad name (e.g. "Goa Trip 🌴")',
        hintStyle: GoogleFonts.inter(color: kTextMuted, fontSize: 15),
        prefixIcon: const Icon(Icons.group_rounded, color: kTextMuted, size: 20),
        filled: true,
        fillColor: kSurface1,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kDivider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kGreen, width: 1.5)),
      ),
    ).animate().fadeIn();
  }

  Widget _buildTotalInput() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('₹',
              style: GoogleFonts.inter(
                  color: kTextSecondary, fontSize: 22, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _totalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => setState(() => _total = double.tryParse(v) ?? 0),
              style: GoogleFonts.inter(
                  color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle:
                    GoogleFonts.inter(color: kTextMuted, fontSize: 22),
                border: InputBorder.none,
              ),
            ),
          ),
          Text('Total bill',
              style: GoogleFonts.inter(color: kTextMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return DragTarget<ContactModel>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHoveringDrop = true);
        return !_squad.any((m) => m.id == details.data.id);
      },
      onLeave: (_) => setState(() => _isHoveringDrop = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHoveringDrop = false);
        _addToSquad(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isEmpty = _squad.isEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          constraints: BoxConstraints(minHeight: isEmpty ? 100 : 70),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHoveringDrop
                ? kGreen.withValues(alpha: 0.15)
                : kSurface1.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHoveringDrop
                  ? kGreen
                  : kDivider,
              width: _isHoveringDrop ? 1.5 : 1,
            ),
          ),
          child: isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_rounded,
                        color: _isHoveringDrop ? kGreen : kTextMuted, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Drag friends here to add to squad',
                      style: GoogleFonts.inter(
                          color: _isHoveringDrop ? kGreen : kTextMuted,
                          fontSize: 13),
                    ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _squad.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    return GestureDetector(
                      onLongPress: () => _removeFromSquad(idx),
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundColor: m.avatarColor,
                          child: Text(m.initials[0],
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        label: Text(m.name.split(' ')[0],
                            style: GoogleFonts.inter(
                                color: kTextPrimary, fontSize: 12)),
                        deleteIcon: const Icon(Icons.close,
                            size: 14, color: kTextMuted),
                        onDeleted: () => _removeFromSquad(idx),
                        backgroundColor: kSurface2,
                        side: const BorderSide(color: kDivider),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildSplitModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        children: [
          _SplitTab(
            label: '⚖️  Equal Split',
            active: _splitMode == 0,
            onTap: () => setState(() { _splitMode = 0; _rebalancePct(); }),
          ),
          _SplitTab(
            label: '🎯  Custom Split',
            active: _splitMode == 1,
            onTap: () => setState(() => _splitMode = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBreakdown() {
    return Column(
      children: _squad.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        final share = _shareForMember(idx);
        final pct = _customPct[idx] ?? (1.0 / _squad.length);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kSurface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kDivider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: m.avatarColor),
                    child: Center(
                      child: Text(m.initials,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(m.name,
                        style: GoogleFonts.inter(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                  Text(
                    '₹${share.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                        color: kGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${(pct * 100).toStringAsFixed(0)}%)',
                    style: GoogleFonts.inter(
                        color: kTextMuted, fontSize: 11),
                  ),
                ],
              ),
              if (_splitMode == 1) ...[
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: kGreen,
                    inactiveTrackColor: kDivider,
                    thumbColor: kGreen,
                    overlayColor: kGreen.withValues(alpha: 0.1),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    min: 0.05,
                    max: 0.95,
                    value: pct.clamp(0.05, 0.95),
                    onChanged: (val) {
                      setState(() {
                        _customPct[idx] = val;
                        // Normalize remaining percentages
                        final remaining = 1.0 - val;
                        final others = _squad.length - 1;
                        if (others > 0) {
                          for (int j = 0; j < _squad.length; j++) {
                            if (j != idx) {
                              _customPct[j] = remaining / others;
                            }
                          }
                        }
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ).animate(delay: (idx * 50).ms).fadeIn().slideX(begin: 0.05);
      }).toList(),
    );
  }

  Widget _buildContactGrid() {
    final available = mockContacts.where((c) => !_squad.any((m) => m.id == c.id)).toList();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: available.map((c) {
        return Draggable<ContactModel>(
          data: c,
          feedback: Material(
            color: Colors.transparent,
            child: _ContactAvatar(contact: c, size: 56, dragging: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _ContactAvatar(contact: c, size: 56),
          ),
          onDragStarted: () => HapticFeedback.selectionClick(),
          child: GestureDetector(
            onTap: () => _addToSquad(c),
            child: _ContactAvatar(contact: c, size: 56),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: kGreen, size: 20),
          const SizedBox(width: 10),
          Text(
            'Payment requests sent to squad! 🎉',
            style: GoogleFonts.inter(
                color: kGreen, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn().shake(hz: 1, offset: const Offset(0, -3));
  }

  Widget _buildSummaryFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: kGreen.withValues(alpha: 0.15),
        border: Border(top: BorderSide(color: kGreen.withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_squad.length} members',
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 12)),
              Text(
                '₹${_total.toStringAsFixed(0)} total bill',
                style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Equal share',
                  style: GoogleFonts.inter(
                      color: kTextMuted, fontSize: 11)),
              Text(
                '₹${(_total / _squad.length).toStringAsFixed(0)} each',
                style: GoogleFonts.inter(
                    color: kGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }
}

class _ContactAvatar extends StatelessWidget {
  final ContactModel contact;
  final double size;
  final bool dragging;

  const _ContactAvatar({
    required this.contact,
    required this.size,
    this.dragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 16,
      padding: const EdgeInsets.all(6),
      decoration: dragging
          ? BoxDecoration(
              color: kGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: kGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2)
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: contact.avatarColor,
              boxShadow: [
                BoxShadow(
                    color: contact.avatarColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Center(
              child: Text(contact.initials,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contact.name.split(' ')[0],
            style: GoogleFonts.inter(color: kTextSecondary, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SplitTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SplitTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? kGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.inter(
                    color: active ? Colors.black : kTextSecondary,
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
