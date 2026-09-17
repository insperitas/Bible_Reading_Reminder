import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/models/activity_config.dart';
import '../../shared/models/activity_type.dart';
import '../../shared/services/jw_meeting_url.dart';
import '../../shared/services/settings_service.dart';
import '../reading/services/reading_progress_service.dart';
import '../reading/setup/reading_setup_wizard.dart';
import '../reading/today_reading_screen.dart';
import '../tree/tree_state_service.dart';
import '../tree/tree_widget.dart';
import '../widget/widget_updater.dart';

/// Main settings screen — shown when the user opens the app.
///
/// Lists all trackable activities with a toggle to enable/disable each.
/// Tapping a row (when enabled) will navigate to that activity's detail
/// settings page (to be built as each activity is designed).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.treeService,
  });

  final SettingsService settings;
  final TreeStateService treeService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late Map<ActivityType, ActivityConfig> _configs;
  static const _optMidweekDay = 'midweekDay';
  static const _optWeekendDay = 'weekendDay';

  static const _channel = MethodChannel('org.foss.biblereader/daily_text');

  @override
  void initState() {
    super.initState();
    _configs = widget.settings.allConfigs;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh the home screen widget tree image now that the Flutter view exists.
      unawaited(updateHomeWidget(
        treeState: widget.treeService.state,
        streak: ReadingProgressService(widget.settings).currentDay,
      ));
      _checkWidgetIntent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkWidgetIntent();
  }

  Future<void> _checkWidgetIntent() async {
    try {
      final screen = await _channel.invokeMethod<String>('getTargetScreen');
      if (!mounted) return;
      if (screen == 'extra') {
        await widget.treeService.onExtraActivityCompleted('widgetBonus');
        setState(() {});
        unawaited(updateHomeWidget(
          treeState: widget.treeService.state,
          streak: 0,
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Extra activity logged — flower earned! 🌸'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (screen == 'reading') {
        _openActivity(context, ActivityType.bibleReading);
      } else if (screen == 'feed') {
        _showActivityChooser(context);
      }
    } catch (_) {
      // MethodChannel not available (e.g. tests or non-Android): ignore.
    }
  }

  Future<void> _toggle(ActivityType type, bool enabled) async {
    await widget.settings.setEnabled(type, enabled: enabled);
    setState(() {
      _configs = widget.settings.allConfigs;
    });
  }

  bool get _anyEnabled => _configs.values.any((c) => c.enabled);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Reading Reminder'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
        children: [
          // ── Tree mascot dashboard ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Center(
              child: TreeWidget(state: widget.treeService.state),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'What would you like to track?',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Switch on the activities you want reminders for. '
              'Tap any enabled row to configure it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          for (final type in ActivityType.values)
            _ActivityTile(
              type: type,
              config: _configs[type]!,
              onToggle: (v) => _toggle(type, v),
              onTap: _configs[type]!.enabled
                  ? () => _openSettings(context, type)
                  : null,
              subtitle: _planSubtitle(type),
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
      // "Let's go" button appears once at least one activity is enabled
      floatingActionButton: _anyEnabled
          ? FloatingActionButton.extended(
              onPressed: () => _showActivityChooser(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Let's go"),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  ActivityType? get _firstEnabled =>
      _configs.entries.where((e) => e.value.enabled).map((e) => e.key).firstOrNull;

  String? _planSubtitle(ActivityType type) {
    if (type == ActivityType.bibleReading) {
      final progress = ReadingProgressService(widget.settings);
      if (!progress.isConfigured) return null;
      return 'Bible in ${progress.targetLabel()} · ${progress.readingOrder.displayName}';
    }
    if (type == ActivityType.meetingPrep) {
      final config = widget.settings.configFor(ActivityType.meetingPrep);
      final midweek = _parseWeekday(config.options[_optMidweekDay], DateTime.thursday);
      final weekend = _parseWeekday(config.options[_optWeekendDay], DateTime.sunday);
      return 'Midweek: ${_weekdayLabel(midweek)} · Weekend: ${_weekdayLabel(weekend)}';
    }
    return null;
  }

  int _parseWeekday(String? raw, int fallback) {
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null) return fallback;
    if (parsed < DateTime.monday || parsed > DateTime.sunday) return fallback;
    return parsed;
  }

  String _weekdayLabel(int day) => switch (day) {
        DateTime.monday => 'Monday',
        DateTime.tuesday => 'Tuesday',
        DateTime.wednesday => 'Wednesday',
        DateTime.thursday => 'Thursday',
        DateTime.friday => 'Friday',
        DateTime.saturday => 'Saturday',
        DateTime.sunday => 'Sunday',
        _ => 'Thursday',
      };

  Future<void> _openActivity(BuildContext context, ActivityType type) async {
    switch (type) {
      case ActivityType.dailyText:
        try {
          await _channel.invokeMethod('openDailyText');
          // Award a flower for completing the Daily Text today.
          await widget.treeService.onExtraActivityCompleted('dailyText');
          if (mounted) setState(() {}); // refresh tree
          // Sync tree state to home screen widget.
          unawaited(updateHomeWidget(
            treeState: widget.treeService.state,
            streak: 0,
          ));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open Daily Text')),
            );
          }
        }
        return;

      case ActivityType.bibleReading:
        final progress = ReadingProgressService(widget.settings);
        if (progress.isConfigured) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TodayReadingScreen(
                settings: widget.settings,
                treeService: widget.treeService,
              ),
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
        return;

      case ActivityType.meetingPrep:
        final config = widget.settings.configFor(ActivityType.meetingPrep);
        final midweek = _parseWeekday(config.options[_optMidweekDay], DateTime.thursday);
        final weekend = _parseWeekday(config.options[_optWeekendDay], DateTime.sunday);
        final url = Uri.parse(
          JwMeetingUrl.nextMeeting(midweekDay: midweek, weekendDay: weekend),
        );
        final openedExternal = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!openedExternal) {
          final openedInApp = await launchUrl(url);
          if (!openedInApp && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open meeting page: $url')),
            );
          }
        }
        return;

      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open ${type.displayName} — coming soon')),
          );
        }
        return;
    }
  }

  void _openSettings(BuildContext context, ActivityType type) {
    switch (type) {
      case ActivityType.bibleReading:
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
        return;
      case ActivityType.meetingPrep:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _MeetingPrepSettingsScreen(
              settings: widget.settings,
              onSaved: () => setState(() => _configs = widget.settings.allConfigs),
            ),
          ),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.displayName} settings — coming soon')),
        );
        return;
    }
  }

  void _showActivityChooser(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final enabled = _configs.entries.where((e) => e.value.enabled).map((e) => e.key).toList();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in enabled)
                ListTile(
                  title: Text(type.displayName),
                  subtitle: Text(type.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.pop(context);
                          _openSettings(context, type);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open',
                        onPressed: () {
                          Navigator.pop(context);
                          _openActivity(context, type);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MeetingPrepSettingsScreen extends StatefulWidget {
  const _MeetingPrepSettingsScreen({
    required this.settings,
    required this.onSaved,
  });

  final SettingsService settings;
  final VoidCallback onSaved;

  @override
  State<_MeetingPrepSettingsScreen> createState() => _MeetingPrepSettingsScreenState();
}

class _MeetingPrepSettingsScreenState extends State<_MeetingPrepSettingsScreen> {
  static const _optMidweekDay = 'midweekDay';
  static const _optWeekendDay = 'weekendDay';

  int _midweekDay = DateTime.thursday;
  int _weekendDay = DateTime.sunday;
  bool _saving = false;

  static const _weekdays = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    final config = widget.settings.configFor(ActivityType.meetingPrep);
    _midweekDay = _safeDay(config.options[_optMidweekDay], DateTime.thursday);
    _weekendDay = _safeDay(config.options[_optWeekendDay], DateTime.sunday);
  }

  int _safeDay(String? raw, int fallback) {
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null) return fallback;
    if (parsed < DateTime.monday || parsed > DateTime.sunday) return fallback;
    return parsed;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final current = widget.settings.configFor(ActivityType.meetingPrep);
    final options = Map<String, String>.from(current.options)
      ..[_optMidweekDay] = _midweekDay.toString()
      ..[_optWeekendDay] = _weekendDay.toString();

    await widget.settings.save(
      ActivityType.meetingPrep,
      current.copyWith(enabled: true, options: options),
    );

    if (!mounted) return;
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Preparation Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose your congregation meeting days.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _midweekDay,
            decoration: const InputDecoration(
              labelText: 'Midweek meeting day',
              border: OutlineInputBorder(),
            ),
            items: _weekdays.entries
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _midweekDay = v);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _weekendDay,
            decoration: const InputDecoration(
              labelText: 'Weekend meeting day',
              border: OutlineInputBorder(),
            ),
            items: _weekdays.entries
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _weekendDay = v);
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.type,
    required this.config,
    required this.onToggle,
    this.onTap,
    this.subtitle,
  });

  final ActivityType type;
  final ActivityConfig config;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final String? subtitle;

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
        subtitle ?? type.description,
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
