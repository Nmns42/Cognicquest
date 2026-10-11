import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/learning_profile.dart';
import '../providers/metacognition_provider.dart';

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
        body: Center(child: CircularProgressIndicator(color: context.cq.vert)),
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
            color: context.cq.vert,
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
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: context.cq.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
             Text(
              'Il n\'y a pas de bonne réponse : seulement la tienne.',
              style: TextStyle(fontSize: 12, color: context.cq.textMuted),
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Motion.duration(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.cq.vert.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                    fontSize: 14, color: context.cq.textPrimary, height: 1.35),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Text(
                  // On préfère ne rien affirmer plutôt que de trancher au
                  // hasard : un profil inventé serait pire qu'un profil absent.
                  'Tes réponses sont partagées sur une dimension : aucun profil '
                  'ne se dégage nettement. C\'est fréquent, et plutôt bon signe '
                  '— tu t\'adaptes selon les situations.',
                  style: TextStyle(
                      fontSize: 12.5,
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
                  fontSize: 14,
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
                      borderRadius: BorderRadius.circular(12),
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
                                fontSize: 12.5,
                                color: context.cq.textPrimary,
                                height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style:  TextStyle(
                color: context.cq.onVertMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
