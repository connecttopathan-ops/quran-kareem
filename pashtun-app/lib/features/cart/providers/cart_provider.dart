import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/cart_repository.dart';
import '../../../shared/models/cart_item.dart';

const _kCartIdKey = 'shopify_cart_id';

class CartNotifier extends Notifier<CartState> {
  final _storage = const FlutterSecureStorage();

  @override
  CartState build() {
    // Bootstrap the cart asynchronously after build
    Future.microtask(initCart);
    return const CartState.empty();
  }

  Future<void> initCart() async {
    final savedId = await _storage.read(key: _kCartIdKey);
    if (savedId != null) {
      try {
        final cartState = await cartRepository.fetchCart(savedId);
        state = cartState;
        return;
      } catch (_) {
        // Cart expired or invalid — create fresh
      }
    }
    await _createNewCart();
  }

  Future<void> _createNewCart() async {
    final (cartId, checkoutUrl) = await cartRepository.createCart();
    await _storage.write(key: _kCartIdKey, value: cartId);
    state = CartState(cartId: cartId, checkoutUrl: checkoutUrl);
  }

  Future<void> addItem(String variantId, int quantity) async {
    final cartId = await _ensureCartId();
    state = state.copyWith(isLoading: true);
    try {
      state = await cartRepository.addLines(cartId, variantId, quantity);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> removeItem(String lineId) async {
    final cartId = state.cartId;
    if (cartId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      state = await cartRepository.removeLine(cartId, lineId);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateQuantity(String lineId, int quantity) async {
    final cartId = state.cartId;
    if (cartId == null) return;
    if (quantity <= 0) {
      await removeItem(lineId);
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      state = await cartRepository.updateLine(cartId, lineId, quantity);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> applyCoupon(String code) async {
    final cartId = state.cartId;
    if (cartId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      state = await cartRepository.applyCoupon(cartId, code);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> clearCart() async {
    await _storage.delete(key: _kCartIdKey);
    state = const CartState.empty();
    await _createNewCart();
  }

  Future<String> _ensureCartId() async {
    if (state.cartId != null) return state.cartId!;
    await _createNewCart();
    return state.cartId!;
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
