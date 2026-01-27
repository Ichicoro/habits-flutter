// Stateful widget
import 'package:flutter/material.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:watch_it/watch_it.dart';

void showAddExpenseSheet(BuildContext context, {Expense? expense}) {
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
          child: AddExpenseSheet(expense: expense),
        ),
      ),
    ),
  );
}

class ParticipantsSection extends StatefulWidget {
  final Board board;
  final SplitTypeEnum splitType;
  final List<ExpenseSplit>? splits;
  final double total;

  const ParticipantsSection({
    super.key,
    required this.board,
    required this.splitType,
    required this.total,
    this.splits,
  });

  @override
  State<ParticipantsSection> createState() => _ParticipantsSectionState();
}

class Participants {
  bool isActive;
  double? percentage;
  double amount;
  User user;
  late TextEditingController controller;

  Participants({
    required this.user,
    this.isActive = false,
    this.percentage,
    this.amount = 0.0,
  }) {
    controller = TextEditingController();
  }

  void dispose() {
    controller.dispose();
  }
}

class _ParticipantsSectionState extends State<ParticipantsSection> {
  List<Participants> participants = [];

  @override
  void dispose() {
    for (var p in participants) {
      p.dispose();
    }
    super.dispose();
  }

  void updateValues() {
    // Dispose old controllers
    for (var p in participants) {
      p.dispose();
    }

    if (widget.splits != null && widget.splits!.isNotEmpty) {
      participants = widget.splits!
          .map(
            (split) => Participants(
              user: split.user,
              isActive: true,
              amount: split.shareAmount,
              percentage: split.percentage,
            ),
          )
          .toList();
      participants += widget.board.users
          .where(
            (user) => !widget.splits!.any((split) => split.user.id == user.id),
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
      final splitAmount = widget.board.users.isEmpty
          ? 0.0
          : widget.total / widget.board.users.length;
      participants = widget.board.users
          .map(
            (user) => Participants(
              isActive: true,
              user: user,
              amount: splitAmount,
              percentage: widget.splitType == SplitTypeEnum.percentage
                  ? 100 / widget.board.users.length
                  : null,
            ),
          )
          .toList();
    }

    _updateControllerValues();
    participants.sort((a, b) => a.user.username.compareTo(b.user.username));
  }

  void _updateControllerValues() {
    final activeCount = participants.where((p) => p.isActive).length;

    for (var p in participants) {
      if (!p.isActive) {
        p.controller.text = '0.00';
      } else if (widget.splitType == SplitTypeEnum.percentage) {
        // Even split: 100% divided among active participants
        final evenPercentage = activeCount == 0 ? 0.0 : 100.0 / activeCount;
        p.percentage = evenPercentage;
        p.controller.text = evenPercentage.toStringAsFixed(2);
      } else if (widget.splitType == SplitTypeEnum.equal) {
        // Even split: total divided among active participants
        final evenAmount = activeCount == 0 ? 0.0 : widget.total / activeCount;
        p.amount = evenAmount;
        p.controller.text = evenAmount.toStringAsFixed(2);
      } else {
        // SplitTypeEnum.amount: even split by total divided among active
        final evenAmount = activeCount == 0 ? 0.0 : widget.total / activeCount;
        p.amount = evenAmount;
        p.controller.text = evenAmount.toStringAsFixed(2);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    updateValues();
  }

  @override
  void didUpdateWidget(covariant ParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateValues();
  }

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    final users = widget.board.users;

    if (users.isEmpty) {
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
                      setState(() {
                        member.isActive = val ?? false;
                        _updateControllerValues();
                      });
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
                        labelText: widget.splitType == SplitTypeEnum.percentage
                            ? "Percent"
                            : "Amount",
                        border: OutlineInputBorder(),
                        isDense: true,
                        enabled: widget.splitType != SplitTypeEnum.equal,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (widget.splitType == SplitTypeEnum.percentage) {
                            member.percentage = double.tryParse(value) ?? 0.0;
                          } else {
                            member.amount = double.tryParse(value) ?? 0.0;
                          }
                        });
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

class AddExpenseSheet extends WatchingStatefulWidget {
  Expense? expense;
  AddExpenseSheet({super.key, this.expense});

  @override
  State<AddExpenseSheet> createState() =>
      _AddExpenseSheetState(expense: expense);
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  ExpenseCategory? _selectedCategory;
  SplitTypeEnum _splitType = SplitTypeEnum.equal;

  late ApiClient apiClient;

  Expense? expense;

  _AddExpenseSheetState({this.expense});

  @override
  void initState() {
    super.initState();
    apiClient = getIt.get<ApiClient>();
    if (expense != null) {
      _amountController.text = expense!.amount.toStringAsFixed(2);
      _descriptionController.text = expense!.description!;
      _selectedCategory = expense!.category;
      _splitType = expense!.splitType;
    }
    // Listen for amount changes to recalculate participant splits
    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _sendDataUpdate() async {
    // Collect data and send to API
    var currentBoard = watchValue(
      (CurrentBoardRepository br) => br.currentBoard,
    );
    if (currentBoard == null) return;
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String description = _descriptionController.text;

    if (widget.expense != null) {
      // Update existing expense
      await apiClient.updateExpense({
        'amount': amount,
        'description': description,
        'category_id': _selectedCategory?.id,
        'split_type': _splitType.value,
      }, widget.expense!.id);
    } else {
      // Create new expense
      await apiClient.createExpense({
        'amount': amount,
        'description': description,
        'category_id': _selectedCategory?.id,
        'split_type': _splitType.value,
      }, currentBoard.id);
    }
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
            onPressed: () async {},
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
                child: Container(
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
                                    .firstWhere((cat) => cat.id == newValue),
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
                                              overflow: TextOverflow.ellipsis,
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
                                  _splitType = SplitTypeEnum.fromString(value!);
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
                          color: Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        child: currentBoard != null
                            ? ParticipantsSection(
                                board: currentBoard,
                                total:
                                    double.tryParse(_amountController.text) ??
                                    0.0,
                                splitType: _splitType,
                                splits: expense?.splits,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
