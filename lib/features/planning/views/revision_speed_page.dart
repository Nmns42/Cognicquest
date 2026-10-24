import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'revision_order_page.dart';
import 'study_speed_page.dart';

/// Volets du module.
enum RevisionSpeedTab { order, speed }

/// Module unifié « Ordre & vitesse » : l'ordre de révision par rentabilité
/// et la vitesse de travail mesurée, qui en convertit les pages en temps.
class RevisionSpeedPage extends ConsumerStatefulWidget {
  const RevisionSpeedPage(
      {super.key, this.initialTab = RevisionSpeedTab.order});

  final RevisionSpeedTab initialTab;

  @override
  ConsumerState<RevisionSpeedPage> createState() => _RevisionSpeedPageState();
}

class _RevisionSpeedPageState extends ConsumerState<RevisionSpeedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: RevisionSpeedTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _onOrder => _tabs.index == RevisionSpeedTab.order.index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordre & vitesse'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.cq.textPrimary,
          unselectedLabelColor: context.cq.textMuted,
          indicatorColor: context.cq.vert,
          tabs: const [
            Tab(text: 'Ordre & rentabilité'),
            Tab(text: 'Vitesse de travail'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [RevisionOrderView(), StudySpeedView()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onOrder
            ? RevisionOrderView.addTarget(context, ref)
            : StudySpeedView.addSample(context),
        backgroundColor: context.cq.vert,
        tooltip: _onOrder ? 'Ajouter un chapitre' : 'Nouvelle mesure',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}
