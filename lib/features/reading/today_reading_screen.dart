import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/services/settings_service.dart';
import '../tree/tree_state.dart';
import '../tree/tree_state_service.dart';
import '../tree/tree_widget.dart';
import '../widget/widget_updater.dart';
import 'models/reading_plan.dart';
import 'services/jw_bible_url.dart';
import 'services/reading_progress_service.dart';
import 'setup/reading_setup_wizard.dart';

/// Shows today's Bible reading assignment and the "Mark as Read" button.
///
/// Three content states:
///   • pending  — assignment shown with Mark as Read CTA
///   • done     — celebratory state; shows tomorrow's reading as a teaser
///   • complete — whole Bible finished
class TodayReadingScreen extends StatefulWidget {
  const TodayReadingScreen({
    super.key,
    required this.settings,
    required this.treeService,
  });

  final SettingsService settings;
  final TreeStateService treeService;

  @override
  State<TodayReadingScreen> createState() => _TodayReadingScreenState();
}

class _TodayReadingScreenState extends State<TodayReadingScreen> {
  late ReadingProgressService _progress;

  @override
  void initState() {
    super.initState();
    _progress = ReadingProgressService(widget.settings);
  }

  Future<void> _markRead() async {
    await _progress.markTodayComplete();
    await widget.treeService.onReadingComplete();
    // Reload progress from settings
    setState(() => _progress = ReadingProgressService(widget.settings));
    // Sync tree state to home screen widget
    unawaited(updateHomeWidget(
      treeState: widget.treeService.state,
      streak: _progress.currentDay,
    ));
  }

  void _reconfigure() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingSetupWizard(
          settings: widget.settings,
          onComplete: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TodayReadingScreen(
                settings: widget.settings,
                treeService: widget.treeService,
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress.planComplete) return _PlanCompleteView(onReconfigure: _reconfigure);

    final assignment = _progress.todayAssignment;
    if (assignment == null) return _PlanCompleteView(onReconfigure: _reconfigure);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Reading'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Change plan',
            onPressed: _reconfigure,
          ),
        ],
      ),
      body: _progress.hasReadToday
          ? _DoneView(
              assignment: assignment,
              tomorrow: _progress.tomorrowAssignment,
              currentDay: _progress.currentDay - 1,
              targetDays: _progress.targetDays,
              treeState: widget.treeService.state,
            )
          : _PendingView(
              assignment: assignment,
              currentDay: _progress.currentDay,
              targetDays: _progress.targetDays,
              orderLabel: _progress.readingOrder.displayName,
              targetLabel: _progress.targetLabel(),
              onMarkRead: _markRead,
            ),
    );
  }
}

// ── Pending view ──────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  const _PendingView({
    required this.assignment,
    required this.currentDay,
    required this.targetDays,
    required this.orderLabel,
    required this.targetLabel,
    required this.onMarkRead,
  });

  final DayAssignment assignment;
  final int currentDay;
  final int targetDays;
  final String orderLabel;
  final String targetLabel;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan meta
          Text(
            'Bible in $targetLabel · $orderLabel',
            style: theme.textTheme.labelMedium?.copyWith(color: colors.outline),
          ),
          const SizedBox(height: 4),
          Text(
            'Day $currentDay of $targetDays',
            style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
          ),

          const SizedBox(height: 32),

          // Assignment card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's reading",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  assignment.summary,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Individual units with open-in-app links
                for (final u in assignment.units)
                  _ReadingUnitRow(unit: u, colors: colors, theme: theme),
              ],
            ),
          ),

          const Spacer(),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Read'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onMarkRead,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Tap after you have finished reading',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done view ─────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.assignment,
    required this.tomorrow,
    required this.currentDay,
    required this.targetDays,
    required this.treeState,
  });

  final DayAssignment assignment;
  final DayAssignment? tomorrow;
  final int currentDay;
  final int targetDays;
  final TreeState treeState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pct = (currentDay / targetDays * 100).round();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Tree mascot
          TreeWidget(state: treeState, canvasSize: 180),
          const SizedBox(height: 20),

          Text(
            'Well done!',
            style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${assignment.summary} — done.',
            style: theme.textTheme.bodyLarge?.copyWith(color: colors.outline),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: currentDay / targetDays,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$pct% of the Bible complete · Day $currentDay of $targetDays',
            style: theme.textTheme.labelSmall?.copyWith(color: colors.outline),
          ),

          const Spacer(),

          // Tomorrow teaser
          if (tomorrow != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tomorrow — Day ${tomorrow!.dayNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.outline),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tomorrow!.summary,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ── Individual reading unit row ───────────────────────────────────────────

class _ReadingUnitRow extends StatelessWidget {
  const _ReadingUnitRow({
    required this.unit,
    required this.colors,
    required this.theme,
  });

  final ReadingUnit unit;
  final ColorScheme colors;
  final ThemeData theme;

  Future<void> _open(BuildContext context) async {
    final url = Uri.parse(JwBibleUrl.forUnit(unit));
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to platform intent via MethodChannel
      final channel = MethodChannel('org.foss.biblereader/daily_text');
      await channel.invokeMethod('openUrl', {'url': url.toString()});
    } catch (e) {
      // Final fallback: show error so user knows
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${unit.label}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: 6, color: colors.onPrimaryContainer.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              unit.label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new,
                size: 18, color: colors.onPrimaryContainer.withOpacity(0.7)),
            tooltip: 'Open in JW Library',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _open(context),
          ),
        ],
      ),
    );
  }
}

// ── Plan complete view ────────────────────────────────────────────────────

class _PlanCompleteView extends StatelessWidget {
  const _PlanCompleteView({required this.onReconfigure});

  final VoidCallback onReconfigure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bible Reading')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'You have read the whole Bible!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'That is a real achievement. Ready to go again?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onReconfigure,
              child: const Text('Start a new plan'),
            ),
          ],
        ),
      ),
    );
  }
}
