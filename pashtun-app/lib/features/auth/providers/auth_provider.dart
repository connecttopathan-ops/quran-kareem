import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/graphql/client.dart';
import '../../../core/graphql/mutations.dart';

const _kTokenKey = 'customer_access_token';
const _kEmailKey = 'customer_email';
const _kNameKey  = 'customer_name';

class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? customerId;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.accessToken,
    this.email,
    this.displayName,
    this.customerId,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? email,
    String? displayName,
    String? customerId,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        accessToken: accessToken ?? this.accessToken,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        customerId: customerId ?? this.customerId,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read(key: _kTokenKey);
    final email = await _storage.read(key: _kEmailKey);
    final name  = await _storage.read(key: _kNameKey);
    if (token != null) {
      state = AuthState(
        isAuthenticated: true,
        accessToken: token,
        email: email,
        displayName: name,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ShopifyGraphQLClient.mutate(
        document: customerAccessTokenCreateMutation,
        variables: {
          'input': {'email': email, 'password': password},
        },
      );
      final result = (data['customerAccessTokenCreate'] as Map);
      final errors =
          result['customerUserErrors'] as List? ?? [];
      if (errors.isNotEmpty) {
        throw Exception((errors.first as Map)['message']);
      }
      final tokenData =
          result['customerAccessToken'] as Map<String, dynamic>;
      final token = tokenData['accessToken'] as String;
      await _storage.write(key: _kTokenKey, value: token);
      await _storage.write(key: _kEmailKey, value: email);
      state = AuthState(
        isAuthenticated: true,
        accessToken: token,
        email: email,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ShopifyGraphQLClient.mutate(
        document: customerCreateMutation,
        variables: {
          'input': {
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'password': password,
          },
        },
      );
      final result = (data['customerCreate'] as Map);
      final errors =
          result['customerUserErrors'] as List? ?? [];
      if (errors.isNotEmpty) {
        throw Exception((errors.first as Map)['message']);
      }
      // Auto-login after register
      await login(email, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final token = state.accessToken;
    if (token != null) {
      await ShopifyGraphQLClient.mutate(
        document: customerAccessTokenDeleteMutation,
        variables: {'customerAccessToken': token},
      );
    }
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
