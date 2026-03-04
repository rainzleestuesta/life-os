import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_flow/core/currency_provider.dart';
import 'package:life_flow/core/export_service.dart';
import 'package:life_flow/features/finance/data/finance_provider.dart';
import 'package:life_flow/features/finance/domain/transaction_model.dart';
import 'package:life_flow/features/finance/domain/budget_model.dart';
import 'package:life_flow/features/finance/domain/wallet_model.dart';
import 'package:life_flow/router.dart';
import 'package:uuid/uuid.dart';

class FinanceScreen extends HookConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(financeNotifierProvider);
    final wallets = ref.watch(walletNotifierProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Listen for "+" nav button trigger
    useEffect(() {
      void listener() {
        showTransactionSheet(context, ref);
      }

      addTransactionNotifier.addListener(listener);
      return () => addTransactionNotifier.removeListener(listener);
    }, const []);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Finance',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            // Currency picker button
                            InkWell(
                              onTap: () => _showCurrencyPicker(context, ref),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currency,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.expand_more_rounded, size: 16, color: cs.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your income & expenses',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Total Balance Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currency${totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BalanceStat(
                            label: 'Income',
                            amount: income,
                            icon: Icons.arrow_upward_rounded,
                            color: const Color(0xFF81C784),
                            currency: currency,
                          ),
                          Container(
                            height: 32,
                            width: 1,
                            color: Colors.white24,
                          ),
                          _BalanceStat(
                            label: 'Expenses',
                            amount: expense,
                            icon: Icons.arrow_downward_rounded,
                            color: const Color(0xFFEF9A9A),
                            currency: currency,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Wallets Section ──
              _WalletSection(),
              const SizedBox(height: 32),

              // ── Budgets Section ──
              const _BudgetSection(),
              const SizedBox(height: 32),

              // ── Category Spending Section ──
              const _CategorySpendingSection(),
              const SizedBox(height: 32),

              // ── Section header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      '${transactions.length} total',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Transaction list (limited to 5 unless expanded) ──
              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to add your first one',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: List.generate(
                      transactions.length.clamp(0, 5),
                      (index) {
                        final transaction =
                            transactions[transactions.length - 1 - index];
                        final walletName = transaction.walletId != null
                            ? wallets.where((w) => w.id == transaction.walletId).firstOrNull?.name
                            : null;
                        return Dismissible(
                          key: Key(transaction.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            ref
                                .read(financeNotifierProvider.notifier)
                                .deleteTransaction(transaction);
                          },
                          child: GestureDetector(
                            onTap: () => showTransactionSheet(context, ref, existingTransaction: transaction),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: transaction.isExpense
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    transaction.isExpense
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: transaction.isExpense
                                        ? Colors.red.shade400
                                        : Colors.green.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.title?.isNotEmpty == true
                                            ? transaction.title!
                                            : transaction.category,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (transaction.title?.isNotEmpty == true) ...[
                                            Text(
                                              transaction.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            DateFormat.yMMMd().format(
                                              transaction.date,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          if (transaction.budgetCategory != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: cs.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                transaction.budgetCategory!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (walletName != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: cs.tertiary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                walletName,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.tertiary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${transaction.isExpense ? "-" : "+"}$currency${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: transaction.isExpense
                                        ? Colors.red.shade400
                                        : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                ),
                if (transactions.length > 5)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton(
                        onPressed: () => context.push('/finance/transactions'),
                        child: Text(
                          'See All (${transactions.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],


            ],
          ),
        ),
      ),
    );
  }
}

void showTransactionSheet(BuildContext context, WidgetRef ref, {Transaction? existingTransaction}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isEditing = existingTransaction != null;

    final amountController = TextEditingController(text: isEditing ? existingTransaction.amount.toString() : '');
    final nameController = TextEditingController(text: isEditing ? (existingTransaction.title ?? '') : '');
    final categoryController = TextEditingController(text: isEditing ? existingTransaction.category : '');
    bool isExpense = isEditing ? existingTransaction.isExpense : true;
    String? selectedBudgetCategory = isEditing ? existingTransaction.budgetCategory : null;
    DateTime selectedDate = isEditing ? existingTransaction.date : DateTime.now();
    String? selectedWalletId = isEditing ? existingTransaction.walletId : null;

    // Get budget categories from provider
    final budgets = ref.read(budgetNotifierProvider);
    final budgetCategories = budgets.map((b) => b.categoryName).toList();
    final wallets = ref.read(walletNotifierProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Transaction' : 'New Transaction',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpense = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isExpense
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExpense ? Colors.red.shade300 : cs.outline,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isExpense
                                  ? Colors.red.shade400
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpense = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isExpense
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isExpense
                                ? Colors.green.shade400
                                : cs.outline,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Income',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !isExpense
                                  ? Colors.green.shade600
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  prefixText: '\$ ',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Name / Title
              TextField(
                controller: nameController,
                style: TextStyle(color: cs.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Transaction Name (e.g. Burger)',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              if (isExpense) ...[
                TextField(
                  controller: categoryController,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Category (e.g. Food, Salary)',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Budget Category (optional)
              if (isExpense && budgetCategories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedBudgetCategory,
                  decoration: InputDecoration(
                    labelText: 'Budget Category (optional)',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                  ),
                  dropdownColor: cs.surface,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Others',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                    ...budgetCategories.map(
                      (cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: TextStyle(color: cs.onSurface)),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedBudgetCategory = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              
              // Tags removed

              // Date picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: cs.outline),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat.yMMMd().format(selectedDate),
                        style: TextStyle(fontSize: 16, color: cs.onSurface),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to change',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Wallet selector (optional)
              if (wallets.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedWalletId,
                  decoration: InputDecoration(
                    labelText: 'Wallet (optional)',
                    labelStyle: TextStyle(color: cs.onSurfaceVariant),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                  ),
                  dropdownColor: cs.surface,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('No wallet', style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                    ...wallets.map(
                      (w) => DropdownMenuItem<String>(
                        value: w.id,
                        child: Text(w.name, style: TextStyle(color: cs.onSurface)),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedWalletId = val),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 24),

              // Save button
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null) {
                    final category = isExpense
                        ? (categoryController.text.isNotEmpty
                            ? categoryController.text
                            : 'General')
                        : 'Income';
                    final transaction = Transaction(
                      id: isEditing ? existingTransaction!.id : const Uuid().v4(),
                      amount: amount,
                      title: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                      category: category,
                      budgetCategory: selectedBudgetCategory,
                      isExpense: isExpense,
                      date: selectedDate,
                      walletId: selectedWalletId,
                    );
                    
                    if (isEditing) {
                      ref
                          .read(financeNotifierProvider.notifier)
                          .updateTransaction(existingTransaction!, transaction);
                    } else {
                      ref
                          .read(financeNotifierProvider.notifier)
                          .addTransaction(transaction);
                    }
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Transaction',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

// ─── Balance stat in the card ──────────────────────────────────────────

class _BalanceStat extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String currency;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$currency${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

// ─── Currency Picker ───────────────────────────────────────────────────

void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
  final cs = Theme.of(context).colorScheme;
  final current = ref.read(currencyProvider);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Select Currency',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...kSupportedCurrencies.entries.map((entry) {
                        final isSelected = entry.key == current;
                        return ListTile(
                          onTap: () {
                            ref.read(currencyProvider.notifier).setCurrency(entry.key);
                            Navigator.pop(ctx);
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: isSelected ? cs.primary.withValues(alpha: 0.08) : null,
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(entry.key,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                )),
                            ),
                          ),
                          title: Text(entry.value,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: cs.primary)
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── Budget Section ────────────────────────────────────────────────────

class _BudgetSection extends ConsumerWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetNotifierProvider);
    final activeBudgets = budgets.where((b) => !b.isExpired).toList();
    final archivedBudgets = budgets.where((b) => b.isExpired).toList();
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Budgets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                '${activeBudgets.length} active',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activeBudgets.map((budget) {
            final spent = ref.watch(budgetSpendingProvider(budget));
            final hasLimit = budget.monthlyLimit != null && budget.monthlyLimit! > 0;
            final percentage = hasLimit ? (spent / budget.monthlyLimit!).clamp(0.0, 1.0) : 0.0;

            Color progressColor = Colors.green;
            if (percentage > 0.9) {
              progressColor = Colors.red;
            } else if (percentage > 0.7) {
              progressColor = Colors.orange;
            }

            final fmt = DateFormat('MMM d');
            final dateRangeStr = budget.endDate != null
                ? '${fmt.format(budget.startDate)} – ${fmt.format(budget.endDate!)}'
                : 'From ${fmt.format(budget.startDate)}';

            return GestureDetector(
              onTap: () => _showBudgetDetailsSheet(
                context,
                ref,
                budget,
                spent,
                percentage,
                progressColor,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.categoryName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateRangeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (budget.isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Expired',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.error),
                                ),
                              )
                            else if (budget.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              hasLimit
                                  ? '$currency${spent.toStringAsFixed(0)} / $currency${budget.monthlyLimit!.toStringAsFixed(0)}'
                                  : '$currency${spent.toStringAsFixed(0)} spent',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: cs.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Archives button
          if (archivedBudgets.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () => _showArchivesSheet(context, ref, archivedBudgets, currency),
                icon: Icon(Icons.archive_outlined, size: 18, color: cs.onSurfaceVariant),
                label: Text(
                  'View Archives (${archivedBudgets.length})',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Add Budget Button
          InkWell(
            onTap: () => _showBudgetSheet(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add Budget Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showBudgetSheet(BuildContext context, WidgetRef ref, {Budget? budget}) {
    final isEditing = budget != null;
    final catController = TextEditingController(
      text: budget?.categoryName ?? '',
    );
    final limitController = TextEditingController(
      text: budget?.monthlyLimit?.toStringAsFixed(0) ?? '',
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final now = DateTime.now();
    DateTimeRange selectedRange = DateTimeRange(
      start: budget?.startDate ?? DateTime(now.year, now.month, 1),
      end: budget?.endDate ?? DateTime(now.year, now.month + 1, 0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle & Header
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Budget' : 'New Budget',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red.shade400,
                            onPressed: () {
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .deleteBudget(budget);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount Field
                    TextField(
                      controller: limitController,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                        hintText: '0 (optional)',
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: cs.outline.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Name Field
                    Text(
                      'Category Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: catController,
                      style: TextStyle(color: cs.onSurface, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'e.g., Gaming, Rent, Groceries...',
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: false,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.outline),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Range Picker
                    Text(
                      'Budget Period',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: selectedRange,
                          builder: (context, child) => Theme(
                            data: Theme.of(context),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedRange = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range_outlined, color: cs.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${DateFormat('MMM d, yyyy').format(selectedRange.start)}  →  ${DateFormat('MMM d, yyyy').format(selectedRange.end)}',
                                style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Action
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final catName = catController.text.trim();
                          final limitText = limitController.text.trim();
                          final limitAmt = limitText.isNotEmpty ? double.tryParse(limitText) : null;
                          if (catName.isNotEmpty) {
                            if (isEditing) {
                              final updated = Budget(
                                id: budget.id,
                                categoryName: catName,
                                monthlyLimit: limitAmt,
                                startDate: selectedRange.start,
                                endDate: selectedRange.end,
                              );
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .updateBudget(budget, updated);
                            } else {
                              final newBudget = Budget(
                                id: const Uuid().v4(),
                                categoryName: catName,
                                monthlyLimit: limitAmt,
                                startDate: selectedRange.start,
                                endDate: selectedRange.end,
                              );
                              ref
                                  .read(budgetNotifierProvider.notifier)
                                  .addBudget(newBudget);
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: cs.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Budget',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        }); // StatefulBuilder
      },
    );
  }

  void _showBudgetDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
    double spent,
    double percentage,
    Color progressColor,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = ref.read(currencyProvider);

    // Fetch all transactions so we can filter them gracefully inside the sheet
    // instead of creating a whole new provider
    final allTransactions = ref.read(financeNotifierProvider);
    final now = DateTime.now();

    // Filter transactions to matching category within the budget's date range
    final end = budget.endDate ?? DateTime.now();
    final relatedTransactions = allTransactions.where((t) {
      return t.isExpense &&
          t.category == budget.categoryName &&
          !t.date.isBefore(budget.startDate) &&
          !t.date.isAfter(end);
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // Newest first

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          // Constraints to mimic scrolling if too many items
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle margin
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget.categoryName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Budget Limit',
                      onPressed: () {
                        // Pop details and show edit sheet
                        Navigator.pop(context);
                        _showBudgetSheet(context, ref, budget: budget);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Custom Progress visual matching the container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent in period',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          budget.monthlyLimit != null
                              ? '$currency${spent.toStringAsFixed(0)} / $currency${budget.monthlyLimit!.toStringAsFixed(0)}'
                              : '$currency${spent.toStringAsFixed(0)} spent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 12,
                        backgroundColor: cs.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),

              // Transactions label
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),

              // Expanded list of transactions
              Expanded(
                child: relatedTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions this month for ${budget.categoryName}.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: relatedTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = relatedTransactions[index];
                          final dateStr = DateFormat('MMM d').format(tx.date);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                // Icon Box
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    color: cs.error,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.category,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-$currency${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showArchivesSheet(BuildContext context, WidgetRef ref, List<Budget> archived, String currency) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('Budget Archives', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: archived.length,
                itemBuilder: (context, index) {
                  final budget = archived[index];
                  final spent = ref.read(budgetSpendingProvider(budget));
                  final fmt = DateFormat('MMM d, yyyy');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(budget.categoryName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
                              child: Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.error)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${fmt.format(budget.startDate)} – ${budget.endDate != null ? fmt.format(budget.endDate!) : 'Ongoing'}',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          budget.monthlyLimit != null
                              ? 'Spent $currency${spent.toStringAsFixed(0)} of $currency${budget.monthlyLimit!.toStringAsFixed(0)} limit'
                              : 'Total spent: $currency${spent.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wallet Section ────────────────────────────────────────────────────

const Map<String, IconData> kWalletIcons = {
  'cash': Icons.payments_outlined,
  'bank': Icons.account_balance_outlined,
  'card': Icons.credit_card_outlined,
  'gcash': Icons.phone_android_outlined,
  'paypal': Icons.account_balance_wallet_outlined,
  'other': Icons.wallet_outlined,
};

class _WalletSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletNotifierProvider);
    final currency = ref.watch(currencyProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
              Text('${wallets.length} sources', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          if (wallets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text('No wallets yet', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...wallets.map((wallet) {
              final balance = ref.watch(walletBalanceProvider(wallet.id));
              final icon = kWalletIcons[wallet.iconKey] ?? Icons.wallet_outlined;
              return Dismissible(
                key: Key(wallet.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(walletNotifierProvider.notifier).deleteWallet(wallet),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(wallet.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface))),
                      Text(
                        '$currency${balance.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: balance >= 0 ? Colors.green.shade600 : Colors.red.shade400),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showAddWalletSheet(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Add Wallet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedIcon = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 24, right: 24, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('New Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: cs.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Wallet Name',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  hintText: 'e.g., GCash, Bank Account, Cash',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outline)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 2)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: balanceController,
                style: TextStyle(color: cs.onSurface, fontSize: 16),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Initial Balance (optional)',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: cs.onSurfaceVariant),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outline)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kWalletIcons.entries.map((entry) {
                  final isSelected = entry.key == selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: cs.primary, width: 2) : null,
                      ),
                      child: Icon(entry.value, color: isSelected ? cs.primary : cs.onSurfaceVariant, size: 24),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    double initialBalance = 0.0;
                    if (balanceController.text.trim().isNotEmpty) {
                      initialBalance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                    }
                    ref.read(walletNotifierProvider.notifier).addWallet(
                      Wallet(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        iconKey: selectedIcon,
                        initialBalance: initialBalance,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Add Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category Spending Section ──────────────────────────────────────────

class _CategorySpendingSection extends ConsumerWidget {
  const _CategorySpendingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(financeNotifierProvider);
    final currency = ref.watch(currencyProvider);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // Filter current month expenses
    final currentMonthExpenses = transactions.where((t) =>
        t.isExpense && t.date.year == now.year && t.date.month == now.month);

    final Map<String, double> categoryTotals = {};
    for (var tx in currentMonthExpenses) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }

    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Spending',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'This Month',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedCategories.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    '$currency${entry.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
