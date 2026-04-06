import 'product.dart';

class CartItem {
  final String lineId;
  final String variantId;
  final String productId;
  final String productHandle;
  final String productTitle;
  final String? variantTitle;
  final String? imageUrl;
  final Money price;
  final Money? compareAtPrice;
  final int quantity;
  final List<SelectedOption> selectedOptions;

  const CartItem({
    required this.lineId,
    required this.variantId,
    required this.productId,
    required this.productHandle,
    required this.productTitle,
    this.variantTitle,
    this.imageUrl,
    required this.price,
    this.compareAtPrice,
    required this.quantity,
    this.selectedOptions = const [],
  });

  CartItem copyWith({int? quantity}) => CartItem(
    lineId: lineId,
    variantId: variantId,
    productId: productId,
    productHandle: productHandle,
    productTitle: productTitle,
    variantTitle: variantTitle,
    imageUrl: imageUrl,
    price: price,
    compareAtPrice: compareAtPrice,
    quantity: quantity ?? this.quantity,
    selectedOptions: selectedOptions,
  );

  double get totalAmount => price.amount * quantity;

  factory CartItem.fromLineNode(Map<String, dynamic> node) {
    final merchandise = node['merchandise'] as Map<String, dynamic>;
    final product = merchandise['product'] as Map<String, dynamic>;
    final images = product['images'] as Map<String, dynamic>?;
    final firstImage = images != null && (images['edges'] as List).isNotEmpty
        ? ((images['edges'] as List).first as Map)['node'] as Map<String, dynamic>
        : null;

    return CartItem(
      lineId: node['id'] as String,
      variantId: merchandise['id'] as String,
      productId: product['id'] as String,
      productHandle: product['handle'] as String,
      productTitle: product['title'] as String,
      variantTitle: merchandise['title'] as String?,
      imageUrl: firstImage?['url'] as String?,
      price: Money.fromJson(merchandise['price'] as Map<String, dynamic>),
      compareAtPrice: merchandise['compareAtPrice'] != null
          ? Money.fromJson(merchandise['compareAtPrice'] as Map<String, dynamic>)
          : null,
      quantity: node['quantity'] as int,
      selectedOptions: (merchandise['selectedOptions'] as List? ?? [])
          .map((e) => SelectedOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CartState {
  final String? cartId;
  final String? checkoutUrl;
  final List<CartItem> items;
  final double subtotal;
  final double total;
  final double? discount;
  final String? appliedCoupon;
  final bool isCouponApplicable;
  final bool isLoading;

  const CartState({
    this.cartId,
    this.checkoutUrl,
    this.items = const [],
    this.subtotal = 0,
    this.total = 0,
    this.discount,
    this.appliedCoupon,
    this.isCouponApplicable = false,
    this.isLoading = false,
  });

  const CartState.empty() : this();

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  String get currencyCode =>
      items.isNotEmpty ? items.first.price.currencyCode : 'INR';

  CartState copyWith({
    String? cartId,
    String? checkoutUrl,
    List<CartItem>? items,
    double? subtotal,
    double? total,
    double? discount,
    String? appliedCoupon,
    bool? isCouponApplicable,
    bool? isLoading,
  }) =>
      CartState(
        cartId: cartId ?? this.cartId,
        checkoutUrl: checkoutUrl ?? this.checkoutUrl,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        total: total ?? this.total,
        discount: discount ?? this.discount,
        appliedCoupon: appliedCoupon ?? this.appliedCoupon,
        isCouponApplicable: isCouponApplicable ?? this.isCouponApplicable,
        isLoading: isLoading ?? this.isLoading,
      );
}
