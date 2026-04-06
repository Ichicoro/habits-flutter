import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:habits/api_client.dart';
import 'package:habits/types.dart';
import 'package:logging/logging.dart';
import 'package:watch_it/watch_it.dart';

final getIt = GetIt.instance;

final _log = Logger('ServiceLocator');

class CurrentUserRepository {
  final ApiClient apiClient;

  final currentUser = ValueNotifier<User?>(null);

  CurrentUserRepository(this.apiClient) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUser.value = await apiClient.getSelf();
    } catch (e) {
      _log.warning('Failed to load current user: $e');
    }
  }
}

class CurrentBoardRepository {
  final ApiClient apiClient;

  final currentBoard = ValueNotifier<Board?>(null);
  final boards = ValueNotifier<List<Board>>([]);
  final expenses = ValueNotifier<List<Expense>>([]);

  CurrentBoardRepository(this.apiClient);

  Future<void> updateData({bool forceReload = false}) async {
    try {
      if (boards.value.isEmpty || forceReload) {
        boards.value = await apiClient.getBoards();
      }
      if (boards.value.isNotEmpty && currentBoard.value == null) {
        currentBoard.value = boards.value[0];
      }
      if (currentBoard.value != null &&
          currentBoard.value!.id.isNotEmpty &&
          (expenses.value.isEmpty || forceReload)) {
        expenses.value = await apiClient.getExpenses(currentBoard.value!.id)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      _log.warning('Failed to update data: $e');
    }
  }

  Future<void> updateExpenses() async {
    if (currentBoard.value != null && currentBoard.value!.id.isNotEmpty) {
      expenses.value = await apiClient.getExpenses(currentBoard.value!.id)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> switchBoard(String boardId) async {
    try {
      boards.value = await apiClient.getBoards();
      var board = boards.value.firstWhere((b) => b.id == boardId);
      currentBoard.value = board;
      await updateExpenses();
    } catch (e) {
      _log.warning('Failed to switch board: $e');
    }
  }
}

Future<void> setupServiceLocator() async {
  final apiClient = ApiClient();
  await apiClient.init();
  getIt.registerSingleton<ApiClient>(apiClient);
  getIt.registerSingleton<CurrentBoardRepository>(
    CurrentBoardRepository(apiClient),
  );
  getIt.registerSingleton<CurrentUserRepository>(
    CurrentUserRepository(apiClient),
  );
}
