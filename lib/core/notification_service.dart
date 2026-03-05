import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:life_flow/features/tasks/domain/task_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Web doesn't support local notifications in the same way, return early
    if (kIsWeb) return;

    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        ),
        macOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        ),
      ),
    );
  }

  Future<void> scheduleRoutineNotification(Task task) async {
    if (kIsWeb) return;
    if (task.scheduledTime == null) return;

    // Use consistent task ID hash as notification ID
    final int notificationId = _fastHash(task.id);

    final now = DateTime.now();
    final parts = task.scheduledTime!.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Routine Reminder',
      body: 'Time to: ${task.title}',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel_id',
          'Routines',
          channelDescription: 'Notifications for daily routines',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelRoutineNotification(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(id: _fastHash(taskId));
  }

  /// Creates a consistent 32-bit integer hash from a string.
  /// Safe for both native and Web (JS 53-bit integers).
  int _fastHash(String string) {
    int hash = 0x811c9dc5; // 32-bit FNV offset basis
    for (int i = 0; i < string.length; i++) {
      hash ^= string.codeUnitAt(i);
      hash *= 0x01000193; // 32-bit FNV prime
      hash &= 0xFFFFFFFF; // mask to 32 bits
    }
    return hash & 0x7FFFFFFF; // Ensure positive 32-bit int
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
