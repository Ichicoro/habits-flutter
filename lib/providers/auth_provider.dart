import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, User>(CurrentUserNotifier.new);

class CurrentUserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    ref.watch(authProvider);
    final apiClient = getIt.get<ApiClient>();
    return apiClient.getSelf();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => getIt.get<ApiClient>().getSelf());
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<bool>>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    _init();
    return const AsyncValue.loading();
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
      await apiClient.removeToken();
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
