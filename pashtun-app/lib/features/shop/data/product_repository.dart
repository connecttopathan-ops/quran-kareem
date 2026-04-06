import '../../../core/graphql/client.dart';
import '../../../core/graphql/queries.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/collection.dart';

class ProductRepository {
  const ProductRepository();

  Future<(List<Product>, bool hasMore, String? cursor)> getCollectionProducts({
    required String handle,
    int first = ApiConstants.productsPerPage,
    String? after,
  }) async {
    final data = await ShopifyGraphQLClient.query(
      document: getCollectionProductsQuery,
      variables: {
        'handle': handle,
        'first': first,
        if (after != null) 'after': after,
      },
    );

    final collection =
        data['collectionByHandle'] as Map<String, dynamic>? ?? {};
    final productsNode =
        collection['products'] as Map<String, dynamic>? ?? {};
    final pageInfo = productsNode['pageInfo'] as Map<String, dynamic>? ?? {};
    final edges = productsNode['edges'] as List? ?? [];

    final products = edges
        .map((e) => Product.fromJson((e as Map)['node'] as Map<String, dynamic>))
        .toList();

    return (
      products,
      pageInfo['hasNextPage'] as bool? ?? false,
      pageInfo['endCursor'] as String?,
    );
  }

  Future<Product?> getProductByHandle(String handle) async {
    final data = await ShopifyGraphQLClient.query(
      document: getProductByHandleQuery,
      variables: {'handle': handle},
    );
    final productJson = data['productByHandle'] as Map<String, dynamic>?;
    return productJson != null ? Product.fromJson(productJson) : null;
  }

  Future<List<Product>> getRelatedProducts(String handle, {int limit = 6}) async {
    final data = await ShopifyGraphQLClient.query(
      document: getRelatedProductsQuery,
      variables: {'handle': handle, 'first': limit + 1},
    );
    final productJson = data['productByHandle'] as Map<String, dynamic>? ?? {};
    final collectionsNode =
        productJson['collections'] as Map<String, dynamic>? ?? {};
    final collEdges = collectionsNode['edges'] as List? ?? [];
    if (collEdges.isEmpty) return [];
    final firstColl = (collEdges.first as Map)['node'] as Map<String, dynamic>;
    final prodEdges =
        (firstColl['products'] as Map)['edges'] as List? ?? [];
    return prodEdges
        .map((e) => Product.fromJson((e as Map)['node'] as Map<String, dynamic>))
        .where((p) => p.handle != handle)
        .take(limit)
        .toList();
  }

  Future<List<Collection>> getCollections() async {
    final data = await ShopifyGraphQLClient.query(
      document: getCollectionsQuery,
    );
    final edges = (data['collections'] as Map)['edges'] as List? ?? [];
    return edges
        .map((e) => Collection.fromJson((e as Map)['node'] as Map<String, dynamic>))
        .toList();
  }
}

// Singleton instance
const productRepository = ProductRepository();
