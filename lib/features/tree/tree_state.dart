/// Immutable snapshot of the tree mascot's visual state.
///
/// [leafCount]   — 0–[maxLeaves]. Full when reading daily; leaves fall when
///                 days are missed.
/// [flowerCount] — 0–[maxFlowers]. Earned by completing extra activities
///                 (Daily Text, Meeting Prep). The goal is to fill every spot.
class TreeState {
  const TreeState({
    required this.leafCount,
    required this.flowerCount,
  });

  final int leafCount;
  final int flowerCount;

  static const int maxLeaves = 20;
  static const int maxFlowers = 20;

  double get leafFraction => leafCount / maxLeaves;
  double get flowerFraction => flowerCount / maxFlowers;

  bool get isCoveredInFlowers =>
      leafCount >= maxLeaves && flowerCount >= maxFlowers;

  String get statusMessage {
    if (isCoveredInFlowers) {
      return 'Glorious — your tree is covered in flowers!';
    }
    if (leafFraction >= 1.0) {
      if (flowerFraction >= 0.75) return 'Beautiful — almost in full bloom!';
      if (flowerFraction >= 0.5) return 'Flowers are blooming!';
      if (flowerFraction >= 0.25) return 'First flowers are appearing!';
      return 'A full, healthy tree. Keep reading!';
    }
    if (leafFraction >= 0.75) return 'Looking good — keep up your reading!';
    if (leafFraction >= 0.5) return 'Some leaves have fallen…';
    if (leafFraction >= 0.25) return 'Many leaves are missing — catch up!';
    if (leafFraction > 0) return 'The tree is nearly bare — restart your reading!';
    return 'The tree is bare — start reading again!';
  }
}
