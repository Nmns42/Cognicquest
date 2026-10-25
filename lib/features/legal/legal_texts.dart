import 'legal_info.dart';

/// Une section d'un texte légal : un intertitre et ses paragraphes. Une
/// ligne qui commence par « • » s'affiche en puce.
class LegalSection {
  const LegalSection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<LegalSection> sections;
}

/// Politique de confidentialité (RGPD).
const LegalDocument privacyPolicy = LegalDocument(
  title: 'Politique de confidentialité',
  intro: '${LegalInfo.appName} t’aide à étudier. Pour cela, l’application '
      'enregistre ce que tu y écris. Cette page explique quelles données, '
      'pourquoi, où, combien de temps, et comment exercer tes droits. '
      'Dernière mise à jour : ${LegalInfo.updatedOn}.',
  sections: [
    LegalSection('Responsable du traitement', [
      '${LegalInfo.publisherName}, ${LegalInfo.publisherAddress}. '
          'Contact : ${LegalInfo.contactEmail}.',
    ]),
    LegalSection('Données traitées', [
      '• Compte : adresse e-mail, nom affiché, identifiant Google si tu '
          'choisis « Continuer avec Google ».',
      '• Contenus d’étude : fiches et leurs blocs, images importées, cartes '
          'de révision et historique de tes réponses, sessions d’étude guidée, '
          'auto-explications, liens du graphe, dossiers.',
      '• Organisation : tâches, habitudes, sessions Pomodoro, objectifs, '
          'planning, vitesses de travail, échéances d’examen, réglages.',
      '• Données de bien-être : humeur, niveau de fatigue et d’effort, '
          'réflexions du journal, recadrages, chaînes des 5 pourquoi. Elles '
          'ne sont collectées qu’avec ton consentement explicite, '
          'facultatif : sans lui, le journal et le recadrage restent '
          'désactivés et le reste de l’application fonctionne normalement.',
      '• Métacognition : cahier d’erreurs (y compris les erreurs relevées '
          'par les quiz), profil d’apprentissage.',
      'Aucune donnée de localisation, aucun contact, aucun identifiant '
          'publicitaire n’est collecté.',
    ]),
    LegalSection('Finalités et bases légales', [
      '• Faire fonctionner l’application et synchroniser tes appareils : '
          'exécution du service que tu utilises (art. 6.1.b du RGPD).',
      '• Enregistrer et analyser tes données de bien-être pour te proposer '
          'des conseils (arbre de croissance) : consentement explicite et '
          'facultatif (art. 9.2.a), demandé à la première ouverture, '
          'modifiable à tout moment. Chaque décision est conservée comme '
          'preuve (date, version des textes). Le retrait efface ces données '
          'de l’appareil et de nos serveurs.',
      '• Sécurité du compte (authentification, prévention des abus) : '
          'intérêt légitime (art. 6.1.f).',
      'Tes données ne sont ni vendues, ni louées, ni utilisées à des fins '
          'publicitaires, ni pour entraîner un modèle d’intelligence '
          'artificielle.',
    ]),
    LegalSection('Où sont tes données', [
      '• Sur ton appareil, dans une base locale : l’application fonctionne '
          'hors ligne. Elle est effacée à la déconnexion.',
      '• Une fois connecté, chez notre sous-traitant ${LegalInfo.dataHost}. '
          'Région d’hébergement : ${LegalInfo.databaseRegion}.',
      'Chaque ligne est protégée par des règles d’accès au niveau de la base '
          '(Row Level Security) : un compte ne peut lire ni modifier que ses '
          'propres données. Les images sont rangées dans un espace privé, au '
          'nom de ton compte. Les échanges sont chiffrés (HTTPS).',
      'Si un sous-traitant transfère des données hors de l’Union '
          'européenne, ce transfert est encadré par les clauses '
          'contractuelles types de la Commission européenne.',
    ]),
    LegalSection('Durée de conservation', [
      'Tes données sont conservées tant que ton compte existe. La '
          'suppression du compte (Réglages > Zone sensible) efface '
          'immédiatement et définitivement toutes tes données sur nos '
          'serveurs, images comprises, ainsi que sur l’appareil utilisé.',
    ]),
    LegalSection('Cookies et stockage local', [
      '${LegalInfo.appName} n’utilise aucun cookie publicitaire ni outil de '
          'mesure d’audience. Le navigateur ou l’appareil garde seulement ce '
          'qui est nécessaire au service : ta session de connexion, tes '
          'réglages, ta base locale et ton choix de consentement. Ce stockage '
          'est exempté de consentement (art. 82 de la loi Informatique et '
          'Libertés).',
    ]),
    LegalSection('Tes droits', [
      'Tu disposes des droits d’accès, de rectification, d’effacement, de '
          'limitation, de portabilité et d’opposition, ainsi que du droit de '
          'retirer ton consentement à tout moment (Réglages > Confidentialité). '
          'Accès et portabilité en un appui : Réglages > Confidentialité > '
          'Exporter mes données (fichier JSON). '
          'Pour les exercer : ${LegalInfo.contactEmail}. Réponse sous un mois.',
      'Tu peux aussi adresser une réclamation à la CNIL '
          '(www.cnil.fr, 3 place de Fontenoy, 75007 Paris).',
    ]),
    LegalSection('Mineurs', [
      'En France, un mineur de moins de 15 ans ne peut consentir seul au '
          'traitement de ses données : l’accord d’un titulaire de l’autorité '
          'parentale est alors requis.',
    ]),
  ],
);

/// Mentions légales (LCEN, art. 6-III).
const LegalDocument legalNotice = LegalDocument(
  title: 'Mentions légales',
  intro: 'Informations sur l’éditeur et l’hébergement de '
      '${LegalInfo.appName}. Dernière mise à jour : ${LegalInfo.updatedOn}.',
  sections: [
    LegalSection('Éditeur', [
      LegalInfo.publisherName,
      LegalInfo.publisherAddress,
      'Contact : ${LegalInfo.contactEmail}',
      'Directeur de la publication : ${LegalInfo.publicationDirector}',
    ]),
    LegalSection('Hébergement', [
      'Application web : ${LegalInfo.webHost}.',
      'Données : ${LegalInfo.dataHost}.',
    ]),
    LegalSection('Propriété intellectuelle', [
      'L’application, son code, son logo et ses illustrations sont protégés '
          'par le droit d’auteur. Les contenus que tu crées (fiches, cartes, '
          'journal) restent ta propriété : ${LegalInfo.appName} ne les utilise '
          'que pour te rendre le service.',
    ]),
    LegalSection('Responsabilité', [
      '${LegalInfo.appName} est un outil d’organisation et d’apprentissage. '
          'Ses conseils (bien-être, méthode de travail) ne remplacent pas '
          'l’avis d’un professionnel de santé.',
    ]),
    LegalSection('Données personnelles', [
      'Voir la politique de confidentialité, accessible depuis les Réglages '
          'et depuis l’écran de connexion.',
    ]),
  ],
);
