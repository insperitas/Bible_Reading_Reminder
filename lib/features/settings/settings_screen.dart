import 'package:flutter/material.dart';

import '../../shared/models/activity_config.dart';
import '../../shared/models/activity_type.dart';
import '../../shared/services/settings_service.dart';
import '../reading/services/reading_progress_service.dart';
import '../reading/setup/reading_setup_wizard.dart';
import '../reading/today_reading_screen.dart';

/// Main settings screen — shown when the user opens the app.
///
/// Lists all trackable activities with a toggle to enable/disable each.
/// Tapping a row (when enabled) will navigate to that activity's detail
/// settings page (to be built as each activity is designed).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<ActivityType, ActivityConfig> _configs;

  @override
  void initState() {
    super.initState();
    _configs = widget.settings.allConfigs;
  }

  Future<void> _toggle(ActivityType type, bool enabled) async {
    await widget.settings.setEnabled(type, enabled: enabled);
    setState(() {
      _configs = widget.settings.allConfigs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Reading Reminder'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Activities to track',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final type in ActivityType.values)
            _ActivityTile(
              type: type,
              config: _configs[type]!,
              onToggle: (v) => _toggle(type, v),
              onTap: _configs[type]!.enabled
                  ? () => _openDetail(context, type)
                  : null,
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'More activity types coming soon.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, ActivityType type) {
    switch (type) {
      case ActivityType.bibleReading:
        final progress = ReadingProgressService(widget.settings);
        if (progress.isConfigured) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TodayReadingScreen(settings: widget.settings),
            ),
          ).then((_) => setState(() => _configs = widget.settings.allConfigs));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReadingSetupWizard(
                settings: widget.settings,
                onComplete: () {
                  Navigator.pop(context);
                  setState(() => _configs = widget.settings.allConfigs);
                },
              ),
            ),
          );
        }
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.displayName} settings — coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.type,
    required this.config,
    required this.onToggle,
    this.onTap,
  });

  final ActivityType type;
  final ActivityConfig config;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: config.enabled
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          _iconFor(type),
          color: config.enabled
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.outline,
        ),
      ),
      title: Text(type.displayName),
      subtitle: Text(
        type.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.enabled && onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
          Switch(value: config.enabled, onChanged: onToggle),
        ],
      ),
      onTap: onTap,
    );
  }

  IconData _iconFor(ActivityType t) => switch (t) {
        ActivityType.dailyText    => Icons.wb_sunny_outlined,
        ActivityType.bibleReading => Icons.menu_book_outlined,
        ActivityType.meetingPrep  => Icons.people_outline,
      };
}
