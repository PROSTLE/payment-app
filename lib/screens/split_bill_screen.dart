import 'package:flutter/material.dart';
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

class _SplitBillScreenState extends State<SplitBillScreen> {
  final Set<String> _selected = {};
  double _total = 0;
  final TextEditingController _totalCtrl = TextEditingController();

  List<ContactModel> get _participants =>
      mockContacts.where((c) => _selected.contains(c.id)).toList();

  double get _perPerson =>
      _participants.isEmpty ? 0 : _total / _participants.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: kBgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Split Bill',
          style: GoogleFonts.inter(
            color: kTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalInput(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Select participants',
              style: GoogleFonts.inter(
                  color: kTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              itemCount: mockContacts.length,
              itemBuilder: (ctx, i) {
                final contact = mockContacts[i];
                final selected = _selected.contains(contact.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(contact.id);
                      } else {
                        _selected.add(contact.id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? kGreen.withOpacity(0.12)
                          : kSurface1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? kGreen : kDivider,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: contact.avatarColor,
                          ),
                          child: Center(
                            child: Text(
                              contact.initials,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contact.name,
                            style: GoogleFonts.inter(
                              color: kTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selected && _total > 0)
                          Text(
                            '\$${_perPerson.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              color: kGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? kGreen : Colors.transparent,
                            border: Border.all(
                              color:
                                  selected ? kGreen : kTextMuted,
                              width: 1.5,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.black)
                              : null,
                        ),
                      ],
                    ),
                  ).animate(delay: (i * 30).ms).fadeIn().slideX(begin: 0.05),
                );
              },
            ),
          ),
          if (_participants.isNotEmpty && _total > 0) _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildTotalInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              '\$',
              style: GoogleFonts.inter(
                color: kTextSecondary,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _totalCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                onChanged: (v) =>
                    setState(() => _total = double.tryParse(v) ?? 0),
                style: GoogleFonts.inter(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.inter(
                      color: kTextMuted, fontSize: 22),
                  border: InputBorder.none,
                ),
              ),
            ),
            Text(
              'Total bill',
              style: GoogleFonts.inter(
                  color: kTextMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_participants.length} people · \$$_total',
            style: GoogleFonts.inter(
                color: kTextSecondary, fontSize: 13),
          ),
          Text(
            '\$${_perPerson.toStringAsFixed(2)} each',
            style: GoogleFonts.inter(
              color: kGreen,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
