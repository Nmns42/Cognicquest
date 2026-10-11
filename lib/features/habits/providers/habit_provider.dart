import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/data_failure.dart';
import '../../../shared/models/habit_model.dart';
import '../data/habit_repository.dart';

/// Suivi des habitudes.
///
/// Ne se construit pas avant qu'une session existe : c'est ce qui rendait le
/// module muet au Lot 0, le `user_id` étant systématiquement nul. Depuis le
/// Lot 10, l'état suit la base locale et fonctionne hors ligne.
class HabitNotifier extends StreamNotifier<List<Habit>> {
  HabitRepository? get _repository => ref.read(habitRepositoryProvider);

  @override
  Stream<List<Habit>> build() {
    final repository = ref.watch(habitRepositoryProvider);
    if (repository == null) return Stream.value(const []);
    return repository.watchAll();
  }

  /// Tire-pour-rafraîchir : déclenche une synchronisation.
  Future<void> refresh() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file sera rejouée par le coordinateur.
    }
  }

  Future<void> addHabit(
    String name, {
    HabitFrequency frequency = HabitFrequency.daily,
  }) async {
    final repository = _repository;
    if (repository == null) return;

    final current = state.valueOrNull ?? const <Habit>[];
    try {
      final created =
          await repository.create(name: name.trim(), frequency: frequency);
      state = AsyncValue.data([...current, created]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(DataFailure.from(error), stackTrace);
    }
  }

  Future<void> renameHabit(Habit habit, String name, HabitFrequency frequency) {
    final updated = habit.copyWith(name: name.trim(), frequency: frequency);
    return _mutate(
      optimistic: (habits) =>
          [for (final h in habits) if (h.id == habit.id) updated else h],
      action: (repository) => repository.update(updated),
    );
  }

  Future<void> toggleToday(Habit habit) => toggleOn(habit, DateTime.now());

  Future<void> toggleOn(Habit habit, DateTime day) {
    final updated = habit.withToggleOn(day);
    return _mutate(
      optimistic: (habits) =>
          [for (final h in habits) if (h.id == habit.id) updated else h],
      action: (repository) => repository.setCompletion(
        habit.id,
        day,
        done: updated.isCompletedOn(day),
      ),
    );
  }

  Future<void> deleteHabit(String id) => _mutate(
        optimistic: (habits) => habits.where((h) => h.id != id).toList(),
        action: (repository) => repository.delete(id),
      );

  Future<void> _mutate({
    required List<Habit> Function(List<Habit>) optimistic,
    required Future<void> Function(HabitRepository) action,
  }) async {
    final repository = _repository;
    if (repository == null) return;

    final previous = state;
    final current = state.valueOrNull ?? const <Habit>[];
    state = AsyncValue.data(optimistic(current));

    try {
      await action(repository);
    } catch (error, stackTrace) {
      // L'ancienne version écrasait `state` deux fois de suite, la première
      // affectation étant morte. On restaure l'état puis on signale l'erreur
      // en conservant les données précédentes.
      state = AsyncValue<List<Habit>>.error(DataFailure.from(error), stackTrace)
          .copyWithPrevious(previous);
    }
  }
}

final habitProvider = StreamNotifierProvider<HabitNotifier, List<Habit>>(
  HabitNotifier.new,
);

/// Agrégat affiché en tête du tracker : combien d'habitudes validées ce jour.
final habitsCompletedTodayProvider = Provider<int>((ref) {
  final habits = ref.watch(habitProvider).valueOrNull ?? const <Habit>[];
  return habits.where((h) => h.completedToday).length;
});

/// Meilleure série tous crédits confondus, pour la gamification (Lot 10).
final bestHabitStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitProvider).valueOrNull ?? const <Habit>[];
  return habits.fold<int>(0, (best, h) => h.streak > best ? h.streak : best);
});
