import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavigationTab {
  dashboard,
  workout,
  analytics,
  profile;
}

class NavigationNotifier extends StateNotifier<NavigationTab> {
  NavigationNotifier() : super(NavigationTab.dashboard);

  void setTab(NavigationTab tab) {
    state = tab;
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationTab>(
  (ref) => NavigationNotifier(),
);

