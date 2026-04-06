import 'product.dart';

class OrderLineItem {
  final String title;
  final int quantity;
  final String? variantId;
  final String? variantTitle;
  final Money? price;
  final String? imageUrl;

  const OrderLineItem({
    required this.title,
    required this.quantity,
    this.variantId,
    this.variantTitle,
    this.price,
    this.imageUrl,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    final variant = json['variant'] as Map<String, dynamic>?;
    final image   = variant?['image'] as Map<String, dynamic>?;
    return OrderLineItem(
      title: json['title'] as String,
      quantity: json['quantity'] as int,
      variantId: variant?['id'] as String?,
      variantTitle: variant?['title'] as String?,
      price: variant != null && variant['price'] != null
          ? Money.fromJson(variant['price'] as Map<String, dynamic>)
          : null,
      imageUrl: image?['url'] as String?,
    );
  }
}

class ShippingAddress {
  final String? address1;
  final String? address2;
  final String? city;
  final String? province;
  final String? country;
  final String? zip;
  final String? phone;

  const ShippingAddress({
    this.address1,
    this.address2,
    this.city,
    this.province,
    this.country,
    this.zip,
    this.phone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        address1: json['address1'] as String?,
        address2: json['address2'] as String?,
        city: json['city'] as String?,
        province: json['province'] as String?,
        country: json['country'] as String?,
        zip: json['zip'] as String?,
        phone: json['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'address1': address1,
    'address2': address2,
    'city': city,
    'province': province,
    'country': country,
    'zip': zip,
    'phone': phone,
  };

  String get formatted =>
      [address1, address2, city, province, zip, country]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
}

enum OrderFinancialStatus {
  pending, paid, refunded, voided, partiallyPaid, partiallyRefunded;

  static OrderFinancialStatus fromString(String? s) => switch (s?.toUpperCase()) {
    'PAID'               => paid,
    'REFUNDED'           => refunded,
    'VOIDED'             => voided,
    'PARTIALLY_PAID'     => partiallyPaid,
    'PARTIALLY_REFUNDED' => partiallyRefunded,
    _                    => pending,
  };

  String get label => switch (this) {
    paid               => 'Paid',
    refunded           => 'Refunded',
    voided             => 'Voided',
    partiallyPaid      => 'Partially Paid',
    partiallyRefunded  => 'Partially Refunded',
    pending            => 'Pending',
  };
}

enum OrderFulfillmentStatus {
  unfulfilled, fulfilled, partiallyFulfilled, inTransit, outForDelivery, delivered;

  static OrderFulfillmentStatus fromString(String? s) => switch (s?.toUpperCase()) {
    'FULFILLED'            => fulfilled,
    'PARTIALLY_FULFILLED'  => partiallyFulfilled,
    'IN_TRANSIT'           => inTransit,
    'OUT_FOR_DELIVERY'     => outForDelivery,
    'DELIVERED'            => delivered,
    _                      => unfulfilled,
  };

  String get label => switch (this) {
    fulfilled           => 'Fulfilled',
    partiallyFulfilled  => 'Partially Fulfilled',
    inTransit           => 'In Transit',
    outForDelivery      => 'Out for Delivery',
    delivered           => 'Delivered',
    unfulfilled         => 'Processing',
  };
}

class Order {
  final String id;
  final int orderNumber;
  final DateTime processedAt;
  final OrderFinancialStatus financialStatus;
  final OrderFulfillmentStatus fulfillmentStatus;
  final Money totalPrice;
  final List<OrderLineItem> lineItems;
  final ShippingAddress? shippingAddress;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.processedAt,
    required this.financialStatus,
    required this.fulfillmentStatus,
    required this.totalPrice,
    required this.lineItems,
    this.shippingAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final lineEdges = (json['lineItems'] as Map)['edges'] as List? ?? [];
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as int,
      processedAt: DateTime.parse(json['processedAt'] as String),
      financialStatus: OrderFinancialStatus.fromString(
        json['financialStatus'] as String?,
      ),
      fulfillmentStatus: OrderFulfillmentStatus.fromString(
        json['fulfillmentStatus'] as String?,
      ),
      totalPrice: Money.fromJson(
        json['currentTotalPrice'] as Map<String, dynamic>,
      ),
      lineItems: lineEdges
          .map((e) => OrderLineItem.fromJson((e as Map)['node'] as Map<String, dynamic>))
          .toList(),
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(
              json['shippingAddress'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
