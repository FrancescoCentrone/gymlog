import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/presentation/screens/dashboard_screen.dart';
import 'package:gym_log/presentation/screens/workout_screen.dart';
import 'package:gym_log/presentation/screens/analytics_screen.dart';
import 'package:gym_log/presentation/screens/profile_screen.dart';
import 'package:gym_log/presentation/state/navigation_provider.dart';
import 'package:gym_log/presentation/widgets/rest_timer_overlay.dart';

import 'package:gym_log/data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: GymLogApp(),
    ),
  );
}

class GymLogApp extends StatelessWidget {
  const GymLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          color: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navigationProvider);

    return Scaffold(
      extendBody: true, // Crucial for glassmorphism under bottom bar
      body: Stack(
        children: [
          IndexedStack(
            index: currentTab.index,
            children: const [
              DashboardScreen(),
              WorkoutScreen(),
              AnalyticsScreen(),
              ProfileScreen(),
            ],
          ),
          const RestTimerOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: NavigationBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              selectedIndex: currentTab.index,
              onDestinationSelected: (index) {
                ref.read(navigationProvider.notifier).setTab(
                      NavigationTab.values[index],
                    );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_rounded),
                  label: 'Workout',
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_rounded),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
