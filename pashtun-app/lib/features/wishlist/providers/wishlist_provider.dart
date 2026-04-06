import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _wishlistBoxName = 'wishlist';

class WishlistNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final box = Hive.box<String>(_wishlistBoxName);
    return box.values.toSet();
  }

  void toggle(String productId) {
    final box = Hive.box<String>(_wishlistBoxName);
    if (state.contains(productId)) {
      box.delete(productId);
      state = {...state}..remove(productId);
    } else {
      box.put(productId, productId);
      state = {...state, productId};
    }
  }

  bool isWishlisted(String productId) => state.contains(productId);
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, Set<String>>(WishlistNotifier.new);

Future<void> initWishlistBox() async {
  await Hive.openBox<String>(_wishlistBoxName);
}
