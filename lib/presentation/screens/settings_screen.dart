import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/presentation/state/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Text(
              'NOTIFICATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          
          // Form Container
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Weight Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Get a daily reminder to log your weight'),
                  value: settings.weightReminderEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleWeightReminder(value);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                if (settings.weightReminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text(
                      'Reminder Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        settings.weightReminderTime.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: settings.weightReminderTime,
                      );
                      if (time != null) {
                        ref.read(settingsProvider.notifier).setWeightReminderTime(time);
                      }
                    },
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Goals Subtitle
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Text(
              'GOALS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Goals Container
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_walk),
                  title: const Text(
                    'Daily Step Goal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        hintText: '10000',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      onSubmitted: (value) {
                        final goal = int.tryParse(value);
                        if (goal != null) {
                          ref.read(settingsProvider.notifier).setDailyStepGoal(goal);
                        }
                      },
                      controller: TextEditingController(text: settings.dailyStepGoal.toString()),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
