import 'package:drops/drops.dart';
import 'package:flutter/material.dart';
import 'package:habits/add_expense.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';
import 'package:habits/utils.dart';
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
  showModalBottomSheet(
    context: context,
    // isScrollControlled: true,
    // showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.all(12),
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
                      title: const Text("Delete", textAlign: TextAlign.center),
                      tileColor: Colors.redAccent,
                      textColor: Colors.black,
                      minVerticalPadding: 0,
                      onTap: () {
                        // Navigator.of(context).pop();
                        showConfirmationDialog(
                          context,
                          title:
                              "Are you sure you want to delete this expense?",
                          isDestructive: true,
                          onConfirm: () async {
                            // final boardRepository =
                            // getIt.get<CurrentBoardRepository>();
                            Navigator.of(context).pop();
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
        Drops.show(
          context,
          title: "Data refreshed",
          icon: Icons.refresh_rounded,
        );
      }
    }

    callOnce((_) => pullRefresh(showFeedback: false));

    return Scaffold(
      // extendBodyBehindAppBar: true,
      // extendBody: true,
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: activeBoard != null
              ? () {
                  // show board switcher
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Column(
              children: [
                Text('Expenses'),
                if (activeBoard != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        activeBoard.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stacked_bar_chart_rounded),
            onPressed: () {
              Drops.show(
                context,
                title: "WIP!",
                subtitle:
                    "Statistics aren't available yet!\nCome back later <3",
                subtitleMaxLines: 2,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.amber,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddExpenseSheet(context);
        },
        elevation: 1,
        child: Icon(Icons.add),
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
                    child: SegmentedListSection(
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
                              foregroundDecoration: expense.category == null
                                  ? BoxDecoration(
                                      color: Colors.grey,
                                      backgroundBlendMode: BlendMode.saturation,
                                    )
                                  : null,
                              child: Text(
                                expense.category?.emoji ?? '💰',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 1,
                              children: [
                                Text(
                                  expense.description ?? '???',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  datetimeToLocalHRFormat(
                                    expense.createdAt.toLocal(),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                  style: Theme.of(context).textTheme.bodySmall,
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
