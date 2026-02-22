import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:life_os/core/constants.dart';
import 'package:life_os/core/notification_service.dart';
import 'package:life_os/features/tasks/domain/task_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

class TaskNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() {
    final box = Hive.box<Task>(AppConstants.tasksBox);
    if (box.isEmpty || box.values.every((t) => t.completedDates.isEmpty)) {
      box.clear();
      _seedDefaults(box);
    }
    return box.values.toList();
  }

  void _seedDefaults(Box<Task> box) {
    const uuid = Uuid();
    final defaults = [
      Task(
        id: uuid.v4(),
        title: 'Drink a glass of water',
        description: 'Stay hydrated first thing in the morning',
        category: TaskCategory.morning,
        scheduledTime: '07:00',
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
        priority: TaskPriority.medium,
      ),
      Task(
        id: uuid.v4(),
        title: 'Meditate to relax',
        description: 'Clear your mind for a focused day',
        category: TaskCategory.morning,
        scheduledTime: '07:15',
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
        priority: TaskPriority.high,
      ),
      Task(
        id: uuid.v4(),
        title: 'Stretch for 10 minutes',
        description: 'Loosen up your body before the day',
        category: TaskCategory.morning,
        scheduledTime: '07:30',
        repeatDays: [1, 2, 3, 4, 5],
        priority: TaskPriority.medium,
      ),
      Task(
        id: uuid.v4(),
        title: 'Go for a short walk',
        description: 'Get some fresh air and sunlight',
        category: TaskCategory.afternoon,
        scheduledTime: '12:30',
        repeatDays: [1, 2, 3, 4, 5],
        priority: TaskPriority.low,
      ),
    ];
    final today = DateTime.now();
    final random = math.Random();

    for (final task in defaults) {
      final List<String> simulatedCompletions = [];
      // Simulate last 30 days
      for (int i = 30; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        // Ensure it's scheduled for that day, and 85% chance they completed it
        if (task.isScheduledFor(date) && random.nextDouble() > 0.15) {
          final dateKey =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          simulatedCompletions.add(dateKey);
        }
      }

      final taskWithHistory = task.copyWith(
        completedDates: simulatedCompletions,
      );
      box.add(taskWithHistory);
    }
  }

  Future<void> addTask(Task task) async {
    final box = Hive.box<Task>(AppConstants.tasksBox);
    await box.add(task);
    state = box.values.toList();
    if (task.scheduledTime != null) {
      await NotificationService().scheduleRoutineNotification(task);
    }
  }

  /// Toggle a task's completion for a specific date.
  /// For recurring tasks, this toggles the date in completedDates.
  /// For one-time tasks, this toggles isCompleted.
  Future<void> toggleTaskForDate(Task task, DateTime date) async {
    final box = Hive.box<Task>(AppConstants.tasksBox);
    final index = box.values.toList().indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final key = box.keyAt(index);
      final updatedTask = task.toggleForDate(date);
      await box.put(key, updatedTask);
      state = box.values.toList();
    }
  }

  /// Legacy toggle (for one-time tasks or dashboard usage)
  Future<void> toggleTask(Task task) async {
    final box = Hive.box<Task>(AppConstants.tasksBox);
    final index = box.values.toList().indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final key = box.keyAt(index);
      final newTask = task.copyWith(isCompleted: !task.isCompleted);
      await box.put(key, newTask);
      state = box.values.toList();
    }
  }

  Future<void> updateTask(Task oldTask, Task updatedTask) async {
    final box = Hive.box<Task>(AppConstants.tasksBox);
    final index = box.values.toList().indexWhere((t) => t.id == oldTask.id);
    if (index != -1) {
      final key = box.keyAt(index);
      await box.put(key, updatedTask);
      state = box.values.toList();

      if (oldTask.scheduledTime != updatedTask.scheduledTime) {
        await NotificationService().cancelRoutineNotification(oldTask.id);
        if (updatedTask.scheduledTime != null) {
          await NotificationService().scheduleRoutineNotification(updatedTask);
        }
      }
    }
  }

  Future<void> deleteTask(Task task) async {
    final box = Hive.box<Task>(AppConstants.tasksBox);
    final index = box.values.toList().indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final key = box.keyAt(index);
      await box.delete(key);
      state = box.values.toList();
      await NotificationService().cancelRoutineNotification(task.id);
    }
  }

  /// Get all routines scheduled for a specific date
  List<Task> getRoutinesForDate(DateTime date) {
    return state.where((task) => task.isScheduledFor(date)).toList()
      ..sort((a, b) {
        if (a.scheduledTime == null && b.scheduledTime == null) return 0;
        if (a.scheduledTime == null) return 1;
        if (b.scheduledTime == null) return -1;
        return a.scheduledTime!.compareTo(b.scheduledTime!);
      });
  }
}

final taskNotifierProvider = NotifierProvider<TaskNotifier, List<Task>>(
  TaskNotifier.new,
);
