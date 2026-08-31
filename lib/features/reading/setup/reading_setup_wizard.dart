import 'package:flutter/material.dart';

import '../../../shared/models/activity_config.dart';
import '../../../shared/models/activity_type.dart';
import '../../../shared/services/settings_service.dart';
import '../models/reading_plan.dart';

/// Two-page conversational wizard that configures the Bible reading plan.
///
/// Page 1: How long to complete the reading?
/// Page 2: Which reading order?
///
/// On completion the chosen settings are saved via [SettingsService] and the
/// callback [onComplete] is called so the parent can navigate away.
class ReadingSetupWizard extends StatefulWidget {
  const ReadingSetupWizard({
    super.key,
    required this.settings,
    required this.onComplete,
  });

  final SettingsService settings;
  final VoidCallback onComplete;

  @override
  State<ReadingSetupWizard> createState() => _ReadingSetupWizardState();
}

class _ReadingSetupWizardState extends State<ReadingSetupWizard> {
  final _pageController = PageController();
  int? _targetDays;
  ReadingOrder? _order;  // stored for potential future confirmation screen

  // ── Duration options ──────────────────────────────────────────────────

  static const _durationOptions = [
    _DurationOption(label: '6 months',  days: 183, hint: 'About 7 chapters a day'),
    _DurationOption(label: '1 year',    days: 365, hint: 'About 3 chapters a day — a popular choice', recommended: true),
    _DurationOption(label: '2 years',   days: 730, hint: 'About 2 chapters a day — a relaxed pace'),
  ];

  // ── Navigation ────────────────────────────────────────────────────────

  void _selectDuration(int days) {
    setState(() => _targetDays = days);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _selectOrder(ReadingOrder order) {
    setState(() => _order = order);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _confirmAndSave() async {
    await widget.settings.save(
      ActivityType.bibleReading,
      ActivityConfig(
        enabled: true,
        options: {
          'readingOrder': _order!.name,
          'targetDays':   _targetDays.toString(),
          'startDate':    DateTime.now().toIso8601String().substring(0, 10),
          'currentDay':   '1',
        },
      ),
    );
    widget.onComplete();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _DurationPage(
            options: _durationOptions,
            onSelect: _selectDuration,
          ),
          _OrderPage(onSelect: _selectOrder),
          _ConfirmationPage(
            targetDays: _targetDays ?? 365,
            order: _order ?? ReadingOrder.canonical,
            onConfirm: _confirmAndSave,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ── Page 1 — Duration ─────────────────────────────────────────────────────

class _DurationPage extends StatelessWidget {
  const _DurationPage({required this.options, required this.onSelect});

  final List<_DurationOption> options;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _WizardShell(
      step: '1 of 2',
      question: 'Over how long would you like to read through the Bible?',
      subtext: "There's no wrong answer — you can always adjust later.",
      children: [
        for (final opt in options)
          _ChoiceCard(
            label: opt.label,
            hint: opt.hint,
            recommended: opt.recommended,
            onTap: () => onSelect(opt.days),
          ),
      ],
    );
  }
}

// ── Page 2 — Reading order ────────────────────────────────────────────────

class _OrderPage extends StatelessWidget {
  const _OrderPage({required this.onSelect});

  final ValueChanged<ReadingOrder> onSelect;

  @override
  Widget build(BuildContext context) {
    return _WizardShell(
      step: '2 of 2',
      question: 'Where would you like to start?',
      subtext: 'Every order covers the whole Bible — it just changes where you begin.',
      children: [
        for (final order in ReadingOrder.values)
          _ChoiceCard(
            label: order.displayName,
            hint: order.description,
            recommended: order == ReadingOrder.canonical,
            onTap: () => onSelect(order),
          ),
      ],
    );
  }
}

// ── Shared shell ──────────────────────────────────────────────────────────

class _WizardShell extends StatelessWidget {
  const _WizardShell({
    required this.step,
    required this.question,
    required this.subtext,
    required this.children,
  });

  final String step;
  final String question;
  final String subtext;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step,
              style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.outline),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Choice card ───────────────────────────────────────────────────────────

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.hint,
    required this.onTap,
    this.recommended = false,
  });

  final String label;
  final String hint;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: recommended ? colors.primary : colors.outlineVariant,
              width: recommended ? 2 : 1,
            ),
            color: recommended
                ? colors.primaryContainer.withOpacity(0.25)
                : colors.surface,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'popular',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.outline),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data helpers ──────────────────────────────────────────────────────────

// ── Page 3 — Confirmation ────────────────────────────────────────────────

class _ConfirmationPage extends StatelessWidget {
  const _ConfirmationPage({
    required this.targetDays,
    required this.order,
    required this.onConfirm,
  });

  final int targetDays;
  final ReadingOrder order;
  final VoidCallback onConfirm;

  String _durationLabel() {
    if (targetDays <= 183) return '6 months';
    if (targetDays <= 365) return '1 year';
    if (targetDays <= 730) return '2 years';
    return '$targetDays days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _WizardShell(
      step: '3 of 3',
      question: "You're all set!",
      subtext: 'Here\'s your reading plan:',
      children: [
        const SizedBox(height: 8),
        _SummaryRow(
          icon: Icons.schedule_outlined,
          label: 'Reading period',
          value: _durationLabel(),
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          icon: Icons.menu_book_outlined,
          label: 'Reading order',
          value: order.displayName,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('Start reading'),
            onPressed: onConfirm,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: colors.outline),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DurationOption {
  final String label;
  final int days;
  final String hint;
  final bool recommended;

  const _DurationOption({
    required this.label,
    required this.days,
    required this.hint,
    this.recommended = false,
  });
}
