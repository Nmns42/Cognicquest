import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/models/task_model.dart';

/// Blocs de la grille « bento » du tableau de bord (direction éditoriale :
/// fond lin, cartes blanches à filet fin, tuiles pierre, accents rares).

/// En-tête sans conteneur : salutation en serif, date en écorce.
class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.greeting,
    required this.name,
    required this.dateLabel,
  });

  final String greeting;
  final String name;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            name.isEmpty ? '$greeting !' : '$greeting, $name !',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: TypeScale.bodyLarge,
            fontWeight: FontWeight.w400,
            color: context.cq.terre,
          ),
        ),
      ],
    );
  }
}

/// Carte blanche « Démarrer une session » : la tâche en cours en sous-titre
/// et un bouton compact vert forêt, la seule action principale de l'écran.
class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.subtitle, required this.onStart});

  final String subtitle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return CqCard(
      radius: Radii.card,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Démarrer une session',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Space.sm),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: TypeScale.body, color: context.cq.textMuted),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm)),
            ),
            child: const Text('Lancer le Pomodoro'),
          ),
        ],
      ),
    );
  }
}

/// Tuile KPI : le chiffre en gras (chiffres tabulaires) suivi du libellé.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.value,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String value;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.card),
      side: BorderSide(color: cq.beigeDark),
    );
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cq.sauge,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.lg, vertical: Space.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' $label'),
                  ]),
                  style: TextStyle(
                    fontSize: TypeScale.bodyLarge,
                    color: cq.textPrimary,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grille 2 × 2 de tuiles KPI. [fill] : remplit la hauteur imposée par la
/// rangée (grand écran, à côté de la carte de session).
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.tiles, this.fill = false})
      : assert(tiles.length == 4);

  final List<KpiTile> tiles;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    Widget row(KpiTile a, KpiTile b) {
      final line = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: Space.md),
          Expanded(child: b),
        ],
      );
      return fill ? Expanded(child: line) : IntrinsicHeight(child: line);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(tiles[0], tiles[1]),
        const SizedBox(height: Space.md),
        row(tiles[2], tiles[3]),
      ],
    );
  }
}

/// Puce ronde de 8 px.
class Dot extends StatelessWidget {
  const Dot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: Space.sm,
        height: Space.sm,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Badge pilule sauge (statut, matière).
class SagePill extends StatelessWidget {
  const SagePill({super.key, required this.label, this.warm = false});

  final String label;

  /// Écorce plutôt que sauge (en retard).
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.sm, vertical: Space.xs / 2),
      decoration: BoxDecoration(
        color: warm ? cq.terre : cq.vertSauge,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: TypeScale.caption,
          fontWeight: FontWeight.w600,
          // Le fond de l'app tient ≥ 4,5:1 sur la sauge et l'écorce.
          color: cq.beige,
        ),
      ),
    );
  }
}

/// Petite carte de tâche : titre, puce de priorité en haut à droite, statut
/// en pilule en bas à gauche.
class TaskMiniCard extends StatelessWidget {
  const TaskMiniCard({super.key, required this.task, required this.onOpen});

  final Task task;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final priority = switch (task.priority) {
      TaskPriority.high => cq.terre,
      TaskPriority.medium => cq.terre.withValues(alpha: 0.55),
      TaskPriority.low => cq.beigeDark,
    };
    return CqCard(
      radius: Radii.card,
      onTap: onOpen,
      semanticLabel: '${task.title}, ${task.status.label}, '
          'priorité ${task.priority.label.toLowerCase()}',
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: TypeScale.body, color: cq.textPrimary),
                ),
              ),
              const SizedBox(width: Space.sm),
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Dot(color: priority),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          SagePill(
            label: task.isOverdue ? 'En retard' : task.status.label,
            warm: task.isOverdue,
          ),
        ],
      ),
    );
  }
}

/// Case à cocher carrée, angles de 4 px, sauge une fois cochée.
class SquareCheck extends StatelessWidget {
  const SquareCheck({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      width: Sizes.iconMd,
      height: Sizes.iconMd,
      decoration: BoxDecoration(
        color: checked ? cq.vertSauge : cq.cardColor,
        borderRadius: BorderRadius.circular(Radii.xs),
        border: Border.all(
            color: checked ? cq.vertSauge : cq.textHint, width: Borders.thin),
      ),
      child: checked
          ? Icon(Icons.check, size: Sizes.iconSm, color: cq.beige)
          : null,
    );
  }
}

/// Ligne de liste posée sur le fond : case (ou puce), texte, indicateur
/// écorce aligné à droite.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    super.key,
    required this.label,
    this.checked,
    this.trailing,
    this.onTap,
  });

  final String label;

  /// `null` : une puce au lieu d'une case (ligne non cochable).
  final bool? checked;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Semantics(
      checked: checked,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Row(
            children: [
              if (checked != null)
                SquareCheck(checked: checked!)
              else
                SizedBox(
                  width: Sizes.iconMd,
                  child: Center(child: Dot(color: cq.vertSauge)),
                ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: TypeScale.body, color: cq.textPrimary),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Space.sm),
                Dot(color: cq.terre),
                const SizedBox(width: Space.xs),
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: cq.terre,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section de liste sans carte englobante : titre en serif et lignes.
class ListSection extends StatelessWidget {
  const ListSection({
    super.key,
    required this.title,
    required this.children,
    this.emptyMessage,
  });

  final String title;
  final List<Widget> children;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: Space.sm),
        if (children.isEmpty && emptyMessage != null)
          Text(
            emptyMessage!,
            style: TextStyle(
                fontSize: TypeScale.body, color: context.cq.textMuted),
          )
        else
          ...children,
      ],
    );
  }
}

/// Carte « Mon arbre de croissance » : l'arbre compagnon, sobrement encadré.
class GrowthTreeCard extends StatelessWidget {
  const GrowthTreeCard({super.key, required this.growth});

  final double growth;

  @override
  Widget build(BuildContext context) {
    return CqCard(
      radius: Radii.card,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mon arbre de croissance',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.md),
          AspectRatio(
            aspectRatio: 0.85,
            child: MindfulTreeIllustration(growth: growth),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Régularité : ${(growth.clamp(0.0, 1.0) * 100).round()} % '
            'sur 30 jours',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TypeScale.caption,
              color: context.cq.textMuted,
              fontFeatures: TypeScale.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
