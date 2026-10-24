import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../legal_texts.dart';

/// Texte légal en lecture : titre serif, intertitres, paragraphes
/// sélectionnables. Accessible connecté ou non.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.document});

  final LegalDocument document;

  /// Largeur de lecture confortable.
  static const double _maxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final text = Theme.of(context).textTheme;
    final body = TextStyle(
        fontSize: TypeScale.body,
        color: cq.textPrimary,
        height: TypeScale.bodyHeight);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          // Ouverte par lien direct, la page n'a pas d'écran précédent.
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(document.title),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Space.lg, Space.lg, Space.lg, Space.xxl),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.title, style: text.headlineMedium),
                    const SizedBox(height: Space.md),
                    Text(document.intro,
                        style: body.copyWith(color: cq.textMuted)),
                    for (final section in document.sections) ...[
                      const SizedBox(height: Space.xl),
                      Semantics(
                        header: true,
                        child: Text(section.title, style: text.titleLarge),
                      ),
                      const SizedBox(height: Space.sm),
                      for (final paragraph in section.paragraphs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.sm),
                          child: paragraph.startsWith('• ')
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('•  ',
                                        style: body.copyWith(
                                            color: cq.vertSauge)),
                                    Expanded(
                                      child: Text(paragraph.substring(2),
                                          style: body),
                                    ),
                                  ],
                                )
                              : Text(paragraph, style: body),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
