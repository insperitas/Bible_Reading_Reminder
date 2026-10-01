import 'package:flutter/material.dart';

import 'tree_state.dart';

/// Displays the tree mascot with a status caption below.
///
/// Pass [state] from [TreeStateService.state].
/// [canvasSize] controls the square canvas the tree is painted on.
class TreeWidget extends StatelessWidget {
  const TreeWidget({
    super.key,
    required this.state,
    this.canvasSize = 220.0,
  });

  final TreeState state;
  final double canvasSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: Image.asset(
              _imageAssetForState(state),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          state.statusMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.68),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        _ProgressRow(state: state),
      ],
    );
  }
}

String _imageAssetForState(TreeState state) {
  final leafFraction = state.leafFraction;
  if (leafFraction >= 1.0) return 'assets/tree_photos/tree_photo_satisfied.png';
  if (leafFraction >= 0.75) return 'assets/tree_photos/tree_photo_happy.png';
  if (leafFraction >= 0.5) return 'assets/tree_photos/tree_photo_neutral.png';
  if (leafFraction >= 0.25) return 'assets/tree_photos/tree_photo_concerned.png';
  if (leafFraction > 0) return 'assets/tree_photos/tree_photo_sad.png';
  return 'assets/tree_photos/tree_photo_dejected.png';
}

/// Compact leaf/flower counters shown below the tree.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.state});

  final TreeState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelSmall?.copyWith(color: colors.outline);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
          icon: '🌿',
          label: '${state.leafCount}/${TreeState.maxLeaves} leaves',
          style: labelStyle,
        ),
        const SizedBox(width: 16),
        _Chip(
          icon: '🌸',
          label: '${state.flowerCount}/${TreeState.maxFlowers} flowers',
          style: labelStyle,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.style});

  final String icon;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}
