# PayFlow — High-End Flutter Payment App

A stunning, high-fidelity payment app built with Flutter, inspired by premium payment UI/UX design references. This app features smooth animations, a dark glassmorphic theme, and a complete payment flow.

---

## 🚀 Features

### Core Payment Flow
- **PIN Lock Screen** — 4-digit secure entry with shake animation on wrong PIN
- **Dashboard** — Total balance display, stacked card preview, send/request actions, spending widget, and a draggable transactions sheet
- **Card Management** — Stacked digital cards with freeze toggle, card details, and live card color customizer
- **Recipients Screen** — Grid of recent contacts + searchable contact list
- **Calculator Send Screen** — Custom keypad with arithmetic operators, recipient avatar badge, and swipe-to-confirm slider
- **Payment Success Screen** — Vibrant full-screen green confirmation with animated checkmark

### Bonus Features ⭐
- **QR Code & UPI Screen** — Live QR code generation, UPI ID copy to clipboard, animated scanner mockup with scan line
- **Split Bill Calculator** — Select multiple contacts, enter total amount, auto-calculates per-person split
- **Analytics Dashboard** — Animated bar chart, spending by category progress bars, summary cards, and split bill entry

---

## 📱 App Flow

```
PIN Lock (1234) → Dashboard → [Send Button] → Recipients → Calculator → Swipe → ✅ Success
                           → [Cards Tab] → Card Stack → Freeze/Customize
                           → [Scan Tab] → QR Code / UPI / Scanner
                           → [Analytics Tab] → Charts / Split Bill
```

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK ≥ 3.10
- Dart SDK ≥ 3.0
- Android Studio / VS Code with Flutter plugin
- Android device/emulator or iOS simulator

### Run the App

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

### Demo PIN
Use PIN **`1234`** to unlock the app.

---

## 🏗️ Project Structure

```
lib/
├── main.dart                  # App entry, dark theme config
├── constants/
│   └── colors.dart            # All colors, gradients, shadows
├── models/
│   ├── card_model.dart        # Digital card data + mock cards
│   ├── contact_model.dart     # Recipient contacts + mock data
│   └── transaction_model.dart # Transaction history + mock data
├── screens/
│   ├── pin_lock_screen.dart
│   ├── navigation_wrapper.dart
│   ├── dashboard_screen.dart
│   ├── cards_screen.dart
│   ├── recipients_screen.dart
│   ├── calculator_send_screen.dart
│   ├── success_screen.dart
│   ├── receive_qr_screen.dart
│   ├── split_bill_screen.dart
│   └── analytics_screen.dart
└── widgets/
    ├── glassmorphic_card.dart  # Reusable blur/glass card
    └── swipe_to_pay_slider.dart # Drag-to-confirm payment
```

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Background | `#0C0E10` |
| Card Surface | `#161A1E` |
| Accent Green | `#3EE07F` |
| Card Yellow | `#FFE036 → #FFB800` |
| Card Mint | `#3DFFC4 → #00C9A7` |
| Card Blue | `#5BA4FF → #2264D1` |

**Font:** Inter (via `google_fonts`)  
**Animations:** `flutter_animate` package  
**QR Code:** `qr_flutter` package

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `google_fonts` | Premium typography (Inter) |
| `flutter_animate` | Declarative micro-animations |
| `qr_flutter` | QR code generation |
| `smooth_page_indicator` | Page dots indicator |
| `intl` | Number/date formatting |

---

## ✅ No Backend Required

All data is mock/hardcoded. No real payment integration. No actual money is transferred.
