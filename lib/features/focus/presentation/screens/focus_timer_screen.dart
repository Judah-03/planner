import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:planner/core/constants/app_colors.dart';
import 'package:planner/features/focus/presentation/providers/focus_provider.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> with TickerProviderStateMixin {
  static const int _workDuration = 25 * 60; // 25 minutes
  static const int _breakDuration = 5 * 60; // 5 minutes

  int _timeRemaining = _workDuration;
  bool _isRunning = false;
  bool _isWorkTime = true;
  Timer? _timer;

  late AnimationController _progressController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _timer?.cancel();
        
        // Save session to backend
        final duration = _isWorkTime ? _workDuration : _breakDuration;
        final type = _isWorkTime ? 'work' : 'break';
        ref.read(focusProvider.notifier).addSession(duration ~/ 60, type);

        if (_isWorkTime) {
          _confettiController.play();
        }

        setState(() {
          _isRunning = false;
          _isWorkTime = !_isWorkTime;
          _timeRemaining = _isWorkTime ? _workDuration : _breakDuration;
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timeRemaining = _isWorkTime ? _workDuration : _breakDuration;
    });
    _timer?.cancel();
  }

  void _skipSession() {
    setState(() {
      _isRunning = false;
      _isWorkTime = !_isWorkTime;
      _timeRemaining = _isWorkTime ? _workDuration : _breakDuration;
    });
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String minutesStr = (_timeRemaining ~/ 60).toString().padLeft(2, '0');
    final String secondsStr = (_timeRemaining % 60).toString().padLeft(2, '0');
    final double progress = _isWorkTime
        ? 1 - (_timeRemaining / _workDuration)
        : 1 - (_timeRemaining / _breakDuration);

    final activeColor = _isWorkTime ? AppColors.primary : AppColors.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mode Concentration', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isWorkTime ? Icons.laptop_mac_rounded : Icons.coffee_rounded, color: activeColor),
                  const SizedBox(width: 12),
                  Text(
                    _isWorkTime ? 'Temps de travail (25 min)' : 'Temps de pause (5 min)',
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$minutesStr:$secondsStr',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRunning ? 'EN COURS' : 'EN PAUSE',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: _isRunning ? 1 : 0.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(20),
                      iconSize: 32,
                    ),
                  ),
                  FloatingActionButton.large(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    backgroundColor: activeColor,
                    elevation: 10,
                    child: Icon(
                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  IconButton(
                    onPressed: _skipSession,
                    icon: const Icon(Icons.skip_next_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(20),
                      iconSize: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [AppColors.primary, AppColors.secondary, Colors.orange, Colors.purple],
        ),
      ),
    ],
  ),
);
  }
}
