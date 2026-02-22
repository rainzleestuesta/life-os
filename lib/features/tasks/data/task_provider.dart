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
    return box.values.toList();
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
