import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_os/features/tasks/data/task_provider.dart';
import 'package:life_os/features/tasks/domain/task_model.dart';
import 'package:life_os/features/tasks/domain/subtask_model.dart';
import 'package:life_os/router.dart';
import 'package:uuid/uuid.dart';

// ─── Category helpers (theme-independent) ────────────────────────────────

Color _categoryColor(TaskCategory c) {
  switch (c) {
    case TaskCategory.morning:
      return const Color(0xFFE8601C);
    case TaskCategory.afternoon:
      return const Color(0xFF5B7A3A);
    case TaskCategory.evening:
      return const Color(0xFF7A5B9A);
    case TaskCategory.anytime:
      return const Color(0xFF3A6B8C);
  }
}

IconData _categoryIcon(TaskCategory c) {
  switch (c) {
    case TaskCategory.morning:
      return Icons.wb_sunny_outlined;
    case TaskCategory.afternoon:
      return Icons.wb_cloudy_outlined;
    case TaskCategory.evening:
      return Icons.nightlight_outlined;
    case TaskCategory.anytime:
      return Icons.bolt_outlined;
  }
}

class TasksScreen extends HookConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskNotifierProvider);
    final selectedDate = useState(DateTime.now());
    final today = DateTime.now();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Listen for "+" nav button trigger
    useEffect(() {
      void listener() {
        _showAddRoutineSheet(context, ref, selectedDate.value);
      }

      addRoutineNotifier.addListener(listener);
      return () => addRoutineNotifier.removeListener(listener);
    }, const []);

    // Filter routines for selected date
    final routinesForDay = useMemoized(
      () =>
          tasks.where((t) => t.isScheduledFor(selectedDate.value)).toList()
            ..sort((a, b) {
              if (a.scheduledTime == null && b.scheduledTime == null) return 0;
              if (a.scheduledTime == null) return 1;
              if (b.scheduledTime == null) return -1;
              return a.scheduledTime!.compareTo(b.scheduledTime!);
            }),
      [tasks, selectedDate.value],
    );

    final completedCount = useMemoized(
      () => routinesForDay
          .where((t) => t.isCompletedForDate(selectedDate.value))
          .length,
      [routinesForDay, selectedDate.value],
    );
    final totalCount = routinesForDay.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Routine',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEEE, d MMMM yyyy',
                              ).format(selectedDate.value),
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (totalCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
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
                            child: Text(
                              '$completedCount / $totalCount done',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Date Carousel ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const int visibleCount = 5;
                    const double gap = 14.0;
                    const double hPad = 24.0;
                    final itemWidth =
                        (constraints.maxWidth -
                            hPad * 2 -
                            gap * (visibleCount - 1)) /
                        visibleCount;
                    final totalItemWidth = itemWidth + gap;
                    final initialOffset = (182 - 2) * totalItemWidth;

                    return ScrollConfiguration(
                      behavior: _WebDragScrollBehavior(),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 365,
                        controller: ScrollController(
                          initialScrollOffset: initialOffset,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: 4,
                        ),
                        itemBuilder: (context, index) {
                          final day = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          ).add(Duration(days: index - 182));

                          final isSelected =
                              day.year == selectedDate.value.year &&
                              day.month == selectedDate.value.month &&
                              day.day == selectedDate.value.day;
                          final isToday =
                              day.year == today.year &&
                              day.month == today.month &&
                              day.day == today.day;

                          return GestureDetector(
                            onTap: () => selectedDate.value = day,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: itemWidth,
                              margin: EdgeInsets.only(
                                right: index < 364 ? gap : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.1)
                                    : cs.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(color: cs.primary, width: 1.5)
                                    : isToday
                                    ? Border.all(
                                        color: cs.outline.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1,
                                      )
                                    : Border.all(color: Colors.transparent),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isSelected ? 0.15 : 0.04,
                                    ),
                                    blurRadius: isSelected ? 8 : 4,
                                    offset: Offset(0, isSelected ? 4 : 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E').format(day).substring(0, 3),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurface,
                                    ),
                                  ),
                                  if (isToday)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Section header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily routine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Routine list ──
            if (routinesForDay.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= routinesForDay.length) return null;
                    final task = routinesForDay[index];
                    return _RoutineCard(
                      task: task,
                      ref: ref,
                      selectedDate: selectedDate.value,
                      onEdit: (t) => _showEditRoutineSheet(context, ref, t),
                    );
                  }, childCount: routinesForDay.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Add / Edit sheets ──────────────────────────────────────────────────

  void _showAddRoutineSheet(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    _showRoutineSheet(
      context: context,
      ref: ref,
      selectedDate: selectedDate,
      existingTask: null,
    );
  }

  void _showEditRoutineSheet(BuildContext context, WidgetRef ref, Task task) {
    _showRoutineSheet(
      context: context,
      ref: ref,
      selectedDate: task.dueDate ?? DateTime.now(),
      existingTask: task,
    );
  }

  void _showRoutineSheet({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime selectedDate,
    required Task? existingTask,
  }) {
    final isEditing = existingTask != null;
    final titleController = TextEditingController(
      text: existingTask?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingTask?.description ?? '',
    );
    final subTaskController = TextEditingController();
    List<SubTask> currentSubTasks = List.from(existingTask?.subTasks ?? []);

    TaskPriority priority = existingTask?.priority ?? TaskPriority.medium;
    TaskCategory category = existingTask?.category ?? TaskCategory.anytime;
    TimeOfDay? selectedTime;
    if (existingTask?.scheduledTime != null) {
      final parts = existingTask!.scheduledTime!.split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    Set<int> repeatDays = Set<int>.from(existingTask?.repeatDays ?? []);

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          child: SingleChildScrollView(
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
                      isEditing ? 'Edit Routine' : 'New Routine',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (isEditing)
                      IconButton(
                        onPressed: () {
                          ref
                              .read(taskNotifierProvider.notifier)
                              .deleteTask(existingTask);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  'Name your routine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Morning Meditation',
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  autofocus: !isEditing,
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  'Description (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  style: TextStyle(color: cs.onSurface, fontSize: 16),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Sub-Tasks
                Text(
                  'Sub-Tasks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (currentSubTasks.isNotEmpty) ...[
                  ...currentSubTasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final st = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                currentSubTasks[idx] = st.copyWith(
                                  isCompleted: !st.isCompleted,
                                );
                              });
                            },
                            child: Icon(
                              st.isCompleted
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: st.isCompleted ? cs.primary : cs.outline,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              st.title,
                              style: TextStyle(
                                fontSize: 15,
                                color: st.isCompleted
                                    ? cs.onSurfaceVariant
                                    : cs.onSurface,
                                decoration: st.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: cs.onSurfaceVariant,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                currentSubTasks.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
                // Add subtask
                Row(
                  children: [
                    Icon(Icons.add, color: cs.onSurfaceVariant, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: subTaskController,
                        style: TextStyle(color: cs.onSurface, fontSize: 15),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              currentSubTasks.add(
                                SubTask(
                                  id: const Uuid().v4(),
                                  title: val.trim(),
                                ),
                              );
                              subTaskController.clear();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Add a sub-task...',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Time & Category
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: cs.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime != null
                                    ? selectedTime!.format(context)
                                    : 'Set Time',
                                style: TextStyle(
                                  color: selectedTime != null
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TaskCategory>(
                            value: category,
                            isExpanded: true,
                            dropdownColor: cs.surface,
                            style: TextStyle(color: cs.onSurface, fontSize: 14),
                            icon: Icon(
                              Icons.expand_more,
                              color: cs.onSurfaceVariant,
                            ),
                            items: TaskCategory.values
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(_categoryLabel(c)),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() => category = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Repeat days
                Text(
                  'Repeat days',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final dayNumber = index + 1;
                    final isActive = repeatDays.contains(dayNumber);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isActive) {
                            repeatDays.remove(dayNumber);
                          } else {
                            repeatDays.add(dayNumber);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? cs.onSurface
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            dayNames[index].substring(0, 1),
                            style: TextStyle(
                              color: isActive
                                  ? cs.surface
                                  : cs.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Priority
                Row(
                  children: [
                    Text(
                      'Priority',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ...TaskPriority.values.map((p) {
                      final isActive = priority == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            p.name[0].toUpperCase() + p.name.substring(1),
                          ),
                          selected: isActive,
                          selectedColor: _priorityColor(
                            p,
                          ).withValues(alpha: 0.15),
                          backgroundColor: theme.scaffoldBackgroundColor,
                          labelStyle: TextStyle(
                            color: isActive
                                ? _priorityColor(p)
                                : cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide.none,
                          onSelected: (_) => setState(() => priority = p),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 28),

                // Save button
                FilledButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      String? timeStr;
                      if (selectedTime != null) {
                        timeStr =
                            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                      }
                      final sortedRepeatDays = repeatDays.toList()..sort();

                      if (isEditing) {
                        final updated = existingTask.copyWith(
                          title: titleController.text,
                          description: descController.text.isNotEmpty
                              ? descController.text
                              : null,
                          priority: priority,
                          category: category,
                          scheduledTime: timeStr,
                          repeatDays: sortedRepeatDays,
                          dueDate: sortedRepeatDays.isEmpty
                              ? selectedDate
                              : null,
                          subTasks: currentSubTasks,
                        );
                        ref
                            .read(taskNotifierProvider.notifier)
                            .updateTask(existingTask, updated);
                      } else {
                        final task = Task(
                          id: const Uuid().v4(),
                          title: titleController.text,
                          description: descController.text.isNotEmpty
                              ? descController.text
                              : null,
                          priority: priority,
                          category: category,
                          scheduledTime: timeStr,
                          repeatDays: sortedRepeatDays,
                          dueDate: sortedRepeatDays.isEmpty
                              ? selectedDate
                              : null,
                          subTasks: currentSubTasks,
                        );
                        ref.read(taskNotifierProvider.notifier).addTask(task);
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
                    isEditing ? 'Save Changes' : 'Save Habit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(TaskCategory c) {
    switch (c) {
      case TaskCategory.morning:
        return '☀️ Morning';
      case TaskCategory.afternoon:
        return '🌤️ Afternoon';
      case TaskCategory.evening:
        return '🌙 Evening';
      case TaskCategory.anytime:
        return '⚡ Anytime';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red.shade600;
      case TaskPriority.medium:
        return const Color(0xFFE8601C);
      case TaskPriority.low:
        return const Color(0xFF5B7A3A);
    }
  }
}

// ─── Routine Card Widget (Swipe-to-reveal, theme-aware) ─────────────────

class _RoutineCard extends StatefulWidget {
  final Task task;
  final WidgetRef ref;
  final DateTime selectedDate;
  final void Function(Task) onEdit;

  const _RoutineCard({
    required this.task,
    required this.ref,
    required this.selectedDate,
    required this.onEdit,
  });

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.22, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeReveal() {
    if (_isRevealed) {
      _controller.reverse();
      setState(() => _isRevealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCompleted = task.isCompletedForDate(widget.selectedDate);
    final catColor = _categoryColor(task.category);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 200 && !_isRevealed) {
              _controller.forward();
              setState(() => _isRevealed = true);
            } else if (details.primaryVelocity! < -200 && _isRevealed) {
              _controller.reverse();
              setState(() => _isRevealed = false);
            }
          }
        },
        child: Stack(
          children: [
            // ── Action buttons (behind) ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _closeReveal();
                          widget.onEdit(task);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: cs.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _closeReveal();
                          widget.ref
                              .read(taskNotifierProvider.notifier)
                              .deleteTask(task);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Foreground card ──
            SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: _isRevealed ? _closeReveal : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Completion circle
                      GestureDetector(
                        onTap: () {
                          if (_isRevealed) {
                            _closeReveal();
                            return;
                          }
                          if (task.subTasks.isNotEmpty) {
                            widget.onEdit(task);
                          } else {
                            widget.ref
                                .read(taskNotifierProvider.notifier)
                                .toggleTaskForDate(task, widget.selectedDate);
                          }
                        },
                        child: task.subTasks.isNotEmpty
                            ? SizedBox(
                                width: 28,
                                height: 28,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: task.completionPercentage,
                                      backgroundColor: cs.outline.withValues(
                                        alpha: 0.2,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        task.completionPercentage == 1.0
                                            ? cs.primary
                                            : cs.primary.withValues(alpha: 0.6),
                                      ),
                                      strokeWidth: 3,
                                    ),
                                    if (task.completionPercentage == 1.0)
                                      Icon(
                                        Icons.check,
                                        size: 16,
                                        color: cs.primary,
                                      ),
                                  ],
                                ),
                              )
                            : AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? cs.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isCompleted
                                      ? null
                                      : Border.all(color: cs.outline, width: 2),
                                ),
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                      ),
                      const SizedBox(width: 12),

                      // Category icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _categoryIcon(task.category),
                          color: catColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? cs.onSurfaceVariant
                                    : cs.onSurface,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (task.repeatDays.isNotEmpty) ...[
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: task.streakDays > 0
                                        ? cs.primary
                                        : cs.outline,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Streak ${task.streakDays} ${task.streakDays == 1 ? 'day' : 'days'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: task.streakDays > 0
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else if (task.description != null &&
                                    task.description!.isNotEmpty) ...[
                                  Expanded(
                                    child: Text(
                                      task.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Time badge
                      if (task.scheduledTime != null)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(task.scheduledTime!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? cs.outline
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '$displayHour:$minute $period';
  }
}

// ─── Empty State Widget ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.event_repeat, size: 40, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No routines yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first routine',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Custom ScrollBehavior for web drag support ─────────────────────────

class _WebDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}
