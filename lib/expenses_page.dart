import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:habits/add_expense.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';
import 'package:habits/utils.dart';
import 'package:habits/widgets/title_with_board_picker.dart';
import 'package:material_segmented_list/material_segmented_list.dart';
import 'package:watch_it/watch_it.dart';

class MoneyTextSpan extends StatelessWidget {
  final double amount;

  const MoneyTextSpan({Key? key, required this.amount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        children: [
          TextSpan(
            text: 'E ',
            style: TextStyle(fontFamily: "BasteleurBold", fontSize: 12),
          ),
          TextSpan(
            text: amount.toStringAsFixed(2),
            style: TextStyle(
              fontFamily: "BasteleurBold",
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

void showHoldExpenseBottomSheet(
  BuildContext context, {
  required Expense expense,
}) {
  var apiClient = getIt.get<ApiClient>();
  var boardRepository = getIt.get<CurrentBoardRepository>();

  showModalBottomSheet(
    context: context,
    // isScrollControlled: true,
    // showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        14,
        12,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  title: const Text("Edit", textAlign: TextAlign.center),
                  tileColor: tileColorForAlert(context),
                  minVerticalPadding: 0,
                  onTap: () {
                    Navigator.of(context).pop();
                    showEditExpensePage(
                      context,
                      expense: expense,
                      onSaved: () {},
                    );
                  },
                ),
                SegmentedListTile(
                  title: const Text("Share", textAlign: TextAlign.center),
                  tileColor: tileColorForAlert(context),
                  minVerticalPadding: 0,
                  onTap: () {
                    Navigator.of(context).pop();
                    showSnackBar(
                      context,
                      "Work in progress!",
                      type: AlertType.warning,
                    );
                  },
                ),
                SegmentedListTile(
                  title: const Text("Delete", textAlign: TextAlign.center),
                  tileColor: Colors.redAccent,
                  textColor: Colors.black,
                  minVerticalPadding: 0,
                  onTap: () {
                    // Navigator.of(context).pop();
                    showConfirmationDialog(
                      context,
                      title: "Are you sure you want to delete this expense?",
                      isDestructive: true,
                      onConfirm: () async {
                        try {
                          await apiClient.deleteExpense(expense.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            showSnackBar(context, "Expense deleted");
                            await boardRepository.updateData(forceReload: true);
                          }
                        } on DioException catch (e) {
                          if (context.mounted) {
                            showSnackBar(
                              context,
                              "Error deleting expense: ${ApiClient.parseDjangoErrorMessage(e)}",
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
            SizedBox(height: 16),
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  title: const Text("Cancel", textAlign: TextAlign.center),
                  tileColor: tileColorForAlert(context),
                  minVerticalPadding: 0,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ExpensesPage extends StatelessWidget with WatchItMixin {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boardRepository = getIt.get<CurrentBoardRepository>();

    var activeBoard = watchValue(
      (CurrentBoardRepository br) => br.currentBoard,
    );
    var expenses = watchValue((CurrentBoardRepository br) => br.expenses);
    // var boards = watchValue((CurrentBoardRepository br) => br.boards);

    Future<void> pullRefresh({bool showFeedback = true}) async {
      await boardRepository.updateData(forceReload: true);
      if (showFeedback && context.mounted) {
        showSnackBar(context, "Data refreshed");
      }
    }

    callOnce((_) => pullRefresh(showFeedback: false));

    return Scaffold(
      // extendBodyBehindAppBar: true,
      // extendBody: true,
      appBar: AppBar(
        title: TitleWithBoardPicker(title: "Expenses"),
        actions: [
          IconButton(
            icon: const Icon(Icons.stacked_bar_chart_rounded),
            onPressed: () {
              showSnackBar(
                context,
                "Statistics aren't available yet! Come back later ^¬^",
                type: AlertType.warning,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Add expense"),
        onPressed: () {
          showAddExpenseSheet(context);
        },
        // elevation: 10,
        icon: const Icon(Icons.add_rounded),
        shape: StadiumBorder(
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: pullRefresh,
        child: activeBoard == null
            ? Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  primary: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 16,
                    ),
                    child: (expenses.isEmpty)
                        ? Center(
                            child: Text(
                              "No expenses yet.\nTap the button below to add your first expense!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : SegmentedListSection(
                            children: [
                              for (var expense in expenses)
                                SegmentedListTile(
                                  minVerticalPadding: 12,
                                  key: ValueKey(expense.id),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 0,
                                  ),
                                  leading: Container(
                                    foregroundDecoration:
                                        expense.category == null
                                        ? BoxDecoration(
                                            color: Colors.grey,
                                            backgroundBlendMode:
                                                BlendMode.saturation,
                                          )
                                        : null,
                                    child: Text(
                                      expense.category?.emoji ?? '💰',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 1,
                                    children: [
                                      Text(
                                        expense.description ?? '???',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      Text(
                                        datetimeToLocalHRFormat(expense.date),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showEditExpensePage(
                                      context,
                                      expense: expense,
                                      onSaved: () {
                                        pullRefresh(showFeedback: false);
                                      },
                                    );
                                  },
                                  onLongPress: () {
                                    showHoldExpenseBottomSheet(
                                      context,
                                      expense: expense,
                                    );
                                  },
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 2,
                                    children: [
                                      MoneyTextSpan(amount: expense.amount),
                                      Text(
                                        "Paid by ${expense.payer.firstName}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
      ),
    );
  }
}
