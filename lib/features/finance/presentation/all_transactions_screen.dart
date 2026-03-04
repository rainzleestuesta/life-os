import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:life_flow/core/currency_provider.dart';
import 'package:life_flow/features/finance/data/finance_provider.dart';
import 'package:life_flow/features/finance/domain/transaction_model.dart';
import 'package:life_flow/features/finance/domain/wallet_model.dart';

class AllTransactionsScreen extends HookConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(financeNotifierProvider);
    final currency = ref.watch(currencyProvider);
    final wallets = ref.watch(walletNotifierProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final filterType = useState<String?>( null); // null = all, 'expense', 'income'

    final walletMap = useMemoized(
      () => {for (final w in wallets) w.id: w.name},
      [wallets],
    );

    // Sort by date descending and apply filters
    final filteredTransactions = useMemoized(() {
      var list = List<Transaction>.from(transactions);
      list.sort((a, b) => b.date.compareTo(a.date));

      if (filterType.value == 'expense') {
        list = list.where((t) => t.isExpense).toList();
      } else if (filterType.value == 'income') {
        list = list.where((t) => !t.isExpense).toList();
      }

      if (searchQuery.value.isNotEmpty) {
        final q = searchQuery.value.toLowerCase();
        list = list.where((t) =>
            t.category.toLowerCase().contains(q) ||
            (t.budgetCategory?.toLowerCase().contains(q) ?? false)
        ).toList();
      }

      return list;
    }, [transactions, filterType.value, searchQuery.value]);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: cs.onSurface, size: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Transactions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${filteredTransactions.length} transactions',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: searchController,
                onChanged: (val) => searchQuery.value = val,
                style: TextStyle(color: cs.onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by category...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isActive: filterType.value == null,
                    onTap: () => filterType.value = null,
                    cs: cs,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Expenses',
                    isActive: filterType.value == 'expense',
                    onTap: () => filterType.value = 'expense',
                    cs: cs,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Income',
                    isActive: filterType.value == 'income',
                    onTap: () => filterType.value = 'income',
                    cs: cs,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Transaction list ──
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.receipt_long_outlined, size: 40, color: cs.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
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
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            ref.read(financeNotifierProvider.notifier).deleteTransaction(transaction);
                          },
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            DateFormat.yMMMd().format(transaction.date),
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
                                          if (transaction.walletId != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: cs.tertiary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                walletMap[transaction.walletId] ?? 'Wallet',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme cs;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.cs,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? cs.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? activeColor : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
