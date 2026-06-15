import 'package:flutter/material.dart';

// ─── Base backgrounds ────────────────────────────────────────────────────────
const Color kBgDark = Color(0xFF0C0E10);
const Color kBgCard = Color(0xFF161A1E);
const Color kBgSheet = Color(0xFF111417);
const Color kBgLight = Color(0xFFF4F4F4);

// ─── Accent & brand ──────────────────────────────────────────────────────────
const Color kGreen = Color(0xFF3EE07F);
const Color kGreenDeep = Color(0xFF25C45E);
const Color kAccentGlow = Color(0xFF4CFFA0);

// ─── Card gradients ──────────────────────────────────────────────────────────
const List<Color> kCardYellow = [Color(0xFFFFE036), Color(0xFFFFB800)];
const List<Color> kCardMint = [Color(0xFF3DFFC4), Color(0xFF00C9A7)];
const List<Color> kCardBlue = [Color(0xFF5BA4FF), Color(0xFF2264D1)];
const List<Color> kCardPurple = [Color(0xFFCB72FF), Color(0xFF8F35D1)];

// ─── Text ─────────────────────────────────────────────────────────────────────
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF9BA3AE);
const Color kTextMuted = Color(0xFF5A6373);

// ─── Surfaces ─────────────────────────────────────────────────────────────────
const Color kSurface1 = Color(0xFF1C2128);
const Color kSurface2 = Color(0xFF232A33);
const Color kDivider = Color(0xFF252D37);

// ─── Semantic ─────────────────────────────────────────────────────────────────
const Color kRed = Color(0xFFFF4D4D);
const Color kOrange = Color(0xFFFF9A3E);

// ─── Shadows & glows ─────────────────────────────────────────────────────────
List<BoxShadow> greenGlow({double blur = 40, double spread = 0}) => [
      BoxShadow(
        color: kGreen.withOpacity(0.35),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];

List<BoxShadow> cardShadow() => [
      BoxShadow(
        color: Colors.black.withOpacity(0.45),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
