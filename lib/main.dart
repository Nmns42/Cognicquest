import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';

// 1. Importe la page que tu veux afficher :
import 'features/dashboard/views/dashboard_page.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lnsncmsxpshqokwchxls.supabase.co',
    anonKey: 'sb_publishable_h6Gn0x_pSZy_LuNMJ8f9Tw_CCYjKhVN',
  );

  runApp(const ProviderScope(child: CognicQuestApp()));
}

class CognicQuestApp extends ConsumerWidget {
  const CognicQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CognicQuest',
      theme: AppTheme.light,
      // 2. Remplace routerConfig par home :
      home: const DashboardPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}
