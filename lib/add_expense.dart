// Stateful widget
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';
import 'package:habits/utils.dart';
import 'package:material_segmented_list/material_segmented_list.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('AddExpense');

void showAddExpenseSheet(
  BuildContext context, {
  Expense? expense,
  Function? onSaved,
}) {
  if (!kIsWeb && Platform.isIOS) {
    Navigator.push(
      context,
      CupertinoModalSheetRoute(
        swipeDismissible: true,
        builder: (context) => PopScope(
          child: Sheet(
            physics: BouncingSheetPhysics(),
            snapGrid: SheetSnapGrid.single(snap: SheetOffset(1)),
            decoration: MaterialSheetDecoration(
              size: SheetSize.fit,
              borderRadius:
                  (Theme.of(context).bottomSheetTheme.shape
                          as RoundedRectangleBorder?)
                      ?.borderRadius,
              clipBehavior: Clip.antiAlias,
            ),
            child: AddExpenseSheet(expense: expense, onSaved: onSaved),
          ),
        ),
      ),
    );
  } else {
    Navigator.push(
      context,
      ModalSheetRoute(
        swipeDismissible: true,
        builder: (context) => PopScope(
          child: Sheet(
            physics: BouncingSheetPhysics(),
            snapGrid: SheetSnapGrid.single(snap: SheetOffset(1)),
            decoration: MaterialSheetDecoration(
              size: SheetSize.fit,
              borderRadius:
                  (Theme.of(context).bottomSheetTheme.shape
                          as RoundedRectangleBorder?)
                      ?.borderRadius,
              // borderRadius: BorderRadius.circular(25),
              clipBehavior: Clip.antiAlias,
            ),
            child: AddExpenseSheet(expense: expense, onSaved: onSaved),
          ),
        ),
      ),
    );
  }
}

void showEditExpensePage(
  BuildContext context, {
  Expense? expense,
  Function? onSaved,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddExpenseSheet(expense: expense, onSaved: onSaved),
    ),
  );
}

class ParticipantsSection extends StatelessWidget {
  final List<Participants> participants;
  final SplitTypeEnum splitType;
  final VoidCallback onParticipantChanged;
  final Function(SplitTypeEnum)? onSplitTypeChanged;

  const ParticipantsSection({
    super.key,
    required this.participants,
    required this.splitType,
    required this.onParticipantChanged,
    this.onSplitTypeChanged,
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

    return SegmentedListSection(
      children: [
        if (onSplitTypeChanged != null)
          SegmentedListTile(
            minVerticalPadding: 2,
            title: SegmentedButton(
              segments: [
                ButtonSegment(
                  value: SplitTypeEnum.equal,
                  label: const Text("Equal"),
                ),
                ButtonSegment(
                  value: SplitTypeEnum.percentage,
                  label: const Text("Percent"),
                ),
                ButtonSegment(
                  value: SplitTypeEnum.amount,
                  label: const Text("Amount"),
                ),
              ],
              selected: {splitType},
              onSelectionChanged: (p0) => onSplitTypeChanged!(p0.first),
            ),
          ),
        for (var member in participants)
          SegmentedListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: member.isActive,
                    onChanged: (val) {
                      member.isActive = val ?? false;
                      onParticipantChanged();
                    },
                  ),
                ),
                Text(
                  member.user.firstName != null &&
                          member.user.firstName!.isNotEmpty
                      ? member.user.firstName!
                      : member.user.username,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            trailing: SizedBox(
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
          ),
      ],
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
  final Expense? expense;
  final Function? onSaved;

  const AddExpenseSheet({super.key, this.expense, this.onSaved});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  ExpenseCategory? _selectedCategory;
  SplitTypeEnum _splitType = SplitTypeEnum.equal;
  List<Participants> _participants = [];
  User? _selectedPayer;

  late ApiClient apiClient;
  late Board currentBoard;

  bool isLoading = false;
  bool descValid = false;
  bool amountValid = false;

  @override
  void initState() {
    super.initState();
    apiClient = getIt.get<ApiClient>();
    currentBoard = getIt.get<CurrentBoardRepository>().currentBoard.value!;
    final currentUser = getIt.get<CurrentUserRepository>().currentUser.value!;
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedCategory = widget.expense!.category;
      _splitType = widget.expense!.splitType;
      _selectedPayer = widget.expense!.payer;
      setDate(widget.expense!.date);
    } else {
      _selectedPayer = currentUser;
      setDate(DateTime.now());
    }
    _initializeParticipants(currentBoard);
    descValid = _descriptionController.text.isNotEmpty;
    amountValid = double.tryParse(_amountController.text) != null;
    // Listen for amount changes to recalculate participant splits
    _descriptionController.addListener(() {
      setState(() {
        descValid = _descriptionController.text.isNotEmpty;
      });
    });
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
    setState(() {
      amountValid = double.tryParse(sanitized) != null;
    });
  }

  void _initializeParticipants(Board board) {
    // Dispose old controllers
    for (var p in _participants) {
      p.dispose();
    }

    if (widget.expense?.splits != null && widget.expense!.splits.isNotEmpty) {
      _participants = widget.expense!.splits
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
            (user) => !widget.expense!.splits.any(
              (split) => split.user.id == user.id,
            ),
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
      // Set controller texts directly from stored split values
      for (var p in _participants) {
        if (!p.isActive) {
          p.controller.text = '0.00';
        } else if (_splitType == SplitTypeEnum.percentage) {
          p.controller.text = (p.percentage ?? 0.0).toStringAsFixed(2);
        } else {
          p.controller.text = p.amount.toStringAsFixed(2);
        }
      }
      _participants.sort((a, b) => a.user.username.compareTo(b.user.username));
      return;
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
      if (_splitType == SplitTypeEnum.equal) {
        _updateControllerValues();
      }
    });
  }

  void setDate(DateTime date) {
    _dateController.text = datetimeToLocalHRFormat(date);
  }

  void _sendDataUpdate() async {
    setState(() {
      isLoading = true;
    });
    // Collect data and send to API
    // if (currentBoard == null) return;
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    String description = _descriptionController.text;

    if (!descValid) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        "Description can't be empty",
        type: AlertType.error,
      );
      return;
    }

    if (!amountValid) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        "Amount must be a valid number",
        type: AlertType.error,
      );
      return;
    }

    if (widget.expense != null) {
      // Update existing expense
      try {
        await apiClient.updateExpense({
          'amount': amount,
          'description': description,
          'category_id': _selectedCategory?.id,
          'date': selectedDate.toIso8601String().split('T')[0],
          'split_type': _splitType.value,
          'payer_id': _selectedPayer?.id,
          'splits': _participants
              .where((p) => p.isActive)
              .map(
                (p) => {
                  'user': p.user.id,
                  if (_splitType == SplitTypeEnum.percentage)
                    'percentage': p.percentage ?? 0.0,
                  'share_amount': p.amount.toStringAsFixed(2),
                },
              )
              .toList(),
        }, widget.expense!.id);
      } on DioException catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          showSnackBar(
            context,
            'Failed to update expense: ${ApiClient.parseDjangoErrorMessage(e)}',
            type: AlertType.error,
          );
        }
        return;
      }
    } else {
      try {
        // Create new expense
        await apiClient.createExpense({
          'amount': amount,
          'description': description,
          'category_id': _selectedCategory?.id,
          'date': selectedDate.toIso8601String().split('T')[0],
          'split_type': _splitType.value,
          'payer_id': _selectedPayer?.id,
          'splits': _participants
              .where((p) => p.isActive)
              .map(
                (p) => {
                  'user': p.user.id,
                  if (_splitType == SplitTypeEnum.percentage)
                    'percentage': p.percentage ?? 0.0,
                  'share_amount': p.amount.toStringAsFixed(2),
                },
              )
              .toList(),
        }, currentBoard.id);
      } on DioException catch (e) {
        setState(() {
          isLoading = false;
        });
        _log.warning(
          'Failed to create expense: ${ApiClient.parseDjangoErrorMessage(e)}',
        );
        if (mounted) {
          showSnackBar(
            context,
            'Failed to create expense: ${ApiClient.parseDjangoErrorMessage(e)}',
            type: AlertType.error,
          );
        }
        return;
      }
    }
    setState(() {
      isLoading = false;
    });
    if (mounted) {
      Navigator.of(context).pop();
      showSnackBar(
        context,
        widget.expense != null ? "Expense updated!" : "Expense saved!",
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
        // automaticallyImplyLeading: false,
        // primary: false,
        centerTitle: true,
        title: Text(widget.expense != null ? 'Edit expense' : 'New expense'),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          else
            TextButton(
              onPressed: descValid && amountValid ? _sendDataUpdate : null,
              child: const Text("Save"),
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
                child: AbsorbPointer(
                  absorbing: isLoading,
                  child: AnimatedOpacity(
                    opacity: isLoading ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
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
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              isDense: false,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final textScaler = MediaQuery.textScalerOf(
                                context,
                              );
                              final fontSize =
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.fontSize ??
                                  16.0;
                              // height = half floating-label (sits on top border)
                              //        + contentPadding top + content + contentPadding bottom
                              final height =
                                  textScaler.scale(fontSize * 0.75) / 2 +
                                  32 +
                                  textScaler.scale(fontSize);
                              return SizedBox(
                                height: height,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _amountController,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: false,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Amount',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 12,
                                          ),
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
                                      flex: 3,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: DropdownButtonFormField<String?>(
                                          initialValue: _selectedCategory?.id,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: "Category",
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.fromLTRB(
                                              12,
                                              14,
                                              12,
                                              14,
                                            ),
                                          ),
                                          items: [
                                            const DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text("None"),
                                            ),
                                            for (var category
                                                in currentBoard
                                                        ?.expenseCategories ??
                                                    <ExpenseCategory>[])
                                              DropdownMenuItem<String?>(
                                                value: category.id,
                                                child: Text(
                                                  "${category.emoji} ${category.name}",
                                                ),
                                              ),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == null) {
                                                _selectedCategory = null;
                                              } else {
                                                _selectedCategory = currentBoard
                                                    ?.expenseCategories
                                                    .firstWhere(
                                                      (c) => c.id == value,
                                                    );
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Builder(
                            builder: (context) {
                              final textScaler = MediaQuery.textScalerOf(
                                context,
                              );
                              final fontSize =
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.fontSize ??
                                  16.0;
                              // height = half floating-label (sits on top border)
                              //        + contentPadding top + content + contentPadding bottom
                              final height =
                                  textScaler.scale(fontSize * 0.75) / 2 +
                                  32 +
                                  textScaler.scale(fontSize);

                              return SizedBox(
                                height: height,
                                child: Row(
                                  spacing: 12,
                                  children: [
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: TextFormField(
                                          controller: _dateController,
                                          decoration: InputDecoration(
                                            labelText: "Date",
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 16,
                                                  horizontal: 12,
                                                ),
                                          ),
                                          readOnly:
                                              true, // Prevents keyboard from showing
                                          onTap: () async {
                                            DateTime? pickedDate =
                                                await showDatePicker(
                                                  context: context,
                                                  initialDate: selectedDate,
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2101),
                                                );

                                            if (pickedDate != null) {
                                              // Update controller with formatted date
                                              setDate(pickedDate);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    if (currentBoard != null)
                                      Expanded(
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child:
                                              DropdownButtonFormField<String>(
                                                initialValue:
                                                    _selectedPayer?.id,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: "Paid by",
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.fromLTRB(
                                                            12,
                                                            14,
                                                            12,
                                                            14,
                                                          ),
                                                    ),
                                                items: [
                                                  for (var user
                                                      in currentBoard.users)
                                                    DropdownMenuItem<String>(
                                                      value: user.id,
                                                      child: Text(user.name),
                                                    ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedPayer =
                                                        currentBoard.users
                                                            .firstWhere(
                                                              (u) =>
                                                                  u.id == value,
                                                            );
                                                  });
                                                },
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          currentBoard != null
                              ? ParticipantsSection(
                                  participants: _participants,
                                  splitType: _splitType,
                                  onParticipantChanged: _onParticipantChanged,
                                  onSplitTypeChanged: (splitType) {
                                    setState(() {
                                      _splitType = splitType;
                                      _updateControllerValues();
                                    });
                                  },
                                )
                              : const SizedBox.shrink(),
                          if (widget.expense != null)
                            Column(
                              spacing: 14,
                              children: [
                                Text(
                                  "Created at ${widget.expense!.createdAt.toLocal()}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                SegmentedListSection(
                                  children: [
                                    SegmentedListTile(
                                      leading: const Text("Delete"),
                                      textColor: Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                      trailing: SegmentedListChevron(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                      ),
                                      onTap: () {
                                        showConfirmationDialog(
                                          context,
                                          title:
                                              "Are you sure you want to delete this expense?",
                                          content:
                                              "This action cannot be undone.",
                                          isDestructive: true,
                                          onConfirm: () async {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            try {
                                              await apiClient.deleteExpense(
                                                widget.expense!.id,
                                              );
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                                showSnackBar(
                                                  context,
                                                  "Expense deleted!",
                                                );
                                                widget.onSaved?.call();
                                              }
                                            } on DioException catch (e) {
                                              setState(() {
                                                isLoading = false;
                                              });
                                              if (context.mounted) {
                                                showSnackBar(
                                                  context,
                                                  "Error! ${ApiClient.parseDjangoErrorMessage(e)}",
                                                  type: AlertType.error,
                                                );
                                              }
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
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
