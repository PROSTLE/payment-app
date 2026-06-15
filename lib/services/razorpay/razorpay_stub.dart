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
    throw UnsupportedError('Razorpay is not supported on this platform.');
  }

  @override
  void openCardValidation({
    required String contactPhone,
    required String contactEmail,
    required String contactName,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  }) {
    throw UnsupportedError('Razorpay is not supported on this platform.');
  }
}
