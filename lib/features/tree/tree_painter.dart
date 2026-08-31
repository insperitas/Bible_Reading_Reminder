import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'tree_state.dart';

/// Draws the tree mascot using [Canvas].
///
/// Layout (normalized fractions, origin = top-left):
///   Trunk    — bottom-centre, y: 0.62 → 1.0
///   Crown    — y: 0.0 → 0.62, 20 fixed leaf positions
///
/// Leaf visibility  — the first [TreeState.leafCount] positions are shown.
///   Positions are ordered so outermost/lower leaves fall first (highest index).
///
/// Flowers — the first [TreeState.flowerCount] visible leaf positions gain
///   a five-petal flower drawn on top. Full bloom = all 20 positions have a
///   flower.
class TreePainter extends CustomPainter {
  const TreePainter({required this.state});

  final TreeState state;

  // ── Leaf positions ─────────────────────────────────────────────────────
  // Normalized (x, y) within the canvas.  Ordered so that higher indices
  // represent outer/lower leaves — they are the first to "fall" as leafCount
  // decreases from maxLeaves.
  static const List<Offset> _leafPositions = [
    // ── Group A: top/core — last to fall ──
    Offset(0.500, 0.05), // 0  apex
    Offset(0.435, 0.11), // 1  upper-left
    Offset(0.565, 0.11), // 2  upper-right
    Offset(0.375, 0.18), // 3  mid-upper-left
    Offset(0.625, 0.18), // 4  mid-upper-right
    // ── Group B: middle ──
    Offset(0.295, 0.23), // 5
    Offset(0.705, 0.23), // 6
    Offset(0.215, 0.33), // 7
    Offset(0.785, 0.33), // 8
    Offset(0.155, 0.43), // 9
    Offset(0.845, 0.43), // 10
    Offset(0.310, 0.45), // 11
    Offset(0.690, 0.45), // 12
    Offset(0.500, 0.51), // 13  centre-low
    Offset(0.410, 0.49), // 14
    // ── Group C: outer/lower — first to fall ──
    Offset(0.590, 0.49), // 15
    Offset(0.130, 0.53), // 16  far-left
    Offset(0.870, 0.53), // 17  far-right
    Offset(0.245, 0.57), // 18  lower-left
    Offset(0.755, 0.57), // 19  lower-right
  ];

  // Flower petal colours, cycling by position index.
  static const List<Color> _petalColors = [
    Color(0xFFFF80AB), // pink
    Color(0xFFCE93D8), // lavender
    Color(0xFFFF7043), // coral
    Color(0xFFF48FB1), // light pink
    Color(0xFFFFCC02), // yellow
  ];

  // ── Branch descriptors (normalized from/to + stroke-width fraction) ───
  static const List<_BranchData> _branches = [
    // Left main
    _BranchData(Offset(0.50, 0.72), Offset(0.16, 0.51), 0.035),
    // Right main
    _BranchData(Offset(0.50, 0.72), Offset(0.84, 0.51), 0.035),
    // Centre up
    _BranchData(Offset(0.50, 0.62), Offset(0.50, 0.37), 0.028),
    // Left sub
    _BranchData(Offset(0.16, 0.51), Offset(0.14, 0.40), 0.020),
    _BranchData(Offset(0.16, 0.51), Offset(0.23, 0.36), 0.020),
    // Right sub
    _BranchData(Offset(0.84, 0.51), Offset(0.86, 0.40), 0.020),
    _BranchData(Offset(0.84, 0.51), Offset(0.77, 0.36), 0.020),
    // Centre sub
    _BranchData(Offset(0.50, 0.37), Offset(0.37, 0.22), 0.016),
    _BranchData(Offset(0.50, 0.37), Offset(0.63, 0.22), 0.016),
    _BranchData(Offset(0.50, 0.37), Offset(0.50, 0.14), 0.016),
  ];

  // ── Paint ──────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _drawTrunk(canvas, size);
    _drawBranches(canvas, size);
    _drawLeavesAndFlowers(canvas, size);
  }

  void _drawTrunk(Canvas canvas, Size size) {
    canvas.drawLine(
      _p(0.50, 1.00, size),
      _p(0.50, 0.62, size),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = _s(0.068, size)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawBranches(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final b in _branches) {
      paint.strokeWidth = _s(b.widthFraction, size);
      canvas.drawLine(
        _p(b.from.dx, b.from.dy, size),
        _p(b.to.dx, b.to.dy, size),
        paint,
      );
    }
  }

  void _drawLeavesAndFlowers(Canvas canvas, Size size) {
    final minDim = math.min(size.width, size.height);
    final leafW = minDim * 0.130;
    final leafH = minDim * 0.092;
    final flowerR = minDim * 0.040;

    final leafFill = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;
    final leafStroke = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < _leafPositions.length; i++) {
      if (i >= state.leafCount) continue; // leaf has fallen

      final pos = _p(_leafPositions[i].dx, _leafPositions[i].dy, size);

      // Slight angle variation per leaf to look natural
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate((i % 5 - 2) * 0.18); // subtle tilt
      final rect = Rect.fromCenter(
          center: Offset.zero, width: leafW, height: leafH);
      canvas.drawOval(rect, leafFill);
      canvas.drawOval(rect, leafStroke);
      canvas.restore();

      // Flower on top if within flower count
      if (i < state.flowerCount) {
        _drawFlower(
            canvas, pos, flowerR, _petalColors[i % _petalColors.length]);
      }
    }
  }

  void _drawFlower(
      Canvas canvas, Offset centre, double radius, Color petalColor) {
    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill;

    // 5 petals arranged radially
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72.0 - 90.0) * math.pi / 180.0;
      final petalCentre = centre +
          Offset(
            math.cos(angle) * radius * 0.62,
            math.sin(angle) * radius * 0.62,
          );
      canvas.drawCircle(petalCentre, radius * 0.45, petalPaint);
    }
    // Yellow centre dot
    canvas.drawCircle(
        centre, radius * 0.32, Paint()..color = const Color(0xFFFDD835));
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Convert normalised (x, y) in [0,1] to canvas coordinates.
  Offset _p(double x, double y, Size size) =>
      Offset(x * size.width, y * size.height);

  /// Convert a normalised fraction to pixels using the smaller canvas dimension.
  double _s(double fraction, Size size) =>
      fraction * math.min(size.width, size.height);

  @override
  bool shouldRepaint(TreePainter old) =>
      old.state.leafCount != state.leafCount ||
      old.state.flowerCount != state.flowerCount;
}

// ── Internal data class ───────────────────────────────────────────────────

class _BranchData {
  const _BranchData(this.from, this.to, this.widthFraction);
  final Offset from;
  final Offset to;
  final double widthFraction;
}
