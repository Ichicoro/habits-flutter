import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((
  ref,
) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final apiClient = getIt.get<ApiClient>();
      // Check if there's a valid token
      final hasToken = await apiClient.hasValidToken();
      state = AsyncValue.data(hasToken);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final apiClient = getIt.get<ApiClient>();
      await apiClient.login(username, password);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final apiClient = getIt.get<ApiClient>();
      apiClient.removeToken();
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
