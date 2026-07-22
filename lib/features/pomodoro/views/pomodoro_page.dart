import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/pomodoro_provider.dart';

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    final isWork    = state.type == PomodoroType.work;
    final isRunning = state.status == PomodoroStatus.running;
    final color     = isWork
        ? const Color(0xFF7A9E7E)
        : const Color(0xFF7A9E7E).withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${state.coins}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Label type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isWork ? 'Temps de travail' : 'Pause',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Cercle progress
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: state.progress,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFD8CFC2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.timeDisplay,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2A),
                        ),
                      ),
                      if (state.status == PomodoroStatus.finished)
                        const Text(
                          'Terminé !',
                          style: TextStyle(
                            color: Color(0xFF7A9E7E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                IconButton(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 32,
                  color: const Color(0xFF6B6B68),
                ),
                const SizedBox(width: 24),

                // Start / Pause
                GestureDetector(
                  onTap: isRunning ? notifier.pause : notifier.start,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Placeholder pour symétrie
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 48),

            // Sessions du jour
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final done = i < (state.completedSessions % 4);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? const Color(0xFF7A9E7E)
                        : const Color(0xFFD8CFC2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.completedSessions} session${state.completedSessions > 1 ? 's' : ''} complétée${state.completedSessions > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Color(0xFF6B6B68),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
