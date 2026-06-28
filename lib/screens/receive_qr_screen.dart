import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';
import '../models/contact_model.dart';
import '../services/upi_parser.dart';
import '../services/auth_service.dart';
import 'calculator_send_screen.dart';
import '../widgets/glassmorphic_card.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ReceiveQrScreen extends StatefulWidget {
  const ReceiveQrScreen({super.key});

  @override
  State<ReceiveQrScreen> createState() => _ReceiveQrScreenState();
}

class _ReceiveQrScreenState extends State<ReceiveQrScreen>
    with SingleTickerProviderStateMixin {
  bool _scanMode = false;
  bool _copied = false;

  String get _upiId {
    final user = AuthService.instance.currentUser;
    return user?.upiId ?? 'payflow@upi';
  }

  String get _userName {
    final user = AuthService.instance.currentUser;
    return user?.fullName ?? 'PayFlow User';
  }

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildModeToggle(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _scanMode
                    ? _buildScanView()
                    : _buildMyQrView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        'Receive Money',
        style: GoogleFonts.inter(
          color: kTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kSurface1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _ModeTab(
              label: 'My QR Code',
              active: !_scanMode,
              onTap: () => setState(() => _scanMode = false),
            ),
            _ModeTab(
              label: 'Scan QR',
              active: _scanMode,
              onTap: () => setState(() => _scanMode = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyQrView() {
    return SingleChildScrollView(
      key: const ValueKey('myqr'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GlassmorphicCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: greenGlow(blur: 20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: 'upi://pay?pa=$_upiId&pn=${Uri.encodeComponent(_userName)}',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan to pay me',
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  style: GoogleFonts.inter(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 20),
          // UPI ID copy tile
          GlassmorphicCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPI ID',
                          style: GoogleFonts.inter(
                              color: kTextMuted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        _upiId,
                        style: GoogleFonts.inter(
                          color: kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _upiId));
                    setState(() => _copied = true);
                    Future.delayed(
                        const Duration(seconds: 2),
                        () => setState(() => _copied = false));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _copied
                          ? kGreen.withOpacity(0.2)
                          : kSurface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _copied
                              ? Icons.check
                              : Icons.copy_outlined,
                          size: 16,
                          color: _copied ? kGreen : kTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: GoogleFonts.inter(
                            color: _copied ? kGreen : kTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 20),
          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined,
                  size: 18, color: Colors.black),
              label: Text(
                'Share QR Code',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildScanView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt QR box size to available height — leave room for text + buttons
        final availH = constraints.maxHeight;
        final qrSize = (availH - 200).clamp(160.0, 280.0);
        final vGap = (availH < 500) ? 16.0 : 32.0;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: vGap),
                Text(
                  'Scan to Pay',
                  style: GoogleFonts.inter(
                      color: kTextPrimary,
                      fontSize: availH < 500 ? 20 : 24,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Point your camera at any UPI QR code',
                  style: GoogleFonts.inter(color: kTextSecondary, fontSize: 13),
                ),
                SizedBox(height: vGap),
                Container(
                  width: qrSize,
                  height: qrSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border:
                        Border.all(color: kGreen.withValues(alpha: 0.5), width: 2),
                    boxShadow: greenGlow(blur: 20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: _buildScannerWidget(),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                SizedBox(height: vGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _ScannerAction(
                        icon: Icons.photo_library_outlined, label: 'Gallery'),
                    const SizedBox(width: 32),
                    GestureDetector(
                      onTap: () => _cameraController.toggleTorch(),
                      child: const _ScannerAction(
                          icon: Icons.flash_on_rounded, label: 'Flash'),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(),
                SizedBox(height: vGap),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildScannerWidget() {
    return MobileScanner(
      controller: _cameraController,
      errorBuilder: (context, error, child) {
        // Clean dark fallback — NO yellow hazard stripes
        return GestureDetector(
          onTap: () {
            _handleScan('upi://pay?pa=mock@upi&pn=Mock%20Merchant&am=100');
          },
          child: Container(
            color: kSurface1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kSurface2,
                      border: Border.all(color: kDivider),
                    ),
                    child: const Icon(Icons.videocam_off_outlined, size: 32, color: kTextMuted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera unavailable',
                    style: GoogleFonts.inter(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to simulate scan',
                    style: GoogleFonts.inter(
                        color: kGreen, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            _handleScan(barcode.rawValue!);
            break;
          }
        }
      },
    );
  }

  void _handleScan(String rawData) {
    final payload = UpiParser.parse(rawData);
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code. Please scan a valid UPI QR.'), backgroundColor: kRed),
      );
      return;
    }
    
    final receiver = ContactModel(
      id: payload.vpa,
      name: payload.name.isEmpty ? 'Unknown Merchant' : payload.name,
      username: payload.vpa,
      bank: 'UPI',
      initials: payload.name.isNotEmpty ? payload.name[0].toUpperCase() : 'U',
      avatarColor: kCardBlue[0],
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalculatorSendScreen(
          recipient: receiver,
          upiId: payload.vpa,
          prefilledAmount: payload.amount,
        ),
      ),
    );
  }
}


class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab(
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
            color: active ? kSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: active ? kTextPrimary : kTextMuted,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ScannerAction({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: kSurface1,
            shape: BoxShape.circle,
            border: Border.all(color: kDivider),
          ),
          child: Icon(this.icon, color: kTextPrimary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          this.label,
          style: GoogleFonts.inter(
              color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
