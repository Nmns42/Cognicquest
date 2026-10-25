import 'package:cognicquest/features/legal/legal_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garde-fou de mise en ligne : un build de production ne part pas avec
/// des mentions légales entre crochets (LCEN, art. 6-III).
///
/// Ignoré en développement ; la CI le lance avant chaque build web avec
/// `--dart-define=CQ_RELEASE=true`, et un échec bloque le déploiement. À
/// lancer de la même façon avant un APK de diffusion :
///
/// ```
/// flutter test --dart-define=CQ_RELEASE=true test/features/legal/legal_release_guard_test.dart
/// ```
const bool _release = bool.fromEnvironment('CQ_RELEASE');

void main() {
  test('production : aucun champ légal à compléter', () {
    expect(LegalInfo.placeholders, isEmpty,
        reason: 'À compléter dans lib/features/legal/legal_info.dart : '
            '${LegalInfo.placeholders.join(', ')}');
  }, skip: _release ? false : 'build de développement (CQ_RELEASE absent)');

  test('production : coordonnées plausibles', () {
    expect(LegalInfo.contactEmail, matches(RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')));
    for (final value in [
      LegalInfo.publisherName,
      LegalInfo.publisherAddress,
      LegalInfo.publicationDirector,
      LegalInfo.databaseRegion,
    ]) {
      expect(value.trim(), isNotEmpty);
    }
  }, skip: _release ? false : 'build de développement (CQ_RELEASE absent)');
}
