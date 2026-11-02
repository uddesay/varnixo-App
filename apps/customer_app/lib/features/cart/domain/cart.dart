class CartItemOption {
  const CartItemOption({required this.name, required this.value});

  factory CartItemOption.fromJson(Map<String, dynamic> json) =>
      CartItemOption(name: json['name'] as String, value: json['value'] as String);

  final String name;
  final String value;
}

class CartItem {
  const CartItem({
    required this.itemId,
    required this.productId,
    required this.variantId,
    required this.title,
    required this.slug,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    this.image,
    this.mrpMinor,
    this.options = const [],
    this.vendorName,
    this.availableStock = 0,
    this.purchasable = true,
    this.isCodAvailable = true,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        itemId: json['itemId'] as String,
        productId: json['productId'] as String,
        variantId: json['variantId'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        image: json['image'] as String?,
        quantity: json['quantity'] as int,
        unitPriceMinor: json['unitPriceMinor'] as int,
        mrpMinor: json['mrpMinor'] as int?,
        lineTotalMinor: json['lineTotalMinor'] as int,
        options: (json['options'] as List<dynamic>? ?? [])
            .map((e) => CartItemOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        vendorName: json['vendorName'] as String?,
        availableStock: json['availableStock'] as int? ?? 0,
        purchasable: json['purchasable'] as bool? ?? true,
        isCodAvailable: json['isCodAvailable'] as bool? ?? true,
      );

  final String itemId;
  final String productId;
  final String variantId;
  final String title;
  final String slug;
  final String? image;
  final int quantity;
  final int unitPriceMinor;
  final int? mrpMinor;
  final int lineTotalMinor;
  final List<CartItemOption> options;
  final String? vendorName;
  final int availableStock;
  final bool purchasable;
  final bool isCodAvailable;

  String get optionsLabel => options.map((o) => o.value).join(', ');
}

class CartCoupon {
  const CartCoupon({required this.code, required this.title});

  factory CartCoupon.fromJson(Map<String, dynamic> json) =>
      CartCoupon(code: json['code'] as String, title: json['title'] as String);

  final String code;
  final String title;
}

class CartTotals {
  const CartTotals({
    this.itemCount = 0,
    this.subtotalMinor = 0,
    this.discountMinor = 0,
    this.shippingMinor = 0,
    this.totalMinor = 0,
    this.coupon,
    this.couponError,
    this.freeShippingThresholdMinor = 0,
  });

  factory CartTotals.fromJson(Map<String, dynamic> json) => CartTotals(
        itemCount: json['itemCount'] as int? ?? 0,
        subtotalMinor: json['subtotalMinor'] as int? ?? 0,
        discountMinor: json['discountMinor'] as int? ?? 0,
        shippingMinor: json['shippingMinor'] as int? ?? 0,
        totalMinor: json['totalMinor'] as int? ?? 0,
        coupon: json['coupon'] != null
            ? CartCoupon.fromJson(json['coupon'] as Map<String, dynamic>)
            : null,
        couponError: json['couponError'] as String?,
        freeShippingThresholdMinor: json['freeShippingThresholdMinor'] as int? ?? 0,
      );

  final int itemCount;
  final int subtotalMinor;
  final int discountMinor;
  final int shippingMinor;
  final int totalMinor;
  final CartCoupon? coupon;
  final String? couponError;
  final int freeShippingThresholdMinor;

  int get amountToFreeShipping =>
      (freeShippingThresholdMinor - (subtotalMinor - discountMinor)).clamp(0, freeShippingThresholdMinor);
}

class Cart {
  const Cart({required this.id, required this.items, required this.savedForLater, required this.totals});

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        savedForLater: (json['savedForLater'] as List<dynamic>? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totals: CartTotals.fromJson(json['totals'] as Map<String, dynamic>),
      );

  final String id;
  final List<CartItem> items;
  final List<CartItem> savedForLater;
  final CartTotals totals;

  bool get isEmpty => items.isEmpty;
  bool get hasUnpurchasableItems => items.any((i) => !i.purchasable);
}
