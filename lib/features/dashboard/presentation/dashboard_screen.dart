import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:life_flow/core/theme_provider.dart';
import 'package:life_flow/core/currency_provider.dart';
import 'package:life_flow/features/finance/data/finance_provider.dart';
import 'package:life_flow/features/finance/domain/transaction_model.dart';
import 'package:life_flow/features/tasks/data/task_provider.dart';
import 'package:life_flow/features/tasks/domain/task_model.dart';
import 'package:life_flow/core/export_service.dart';

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskNotifierProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final transactions = ref.watch(financeNotifierProvider);
    final currency = ref.watch(currencyProvider);
    final wallets = ref.watch(walletNotifierProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final today = DateTime.now();
    final todayRoutines = useMemoized(
      () => tasks.where((t) => t.isScheduledFor(today)).toList(),
      [tasks, today.day],
    );
    final completedToday = todayRoutines
        .where((t) => t.isCompletedForDate(today))
        .length;

    // Top streaks
    final topStreaks = useMemoized(() {
      final streakTasks =
          tasks
              .where((t) => t.repeatDays.isNotEmpty && t.streakDays > 0)
              .toList()
            ..sort((a, b) => b.streakDays.compareTo(a.streakDays));
      return streakTasks.take(3).toList();
    }, [tasks]);

    // Greeting
    final greeting = useMemoized(() {
      final hour = today.hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }, [today.hour]);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + theme toggle ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(today),
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Import button
                      GestureDetector(
                        onTap: () async {
                          final result = await ExportService().importDataCsv(wallets);
                          if (result != null) {
                            int count = 0;
                            if (result.transactions != null && result.transactions!.isNotEmpty) {
                              for (final t in result.transactions!) {
                                ref.read(financeNotifierProvider.notifier).addTransaction(t);
                              }
                              count += result.transactions!.length;
                            }
                            if (result.tasks != null && result.tasks!.isNotEmpty) {
                              for (final t in result.tasks!) {
                                ref.read(taskNotifierProvider.notifier).addTask(t);
                              }
                              count += result.tasks!.length;
                            }
                            
                            if (count > 0 && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Successfully imported $count items')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.file_upload_outlined, size: 22, color: cs.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Export button
                      GestureDetector(
                        onTap: () {
                          ExportService().exportAllDataCsv(
                            transactions, wallets, tasks, currency,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.file_download_outlined, size: 22, color: cs.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Theme toggle
                      GestureDetector(
                        onTap: () => ref.read(themeProvider.notifier).toggle(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            theme.brightness == Brightness.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: cs.onSurface,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Today's progress card ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Progress ring
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: todayRoutines.isEmpty
                                  ? 0
                                  : completedToday / todayRoutines.length,
                              strokeWidth: 8,
                              backgroundColor: cs.outline.withValues(
                                alpha: 0.15,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completedToday == todayRoutines.length &&
                                        todayRoutines.isNotEmpty
                                    ? const Color(0xFF4CAF50)
                                    : cs.primary,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${todayRoutines.isEmpty ? 0 : ((completedToday / todayRoutines.length) * 100).round()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Routines",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedToday of ${todayRoutines.length} completed',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/tasks'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Daily Routines Chart (Last 7 Days) ──
              Text('Weekly Routines', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _DailyRoutinesChart(tasks: tasks, today: today, cs: cs),
              ),
              const SizedBox(height: 24),

              // ── Finance snapshot ──
              Text('Finance Overview', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Income',
                      amount: income,
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF4CAF50),
                      cs: cs,
                      currency: currency,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Spending',
                      amount: expense,
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFFE53935),
                      cs: cs,
                      currency: currency,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Financial Tracks Chart ──
              _FinanceSection(transactions: transactions, theme: theme, cs: cs, currency: currency),
              const SizedBox(height: 24),

              // ── Top streaks ──
              if (topStreaks.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Streaks 🔥', style: theme.textTheme.titleMedium),
                    GestureDetector(
                      onTap: () => context.go('/tasks'),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...topStreaks.map((task) => _StreakRow(task: task, cs: cs)),
              ],
              const SizedBox(height: 24),

              // ── Monthly Activity ──
              Text('Monthly Activity', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _StreakHeatmap(tasks: tasks, cs: cs),

              // ── Quick action ──
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/finance'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Transaction',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              'Track your income and expenses',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final ColorScheme cs;
  final String currency;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.cs,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Row ─────────────────────────────────────────────────────────

class _StreakRow extends StatelessWidget {
  final Task task;
  final ColorScheme cs;

  const _StreakRow({required this.task, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8601C).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Color(0xFFE8601C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8601C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${task.streakDays} ${task.streakDays == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8601C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Charts ─────────────────────────────────────────────────────────────

class _DailyRoutinesChart extends StatelessWidget {
  final List<Task> tasks;
  final DateTime today;
  final ColorScheme cs;

  const _DailyRoutinesChart({
    required this.tasks,
    required this.today,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate completion for the last 7 days
    final List<BarChartGroupData> barGroups = [];
    final List<String> dayLabels = [];
    final List<String> topLabels = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(date)); // e.g., 'Mon', 'Tue'

      final dayTasks = tasks.where((t) => t.isScheduledFor(date)).toList();
      final total = dayTasks.length;
      final completed = dayTasks
          .where((t) => t.isCompletedForDate(date))
          .length;

      final double percentage = total > 0 ? (completed / total) * 100 : 0;
      topLabels.add(total > 0 ? '$completed/$total' : '0');

      final Color barColor = percentage >= 80
          ? const Color(0xFF4CAF50)
          : (percentage >= 50 ? Colors.orange : cs.error);

      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: cs.outline.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
        bottom: 8.0,
        left: 8.0,
        right: 8.0,
      ),
      child: BarChart(
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeOutCubic,
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.onSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()}%',
                  TextStyle(color: cs.surface, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28, // extra room for text
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dayLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        topLabels[index],
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

enum FinanceTimeframe { past7Days, past4Weeks, past6Months }

class _FinanceSection extends StatefulWidget {
  final List<Transaction> transactions;
  final ThemeData theme;
  final ColorScheme cs;
  final String currency;

  const _FinanceSection({
    required this.transactions,
    required this.theme,
    required this.cs,
    required this.currency,
  });

  @override
  State<_FinanceSection> createState() => _FinanceSectionState();
}

class _FinanceSectionState extends State<_FinanceSection> {
  FinanceTimeframe _selectedTimeframe = FinanceTimeframe.past7Days;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTimeframe == FinanceTimeframe.past7Days
                  ? 'Last 7 Days (Daily)'
                  : _selectedTimeframe == FinanceTimeframe.past4Weeks
                  ? 'Last 4 Weeks (Weekly)'
                  : 'Last 6 Months (Monthly)',
              style: widget.theme.textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: widget.cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.cs.outline.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FinanceTimeframe>(
                  value: _selectedTimeframe,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.cs.onSurfaceVariant,
                    size: 20,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.cs.onSurface,
                  ),
                  onChanged: (FinanceTimeframe? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTimeframe = newValue;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: FinanceTimeframe.past7Days,
                      child: Text('7 Days'),
                    ),
                    DropdownMenuItem(
                      value: FinanceTimeframe.past4Weeks,
                      child: Text('4 Weeks'),
                    ),
                    DropdownMenuItem(
                      value: FinanceTimeframe.past6Months,
                      child: Text('6 Months'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _FinancialTracksChart(
            transactions: widget.transactions,
            timeframe: _selectedTimeframe,
            cs: widget.cs,
            currency: widget.currency,
          ),
        ),
        const SizedBox(height: 24),
        Text('Expenses Breakdown', style: widget.theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _ExpensePieChart(
            transactions: widget.transactions,
            timeframe: _selectedTimeframe,
            cs: widget.cs,
            currency: widget.currency,
          ),
        ),
      ],
    );
  }
}

class _FinancialTracksChart extends StatelessWidget {
  final List<Transaction> transactions;
  final FinanceTimeframe timeframe;
  final ColorScheme cs;
  final String currency;

  const _FinancialTracksChart({
    required this.transactions,
    required this.timeframe,
    required this.cs,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> savingsSpots = [];
    final List<String> xAxisLabels = [];

    double maxAmount = 100;
    double minAmount = 0;

    int itemCount = 0;

    if (timeframe == FinanceTimeframe.past7Days) {
      itemCount = 7;
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        xAxisLabels.add(DateFormat('E').format(date)); // Mon, Tue

        final dayTxs = transactions.where(
          (t) =>
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day,
        );

        final double dayIncome = dayTxs
            .where((t) => !t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final double dayExpense = dayTxs
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        final double daySavings = dayIncome - dayExpense;

        incomeSpots.add(FlSpot((6 - i).toDouble(), dayIncome));
        expenseSpots.add(FlSpot((6 - i).toDouble(), dayExpense));
        savingsSpots.add(FlSpot((6 - i).toDouble(), daySavings));

        if (dayIncome > maxAmount) maxAmount = dayIncome;
        if (dayExpense > maxAmount) maxAmount = dayExpense;
        if (daySavings > maxAmount) maxAmount = daySavings;
        if (daySavings < minAmount) minAmount = daySavings;
      }
    } else if (timeframe == FinanceTimeframe.past4Weeks) {
      itemCount = 4;
      // Step backwards by weeks.
      final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));

      for (int i = 3; i >= 0; i--) {
        final weekStart = startOfThisWeek.subtract(Duration(days: i * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));

        // Label format: "Oct 1-7"
        xAxisLabels.add(
          '${DateFormat('MMM d').format(weekStart)}-${DateFormat('d').format(weekEnd)}',
        );

        final weekTxs = transactions.where((t) {
          final strippedTxDate = DateTime(
            t.date.year,
            t.date.month,
            t.date.day,
          );
          final strippedStart = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day,
          );
          final strippedEnd = DateTime(
            weekEnd.year,
            weekEnd.month,
            weekEnd.day,
          );

          return (strippedTxDate.isAfter(strippedStart) ||
                  strippedTxDate.isAtSameMomentAs(strippedStart)) &&
              (strippedTxDate.isBefore(strippedEnd) ||
                  strippedTxDate.isAtSameMomentAs(strippedEnd));
        });

        final double weekIncome = weekTxs
            .where((t) => !t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final double weekExpense = weekTxs
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        final double weekSavings = weekIncome - weekExpense;

        incomeSpots.add(FlSpot((3 - i).toDouble(), weekIncome));
        expenseSpots.add(FlSpot((3 - i).toDouble(), weekExpense));
        savingsSpots.add(FlSpot((3 - i).toDouble(), weekSavings));

        if (weekIncome > maxAmount) maxAmount = weekIncome;
        if (weekExpense > maxAmount) maxAmount = weekExpense;
        if (weekSavings > maxAmount) maxAmount = weekSavings;
        if (weekSavings < minAmount) minAmount = weekSavings;
      }
    } else if (timeframe == FinanceTimeframe.past6Months) {
      itemCount = 6;
      for (int i = 5; i >= 0; i--) {
        // Calculate the month safely covering year boundaries
        int targetMonth = today.month - i;
        int targetYear = today.year;
        if (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }

        final testDate = DateTime(targetYear, targetMonth, 1);
        xAxisLabels.add(DateFormat('MMM').format(testDate)); // Jan, Feb

        final monthTxs = transactions.where(
          (t) => t.date.year == targetYear && t.date.month == targetMonth,
        );

        final double monthIncome = monthTxs
            .where((t) => !t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final double monthExpense = monthTxs
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        final double monthSavings = monthIncome - monthExpense;

        incomeSpots.add(FlSpot((5 - i).toDouble(), monthIncome));
        expenseSpots.add(FlSpot((5 - i).toDouble(), monthExpense));
        savingsSpots.add(FlSpot((5 - i).toDouble(), monthSavings));

        if (monthIncome > maxAmount) maxAmount = monthIncome;
        if (monthExpense > maxAmount) maxAmount = monthExpense;
        if (monthSavings > maxAmount) maxAmount = monthSavings;
        if (monthSavings < minAmount) minAmount = monthSavings;
      }
    }

    // Add 20% padding to max Y
    maxAmount = maxAmount * 1.2;

    minAmount = minAmount < 0 ? minAmount * 1.2 : 0;

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: const Color(0xFF4CAF50), text: 'Income', cs: cs),
            const SizedBox(width: 16),
            _LegendItem(color: const Color(0xFFE53935), text: 'Expense', cs: cs),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.blueAccent, text: 'Savings', cs: cs),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 8.0,
              right: 16.0,
            ),
            child: LineChart(
              LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.onSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: touchedSpot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  return LineTooltipItem(
                    '$currency${touchedSpot.y.toStringAsFixed(0)}',
                    textStyle,
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxAmount / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: cs.outline.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < xAxisLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        xAxisLabels[index],
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11, // Slightly smaller to fit "Oct 1-7"
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (itemCount - 1).toDouble(),
          minY: minAmount,
          maxY: maxAmount,
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: const Color(0xFF4CAF50),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: const Color(0xFFE53935),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: savingsSpots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final ColorScheme cs;

  const _LegendItem({required this.color, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StreakHeatmap extends StatelessWidget {
  final List<Task> tasks;
  final ColorScheme cs;

  const _StreakHeatmap({
    required this.tasks,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month - 2, 1);
    final lastDay = DateTime(today.year, today.month + 1, 0);

    // Calculate completions per day
    final Map<DateTime, int> completionsPerDay = {};
    for (var task in tasks) {
      if (task.completedDates != null) {
        for (var dateStr in task.completedDates!) {
          try {
            final date = DateTime.parse(dateStr);
            final dayKey = DateTime(date.year, date.month, date.day);
            completionsPerDay[dayKey] = (completionsPerDay[dayKey] ?? 0) + 1;
          } catch (_) {}
        }
      }
    }

    int maxCompletions = 1;
    if (completionsPerDay.isNotEmpty) {
      maxCompletions = completionsPerDay.values.reduce((a, b) => a > b ? a : b);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: today,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
          rightChevronIcon: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          weekendStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCell(day, completionsPerDay, maxCompletions),
          todayBuilder: (context, day, focusedDay) => _buildCell(day, completionsPerDay, maxCompletions, isToday: true),
          outsideBuilder: (context, day, focusedDay) => const SizedBox.shrink(),
        ),
        availableGestures: AvailableGestures.horizontalSwipe,
      ),
    );
  }

  Widget _buildCell(DateTime day, Map<DateTime, int> map, int maxCompletions, {bool isToday = false}) {
    final dayKey = DateTime(day.year, day.month, day.day);
    final count = map[dayKey] ?? 0;

    double intensity = count == 0 ? 0 : (count / maxCompletions).clamp(0.2, 1.0);
    
    Color cellColor;
    if (intensity == 0) {
      cellColor = cs.outline.withValues(alpha: 0.1);
    } else {
      cellColor = Color.lerp(
        const Color(0xFFC8E6C9), // Light green
        const Color(0xFF2E7D32), // Dark green
        intensity,
      )!;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: cs.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: intensity > 0.5 ? Colors.white : cs.onSurface,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ExpensePieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final FinanceTimeframe timeframe;
  final ColorScheme cs;
  final String currency;

  const _ExpensePieChart({
    required this.transactions,
    required this.timeframe,
    required this.cs,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    late DateTime startDate;

    if (timeframe == FinanceTimeframe.past7Days) {
      startDate = today.subtract(const Duration(days: 6));
    } else if (timeframe == FinanceTimeframe.past4Weeks) {
      startDate = today.subtract(const Duration(days: 27));
    } else {
      int targetMonth = today.month - 5;
      int targetYear = today.year;
      if (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      startDate = DateTime(targetYear, targetMonth, 1);
    }
    final strippedStart = DateTime(startDate.year, startDate.month, startDate.day);

    final matchingTxs = transactions.where((t) {
      final strippedTxDate = DateTime(t.date.year, t.date.month, t.date.day);
      return (strippedTxDate.isAfter(strippedStart) || strippedTxDate.isAtSameMomentAs(strippedStart)) && t.isExpense;
    }).toList();

    if (matchingTxs.isEmpty) {
      return Center(
        child: Text(
          'No expenses found',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    final Map<String, double> categoryTotals = {};
    for (var tx in matchingTxs) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> colors = [
      const Color(0xFFE53935),
      Colors.orange,
      Colors.amber,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];

    double totalExpense = sortedEntries.fold(0.0, (sum, e) => sum + e.value);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOutCubic,
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(sortedEntries.length, (i) {
                final fontSize = 12.0;
                final radius = 40.0;
                final color = colors[i % colors.length];
                final value = sortedEntries[i].value;
                final percentage = (value / totalExpense) * 100;

                return PieChartSectionData(
                  color: color,
                  value: value,
                  title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView.builder(
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
