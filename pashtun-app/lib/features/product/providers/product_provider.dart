import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shop/providers/products_provider.dart';
import '../../../shared/models/product.dart';

// Re-export from shop providers for convenience
export '../../shop/providers/products_provider.dart'
    show productProvider, relatedProductsProvider;

// Selected variant state per product handle
final selectedVariantProvider =
    StateProvider.family<ProductVariant?, String>((ref, handle) {
  // Default to first available variant
  final product = ref.watch(productProvider(handle)).valueOrNull;
  if (product == null) return null;
  return product.variants.firstWhere(
    (v) => v.availableForSale,
    orElse: () => product.variants.first,
  );
});

// Selected options per product (e.g. {'Size': 'M', 'Color': 'Red'})
final selectedOptionsProvider =
    StateProvider.family<Map<String, String>, String>((ref, handle) => {});
