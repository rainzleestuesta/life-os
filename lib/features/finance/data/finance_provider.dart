import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:life_os/core/constants.dart';
import 'package:life_os/features/finance/domain/transaction_model.dart';
import 'package:life_os/features/finance/domain/budget_model.dart';

import 'dart:math' as math;
import 'package:uuid/uuid.dart';

class FinanceNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    final box = Hive.box<Transaction>(AppConstants.financeBox);
    if (box.isEmpty || box.length < 10) {
      box.clear();
      _seedDefaults(box);
    }
    return box.values.toList();
  }

  void _seedDefaults(Box<Transaction> box) {
    const uuid = Uuid();
    final random = math.Random();
    final today = DateTime.now();

    final categories = [
      'Groceries',
      'Transport',
      'Entertainment',
      'Dining',
      'Shopping',
    ];

    // Generate roughly 6 months of data
    for (int i = 180; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));

      // 1. Add salary on the 1st of every month
      if (date.day == 1) {
        box.add(
          Transaction(
            id: uuid.v4(),
            amount: 4500.0,
            category: 'Salary',
            isExpense: false,
            date: date,
          ),
        );
      }

      // 2. Add random expenses (mostly every day or every other day)
      // 70% chance to have an expense on a given day
      if (random.nextDouble() > 0.3) {
        // 1 to 3 transactions per day
        final txCount = random.nextInt(3) + 1;
        for (int j = 0; j < txCount; j++) {
          final isLargeExpense =
              random.nextDouble() > 0.9; // 10% chance for big expense
          final amount = isLargeExpense
              ? 100.0 +
                    random.nextInt(400) // $100 - $500
              : 5.0 + random.nextInt(45); // $5 - $50

          final category = categories[random.nextInt(categories.length)];

          box.add(
            Transaction(
              id: uuid.v4(),
              amount: amount.toDouble(),
              category: category,
              isExpense: true,
              date: date,
            ),
          );
        }
      }
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    final box = Hive.box<Transaction>(AppConstants.financeBox);
    await box.add(transaction);
    state = box.values.toList();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
    state = state.where((t) => t.key != transaction.key).toList();
  }
}

final financeNotifierProvider =
    NotifierProvider<FinanceNotifier, List<Transaction>>(FinanceNotifier.new);

// Derived state for totals
final totalBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(financeNotifierProvider);
  return transactions.fold(
    0,
    (sum, t) => t.isExpense ? sum - t.amount : sum + t.amount,
  );
});

final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(financeNotifierProvider);
  return transactions
      .where((t) => !t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);
});

final totalExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(financeNotifierProvider);
  return transactions
      .where((t) => t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);
});

class BudgetNotifier extends Notifier<List<Budget>> {
  @override
  List<Budget> build() {
    final box = Hive.box<Budget>(AppConstants.budgetBox);
    if (box.isEmpty) {
      _seedDefaults(box);
    }
    return box.values.toList();
  }

  void _seedDefaults(Box<Budget> box) {
    const uuid = Uuid();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    box.add(Budget(id: uuid.v4(), categoryName: 'Dining', monthlyLimit: 300.0, startDate: startOfMonth, endDate: endOfMonth));
    box.add(Budget(id: uuid.v4(), categoryName: 'Groceries', monthlyLimit: 400.0, startDate: startOfMonth, endDate: endOfMonth));
    box.add(Budget(id: uuid.v4(), categoryName: 'Entertainment', monthlyLimit: 150.0, startDate: startOfMonth, endDate: endOfMonth));
  }

  Future<void> addBudget(Budget budget) async {
    final box = Hive.box<Budget>(AppConstants.budgetBox);
    await box.add(budget);
    state = box.values.toList();
  }

  Future<void> updateBudget(Budget oldBudget, Budget updatedBudget) async {
    final box = Hive.box<Budget>(AppConstants.budgetBox);
    final index = box.values.toList().indexWhere((b) => b.id == oldBudget.id);
    if (index != -1) {
      final key = box.keyAt(index);
      await box.put(key, updatedBudget);
      state = box.values.toList();
    }
  }

  Future<void> deleteBudget(Budget budget) async {
    await budget.delete();
    state = state.where((b) => b.key != budget.key).toList();
  }
}

final budgetNotifierProvider = NotifierProvider<BudgetNotifier, List<Budget>>(
  BudgetNotifier.new,
);

// Calculate how much was spent in a specific budget's date range
final budgetSpendingProvider = Provider.family<double, Budget>((ref, budget) {
  final transactions = ref.watch(financeNotifierProvider);
  final end = budget.endDate ?? DateTime.now();

  return transactions
      .where(
        (t) =>
            t.isExpense &&
            t.category == budget.categoryName &&
            !t.date.isBefore(budget.startDate) &&
            !t.date.isAfter(end),
      )
      .fold(0.0, (sum, t) => sum + t.amount);
});
