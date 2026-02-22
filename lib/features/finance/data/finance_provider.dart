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
    return box.values.toList();
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
    return box.values.toList();
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
            (t.budgetCategory ?? t.category) == budget.categoryName &&
            !t.date.isBefore(budget.startDate) &&
            !t.date.isAfter(end),
      )
      .fold(0.0, (sum, t) => sum + t.amount);
});
