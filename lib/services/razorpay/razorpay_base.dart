typedef PaymentSuccessCallback = void Function(String paymentId, String orderId);
typedef PaymentErrorCallback = void Function(String message);

abstract class RazorpayServiceBase {
  void init();
  void dispose();
  void checkout({
    required int amountInPaise,
    required String contactPhone,
    required String contactEmail,
    required String contactName,
    String description = 'PayFlow Payment',
    String? upiId,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  });

  void openCardValidation({
    required String contactPhone,
    required String contactEmail,
    required String contactName,
    PaymentSuccessCallback? onSuccess,
    PaymentErrorCallback? onError,
  });
}
