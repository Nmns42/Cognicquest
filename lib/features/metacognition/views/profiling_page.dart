import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../graph/providers/graph_provider.dart';
import '../../reminders/reminder_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../domain/learning_profile.dart';
import '../domain/profile_playbook.dart';
import '../providers/metacognition_provider.dart';
import '../../../core/theme/tokens.dart';

/// Onboarding de profilage — « un questionnaire initial pour aider l'étudiant
/// à comprendre son propre mode d'emploi avant de commencer » (CdC).
class ProfilingPage extends ConsumerStatefulWidget {
  const ProfilingPage({super.key});

  @override
  ConsumerState<ProfilingPage> createState() => _ProfilingPageState();
}

class _ProfilingPageState extends ConsumerState<ProfilingPage> {
  Map<String, String> _answers = {};
  int _index = 0;
  bool _hydrated = false;
  bool _showResult = false;

  void _hydrate(LearningProfile profile) {
    if (_hydrated) return;
    _hydrated = true;

    _answers = Map<String, String>.from(profile.answers);
    if (profile.isComplete) {
      _showResult = true;
      return;
    }
    // On reprend à la première question sans réponse plutôt qu'au début.
    final firstUnanswered = ProfilingQuestionnaire.questions
        .indexWhere((q) => !_answers.containsKey(q.id));
    _index = firstUnanswered == -1 ? 0 : firstUnanswered;
  }

  Future<void> _choose(String questionId, String value) async {
    setState(() => _answers = {..._answers, questionId: value});

    final isLast = _index >= ProfilingQuestionnaire.questions.length - 1;
    await ref
        .read(metacognitionActionsProvider)
        .saveProfileAnswers(_answers, complete: isLast);

    if (!mounted) return;
    setState(() {
      if (isLast) {
        _showResult = true;
      } else {
        _index++;
      }
    });
  }

  void _restart() {
    setState(() {
      _answers = {};
      _index = 0;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(learningProfileProvider);
    final profile = profileAsync.valueOrNull;

    if (profile == null) {
      return  Scaffold(
        body: Center(child: CircularProgressIndicator(color: context.cq.vertDark)),
      );
    }
    _hydrate(profile);

    if (_showResult) {
      return _ResultScaffold(
        profile: ProfilingQuestionnaire.score(
          _answers,
          completedAt: profile.completedAt ?? DateTime.now(),
        ),
        onRestart: _restart,
      );
    }

    final question = ProfilingQuestionnaire.questions[_index];
    final total = ProfilingQuestionnaire.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_index + 1} / $total'),
        leading: _index == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _index--),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _index / total,
            minHeight: 3,
            backgroundColor: context.cq.beigeDark,
            color: context.cq.vertDark,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text(
              question.prompt,
              style:  TextStyle(
                fontSize: TypeScale.title,
                fontWeight: FontWeight.w600,
                color: context.cq.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
             Text(
              'Il n\'y a pas de bonne réponse : seulement la tienne.',
              style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
            const SizedBox(height: 24),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionCard(
                  label: option.label,
                  isSelected: _answers[question.id] == option.value,
                  onTap: () => _choose(question.id, option.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: AnimatedContainer(
        duration: Motion.duration(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.cq.vert.withValues(alpha: 0.1)
              : context.cq.cardColor,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: isSelected ? context.cq.vert : context.cq.beigeDark,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 19,
              color: isSelected ? context.cq.vert : context.cq.textHint,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style:  TextStyle(
                    fontSize: TypeScale.body, color: context.cq.textPrimary, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultScaffold extends StatelessWidget {
  const _ResultScaffold({required this.profile, required this.onRestart});

  final LearningProfile profile;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final style = profile.processingStyle;
    final channel = profile.preferredChannel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ton mode d\'emploi'),
        actions: [
          TextButton(onPressed: onRestart, child: const Text('Refaire')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (style != null)
              _TraitCard(
                icon: style == ProcessingStyle.global
                    ? Icons.hub_outlined
                    : Icons.list_alt_outlined,
                title: 'Profil ${style.label.toLowerCase()}',
                description: style.description,
              ),
            if (style != null && channel != null) const SizedBox(height: 12),
            if (channel != null)
              _TraitCard(
                icon: switch (channel) {
                  PreferredChannel.visual => Icons.image_outlined,
                  PreferredChannel.auditory => Icons.hearing_outlined,
                  PreferredChannel.kinesthetic => Icons.pan_tool_outlined,
                  PreferredChannel.reading => Icons.menu_book_outlined,
                },
                title: 'Canal ${channel.label.toLowerCase()}',
                description: channel.description,
              ),

            if (style == null || channel == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cq.beigeDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child:  Text(
                  // On préfère ne rien affirmer plutôt que de trancher au
                  // hasard : un profil inventé serait pire qu'un profil absent.
                  'Tes réponses sont partagées sur une dimension : aucun profil '
                  'ne se dégage nettement. C\'est fréquent, et plutôt bon signe '
                  '— tu t\'adaptes selon les situations.',
                  style: TextStyle(
                      fontSize: TypeScale.caption,
                      color: context.cq.textMuted,
                      height: 1.45),
                ),
              ),
            ],

            if (profile.recommendations.isNotEmpty) ...[
              const SizedBox(height: 24),
               Text(
                'Ce que CognicQuest te conseille',
                style: TextStyle(
                  fontSize: TypeScale.body,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final tip in profile.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: context.cq.vert.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(
                          color: context.cq.vert.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Icon(Icons.check_circle_outline,
                            size: 16, color: context.cq.vertDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style:  TextStyle(
                                fontSize: TypeScale.caption,
                                color: context.cq.textPrimary,
                                height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            if (style != null || channel != null) ...[
              const SizedBox(height: Space.xl),
              _PlaybookSection(profile: profile),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Retour au journal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mode d'emploi détaillé : pour chaque conseil, pourquoi il convient à ce
/// profil, comment l'appliquer dans CognicQuest, et le réglage à poser
/// d'un appui (Pomodoro, graphe, rappel) ou l'écran à ouvrir.
class _PlaybookSection extends ConsumerWidget {
  const _PlaybookSection({required this.profile});

  final LearningProfile profile;

  Future<void> _apply(
      BuildContext context, WidgetRef ref, PlaybookAction action) async {
    String? done;
    switch (action) {
      case PomodoroPreset():
        final settings = ref.read(settingsProvider.notifier);
        settings.setPomodoro(ref.read(settingsProvider).pomodoro.copyWith(
              workMinutes: action.work,
              shortBreakMinutes: action.shortBreak,
              longBreakMinutes: action.longBreak,
              sessionsBeforeLongBreak: action.sessions,
            ));
        done = 'Pomodoro réglé : ${action.work} / ${action.shortBreak} min, '
            '${action.sessions} sessions.';
      case GraphOverviewPreset():
        ref.read(graphSettingsProvider.notifier).update((s) =>
            s.copyWith(colorByFolder: true, groupByFolder: true));
        done = 'Graphe : couleurs et regroupement par dossier activés.';
      case DailyReminderPreset():
        await ref.read(reminderServiceProvider).requestPermission();
        final settings = ref.read(settingsProvider.notifier);
        settings.setDailyReminderMinutes(action.minutes);
        settings.setDailyReminder(true);
        done = 'Rappel quotidien activé à '
            '${reminderTimeLabel(action.minutes)}.';
      case OpenScreen():
        if (context.mounted) await context.push(action.route);
    }
    if (done != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarAnimationStyle: Motion.style(context),
        SnackBar(content: Text(done)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final advice = ProfilePlaybook.of(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ton mode d’emploi détaillé',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Space.xs),
        Text(
          'Chaque conseil s’appuie sur ton profil et se règle dans '
          'CognicQuest d’un appui.',
          style: TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
        ),
        const SizedBox(height: Space.md),
        for (final item in advice)
          Container(
            margin: const EdgeInsets.only(bottom: Space.md),
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: cq.cardColor,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: cq.beigeDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(item.title,
                    style: TextStyle(
                        fontSize: TypeScale.bodyLarge,
                        fontWeight: FontWeight.w600,
                        color: cq.textPrimary)),
                const SizedBox(height: Space.xs),
                Text(item.why,
                    style: TextStyle(
                        fontSize: TypeScale.caption,
                        color: cq.terre,
                        height: TypeScale.bodyHeight)),
                const SizedBox(height: Space.sm),
                for (final step in item.steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(Icons.check,
                              size: Sizes.iconSm, color: cq.vertSauge),
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(step,
                              style: TextStyle(
                                  fontSize: TypeScale.body,
                                  color: cq.textPrimary,
                                  height: TypeScale.bodyHeight)),
                        ),
                      ],
                    ),
                  ),
                if (item.action case final action?) ...[
                  const SizedBox(height: Space.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: () => _apply(context, ref, action),
                      icon: Icon(
                        action is OpenScreen
                            ? Icons.arrow_forward
                            : Icons.tune,
                        size: Sizes.iconSm,
                      ),
                      label: Text(action.label),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TraitCard extends StatelessWidget {
  const _TraitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cq.vert,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: context.onAccent),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: context.onAccent,
              fontSize: TypeScale.title,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style:  TextStyle(
                color: context.cq.onVertMuted, fontSize: TypeScale.body, height: 1.4),
          ),
        ],
      ),
    );
  }
}
