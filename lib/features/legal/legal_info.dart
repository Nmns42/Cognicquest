/// Identité de l'éditeur et paramètres des textes légaux.
///
/// Les champs entre crochets sont **à compléter avant la mise en ligne
/// publique** (obligation de la loi pour la confiance dans l'économie
/// numérique, art. 6-III). Ils sont regroupés ici pour qu'un seul fichier
/// fasse foi ; `legal_info_test.dart` les recense.
abstract final class LegalInfo {
  static const String appName = 'CognicQuest';

  static const String publisherName = '[Nom et prénom de l’éditeur]';
  static const String publisherAddress = '[Adresse postale de l’éditeur]';
  static const String contactEmail = '[Adresse e-mail de contact]';
  static const String publicationDirector = '[Directeur de la publication]';

  /// Région du projet Supabase (Settings > General > Region).
  static const String databaseRegion = '[Région d’hébergement Supabase]';

  static const String webHost =
      'GitHub, Inc. — 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, '
      'États-Unis (GitHub Pages)';
  static const String dataHost =
      'Supabase, Inc. — supabase.com (base de données, authentification et '
      'stockage des images)';

  static const String crashReportHost =
      'Functional Software, Inc. (Sentry) — sentry.io (rapports de plantage)';

  /// Date de dernière mise à jour des textes.
  static const String updatedOn = '25 octobre 2026';

  /// Version du consentement : l'augmenter redemande l'accord à chacun
  /// (changement substantiel de la politique).
  static const int consentVersion = 1;

  /// Champs encore à compléter.
  static List<String> get placeholders => [
        publisherName,
        publisherAddress,
        contactEmail,
        publicationDirector,
        databaseRegion,
      ].where((value) => value.startsWith('[')).toList();
}
