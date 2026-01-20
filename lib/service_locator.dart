import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:watch_it/watch_it.dart';
import 'package:habits/api_client.dart';
import 'package:habits/types.dart';
import 'constants.dart' as Constants;

final getIt = GetIt.instance;

class CurrentBoardRepository {
  final ApiClient apiClient;

  final currentBoard = ValueNotifier<Board?>(null);
  final boards = ValueNotifier<List<Board>>([]);
  final expenses = ValueNotifier<List<Expense>>([]);

  CurrentBoardRepository(this.apiClient);

  Future<void> updateData({bool forceReload = false}) async {
    // TODO: Handle errors
    if (boards.value.isEmpty || forceReload) {
      boards.value = await apiClient.getBoards();
    }
    if (boards.value.isNotEmpty) {
      currentBoard.value = boards.value[0];
    }
    if (currentBoard.value != null &&
        currentBoard.value!.id.isNotEmpty &&
        (expenses.value.isEmpty || forceReload)) {
      expenses.value = await apiClient.getExpenses(currentBoard.value!.id);
    }
  }

  Future<void> updateExpenses() async {
    if (currentBoard.value != null && currentBoard.value!.id.isNotEmpty) {
      expenses.value = await apiClient.getExpenses(currentBoard.value!.id);
    }
  }
}

Future<void> setupServiceLocator() async {
  final apiClient = ApiClient(baseUrl: Constants.baseApiUrl);
  await apiClient.init();
  getIt.registerSingleton<ApiClient>(apiClient);
  getIt.registerSingleton<CurrentBoardRepository>(
    CurrentBoardRepository(getIt<ApiClient>()),
  );
}
