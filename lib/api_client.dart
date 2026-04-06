import 'package:flutter/foundation.dart';
import 'package:habits/types.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart' as Constants;

final logger = Logger('ApiClient');

class ApiClient {
  late String baseUrl;
  late Dio _client;
  late SharedPreferencesAsync _prefs;
  final _secureStorage = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      groupId: 'api',
      useDataProtectionKeyChain: kDebugMode ? false : true,
    ),
  );

  static String parseDjangoErrorMessage(DioException e) {
    logger.severe('API error: ${e.response?.data}', e, e.stackTrace);
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('detail')) {
        return data['detail'] as String;
      } else {
        // Return the first error message from the response
        for (var value in data.values) {
          if (value is List && value.isNotEmpty) {
            return value[0] as String;
          } else if (value is String) {
            return value;
          }
        }
      }
    } else if (e.response?.data is List) {
      return (e.response?.data as List).first as String;
    }
    return 'An unknown error occurred';
  }

  ApiClient() {
    _prefs = SharedPreferencesAsync();
    _client = Dio(
      BaseOptions(
        baseUrl: Constants.baseApiUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<void> init() async {
    final token = await _secureStorage.read(key: 'auth_token');
    baseUrl = await _prefs.getString('base_url') ?? Constants.baseApiUrl;
    _client.options.baseUrl = baseUrl;
    if (token != null) {
      setToken(token);
    }
  }

  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null;
  }

  Future<void> removeToken() async {
    _client.options.headers.remove('Authorization');
    await _secureStorage.delete(key: 'auth_token');
  }

  void setToken(String token) {
    _client.options.headers['Authorization'] = 'Token $token';
  }

  Future<void> setBaseUrl(String? url) async {
    baseUrl = url ?? Constants.baseApiUrl;
    _client.options.baseUrl = url ?? Constants.baseApiUrl;
    if (url != null) {
      await _prefs.setString("base_url", url);
    } else {
      await _prefs.remove("base_url");
    }
  }

  Future<void> _handleAuthFailure() async {
    await removeToken();
  }

  Future<User> getSelf() async {
    try {
      final response = await _client.get('/api/users/me/');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to fetch current user: ${e.response}');
    }
  }

  Future<void> login(String username, String password) async {
    final response = await _client.post(
      '/api/auth/login/',
      data: {'username': username, 'password': password},
    );
    final token = response.data['token'] as String;
    setToken(token);
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Boards
  Future<List<Board>> getBoards() async {
    try {
      final response = await _client.get('/api/boards/');
      return (response.data as List)
          .map((e) => Board.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to fetch boards: ${e.response}');
    }
  }

  Future<Board> createBoard(Board board) async {
    try {
      final response = await _client.post('/api/boards/', data: board.toJson());
      return Board.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to create board: ${e.message}');
    }
  }

  Future<Board> getBoard(String id) async {
    try {
      final response = await _client.get('/api/boards/$id/');
      return Board.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to fetch board: ${e.message}');
    }
  }

  Future<Board> updateBoard(String id, Board board) async {
    try {
      final response = await _client.put(
        '/api/boards/$id/',
        data: board.toJson(),
      );
      return Board.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to update board: ${e.message}');
    }
  }

  // Future<void> deleteBoard(String id) async {
  //   try {
  //     await _client.delete('/boards/$id/');
  //   } on DioException catch (e) {
  //     throw Exception('Failed to delete board: ${e.message}');
  //   }
  // }

  // Users
  // Future<List<User>> getUsers() async {
  //   try {
  //     final response = await _client.get('/users/');
  //     return (response.data as List)
  //         .map((e) => User.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //   } on DioException catch (e) {
  //     throw Exception('Failed to fetch users: ${e.message}');
  //   }
  // }

  // Future<User> createUser(User user) async {
  //   try {
  //     final response = await _client.post('/users/', data: user.toJson());
  //     return User.fromJson(response.data as Map<String, dynamic>);
  //   } on DioException catch (e) {
  //     throw Exception('Failed to create user: ${e.message}');
  //   }
  // }

  Future<User> getUser(String id) async {
    try {
      final response = await _client.get('/api/users/$id/');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to fetch user: ${e.message}');
    }
  }

  Future<User> updateUser(String id, User user) async {
    try {
      final response = await _client.put(
        '/api/users/$id/',
        data: user.toJson(),
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to update user: ${e.message}');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _client.delete('/api/users/$id/');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to delete user: ${e.message}');
    }
  }

  // Expenses
  Future<List<Expense>> getExpenses(String boardId) async {
    try {
      final response = await _client.get('/api/boards/$boardId/expenses/');
      return (response.data as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to fetch expenses: ${e.message}');
    }
  }

  Future<Expense> createExpense(
    Map<String, dynamic> data,
    String boardId,
  ) async {
    try {
      final response = await _client.post(
        '/api/boards/$boardId/expenses/',
        data: data,
      );
      return Expense.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      rethrow;
    }
  }

  Future<Expense> updateExpense(
    Map<String, dynamic> data,
    String expenseId,
  ) async {
    try {
      final response = await _client.put(
        '/api/expenses/$expenseId/',
        data: data,
      );
      return Expense.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      rethrow;
    }
  }

  Future<Expense> getExpense(String id) async {
    try {
      final response = await _client.get('/api/expenses/$id/');
      return Expense.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to fetch expense: ${e.message}');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _client.delete('/api/expenses/$id/');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to delete expense: ${e.message}');
    }
  }
}
