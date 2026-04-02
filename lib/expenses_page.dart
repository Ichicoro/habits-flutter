import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habits/add_expense.dart';
import 'package:habits/service_locator.dart';
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
      if (showFeedback) {
        showSnackBar(context, Text("Data refreshed"));
      }
    }

    callOnce((_) => pullRefresh(showFeedback: false));

    return Scaffold(
      // extendBodyBehindAppBar: true,
      // extendBody: true,
      appBar: AppBar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceDim.withValues(alpha: 0.8),
        // flexibleSpace: ClipRect(
        //   child: BackdropFilter(
        //     filter: ImageFilter.blur(sigmaX: 15, sigmaY: 10),
        //     child: Container(color: Colors.transparent, height: 120),
        //   ),
        // ),
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
                        // style: TextStyle(
                        //   fontSize: 14,
                        //   // fontFamily: "BasteleurBold",
                        //   fontWeight: FontWeight.w400,
                        //   color: Theme.of(context).colorScheme.onSurfaceVariant,
                        // ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Add expense"),
        onPressed: () {
          showAddExpenseSheet(context);
        },
        icon: Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: pullRefresh,
        child: activeBoard == null
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        title: Text(
                          expense.description ?? '???',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          datetimeToLocalHRFormat(expense.createdAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () {
                          showEditExpensePage(
                            context,
                            expense: expense,
                            onSaved: () {
                              pullRefresh();
                            },
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
    );
  }
}
