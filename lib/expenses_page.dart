import 'package:flutter/material.dart';
import 'package:habits/add_expense_sheet.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/utils.dart';
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
    var boards = watchValue((CurrentBoardRepository br) => br.boards);

    Future<void> pullRefresh() async {
      await boardRepository.updateData(forceReload: true);
    }

    callOnce((_) => pullRefresh());

    return Scaffold(
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
                const Text('Expenses'),
                if (activeBoard != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        activeBoard.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "BasteleurBold",
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  var expense = expenses[index];
                  return ListTile(
                    leading: Icon(Icons.fastfood_rounded),
                    title: Text(expense.description ?? '???'),
                    subtitle: Text(
                      datetimeToLocalHRFormat(expense.createdAt.toLocal()),
                    ),
                    onTap: () {
                      showAddExpenseSheet(context, expense: expense);
                    },
                    trailing: MoneyTextSpan(amount: expense.amount),
                  );
                },
              ),
      ),
    );
  }
}
