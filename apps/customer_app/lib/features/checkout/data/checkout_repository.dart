import 'dart:math';

import '../../../core/network/api_client.dart';

/// A one-off variant + quantity to check out directly, bypassing the
/// persisted cart entirely — the "Buy Now" flow. Value-equality matters
/// here: it's used as a Riverpod family argument (`buyNowPreviewProvider`),
/// so two selections with the same values must compare equal or the
/// preview would silently refetch on every rebuild instead of caching.
class BuyNowSelection {
  const BuyNowSelection({required this.variantId, required this.quantity});
  final String variantId;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      other is BuyNowSelection && other.variantId == variantId && other.quantity == quantity;

  @override
  int get hashCode => Object.hash(variantId, quantity);
}

class OrderCreateResult {
  const OrderCreateResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.totalMinor,
    required this.payableMinor,
    required this.requiresPayment,
  });

  factory OrderCreateResult.fromJson(Map<String, dynamic> json) => OrderCreateResult(
        orderId: json['orderId'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        totalMinor: json['totalMinor'] as int,
        payableMinor: json['payableMinor'] as int,
        requiresPayment: json['requiresPayment'] as bool,
      );

  final String orderId;
  final String orderNumber;
  final String status;
  final int totalMinor;
  final int payableMinor;
  final bool requiresPayment;
}

class PaymentIntentResult {
  const PaymentIntentResult({
    required this.paymentId,
    required this.provider,
    required this.amountMinor,
    required this.currency,
    this.intentId,
    this.clientSecret,
    this.keyId,
  });

  factory PaymentIntentResult.fromJson(Map<String, dynamic> json) => PaymentIntentResult(
        paymentId: json['paymentId'] as String,
        provider: json['provider'] as String,
        amountMinor: json['amountMinor'] as int,
        currency: json['currency'] as String,
        intentId: json['intentId'] as String?,
        clientSecret: json['clientSecret'] as String?,
        keyId: json['keyId'] as String?,
      );

  final String paymentId;
  final String provider;
  final int amountMinor;
  final String currency;
  final String? intentId;
  final String? clientSecret;
  final String? keyId;
}

class CheckoutRepository {
  CheckoutRepository(this._client);

  final ApiClient _client;

  /// Random-enough client-generated key — collisions are inconsequential
  /// here since it only needs to be unique per checkout attempt on this
  /// device, not globally.
  static String _idempotencyKey() {
    final Random random = Random.secure();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String randomPart = List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
    return '$timestamp-$randomPart';
  }

  Future<OrderCreateResult> createOrder({
    required String addressId,
    required String paymentMethod,
    int useWalletMinor = 0,
    String? customerNote,
    BuyNowSelection? buyNow,
  }) async {
    final data = await _client.post(
      '/orders',
      data: {
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        'useWalletMinor': useWalletMinor,
        if (customerNote != null && customerNote.isNotEmpty) 'customerNote': customerNote,
        if (buyNow != null) 'buyNow': {'variantId': buyNow.variantId, 'quantity': buyNow.quantity},
      },
      // Guards against a duplicate order if the user double-taps "place
      // order" or the request is retried after a flaky connection.
      headers: {'Idempotency-Key': _idempotencyKey()},
    );
    return OrderCreateResult.fromJson(data as Map<String, dynamic>);
  }

  Future<PaymentIntentResult> createPaymentIntent(String orderId) async {
    final data = await _client.post('/payments/intent', data: {'orderId': orderId});
    return PaymentIntentResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> confirmRazorpayPayment({
    required String rpOrderId,
    required String rpPaymentId,
    required String signature,
  }) =>
      _client.post('/payments/razorpay/confirm', data: {
        'rpOrderId': rpOrderId,
        'rpPaymentId': rpPaymentId,
        'signature': signature,
      },);
}
