// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist, undefined_function, undefined_method, deprecated_member_use, invalid_assignment
import 'dart:js' as js;
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
    final options = {
      'key': 'rzp_test_SDdi0bRwia1AA4',
      'amount': amountInPaise,
      'name': 'PayFlow',
      'description': description,
      'prefill': {
        'contact': contactPhone,
        'email': contactEmail,
        'name': contactName,
      },
      'theme': {
        'color': '#00E676',
      }
    };

    try {
      final jsOptions = js.JsObject.jsify({
        ...options,
        'handler': js.allowInterop((response) {
          final paymentId = response['razorpay_payment_id'] ?? '';
          final orderId = response['razorpay_order_id'] ?? '';
          onSuccess?.call(paymentId, orderId);
        }),
        'modal': {
          'ondismiss': js.allowInterop(() {
            onError?.call('Payment cancelled by user');
          }),
        }
      });
      final rzp = js.JsObject(js.context['Razorpay'], [jsOptions]);
      rzp.callMethod('open');
    } catch (e) {
      onError?.call('Failed to load Razorpay payment gateway on Web.');
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
