import 'dart:async';

import 'package:flutter/material.dart';

import 'shared/services/settings_service.dart';
import 'features/settings/settings_screen.dart';
import 'features/tree/tree_state_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.load();
  final treeService = await TreeStateService.load();
  runApp(BibleReminderApp(settings: settings, treeService: treeService));
}

class BibleReminderApp extends StatelessWidget {
  const BibleReminderApp({
    super.key,
    required this.settings,
    required this.treeService,
  });

  final SettingsService settings;
  final TreeStateService treeService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reading Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4A6FA5),
        useMaterial3: true,
      ),
      home: SettingsScreen(settings: settings, treeService: treeService),
    );
  }
}
