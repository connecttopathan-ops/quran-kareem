import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/api_constants.dart';

class ShopifyGraphQLClient {
  ShopifyGraphQLClient._();

  static GraphQLClient? _instance;

  static GraphQLClient get instance {
    _instance ??= _buildClient();
    return _instance!;
  }

  static GraphQLClient _buildClient() {
    final httpLink = HttpLink(
      ApiConstants.shopifyGraphqlEndpoint,
      defaultHeaders: {
        'X-Shopify-Storefront-Access-Token': ApiConstants.shopifyStorefrontToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.cacheAndNetwork,
        ),
      ),
    );
  }

  /// Executes a query and returns the data map or throws.
  static Future<Map<String, dynamic>> query({
    required String document,
    Map<String, dynamic> variables = const {},
  }) async {
    final result = await instance.query(
      QueryOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
    );
    if (result.hasException) {
      throw result.exception!;
    }
    return result.data ?? {};
  }

  /// Executes a mutation and returns the data map or throws.
  static Future<Map<String, dynamic>> mutate({
    required String document,
    Map<String, dynamic> variables = const {},
  }) async {
    final result = await instance.mutate(
      MutationOptions(
        document: gql(document),
        variables: variables,
      ),
    );
    if (result.hasException) {
      throw result.exception!;
    }
    return result.data ?? {};
  }
}
