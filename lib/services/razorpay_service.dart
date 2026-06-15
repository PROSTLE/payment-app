import 'razorpay/razorpay_base.dart';
import 'razorpay/razorpay_stub.dart'
    if (dart.library.js_util) 'razorpay/razorpay_web.dart'
    if (dart.library.io) 'razorpay/razorpay_mobile.dart';

class RazorpayService {
  static RazorpayService? _instance;
  static RazorpayService get instance => _instance ??= RazorpayService._();
  RazorpayService._();

  final RazorpayServiceBase _delegate = RazorpayServiceImpl();

  void init() => _delegate.init();
  void dispose() => _delegate.dispose();

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
    _delegate.checkout(
      amountInPaise: amountInPaise,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      contactName: contactName,
      description: description,
      upiId: upiId,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  void openCardValidation({
    required String contactPhone,
    required String contactEmail,
    required String contactName,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  }) {
    _delegate.openCardValidation(
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      contactName: contactName,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
