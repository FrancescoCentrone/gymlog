import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/services/notification_service.dart';

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isActive;

  RestTimerState({
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.isActive = false,
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isActive,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isActive: isActive ?? this.isActive,
    );
  }

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(RestTimerState());

  void startTimer(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isActive: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        if (state.remainingSeconds == 0) {
          _onTimerEnd();
        }
      } else {
        _timer?.cancel();
        state = state.copyWith(isActive: false);
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isActive: false, remainingSeconds: 0);
  }

  void _onTimerEnd() {
    _timer?.cancel();
    state = state.copyWith(isActive: false);
    NotificationService().showNotification(
      title: 'Rest Over!',
      body: 'Time for your next set.',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});
