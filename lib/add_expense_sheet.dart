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
  List<ExpenseSplit> _splits = [];

  late ApiClient apiClient;

  Expense? expense;

  _AddExpenseSheetState({this.expense});

  @override
  void initState() {
    super.initState();
    apiClient = getIt.get<ApiClient>();
    CurrentBoardRepository boardRepository = getIt
        .get<CurrentBoardRepository>();
    if (expense != null) {
      _amountController.text = expense!.amount.toStringAsFixed(2);
      _descriptionController.text = expense!.description!;
      _selectedCategory = expense!.category;
      _splitType = expense!.splitType;
      _splits = expense!.splits;
    } else {
      var board = boardRepository.currentBoard.value;
      if (board == null) {
        return;
      }
      _splitType = SplitTypeEnum.equal;
      _splits =
          boardRepository.currentBoard.value?.users
              .map(
                (user) => ExpenseSplit(
                  id: "",
                  user: user,
                  shareAmount: 0,
                  percentage: board.users.length / 100,
                ),
              )
              .toList() ??
          [];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildParticipantsSection(Board? board) {
    if (board == null) {
      return const SizedBox.shrink();
    }

    final users = board.users;

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
      children: users
          .map(
            (member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _splits.any((s) => s.user.id == member.id),
                    onChanged: (val) {
                      setState(() {
                        // Handle split checkbox
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      member.firstName != null && member.firstName!.isNotEmpty
                          ? member.firstName!
                          : member.username,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        labelText: _splitType == SplitTypeEnum.amount
                            ? "Amount"
                            : "Percent",
                        border: OutlineInputBorder(),
                        isDense: true,
                        enabled: _splitType != SplitTypeEnum.equal,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
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
            onPressed: () {},
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
                        child: _buildParticipantsSection(currentBoard),
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
