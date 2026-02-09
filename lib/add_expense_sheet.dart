// Stateful widget
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';
import 'package:habits/utils.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:watch_it/watch_it.dart';

void showAddExpenseSheet(
  BuildContext context, {
  Expense? expense,
  Function? onSaved,
}) {
  Navigator.push(
    context,
    CupertinoModalSheetRoute(
      // fullscreenDialog: false,
      swipeDismissible: true,
      builder: (context) => PopScope(
        child: Sheet(
          physics: BouncingSheetPhysics(),
          snapGrid: SheetSnapGrid.single(snap: SheetOffset(1)),
          decoration: MaterialSheetDecoration(
            size: SheetSize.fit,
            borderRadius: BorderRadius.circular(25),
            clipBehavior: Clip.antiAlias,
          ),
          child: AddExpenseSheet(expense: expense, onSaved: onSaved),
        ),
      ),
    ),
  );
}

class ParticipantsSection extends StatelessWidget {
  final List<Participants> participants;
  final SplitTypeEnum splitType;
  final VoidCallback onParticipantChanged;

  const ParticipantsSection({
    super.key,
    required this.participants,
    required this.splitType,
    required this.onParticipantChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Text(
          "No members in this board",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: participants
          .map(
            (member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: member.isActive,
                    onChanged: (val) {
                      member.isActive = val ?? false;
                      onParticipantChanged();
                    },
                  ),
                  Expanded(
                    child: Text(
                      member.user.firstName != null &&
                              member.user.firstName!.isNotEmpty
                          ? member.user.firstName!
                          : member.user.username,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: member.controller,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        labelText: splitType == SplitTypeEnum.percentage
                            ? "Percent"
                            : "Amount",
                        border: OutlineInputBorder(),
                        isDense: true,
                        enabled: splitType != SplitTypeEnum.equal,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      onChanged: (value) {
                        if (splitType == SplitTypeEnum.percentage) {
                          member.percentage = double.tryParse(value) ?? 0.0;
                        } else {
                          member.amount = double.tryParse(value) ?? 0.0;
                        }
                        onParticipantChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class Participants {
  bool isActive;
  double? percentage;
  double amount;
  User user;
  late TextEditingController controller;

  void handleTextChange() {
    // remove all non-numeric characters except dot and disallow more than one dot
    String text = controller.text;
    String sanitized = text
        .replaceAll(RegExp(r','), '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    int dotCount = '.'.allMatches(sanitized).length;
    if (dotCount > 1) {
      int firstDotIndex = sanitized.indexOf('.');
      sanitized =
          sanitized.substring(0, firstDotIndex + 1) +
          sanitized
              .substring(firstDotIndex + 1)
              .replaceAll('.', ''); // remove extra dots
    }
    if (sanitized != text) {
      controller.value = controller.value.copyWith(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
  }

  Participants({
    required this.user,
    this.isActive = false,
    this.percentage,
    this.amount = 0.0,
  }) {
    controller = TextEditingController();
    controller.addListener(handleTextChange);
  }

  void dispose() {
    controller.removeListener(handleTextChange);
    controller.dispose();
  }
}

class AddExpenseSheet extends WatchingStatefulWidget {
  Expense? expense;
  Function? onSaved;
  AddExpenseSheet({super.key, this.expense, this.onSaved});

  @override
  State<AddExpenseSheet> createState() =>
      _AddExpenseSheetState(expense: expense);
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  ExpenseCategory? _selectedCategory;
  SplitTypeEnum _splitType = SplitTypeEnum.equal;
  List<Participants> _participants = [];

  late ApiClient apiClient;
  late Board currentBoard;

  bool isLoading = false;

  Expense? expense;

  _AddExpenseSheetState({this.expense});

  @override
  void initState() {
    super.initState();
    apiClient = getIt.get<ApiClient>();
    currentBoard = getIt.get<CurrentBoardRepository>().currentBoard.value!;
    if (expense != null) {
      _amountController.text = expense!.amount.toStringAsFixed(2);
      _descriptionController.text = expense!.description!;
      _selectedCategory = expense!.category;
      _splitType = expense!.splitType;
    }
    // Listen for amount changes to recalculate participant splits
    _amountController.addListener(handleTextChange);
    _amountController.addListener(() {
      if (_participants.isNotEmpty) {
        _updateControllerValues();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(handleTextChange);
    _amountController.dispose();
    _descriptionController.dispose();
    for (var p in _participants) {
      p.dispose();
    }
    super.dispose();
  }

  void handleTextChange() {
    // remove all non-numeric characters except dot and disallow more than one dot
    String text = _amountController.text;
    String sanitized = text
        .replaceAll(RegExp(r','), '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    int dotCount = '.'.allMatches(sanitized).length;
    if (dotCount > 1) {
      int firstDotIndex = sanitized.indexOf('.');
      sanitized =
          sanitized.substring(0, firstDotIndex + 1) +
          sanitized
              .substring(firstDotIndex + 1)
              .replaceAll('.', ''); // remove extra dots
    }
    if (sanitized != text) {
      _amountController.value = _amountController.value.copyWith(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
  }

  void _initializeParticipants(Board board) {
    // Dispose old controllers
    for (var p in _participants) {
      p.dispose();
    }

    if (expense?.splits != null && expense!.splits.isNotEmpty) {
      _participants = expense!.splits
          .map(
            (split) => Participants(
              user: split.user,
              isActive: true,
              amount: split.shareAmount,
              percentage: split.percentage,
            ),
          )
          .toList();
      _participants += board.users
          .where(
            (user) => !expense!.splits.any((split) => split.user.id == user.id),
          )
          .map(
            (user) => Participants(
              isActive: false,
              user: user,
              amount: 0.0,
              percentage: 0.0,
            ),
          )
          .toList();
    } else {
      final splitAmount = board.users.isEmpty
          ? 0.0
          : (double.tryParse(_amountController.text) ?? 0.0) /
                board.users.length;
      _participants = board.users
          .map(
            (user) => Participants(
              isActive: true,
              user: user,
              amount: splitAmount,
              percentage: _splitType == SplitTypeEnum.percentage
                  ? 100 / board.users.length
                  : null,
            ),
          )
          .toList();
    }

    _updateControllerValues();
    _participants.sort((a, b) => a.user.username.compareTo(b.user.username));
  }

  void _updateControllerValues() {
    final activeCount = _participants.where((p) => p.isActive).length;
    final total = double.tryParse(_amountController.text) ?? 0.0;

    for (var p in _participants) {
      if (!p.isActive) {
        p.controller.text = '0.00';
      } else if (_splitType == SplitTypeEnum.percentage) {
        final evenPercentage = activeCount == 0 ? 0.0 : 100.0 / activeCount;
        p.percentage = evenPercentage;
        p.controller.text = evenPercentage.toStringAsFixed(2);
      } else if (_splitType == SplitTypeEnum.equal) {
        final evenAmount = activeCount == 0 ? 0.0 : total / activeCount;
        p.amount = evenAmount;
        p.controller.text = evenAmount.toStringAsFixed(2);
      } else {
        final evenAmount = activeCount == 0 ? 0.0 : total / activeCount;
        p.amount = evenAmount;
        p.controller.text = evenAmount.toStringAsFixed(2);
      }
    }
  }

  void _onParticipantChanged() {
    setState(() {
      _updateControllerValues();
    });
  }

  void _sendDataUpdate() async {
    setState(() {
      isLoading = true;
    });
    // Collect data and send to API
    // if (currentBoard == null) return;
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String description = _descriptionController.text;

    User currentUser = getIt
        .get<CurrentUserRepository>()
        .currentUser
        .value!; // Assuming user is logged in

    if (widget.expense != null) {
      // Update existing expense
      try {
        await apiClient.updateExpense({
          'amount': amount,
          'description': description,
          'category_id': _selectedCategory?.id,
          'split_type': _splitType.value,
          // 'board': currentBoard.id,
          'payer_id': currentUser.id,
          'splits': _participants
              .where((p) => p.isActive)
              .map(
                (p) => {
                  'user': p.user.id,
                  if (_splitType == SplitTypeEnum.percentage)
                    'percentage': p.percentage ?? 0.0,
                  'share_amount': p.amount,
                },
              )
              .toList(),
        }, widget.expense!.id);
      } on DioException catch (e) {
        print((e as DioException).response?.data);
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update expense: $e')),
          );
        }
      }
    } else {
      // Create new expense
      await apiClient.createExpense({
        'amount': amount,
        'description': description,
        'category_id': _selectedCategory?.id,
        'split_type': _splitType.value,
        // 'board': currentBoard.id,
        'payer_id': currentUser.id,
        'splits': _participants
            .where((p) => p.isActive)
            .map(
              (p) => {
                'user': p.user.id,
                if (_splitType == SplitTypeEnum.percentage)
                  'percentage': p.percentage ?? 0.0,
                'share_amount': p.amount,
              },
            )
            .toList(),
      }, currentBoard.id);
    }
    setState(() {
      isLoading = false;
    });
    if (mounted) {
      Navigator.of(context).pop();
      showSnackBar(
        context,
        Text(expense != null ? "Expense updated!" : "Expense saved!"),
        clearExisting: true,
      );
    }
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    var currentBoard = watchValue(
      (CurrentBoardRepository br) => br.currentBoard,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        primary: false,
        centerTitle: true,
        title: Text(expense != null ? 'Edit expense' : 'New expense'),
        actions: [
          TextButton(
            onPressed: _sendDataUpdate,
            child: const Text(
              "Save",
              style: TextStyle(fontFamily: "BasteleurBold"),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.all(8),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Stack(
                  children: [
                    Container(
                      // color: Colors.red, // debug red, my favorite
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          TextField(
                            controller: _descriptionController,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                    prefix: Text(
                                      'E ',
                                      style: TextStyle(
                                        fontFamily: "BasteleurBold",
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _selectedCategory?.id,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSaved: (newValue) => {
                                    _selectedCategory = currentBoard
                                        ?.expenseCategories
                                        .firstWhere(
                                          (cat) => cat.id == newValue,
                                        ),
                                  },
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text("None"),
                                    ),
                                    ...(currentBoard?.expenseCategories
                                            .map(
                                              (cat) => DropdownMenuItem<String>(
                                                value: cat.id,
                                                child: Text(
                                                  "${cat.emoji} ${cat.name}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList() ??
                                        []),
                                  ],
                                  onChanged: (value) {
                                    // Handle category selection
                                    setState(() {
                                      _selectedCategory = currentBoard
                                          ?.expenseCategories
                                          .firstWhere((cat) => cat.id == value);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Participants",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "BasteleurBold",
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _splitType.value,
                                  decoration: const InputDecoration(
                                    labelText: "Split type",
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 12,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "equal",
                                      child: Text("Equal"),
                                    ),
                                    DropdownMenuItem(
                                      value: "percentage",
                                      child: Text("Percent"),
                                    ),
                                    DropdownMenuItem(
                                      value: "amount",
                                      child: Text("Amount"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _splitType = SplitTypeEnum.fromString(
                                        value!,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                            ),
                            child: currentBoard != null
                                ? Builder(
                                    builder: (context) {
                                      if (_participants.isEmpty) {
                                        _initializeParticipants(currentBoard);
                                      }
                                      return ParticipantsSection(
                                        participants: _participants,
                                        splitType: _splitType,
                                        onParticipantChanged:
                                            _onParticipantChanged,
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer.withOpacity(0.6),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
