import 'package:habits/types.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart' as Constants;

class ApiClient {
  final String baseUrl;
  late Dio _client;
  late SharedPreferencesAsync _prefs;

  ApiClient({required this.baseUrl}) {
    _client = Dio(
      BaseOptions(
        baseUrl: Constants.baseApiUrl,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _prefs = SharedPreferencesAsync();
  }

  Future<void> init() async {
    final token = await _prefs.getString('auth_token');
    if (token != null) {
      setToken(token);
    }
  }

  Future<bool> hasValidToken() async {
    final token = await _prefs.getString('auth_token');
    return token != null;
  }

  void removeToken() {
    _client.options.headers.remove('Authorization');
  }

  void setToken(String token) {
    _client.options.headers['Authorization'] = 'Token $token';
  }

  Future<void> _handleAuthFailure() async {
    removeToken();
    await _prefs.remove('auth_token');
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _client.post(
        '/api/auth/login/',
        data: {'username': username, 'password': password},
      );
      final token = response.data['token'] as String;
      setToken(token);
      await _prefs.setString('auth_token', token);
    } on DioException catch (e) {
      print(e.response);
      rethrow;
    }
  }

  // Boards
  Future<List<Board>> getBoards() async {
    try {
      final response = await _client.get('/api/boards/');
      print(response.data);
      return (response.data as List)
          .map((e) => Board.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      print(e.requestOptions.uri);
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

  Future<Expense> createExpense(Expense expense, String boardId) async {
    try {
      final response = await _client.post(
        '/api/boards/$boardId/expenses/',
        data: expense.toJson(),
      );
      return Expense.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleAuthFailure();
      }
      throw Exception('Failed to create expense: ${e.message}');
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
