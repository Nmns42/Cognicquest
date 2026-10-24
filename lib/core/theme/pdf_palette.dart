import 'package:pdf/pdf.dart';

/// Couleurs des fiches exportées en PDF (papier blanc, encre forêt), tirées
/// de la palette claire de l'app.
abstract final class PdfPalette {
  static const PdfColor ink = PdfColor.fromInt(0xFF1E2A1A);
  static const PdfColor muted = PdfColor.fromInt(0xFF56614F);
  static const PdfColor forest = PdfColor.fromInt(0xFF083B32);
  static const PdfColor sage = PdfColor.fromInt(0xFF3D6A53);
  static const PdfColor bark = PdfColor.fromInt(0xFF7C4D25);
  static const PdfColor rule = PdfColor.fromInt(0xFFE6E2D8);
  static const PdfColor parchment = PdfColor.fromInt(0xFFFAF3E6);

  static const Map<String, PdfColor> highlights = {
    'jaune': PdfColor.fromInt(0xFFFFE58A),
    'vert': PdfColor.fromInt(0xFFC8E6C9),
    'bleu': PdfColor.fromInt(0xFFBBDEFB),
    'rose': PdfColor.fromInt(0xFFF8BBD0),
    'orange': PdfColor.fromInt(0xFFFFD3A6),
  };

  static PdfColor highlight(String name) =>
      highlights[name] ?? highlights['jaune']!;
}

/// Tailles (en points) et rayons des fiches exportées en PDF.
abstract final class PdfTypeScale {
  static const double title = 24;
  static const double body = 11;
  static const double small = 10;
  static const double code = 9.5;
  static const double caption = 9;
  static const double footer = 8;

  /// Titres de la fiche, du niveau 1 au niveau 6.
  static const List<double> headings = [20, 17, 14, 12.5, 11.5, 10.5];

  static const double radius = 4;
  static const double checkboxRadius = 2;
}
