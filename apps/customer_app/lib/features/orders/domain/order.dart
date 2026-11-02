class OrderItemPreview {
  const OrderItemPreview({required this.title, required this.quantity, this.image});

  factory OrderItemPreview.fromJson(Map<String, dynamic> json) => OrderItemPreview(
        title: json['title'] as String,
        quantity: json['quantity'] as int,
        image: json['image'] as String?,
      );

  final String title;
  final int quantity;
  final String? image;
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalMinor,
    required this.paymentMethod,
    required this.placedAt,
    this.items = const [],
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        totalMinor: json['totalMinor'] as int,
        paymentMethod: json['paymentMethod'] as String,
        placedAt: DateTime.tryParse(json['placedAt'] as String? ?? '') ?? DateTime.now(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItemPreview.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String orderNumber;
  final String status;
  final int totalMinor;
  final String paymentMethod;
  final DateTime placedAt;
  final List<OrderItemPreview> items;
}

class OrderItemDetail {
  const OrderItemDetail({
    required this.id,
    required this.title,
    required this.sku,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    this.imageUrl,
    this.variantLabel,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) => OrderItemDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        sku: json['sku'] as String,
        quantity: json['quantity'] as int,
        unitPriceMinor: json['unit_price_minor'] as int,
        lineTotalMinor: json['line_total_minor'] as int,
        imageUrl: json['image_url'] as String?,
        variantLabel: json['variant_label'] as String?,
      );

  final String id;
  final String title;
  final String sku;
  final int quantity;
  final int unitPriceMinor;
  final int lineTotalMinor;
  final String? imageUrl;
  final String? variantLabel;
}

class OrderShipment {
  const OrderShipment({
    required this.id,
    required this.status,
    this.vendorName,
    this.courier,
    this.awbNumber,
    this.trackingUrl,
  });

  factory OrderShipment.fromJson(Map<String, dynamic> json) => OrderShipment(
        id: json['id'] as String,
        status: json['status'] as String,
        vendorName: json['vendor_name'] as String?,
        courier: json['courier'] as String?,
        awbNumber: json['awb_number'] as String?,
        trackingUrl: json['tracking_url'] as String?,
      );

  final String id;
  final String status;
  final String? vendorName;
  final String? courier;
  final String? awbNumber;
  final String? trackingUrl;
}

class OrderStatusEvent {
  const OrderStatusEvent({required this.toStatus, required this.createdAt, this.note});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) => OrderStatusEvent(
        toStatus: json['to_status'] as String,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String?,
      );

  final String toStatus;
  final DateTime createdAt;
  final String? note;
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.shippingMinor,
    required this.totalMinor,
    required this.paymentMethod,
    required this.items,
    required this.shipments,
    required this.statusHistory,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        id: json['id'] as String,
        orderNumber: json['order_number'] as String,
        status: json['status'] as String,
        subtotalMinor: json['subtotal_minor'] as int,
        discountMinor: json['discount_minor'] as int,
        shippingMinor: json['shipping_minor'] as int,
        totalMinor: json['total_minor'] as int,
        paymentMethod: json['payment_method'] as String,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItemDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
        shipments: (json['shipments'] as List<dynamic>? ?? [])
            .map((e) => OrderShipment.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
            .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String orderNumber;
  final String status;
  final int subtotalMinor;
  final int discountMinor;
  final int shippingMinor;
  final int totalMinor;
  final String paymentMethod;
  final List<OrderItemDetail> items;
  final List<OrderShipment> shipments;
  final List<OrderStatusEvent> statusHistory;

  static const List<String> _cancellable = ['pending_payment', 'confirmed', 'processing', 'packed'];
  bool get isCancellable => _cancellable.contains(status);
  bool get isDelivered => status == 'delivered';
}
