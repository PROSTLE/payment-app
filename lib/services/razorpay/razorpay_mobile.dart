import 'razorpay_base.dart';

class RazorpayServiceImpl implements RazorpayServiceBase {
  @override
  void init() {}

  @override
  void dispose() {}

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
    // Mock checkout for mobile platform as razorpay_flutter is disabled
    Future.delayed(const Duration(seconds: 1), () {
      onSuccess?.call('pay_mock_123456', 'order_mock_123456');
    });
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
