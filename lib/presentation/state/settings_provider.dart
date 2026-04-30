import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:gym_log/data/services/notification_service.dart';

class SettingsState {
  final bool weightReminderEnabled;
  final TimeOfDay weightReminderTime;
  final int dailyStepGoal;

  SettingsState({
    required this.weightReminderEnabled,
    required this.weightReminderTime,
    required this.dailyStepGoal,
  });

  SettingsState copyWith({
    bool? weightReminderEnabled,
    TimeOfDay? weightReminderTime,
    int? dailyStepGoal,
  }) {
    return SettingsState(
      weightReminderEnabled: weightReminderEnabled ?? this.weightReminderEnabled,
      weightReminderTime: weightReminderTime ?? this.weightReminderTime,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          weightReminderEnabled: false,
          weightReminderTime: const TimeOfDay(hour: 9, minute: 0),
          dailyStepGoal: 10000,
        ));

  void toggleWeightReminder(bool enabled) {
    state = state.copyWith(weightReminderEnabled: enabled);
    _updateNotification();
  }

  void setWeightReminderTime(TimeOfDay time) {
    state = state.copyWith(weightReminderTime: time);
    _updateNotification();
  }

  void setDailyStepGoal(int goal) {
    state = state.copyWith(dailyStepGoal: goal);
  }

  void _updateNotification() {
    if (state.weightReminderEnabled) {
      NotificationService().scheduleWeightReminder(state.weightReminderTime);
    } else {
      NotificationService().cancelAllReminders();
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
