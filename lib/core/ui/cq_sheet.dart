import 'package:flutter/material.dart';

import '../motion/reduce_motion.dart';
import '../theme/tokens.dart';

/// Ouvre une feuille du bas avec titre, sur le modèle commun à toute l'app :
/// poignée visible, marges des jetons, défilement si le contenu dépasse,
/// clavier pris en compte.
Future<T?> showCqSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: Motion.style(context),
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      // Le clavier ne doit pas recouvrir le champ en cours de saisie.
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(title,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            const SizedBox(height: Space.lg),
            builder(sheetContext),
          ],
        ),
      ),
    ),
  );
}
