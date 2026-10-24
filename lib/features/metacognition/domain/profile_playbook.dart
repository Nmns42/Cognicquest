import 'learning_profile.dart';

/// Réglage que CognicQuest peut appliquer d'un appui, depuis un conseil.
sealed class PlaybookAction {
  const PlaybookAction(this.label);

  final String label;
}

/// Durées du Pomodoro adaptées au profil.
class PomodoroPreset extends PlaybookAction {
  const PomodoroPreset(
    super.label, {
    required this.work,
    required this.shortBreak,
    required this.longBreak,
    required this.sessions,
  });

  final int work;
  final int shortBreak;
  final int longBreak;
  final int sessions;
}

/// Graphe : vue d'ensemble regroupée par dossier, en couleur.
class GraphOverviewPreset extends PlaybookAction {
  const GraphOverviewPreset(super.label);
}

/// Rappel quotidien de révision.
class DailyReminderPreset extends PlaybookAction {
  const DailyReminderPreset(super.label, {required this.minutes});

  final int minutes;
}

/// Ouvre l'écran utile.
class OpenScreen extends PlaybookAction {
  const OpenScreen(super.label, this.route);

  final String route;
}

/// Un conseil : quoi faire, pourquoi ça marche pour ce profil, comment le
/// faire dans CognicQuest, et le réglage à appliquer.
class PlaybookAdvice {
  const PlaybookAdvice({
    required this.title,
    required this.why,
    required this.steps,
    this.action,
  });

  final String title;
  final String why;
  final List<String> steps;
  final PlaybookAction? action;
}

/// Mode d'emploi détaillé, tiré du style de traitement et du canal
/// privilégié (complète les recommandations courtes du profil).
abstract final class ProfilePlaybook {
  static List<PlaybookAdvice> of(LearningProfile profile) => [
        ..._forStyle(profile.processingStyle),
        ..._forChannel(profile.preferredChannel),
        // Valable pour tous : la récupération active et l'espacement sont
        // les deux leviers les mieux établis.
        const PlaybookAdvice(
          title: 'Teste-toi plutôt que relire',
          why: 'Se rappeler une notion la consolide bien plus que la relire '
              '(effet de test), et l’espacer l’ancre durablement.',
          steps: [
            'Après chaque lecture, lance un quiz ciblé sur la fiche.',
            'Laisse la méthode des J espacer tes cartes : ne les révise pas '
                'avant leur échéance.',
            'Vise un taux de rétention entre 85 et 90 % (Révisions).',
          ],
          action: OpenScreen('Lancer un quiz ciblé', '/review/quiz'),
        ),
      ];

  static List<PlaybookAdvice> _forStyle(ProcessingStyle? style) =>
      switch (style) {
        ProcessingStyle.global => const [
            PlaybookAdvice(
              title: 'Commence par la carte, pas par le détail',
              why: 'Un esprit global retient mieux quand chaque notion trouve '
                  'sa place dans un ensemble déjà visible.',
              steps: [
                'Ouvre le graphe avant un nouveau chapitre : repère les '
                    'carrefours et les îlots.',
                'Range tes fiches par dossier de matière : le graphe les '
                    'colore et les regroupe.',
                'En étude guidée, fais toujours le survol complet avant de '
                    'lire.',
              ],
              action: GraphOverviewPreset(
                  'Graphe : couleurs et regroupement par dossier'),
            ),
            PlaybookAdvice(
              title: 'Des sessions longues pour plonger',
              why: 'Il te faut le temps d’embrasser un sujet entier : des '
                  'sessions de 25 min coupent l’élan trop tôt.',
              steps: [
                'Sessions de 45 min, pauses de 10 min, 3 sessions par cycle.',
                'Pendant la pause longue, relie au graphe ce que tu viens '
                    'd’apprendre.',
              ],
              action: PomodoroPreset('Pomodoro 45 / 10 × 3',
                  work: 45, shortBreak: 10, longBreak: 20, sessions: 3),
            ),
          ],
        ProcessingStyle.sequential => const [
            PlaybookAdvice(
              title: 'Une étape après l’autre, dans l’ordre',
              why: 'Un esprit séquentiel progresse quand chaque pas s’appuie '
                  'sur le précédent, sans sauter d’étape.',
              steps: [
                'Structure tes fiches en titres numérotés (Titre 2, Titre 3) : '
                    'le quiz interroge section par section.',
                'Suis l’ordre de « Ordre & vitesse » : il classe les chapitres '
                    'par rentabilité.',
                'Une seule tâche « En cours » à la fois dans le Kanban.',
              ],
              action: OpenScreen('Ouvrir Ordre & vitesse', '/planning/order'),
            ),
            PlaybookAdvice(
              title: 'Un rythme régulier et court',
              why: 'Des blocs courts et réguliers rendent la progression '
                  'visible et évitent la surcharge.',
              steps: [
                'Sessions de 25 min, pauses de 5 min, 4 sessions par cycle.',
                'Coche une habitude « révision quotidienne » chaque jour.',
              ],
              action: PomodoroPreset('Pomodoro 25 / 5 × 4',
                  work: 25, shortBreak: 5, longBreak: 15, sessions: 4),
            ),
          ],
        null => const [],
      };

  static List<PlaybookAdvice> _forChannel(PreferredChannel? channel) =>
      switch (channel) {
        PreferredChannel.visual => const [
            PlaybookAdvice(
              title: 'Rends tes fiches visuelles',
              why: 'L’information mise en forme et en couleur est mieux '
                  'encodée par un apprenant visuel.',
              steps: [
                'Surligne une couleur par fonction : jaune = définition, vert '
                    '= exemple, rose = piège.',
                'Ajoute un schéma (bloc Image) par fiche, et annote tes PDF.',
                'Centre les formules clés pour qu’elles ressortent.',
              ],
              action: OpenScreen('Ouvrir mes fiches', '/notes'),
            ),
          ],
        PreferredChannel.auditory => const [
            PlaybookAdvice(
              title: 'Explique à voix haute',
              why: 'Formuler à l’oral oblige à organiser sa pensée et révèle '
                  'immédiatement ce qui n’est pas compris.',
              steps: [
                'En étude guidée, dis ton explication avant de l’écrire.',
                'Lis tes cartes à voix haute pendant la révision.',
                'Un rappel quotidien à heure fixe installe la routine.',
              ],
              action: DailyReminderPreset('Rappel quotidien à 18 h',
                  minutes: 18 * 60),
            ),
          ],
        PreferredChannel.kinesthetic => const [
            PlaybookAdvice(
              title: 'Apprends en faisant, bouge entre les sessions',
              why: 'La pratique et le mouvement soutiennent l’attention d’un '
                  'apprenant kinesthésique.',
              steps: [
                'Sessions courtes de 20 min, pauses actives de 5 min (marche, '
                    'étirements).',
                'Privilégie les exercices aux relectures : mesure ta vitesse '
                    'en « Exercices ».',
                'Une habitude « sport » dans le tracker soutient la '
                    'concentration.',
              ],
              action: PomodoroPreset('Pomodoro 20 / 5 × 4',
                  work: 20, shortBreak: 5, longBreak: 15, sessions: 4),
            ),
          ],
        PreferredChannel.reading => const [
            PlaybookAdvice(
              title: 'Reformule par écrit',
              why: 'Réécrire avec ses mots est le canal d’encodage le plus '
                  'efficace pour un apprenant lecture / écriture.',
              steps: [
                'Écris tes définitions sous la forme « terme : sens » : le '
                    'quiz les transforme en questions.',
                'Mets en gras les mots-clés : ils deviennent des textes à '
                    'trous.',
                'Exporte tes fiches en PDF pour les relire hors écran.',
              ],
              action: OpenScreen('Ouvrir mes fiches', '/notes'),
            ),
          ],
        null => const [],
      };
}
