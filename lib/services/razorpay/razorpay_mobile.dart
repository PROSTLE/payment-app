import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../constants/razorpay_config.dart';
import 'razorpay_base.dart';

class RazorpayServiceImpl implements RazorpayServiceBase {
  Razorpay? _razorpay;
  PaymentSuccessCallback? _onSuccess;
  PaymentErrorCallback? _onError;

  @override
  void init() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(
      response.paymentId ?? '',
      response.orderId ?? '',
    );
    _onSuccess = null;
    _onError = null;
  }

  void _handleError(PaymentFailureResponse response) {
    _onError?.call(response.message ?? 'Payment failed');
    _onSuccess = null;
    _onError = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onSuccess?.call('wallet_${response.walletName ?? "external"}', '');
    _onSuccess = null;
    _onError = null;
  }

  @override
  void checkout({
    required int amountInPaise,
    required String contactPhone,
    required String contactEmail,
    required String contactName,
    String description = 'PayFlow Payment',
    String? upiId,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  }) {
    if (_razorpay == null) init();
    _onSuccess = onSuccess;
    _onError = onError;

    // Use your actual Razorpay key here
    const razorpayKey = RazorpayConfig.keyId;

    final options = <String, dynamic>{
      'key': razorpayKey,
      'amount': amountInPaise,
      'name': 'PayFlow',
      'description': description,
      'prefill': {
        'contact': contactPhone,
        'email': contactEmail,
        'name': contactName,
      },
      'theme': {
        'color': '#3EE07F',
      },
    };

    if (upiId != null && upiId.isNotEmpty) {
      options['prefill']['vpa'] = upiId;
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      _onError?.call(e.toString());
      _onSuccess = null;
      _onError = null;
    }
  }

  @override
  void openCardValidation({
    required String contactPhone,
    required String contactEmail,
    required String contactName,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  }) {
    checkout(
      amountInPaise: 100,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      contactName: contactName,
      description: 'Card Validation (₹1 refundable)',
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
