import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/metacognition_model.dart';
import '../data/metacognition_repository.dart';
import '../providers/metacognition_provider.dart';

/// Méthode des 5 Pourquoi : remonter d'un blocage constaté à sa cause réelle.
///
/// La sortie est typée (`BlockerType`), ce qui répond à l'exigence du CdC :
/// « un module pour identifier si le frein est cognitif, émotionnel, sensoriel
/// ou environnemental ».
class WhyChainPage extends ConsumerStatefulWidget {
  const WhyChainPage({super.key});

  @override
  ConsumerState<WhyChainPage> createState() => _WhyChainPageState();
}

class _WhyChainPageState extends ConsumerState<WhyChainPage> {
  final _problemController = TextEditingController();
  final _answerController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _actionController = TextEditingController();

  List<String> _answers = [];
  BlockerType? _blockerType;
  WhyChain? _editing;

  @override
  void dispose() {
    _problemController.dispose();
    _answerController.dispose();
    _rootCauseController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  int get _depth => _answers.where((a) => a.trim().isNotEmpty).length;

  bool get _canGoDeeper => _depth < WhyChain.maxDepth;

  void _addAnswer() {
    final text = _answerController.text.trim();
    if (text.isEmpty || !_canGoDeeper) return;
    setState(() {
      _answers = [..._answers, text];
      _answerController.clear();
    });
  }

  void _removeAnswer(int index) {
    setState(() {
      // On coupe la chaîne à partir de l'élément retiré : les « pourquoi »
      // suivants découlaient de celui-ci, les garder n'aurait aucun sens.
      _answers = _answers.sublist(0, index);
    });
  }

  void _load(WhyChain chain) {
    setState(() {
      _editing = chain;
      _problemController.text = chain.problem;
      _answers = List<String>.from(chain.answers);
      _rootCauseController.text = chain.rootCause;
      _actionController.text = chain.actionPlan;
      _blockerType = chain.blockerType;
      _answerController.clear();
    });
  }

  void _reset() {
    setState(() {
      _editing = null;
      _problemController.clear();
      _answerController.clear();
      _rootCauseController.clear();
      _actionController.clear();
      _answers = [];
      _blockerType = null;
    });
  }

  Future<void> _save() async {
    final problem = _problemController.text.trim();
    if (problem.isEmpty) return;

    final editing = _editing;
    await ref.read(metacognitionActionsProvider).saveWhyChain(
          WhyChain(
            id: editing?.id ?? newMetacognitionId(),
            userId: editing?.userId ?? '',
            problem: problem,
            answers: _answers,
            rootCause: _rootCauseController.text.trim(),
            blockerType: _blockerType,
            actionPlan: _actionController.text.trim(),
            createdAt: editing?.createdAt ?? DateTime.now(),
            isSynced: false,
          ),
        );

    if (!mounted) return;
    _reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analyse enregistrée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chains = ref.watch(whyChainsProvider).valueOrNull ?? const <WhyChain>[];
    final hasProblem = _problemController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Les 5 Pourquoi'),
        actions: [
          if (_editing != null)
            TextButton(onPressed: _reset, child: const Text('Nouveau')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
             Text(
              'Pars du blocage constaté et demande « pourquoi » jusqu\'à '
              'tomber sur quelque chose que tu peux changer.',
              style: TextStyle(
                  fontSize: 12.5, color: context.cq.textMuted, height: 1.45),
            ),
            const SizedBox(height: 20),

            const _Label('Le blocage'),
            const SizedBox(height: 8),
            TextField(
              controller: _problemController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ex : « Je n\'ai pas révisé hier soir »',
              ),
            ),

            if (hasProblem) ...[
              const SizedBox(height: 22),
              for (var i = 0; i < _answers.length; i++)
                _WhyStep(
                  index: i,
                  answer: _answers[i],
                  onRemove: () => _removeAnswer(i),
                ),

              if (_canGoDeeper) ...[
                const SizedBox(height: 8),
                _Label('Pourquoi ${_depth + 1} ?'),
                const SizedBox(height: 8),
                TextField(
                  controller: _answerController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _addAnswer(),
                  decoration: InputDecoration(
                    hintText: _depth == 0
                        ? 'Pourquoi cela est-il arrivé ?'
                        : 'Et pourquoi cela ?',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      tooltip: 'Creuser',
                      onPressed: _addAnswer,
                    ),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: context.cq.vert.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:  Text(
                    'Cinq niveaux atteints. Si la cause n\'est toujours pas '
                    'claire, c\'est souvent que le vrai problème est ailleurs '
                    'que là où tu cherches.',
                    style: TextStyle(
                        fontSize: 12, color: context.cq.vertDark, height: 1.4),
                  ),
                ),

              if (_depth >= 2) ...[
                const SizedBox(height: 24),
                const _Label('La cause réelle'),
                const SizedBox(height: 8),
                TextField(
                  controller: _rootCauseController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Formule-la en une phrase',
                  ),
                ),
                const SizedBox(height: 22),

                const _Label('De quelle nature est ce frein ?'),
                const SizedBox(height: 10),
                for (final type in BlockerType.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BlockerOption(
                      type: type,
                      isSelected: _blockerType == type,
                      onTap: () => setState(() =>
                          _blockerType = _blockerType == type ? null : type),
                    ),
                  ),
                const SizedBox(height: 14),

                const _Label('Que fais-tu concrètement ?'),
                const SizedBox(height: 4),
                 Text(
                  'Une action, pas une intention. Sinon l\'analyse ne sert '
                  'qu\'à ruminer.',
                  style: TextStyle(fontSize: 11.5, color: context.cq.textMuted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _actionController,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ex : « Je pose mon téléphone dans l\'entrée »',
                  ),
                ),
              ],

              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: _save,
                child: Text(_editing == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ],

            if (chains.isNotEmpty) ...[
              const SizedBox(height: 30),
               Text(
                'Tes analyses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final chain in chains)
                _ChainRow(chain: chain, onTap: () => _load(chain)),
            ],
          ],
        ),
      ),
    );
  }
}

class _WhyStep extends StatelessWidget {
  const _WhyStep({
    required this.index,
    required this.answer,
    required this.onRemove,
  });

  final int index;
  final String answer;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: index * 10.0, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cq.vert.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style:  TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.cq.vertDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              answer,
              style:  TextStyle(
                  fontSize: 13, color: context.cq.textPrimary, height: 1.4),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
            tooltip: 'Reprendre à partir d\'ici',
            icon:  Icon(Icons.undo, size: 15, color: context.cq.textHint),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _BlockerOption extends StatelessWidget {
  const _BlockerOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final BlockerType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Motion.duration(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? context.cq.vert.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              size: 17,
              color: isSelected ? context.cq.vert : context.cq.textHint,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style:  TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.cq.textPrimary)),
                  const SizedBox(height: 1),
                  Text(type.description,
                      style:  TextStyle(
                          fontSize: 11.5, color: context.cq.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  const _ChainRow({required this.chain, required this.onTap});

  final WhyChain chain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chain.problem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cq.textPrimary,
                    height: 1.35),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Tag('${chain.depth} pourquoi'),
                  if (chain.blockerType != null)
                    _Tag(chain.blockerType!.label, highlighted: true),
                  if (!chain.isComplete) const _Tag('à finir', warning: true),
                ],
              ),
              if (chain.rootCause.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Cause : ${chain.rootCause}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:  TextStyle(
                      fontSize: 12, color: context.cq.textMuted, height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.highlighted = false, this.warning = false});

  final String label;
  final bool highlighted;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? const Color(0xFFE39A3B)
        : (highlighted ? context.cq.vertDark : context.cq.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:  TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}
