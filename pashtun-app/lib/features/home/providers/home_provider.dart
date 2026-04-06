import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/graphql/client.dart';
import '../../../core/graphql/queries.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/collection.dart';

// ── Collections ────────────────────────────────────────────────────────────────

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final data = await ShopifyGraphQLClient.query(
    document: getCollectionsQuery,
  );
  final edges = (data['collections'] as Map)['edges'] as List? ?? [];
  return edges
      .map((e) => Collection.fromJson((e as Map)['node'] as Map<String, dynamic>))
      .toList();
});

// ── New Arrivals ───────────────────────────────────────────────────────────────

class NewArrivalsState {
  final List<Product> products;
  final bool hasMore;
  final String? cursor;
  final bool isLoadingMore;

  const NewArrivalsState({
    this.products = const [],
    this.hasMore = true,
    this.cursor,
    this.isLoadingMore = false,
  });

  NewArrivalsState copyWith({
    List<Product>? products,
    bool? hasMore,
    String? cursor,
    bool? isLoadingMore,
  }) =>
      NewArrivalsState(
        products: products ?? this.products,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor ?? this.cursor,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class NewArrivalsNotifier extends AsyncNotifier<NewArrivalsState> {
  @override
  Future<NewArrivalsState> build() => _fetchPage(cursor: null);

  Future<NewArrivalsState> _fetchPage({String? cursor}) async {
    final data = await ShopifyGraphQLClient.query(
      document: getCollectionProductsQuery,
      variables: {
        'handle': 'new-arrivals',
        'first': ApiConstants.productsPerPage,
        if (cursor != null) 'after': cursor,
      },
    );

    final collection =
        data['collectionByHandle'] as Map<String, dynamic>? ?? {};
    final productsNode = collection['products'] as Map<String, dynamic>? ?? {};
    final pageInfo = productsNode['pageInfo'] as Map<String, dynamic>? ?? {};
    final edges = productsNode['edges'] as List? ?? [];

    final products = edges
        .map((e) => Product.fromJson((e as Map)['node'] as Map<String, dynamic>))
        .toList();

    return NewArrivalsState(
      products: products,
      hasMore: pageInfo['hasNextPage'] as bool? ?? false,
      cursor: pageInfo['endCursor'] as String?,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final next = await _fetchPage(cursor: current.cursor);
      state = AsyncData(NewArrivalsState(
        products: [...current.products, ...next.products],
        hasMore: next.hasMore,
        cursor: next.cursor,
      ));
    } catch (e, st) {
      // Restore state on error, keep existing products
      state = AsyncData(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(e, st);
    }
  }
}

final newArrivalsProvider =
    AsyncNotifierProvider<NewArrivalsNotifier, NewArrivalsState>(
  NewArrivalsNotifier.new,
);

// ── Flash Sale ─────────────────────────────────────────────────────────────────

class FlashSale {
  final String title;
  final DateTime endTime;
  final int discountPercent;

  const FlashSale({
    required this.title,
    required this.endTime,
    required this.discountPercent,
  });

  bool get isActive => endTime.isAfter(DateTime.now());
}

// In a real app this would come from a Shopify metafield or remote config.
// Hard-coded as a placeholder until backend integration is done.
final flashSaleProvider = Provider<FlashSale?>((ref) {
  final endTime = DateTime.now().add(const Duration(hours: 6));
  return FlashSale(
    title: 'Eid Special Sale',
    endTime: endTime,
    discountPercent: 40,
  );
});

// ── Hero Banners ──────────────────────────────────────────────────────────────

class HeroBanner {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String route;
  final String cta;

  const HeroBanner({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.route,
    required this.cta,
  });
}

final heroBannersProvider = Provider<List<HeroBanner>>((ref) => const [
  HeroBanner(
    title: 'Eid Collection',
    subtitle: 'Shop the finest Pakistani designer suits',
    route: '/collection/festive',
    cta: 'Shop Now',
  ),
  HeroBanner(
    title: 'Bridal 2025',
    subtitle: 'Crafted for your most special moments',
    route: '/collection/bridal',
    cta: 'Explore Bridal',
  ),
  HeroBanner(
    title: 'New Arrivals',
    subtitle: 'Fresh drops — limited pieces available',
    route: '/collection/new-arrivals',
    cta: 'View All',
  ),
]);
