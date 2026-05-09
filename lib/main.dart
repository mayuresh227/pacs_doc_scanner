import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/scanner/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PACS_doc_scannerApp(),
    ),
  );
}

class PACS_doc_scannerApp extends StatelessWidget {
  const PACS_doc_scannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PACS Document Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}