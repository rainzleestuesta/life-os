import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:life_flow/core/theme_provider.dart';
import 'package:life_flow/features/tasks/data/task_provider.dart';
import 'package:life_flow/features/tasks/domain/task_model.dart';
import 'package:life_flow/features/finance/data/finance_provider.dart';
import 'package:life_flow/features/finance/domain/transaction_model.dart';

class CalendarScreen extends StatefulHookConsumerWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Get tasks for a specific date to show markers
  List<Task> _getEventsForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) => task.isScheduledFor(day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final allTasks = ref.watch(taskNotifierProvider);
    final allTransactions = ref.watch(financeNotifierProvider);

    final selectedDayTasks = useMemoized(
      () => _selectedDay != null
          ? _getEventsForDay(_selectedDay!, allTasks)
          : <Task>[],
      [allTasks, _selectedDay],
    );

    final selectedDayTransactions = useMemoized(
      () => _selectedDay != null
          ? allTransactions
                .where(
                  (t) =>
                      t.date.year == _selectedDay!.year &&
                      t.date.month == _selectedDay!.month &&
                      t.date.day == _selectedDay!.day,
                )
                .toList()
          : <Transaction>[],
      [allTransactions, _selectedDay],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TableCalendar<Task>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) => _getEventsForDay(day, allTasks),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    markerSizeScale: 0.15,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
                    markerDecoration: BoxDecoration(
                      color: const Color(0xFFE8601C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_selectedDay != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (selectedDayTasks.isEmpty &&
                      selectedDayTransactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nothing scheduled for this day',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (selectedDayTasks.isNotEmpty) ...[
                    Text(
                      'Routines & Tasks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedDayTasks.map(
                      (task) => _TaskItem(task: task, date: _selectedDay!),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (selectedDayTransactions.isNotEmpty) ...[
                    Text(
                      'Financial Transactions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedDayTransactions.map(
                      (tx) => _TransactionItem(tx: tx),
                    ),
                    const SizedBox(height: 80), // Padding for bottom nav bar
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskItem extends ConsumerWidget {
  final Task task;
  final DateTime date;

  const _TaskItem({required this.task, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isCompleted = task.isCompletedForDate(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () {
            ref
                .read(taskNotifierProvider.notifier)
                .toggleTaskForDate(task, date);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? Colors.transparent
                    : cs.outline.withValues(alpha: 0.5),
                width: 2,
              ),
              color: isCompleted ? const Color(0xFF4CAF50) : Colors.transparent,
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
        subtitle: task.scheduledTime != null
            ? Text(
                task.scheduledTime!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              )
            : null,
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction tx;

  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = tx.isExpense
        ? const Color(0xFFE53935)
        : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            tx.isExpense
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          tx.category,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        subtitle: tx.budgetCategory != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.budgetCategory!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Text(
          '${tx.isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
