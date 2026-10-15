# Règles d'Économie de Tokens (RTK + Agents Chirurgicaux)

1. ZÉRO EXPLORATION GLOBALE : N'utilise jamais grep, find ou glob sur tout le dépôt. Utilise exclusivement les chemins de fichiers fournis dans la fiche de l'agent actif.
2. CONCISION EXTRÊME : Aucune phrase d'introduction, aucun récapitulatif verbeux.
3. COMMANDES CIBLÉES (RTK) :
   - Ne lance jamais flutter test complet pendant le développement d'un lot : cible uniquement le dossier de test du module indiqué par l'agent.
   - Lance flutter analyze uniquement à la fin du lot.
4. GARDE-FOUS D'ARCHITECTURE À RESPECTER :
   - test/core/theme/design_tokens_guard_test.dart : Interdiction d'écrire des couleurs Color(0x...), Colors.white/black ou des fontSize en dur hors de lib/core/theme/. Utilise toujours context.cq, Space.*, Radii.*, TypeScale.*.
   - test/features/motion/motion_inventory_test.dart : Toute animation implicite doit passer par Motion.duration(context, ...).
5. ZONES VERROUILLÉES (STANDBY) : Interdiction absolue de modifier lib/features/metacognition/views/error_logs_page.dart, lib/features/metacognition/views/profiling_page.dart et lib/features/metacognition/domain/learning_profile.dart.
