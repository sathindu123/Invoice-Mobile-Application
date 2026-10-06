import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  List<Reminder> get pendingReminders =>
      _reminders.where((r) => !r.isCompleted).toList()
        ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

  List<Reminder> get completedReminders =>
      _reminders.where((r) => r.isCompleted).toList()
        ..sort((a, b) => b.reminderDate.compareTo(a.reminderDate));

  List<Reminder> get todayReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      return !r.isCompleted &&
          r.reminderDate.year == now.year &&
          r.reminderDate.month == now.month &&
          r.reminderDate.day == now.day;
    }).toList();
  }

  int get overdueCount {
    final now = DateTime.now();
    return _reminders.where((r) => !r.isCompleted && r.reminderDate.isBefore(now)).length;
  }

  ReminderProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await NotificationService.initialize();
    _reminders = await StorageService.loadReminders();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveReminder(Reminder reminder) async {
    int? notifId = reminder.notificationId;

    // Schedule notification if enabled
    if (reminder.notificationEnabled) {
      // Cancel old notification if it exists
      if (notifId != null) {
        await NotificationService.cancelNotification(notifId);
      }
      notifId = await NotificationService.scheduleReminderNotification(reminder);
    } else {
      if (notifId != null) {
        await NotificationService.cancelNotification(notifId);
        notifId = null;
      }
    }

    final updatedReminder = reminder.copyWith(notificationId: notifId);

    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index >= 0) {
      _reminders[index] = updatedReminder;
    } else {
      _reminders.insert(0, updatedReminder);
    }

    notifyListeners();
    await StorageService.saveReminders(_reminders);
  }

  Future<void> deleteReminder(String id) async {
    final reminder = _reminders.firstWhere((r) => r.id == id, orElse: () => Reminder(
      id: '',
      title: '',
      description: '',
      reminderDate: DateTime.now(),
    ));

    if (reminder.notificationId != null) {
      await NotificationService.cancelNotification(reminder.notificationId!);
    }

    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await StorageService.saveReminders(_reminders);
  }

  Future<void> markCompleted(String id, bool completed) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final reminder = _reminders[index];
      // Cancel notification if marking complete
      if (completed && reminder.notificationId != null) {
        await NotificationService.cancelNotification(reminder.notificationId!);
      }
      _reminders[index] = reminder.copyWith(isCompleted: completed);
      notifyListeners();
      await StorageService.saveReminders(_reminders);
    }
  }
}
