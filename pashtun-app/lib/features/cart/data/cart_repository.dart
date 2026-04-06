import '../../../core/graphql/client.dart';
import '../../../core/graphql/mutations.dart';
import '../../../core/graphql/queries.dart';
import '../../../shared/models/cart_item.dart';

class CartRepository {
  const CartRepository();

  Future<(String cartId, String checkoutUrl)> createCart() async {
    final data = await ShopifyGraphQLClient.mutate(
      document: cartCreateMutation,
      variables: {'input': {}},
    );
    final cart = (data['cartCreate'] as Map)['cart'] as Map<String, dynamic>;
    return (
      cart['id'] as String,
      cart['checkoutUrl'] as String,
    );
  }

  Future<CartState> addLines(
    String cartId,
    String variantId,
    int quantity,
  ) async {
    final data = await ShopifyGraphQLClient.mutate(
      document: cartLinesAddMutation,
      variables: {
        'cartId': cartId,
        'lines': [
          {'merchandiseId': variantId, 'quantity': quantity}
        ],
      },
    );
    final cart =
        (data['cartLinesAdd'] as Map)['cart'] as Map<String, dynamic>;
    return _parseCartState(cart);
  }

  Future<CartState> updateLine(
    String cartId,
    String lineId,
    int quantity,
  ) async {
    final data = await ShopifyGraphQLClient.mutate(
      document: cartLinesUpdateMutation,
      variables: {
        'cartId': cartId,
        'lines': [
          {'id': lineId, 'quantity': quantity}
        ],
      },
    );
    final cart =
        (data['cartLinesUpdate'] as Map)['cart'] as Map<String, dynamic>;
    return _parseCartState(cart);
  }

  Future<CartState> removeLine(String cartId, String lineId) async {
    final data = await ShopifyGraphQLClient.mutate(
      document: cartLinesRemoveMutation,
      variables: {
        'cartId': cartId,
        'lineIds': [lineId],
      },
    );
    final cart =
        (data['cartLinesRemove'] as Map)['cart'] as Map<String, dynamic>;
    return _parseCartState(cart);
  }

  Future<CartState> applyCoupon(String cartId, String code) async {
    final data = await ShopifyGraphQLClient.mutate(
      document: cartDiscountCodesUpdateMutation,
      variables: {
        'cartId': cartId,
        'discountCodes': [code],
      },
    );
    final cart = (data['cartDiscountCodesUpdate'] as Map)['cart']
        as Map<String, dynamic>;
    return _parseCartState(cart);
  }

  Future<CartState> fetchCart(String cartId) async {
    final data = await ShopifyGraphQLClient.query(
      document: cartQuery,
      variables: {'cartId': cartId},
    );
    final cart = data['cart'] as Map<String, dynamic>?;
    if (cart == null) return const CartState.empty();
    return _parseCartState(cart);
  }

  CartState _parseCartState(Map<String, dynamic> cart) {
    final lines = (cart['lines'] as Map)['edges'] as List? ?? [];
    final items = lines
        .map((e) => CartItem.fromLineNode(
              (e as Map)['node'] as Map<String, dynamic>,
            ))
        .toList();

    final costNode = cart['cost'] as Map<String, dynamic>? ?? {};
    final totalNode =
        costNode['totalAmount'] as Map<String, dynamic>? ?? {};
    final subtotalNode =
        costNode['subtotalAmount'] as Map<String, dynamic>? ?? {};

    final discountCodes =
        cart['discountCodes'] as List? ?? [];
    final appliedCode = discountCodes.isNotEmpty
        ? (discountCodes.first as Map)['code'] as String?
        : null;
    final isCouponApplicable = discountCodes.isNotEmpty
        ? (discountCodes.first as Map)['applicable'] as bool? ?? false
        : false;

    final total = double.tryParse(
            totalNode['amount']?.toString() ?? '0') ??
        0;
    final subtotal = double.tryParse(
            subtotalNode['amount']?.toString() ?? '0') ??
        0;

    return CartState(
      cartId: cart['id'] as String?,
      checkoutUrl: cart['checkoutUrl'] as String?,
      items: items,
      subtotal: subtotal,
      total: total,
      discount: subtotal > total ? subtotal - total : null,
      appliedCoupon: appliedCode,
      isCouponApplicable: isCouponApplicable,
    );
  }
}

const cartRepository = CartRepository();
