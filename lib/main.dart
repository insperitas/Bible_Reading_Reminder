import 'package:flutter/material.dart';

import 'shared/services/settings_service.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.load();
  runApp(BibleReminderApp(settings: settings));
}

class BibleReminderApp extends StatelessWidget {
  const BibleReminderApp({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reading Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4A6FA5),
        useMaterial3: true,
      ),
      home: SettingsScreen(settings: settings),
    );
  }
}
