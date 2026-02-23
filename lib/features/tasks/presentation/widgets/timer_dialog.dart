import 'dart:async';
import 'package:flutter/material.dart';
import 'package:life_os/features/tasks/domain/task_model.dart';

class TimerDialog extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;

  const TimerDialog({
    super.key,
    required this.task,
    required this.onComplete,
  });

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  late int remainingSeconds;
  Timer? _timer;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    remainingSeconds = (widget.task.timerDuration ?? 0) * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (isRunning) return;
    setState(() => isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() => isRunning = false);
        widget.onComplete();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void _completeEarly() {
    _timer?.cancel();
    widget.onComplete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final totalSeconds = (widget.task.timerDuration ?? 1) * 60;
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    
    final minutesRaw = remainingSeconds ~/ 60;
    final secondsRaw = remainingSeconds % 60;
    final timeString = '${minutesRaw.toString().padLeft(2, '0')}:${secondsRaw.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.task.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: cs.outline.withValues(alpha: 0.2),
                    color: cs.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isRunning)
                  FloatingActionButton(
                    onPressed: _startTimer,
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    child: const Icon(Icons.play_arrow, size: 32),
                  )
                else
                  FloatingActionButton(
                    onPressed: _pauseTimer,
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                    elevation: 0,
                    child: const Icon(Icons.pause, size: 32),
                  ),
                FilledButton.tonal(
                  onPressed: _completeEarly,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Complete'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
