/// Parses UPI QR code strings into structured payment data.
/// Handles paper money / shop QR codes (standard UPI intent format).
///
/// Example UPI URL:
///   upi://pay?pa=merchant@paytm&pn=Merchant+Name&am=500&tn=Payment&cu=INR
class UpiPayload {
  final String vpa;       // UPI Virtual Payment Address (e.g. merchant@paytm)
  final String name;      // Payee name
  final double? amount;   // Pre-filled amount (optional)
  final String? note;     // Payment note/description
  final String currency;  // INR (default)
  final String? merchantCode;

  const UpiPayload({
    required this.vpa,
    required this.name,
    this.amount,
    this.note,
    this.currency = 'INR',
    this.merchantCode,
  });

  bool get isValid => vpa.isNotEmpty && vpa.contains('@');

  @override
  String toString() =>
      'UpiPayload(vpa: $vpa, name: $name, amount: $amount, note: $note)';
}

class UpiParser {
  static UpiPayload? parse(String raw) {
    try {
      raw = raw.trim();

      // Standard UPI intent URL
      if (raw.startsWith('upi://pay')) {
        return _parseUpiUrl(raw);
      }

      // Some QR codes just contain a UPI ID directly (e.g. "merchant@upi")
      if (raw.contains('@') && !raw.contains('://') && !raw.contains(' ')) {
        return UpiPayload(vpa: raw, name: _formatVpaName(raw));
      }

      // PayFlow internal QR format
      if (raw.startsWith('upi://pay?pa=')) {
        return _parseUpiUrl(raw);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static UpiPayload _parseUpiUrl(String url) {
    final uri = Uri.parse(url.replaceFirst('upi://', 'https://'));
    final params = uri.queryParameters;

    final vpa = params['pa'] ?? '';
    final name = _decode(params['pn'] ?? _formatVpaName(vpa));
    final amountStr = params['am'];
    final note = _decode(params['tn'] ?? params['tr'] ?? '');
    final currency = params['cu'] ?? 'INR';
    final mc = params['mc'];

    double? amount;
    if (amountStr != null && amountStr.isNotEmpty) {
      amount = double.tryParse(amountStr);
    }

    return UpiPayload(
      vpa: vpa,
      name: name,
      amount: amount,
      note: note.isEmpty ? null : note,
      currency: currency,
      merchantCode: mc,
    );
  }

  static String _decode(String s) {
    try {
      return Uri.decodeComponent(s.replaceAll('+', ' '));
    } catch (_) {
      return s;
    }
  }

  static String _formatVpaName(String vpa) {
    final handle = vpa.split('@').first;
    return handle
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ')
        .trim();
  }
}
