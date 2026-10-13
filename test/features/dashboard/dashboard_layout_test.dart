import 'package:cognicquest/features/dashboard/models/dashboard_module.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tous les modules visibles : les règles de réordonnancement se testent
/// indépendamment de la disposition par défaut.
const all = DashboardLayout(
  order: DashboardModule.values,
  hidden: <DashboardModule>{},
);

void main() {
  group('DashboardLayout.initial (refonte zen)', () {
    test('affiche trois blocs : prochaine action, révisions, tâches', () {
      expect(DashboardLayout.initial.visibleModules, [
        DashboardModule.quickStart,
        DashboardModule.reviews,
        DashboardModule.tasks,
      ]);
    });

    test('un module retiré (habitudes) n’est jamais affiché', () {
      const layout = DashboardLayout(
        order: DashboardModule.values,
        hidden: <DashboardModule>{},
      );
      expect(layout.visibleModules, isNot(contains(DashboardModule.habits)));
    });

    test('garde tous les autres modules, masqués mais réactivables', () {
      expect(DashboardLayout.initial.order.toSet(),
          DashboardModule.values.toSet());
      expect(DashboardLayout.initial.order,
          hasLength(DashboardModule.values.length));
    });
  });

  group('DashboardLayout.reorder', () {
    test('déplace un module vers le bas', () {
      // newIndex est l'index final, après retrait : contrat de onReorderItem.
      final layout = all.reorder(0, 2);

      expect(layout.order[0], DashboardModule.weeklyFocus);
      expect(layout.order[1], DashboardModule.quickStart);
      expect(layout.order[2], DashboardModule.stats);
    });

    test('déplace un module vers le haut', () {
      final layout = all.reorder(3, 0);

      expect(layout.order.first, DashboardModule.tasks);
      expect(layout.order[1], DashboardModule.stats);
    });

    test('conserve tous les modules, sans perte ni doublon', () {
      final layout = all.reorder(4, 1);

      expect(layout.order.toSet(), DashboardModule.values.toSet());
      expect(layout.order, hasLength(DashboardModule.values.length));
    });

    test('ignore un index hors bornes plutôt que de planter', () {
      expect(all.reorder(99, 0), all);
      expect(all.reorder(-1, 0), all);
    });

    test('réordonne sur les seuls modules visibles, sans perdre les masqués', () {
      // Compté sur l'énumération : ajouter un module ne doit pas casser ce test.
      final total = DashboardModule.values.where((m) => !m.isRetired).length;
      final hidden = all.toggle(DashboardModule.stats);
      expect(hidden.visibleModules, hasLength(total - 1));

      final reordered = hidden.reorder(0, 2);

      // Le module masqué reste présent dans `order`, donc réactivable.
      expect(reordered.order.toSet(), DashboardModule.values.toSet());
      expect(reordered.hidden, {DashboardModule.stats});
      expect(reordered.visibleModules, hasLength(total - 1));
    });
  });

  group('DashboardLayout.toggle', () {
    test('masque puis réaffiche un module', () {
      final hidden = all.toggle(DashboardModule.habits);
      expect(hidden.isVisible(DashboardModule.habits), isFalse);
      expect(hidden.visibleModules, isNot(contains(DashboardModule.habits)));

      final shown = hidden.toggle(DashboardModule.habits);
      expect(shown.isVisible(DashboardModule.habits), isTrue);
    });

    test('n\'altère pas l\'instance d\'origine', () {
      const original = all;
      original.toggle(DashboardModule.tasks);
      expect(original.isVisible(DashboardModule.tasks), isTrue);
    });
  });

  group('DashboardLayout sérialisation', () {
    test('fait l\'aller-retour JSON', () {
      final layout = all
          .reorder(0, 3)
          .toggle(DashboardModule.quickStart);

      final restored = DashboardLayout.fromJson(layout.toJson());

      expect(restored, layout);
      expect(restored.hidden, {DashboardModule.quickStart});
    });

    test('ignore un identifiant de module inconnu', () {
      // Cas d'un module retiré dans une version ultérieure.
      final restored = DashboardLayout.fromJson(const {
        'order': ['tasks', 'module_disparu', 'stats'],
        'hidden': ['module_disparu'],
      });

      expect(restored.order.first, DashboardModule.tasks);
      expect(restored.order[1], DashboardModule.stats);
      expect(restored.hidden, isEmpty);
    });

    test('ajoute en fin de liste les modules absents du layout enregistré', () {
      // Layout écrit par une version plus ancienne, qui ignorait les autres.
      final restored = DashboardLayout.fromJson(const {
        'order': ['tasks'],
        'hidden': <String>[],
      });

      expect(restored.order.first, DashboardModule.tasks);
      expect(restored.order.toSet(), DashboardModule.values.toSet());
    });

    test('retombe sur la disposition complète pour un JSON vide', () {
      final restored = DashboardLayout.fromJson(const {});
      expect(restored.order.toSet(), DashboardModule.values.toSet());
      expect(restored.hidden, isEmpty);
    });
  });

  group('DashboardModule.fromId', () {
    test('les identifiants persistés résolvent bien', () {
      for (final module in DashboardModule.values) {
        expect(DashboardModule.fromId(module.id), module);
      }
    });

    test('rend null pour un identifiant inconnu', () {
      expect(DashboardModule.fromId('nope'), isNull);
    });
  });
}
