import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:life_flow/core/constants.dart';
import 'package:life_flow/features/finance/domain/transaction_model.dart';
import 'package:life_flow/features/finance/domain/budget_model.dart';
import 'package:life_flow/features/finance/domain/wallet_model.dart';

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

  Future<void> updateTransaction(Transaction oldTx, Transaction newTx) async {
    final box = Hive.box<Transaction>(AppConstants.financeBox);
    // Find index to maintain order and overwrite correctly
    final index = box.values.toList().indexWhere((t) => t.id == oldTx.id);
    if (index != -1) {
      final key = box.keyAt(index);
      await box.put(key, newTx);
      state = box.values.toList();
    }
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

// ─── Wallet Providers ──────────────────────────────────────────────────

class WalletNotifier extends Notifier<List<Wallet>> {
  @override
  List<Wallet> build() {
    final box = Hive.box<Wallet>(AppConstants.walletBox);
    if (box.isEmpty) {
      final defaultWallet = Wallet(
        id: const Uuid().v4(),
        name: 'Cash',
        iconKey: 'cash',
        initialBalance: 0.0,
      );
      box.add(defaultWallet);
    }
    return box.values.toList();
  }

  Future<void> addWallet(Wallet wallet) async {
    final box = Hive.box<Wallet>(AppConstants.walletBox);
    await box.add(wallet);
    state = box.values.toList();
  }

  Future<void> updateWallet(Wallet oldWallet, Wallet updatedWallet) async {
    final box = Hive.box<Wallet>(AppConstants.walletBox);
    final index = box.values.toList().indexWhere((w) => w.id == oldWallet.id);
    if (index != -1) {
      final key = box.keyAt(index);
      await box.put(key, updatedWallet);
      state = box.values.toList();
    }
  }

  Future<void> deleteWallet(Wallet wallet) async {
    await wallet.delete();
    state = state.where((w) => w.key != wallet.key).toList();
  }
}

final walletNotifierProvider = NotifierProvider<WalletNotifier, List<Wallet>>(
  WalletNotifier.new,
);

final walletBalanceProvider = Provider.family<double, String>((ref, walletId) {
  final transactions = ref.watch(financeNotifierProvider);
  final wallets = ref.watch(walletNotifierProvider);
  
  double initialBalance = 0.0;
  try {
    final wallet = wallets.firstWhere((w) => w.id == walletId);
    initialBalance = wallet.initialBalance;
  } catch (_) {}

  return transactions
      .where((t) => t.walletId == walletId)
      .fold(initialBalance, (sum, t) => t.isExpense ? sum - t.amount : sum + t.amount);
});
