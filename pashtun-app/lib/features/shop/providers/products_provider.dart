import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_repository.dart';
import '../../../shared/models/product.dart';
import '../presentation/widgets/filter_bottom_sheet.dart';

// ── Collection Products ────────────────────────────────────────────────────────

class CollectionProductsState {
  final List<Product> products;
  final bool hasMore;
  final String? cursor;
  final bool isLoadingMore;
  final FilterOptions filter;

  const CollectionProductsState({
    this.products = const [],
    this.hasMore = true,
    this.cursor,
    this.isLoadingMore = false,
    this.filter = const FilterOptions(),
  });

  CollectionProductsState copyWith({
    List<Product>? products,
    bool? hasMore,
    String? cursor,
    bool? isLoadingMore,
    FilterOptions? filter,
  }) =>
      CollectionProductsState(
        products: products ?? this.products,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor ?? this.cursor,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        filter: filter ?? this.filter,
      );
}

class CollectionProductsNotifier
    extends FamilyAsyncNotifier<CollectionProductsState, String> {
  @override
  Future<CollectionProductsState> build(String handle) async {
    return _load(handle: handle, cursor: null, filter: const FilterOptions());
  }

  Future<CollectionProductsState> _load({
    required String handle,
    required String? cursor,
    required FilterOptions filter,
  }) async {
    final (products, hasMore, newCursor) =
        await productRepository.getCollectionProducts(
      handle: handle,
      after: cursor,
    );

    var filtered = products;
    if (filter.onSaleOnly) {
      filtered = filtered.where((p) => p.isOnSale).toList();
    }
    if (filter.sizes.isNotEmpty) {
      filtered = filtered
          .where((p) => p.sizeOptions
              .any((s) => filter.sizes.contains(s)))
          .toList();
    }

    return CollectionProductsState(
      products: filtered,
      hasMore: hasMore,
      cursor: newCursor,
      filter: filter,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final (newProducts, hasMore, cursor) =
          await productRepository.getCollectionProducts(
        handle: arg,
        after: current.cursor,
      );
      state = AsyncData(current.copyWith(
        products: [...current.products, ...newProducts],
        hasMore: hasMore,
        cursor: cursor,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> applyFilter(FilterOptions filter) async {
    state = const AsyncLoading();
    state = AsyncData(
      await _load(handle: arg, cursor: null, filter: filter),
    );
  }
}

final collectionProductsProvider = AsyncNotifierProviderFamily<
    CollectionProductsNotifier, CollectionProductsState, String>(
  CollectionProductsNotifier.new,
);

// ── Single Product ─────────────────────────────────────────────────────────────

final productProvider = FutureProvider.family<Product?, String>((ref, handle) {
  return productRepository.getProductByHandle(handle);
});

final relatedProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, handle) {
  return productRepository.getRelatedProducts(handle);
});
