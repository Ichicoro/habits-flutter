// Enums
enum FrequencyEnum {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  custom('custom'),
  none('none');

  final String value;
  const FrequencyEnum(this.value);

  factory FrequencyEnum.fromString(String value) {
    return FrequencyEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FrequencyEnum.none,
    );
  }
}

enum SplitTypeEnum {
  equal('equal'),
  amount('amount'),
  percentage('percentage');

  final String value;
  const SplitTypeEnum(this.value);

  factory SplitTypeEnum.fromString(String value) {
    return SplitTypeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SplitTypeEnum.equal,
    );
  }
}

class ExpenseCategory {
  final String id;
  final String name;
  final String emoji;
  final String? board;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.board,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      board: json['board'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'board': board,
  };
}

// User
class User {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
  };

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

// Board
class Board {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User createdBy;
  final List<User> users;
  final List<ExpenseCategory> expenseCategories;

  Board({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.users,
    required this.expenseCategories,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    final dynamic createdByJson = json['created_by'];
    User createdBy;
    if (createdByJson is Map<String, dynamic>) {
      createdBy = User.fromJson(createdByJson);
    } else if (createdByJson is String) {
      // Fallback: backend returns only the UUID string.
      createdBy = User(id: createdByJson, username: '', email: '');
    } else {
      createdBy = User(id: '', username: '', email: '');
    }

    return Board(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      users: json['users'] != null
          ? (json['users'] as List<dynamic>)
                .map((e) => User.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      expenseCategories: json['expense_categories'] != null
          ? (json['expense_categories'] as List<dynamic>)
                .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      createdBy: createdBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'users': users.map((e) => e.toJson()).toList(),
    'board_categories': expenseCategories.map((e) => e.toJson()).toList(),
    // Send only the UUID per API contract
    'created_by': createdBy.id,
  };

  Board copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ExpenseCategory>? expenseCategories,
    User? createdBy,
    List<User>? users,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      createdBy: createdBy ?? this.createdBy,
      users: users ?? this.users,
    );
  }
}

// Habit
class Habit {
  final String id;
  final String name;
  final String? description;
  final FrequencyEnum frequency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String board;

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.frequency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.board,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequency: FrequencyEnum.fromString(
        json['frequency'] as String? ?? 'none',
      ),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      board: json['board'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'frequency': frequency.value,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'board': board,
  };

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    FrequencyEnum? frequency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? board,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      board: board ?? this.board,
    );
  }
}

// ExpenseSplit
class ExpenseSplit {
  final String id;
  final User user;
  final double shareAmount;
  final double? percentage;

  ExpenseSplit({
    required this.id,
    required this.user,
    required this.shareAmount,
    this.percentage,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as String,
      user: User.fromJson(json['user']),
      shareAmount: json['share_amount'] as double,
      percentage: json['percentage'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user,
    'share_amount': shareAmount,
    'percentage': percentage,
  };

  ExpenseSplit copyWith({
    String? id,
    User? user,
    double? shareAmount,
    double? percentage,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      user: user ?? this.user,
      shareAmount: shareAmount ?? this.shareAmount,
      percentage: percentage ?? this.percentage,
    );
  }
}

// Expense
class Expense {
  final String id;
  final List<ExpenseSplit> splits;
  final SplitTypeEnum splitType;
  final double amount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String board;
  final User payer;
  final ExpenseCategory? category;

  Expense({
    required this.id,
    required this.splits,
    required this.splitType,
    required this.amount,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.board,
    required this.payer,
    this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      splits:
          (json['splits'] as List<dynamic>?)
              ?.map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      splitType: SplitTypeEnum.fromString(
        json['split_type'] as String? ?? 'equal',
      ),
      amount: json['amount'] as double,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      board: json['board'] as String,
      payer: User.fromJson(json['payer']),
      category: json['category'] != null
          ? ExpenseCategory.fromJson(json['category'])
          : null as ExpenseCategory?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'splits': splits.map((e) => e.toJson()).toList(),
    'split_type': splitType.value,
    'amount': amount,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    // 'board': board,
    'payer': payer,
    'category': category,
  };

  Expense copyWith({
    String? id,
    List<ExpenseSplit>? splits,
    SplitTypeEnum? splitType,
    double? amount,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? board,
    User? payer,
    ExpenseCategory? category,
  }) {
    return Expense(
      id: id ?? this.id,
      splits: splits ?? this.splits,
      splitType: splitType ?? this.splitType,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      board: board ?? this.board,
      payer: payer ?? this.payer,
      category: category ?? this.category,
    );
  }
}

// Patched types for partial updates
class PatchedBoard {
  final String? name;
  final String? description;

  PatchedBoard({this.name, this.description});

  factory PatchedBoard.fromJson(Map<String, dynamic> json) {
    return PatchedBoard(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    return map;
  }
}

class PatchedHabit {
  final String? name;
  final String? description;
  final FrequencyEnum? frequency;
  final bool? isActive;
  final String? board;

  PatchedHabit({
    this.name,
    this.description,
    this.frequency,
    this.isActive,
    this.board,
  });

  factory PatchedHabit.fromJson(Map<String, dynamic> json) {
    return PatchedHabit(
      name: json['name'] as String?,
      description: json['description'] as String?,
      frequency: json['frequency'] != null
          ? FrequencyEnum.fromString(json['frequency'] as String)
          : null,
      isActive: json['is_active'] as bool?,
      board: json['board'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (frequency != null) map['frequency'] = frequency!.value;
    if (isActive != null) map['is_active'] = isActive;
    if (board != null) map['board'] = board;
    return map;
  }
}

class PatchedUser {
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;

  PatchedUser({this.username, this.email, this.firstName, this.lastName});

  factory PatchedUser.fromJson(Map<String, dynamic> json) {
    return PatchedUser(
      username: json['username'] as String?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map['username'] = username;
    if (email != null) map['email'] = email;
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    return map;
  }
}
