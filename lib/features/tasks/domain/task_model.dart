import 'package:hive/hive.dart';
import 'package:life_os/features/tasks/domain/subtask_model.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 3)
enum TaskCategory {
  @HiveField(0)
  morning,
  @HiveField(1)
  afternoon,
  @HiveField(2)
  evening,
  @HiveField(3)
  anytime,
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool isCompleted;

  @HiveField(3)
  final DateTime? dueDate;

  @HiveField(4)
  final TaskPriority priority;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? scheduledTime; // e.g. "07:00", "14:30"

  @HiveField(7)
  final List<int> repeatDays; // 1=Mon, 7=Sun, empty=one-time

  @HiveField(8)
  final TaskCategory category;

  /// Stores dates (as "yyyy-MM-dd" strings) when this recurring task was completed.
  /// For one-time tasks, use `isCompleted` instead.
  @HiveField(9)
  final List<String> completedDates;

  @HiveField(10, defaultValue: [])
  final List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.description,
    this.scheduledTime,
    this.repeatDays = const [],
    this.category = TaskCategory.anytime,
    this.completedDates = const [],
    this.subTasks = const [],
  });

  double get completionPercentage {
    if (subTasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    final completedCount = subTasks.where((st) => st.isCompleted).length;
    return completedCount / subTasks.length;
  }

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    TaskPriority? priority,
    String? description,
    String? scheduledTime,
    List<int>? repeatDays,
    TaskCategory? category,
    List<String>? completedDates,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatDays: repeatDays ?? this.repeatDays,
      category: category ?? this.category,
      completedDates: completedDates ?? this.completedDates,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  /// Format a date to the string key used in completedDates
  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Check if this routine is completed for a specific date.
  /// For recurring tasks, checks completedDates list.
  /// For one-time tasks, checks the isCompleted flag.
  bool isCompletedForDate(DateTime date) {
    if (repeatDays.isNotEmpty) {
      return completedDates.contains(_dateKey(date));
    }
    return isCompleted;
  }

  /// Toggle completion for a specific date (for recurring tasks).
  Task toggleForDate(DateTime date) {
    if (repeatDays.isNotEmpty) {
      final key = _dateKey(date);
      final newDates = List<String>.from(completedDates);
      if (newDates.contains(key)) {
        newDates.remove(key);
      } else {
        newDates.add(key);
      }
      return copyWith(completedDates: newDates);
    }
    // One-time task: just toggle isCompleted
    return copyWith(isCompleted: !isCompleted);
  }

  /// Check if this routine is scheduled for a given date
  bool isScheduledFor(DateTime date) {
    // If it has repeat days, check if the date's weekday matches
    if (repeatDays.isNotEmpty) {
      return repeatDays.contains(date.weekday);
    }
    // Otherwise, check exact dueDate match
    if (dueDate != null) {
      return dueDate!.year == date.year &&
          dueDate!.month == date.month &&
          dueDate!.day == date.day;
    }
    // Tasks without a date or repeat schedule show on all days
    return true;
  }

  /// Calculate the current streak (consecutive scheduled days completed).
  /// Walks backward from yesterday, only counting days that are
  /// actually scheduled (matching repeatDays). Streak breaks on the
  /// first scheduled day that was NOT completed.
  int get streakDays {
    if (repeatDays.isEmpty) return isCompleted ? 1 : 0;
    if (completedDates.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    // Start from yesterday and walk backward
    var checkDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    // Check up to 365 days back
    for (int i = 0; i < 365; i++) {
      if (repeatDays.contains(checkDate.weekday)) {
        // This day is a scheduled day
        if (completedDates.contains(_dateKey(checkDate))) {
          streak++;
        } else {
          break; // streak broken
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Also count today if completed
    final todayKey = _dateKey(now);
    if (repeatDays.contains(now.weekday) && completedDates.contains(todayKey)) {
      streak++;
    }

    return streak;
  }
}
