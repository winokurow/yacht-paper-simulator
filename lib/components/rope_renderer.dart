import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../game/yacht_game.dart';
import 'yacht_player.dart';

/// Смещение шпринга от швартового (пиксели), чтобы обе линии были видны.
const double _springOffsetPixels = 4.0;

/// Отрисовка швартовых и шпрингов в мировых координатах, чтобы линии всегда были видны поверх яхты.
class RopeRenderer extends Component with HasGameReference<YachtMasterGame> {
  @override
  int get priority => 5;

  @override
  void render(Canvas canvas) {
    final YachtPlayer yacht = game.yacht;
    if (yacht.bowMooredTo != null) {
      _drawRope(canvas, yacht.bowWorldPosition, yacht.bowMooredTo!, isSpring: false);
    }
    if (yacht.sternMooredTo != null) {
      _drawRope(canvas, yacht.sternWorldPosition, yacht.sternMooredTo!, isSpring: false);
    }
    if (yacht.forwardSpringMooredTo != null) {
      _drawRope(canvas, yacht.forwardSpringWorldPosition, yacht.forwardSpringMooredTo!, isSpring: true);
    }
    if (yacht.backSpringMooredTo != null) {
      _drawRope(canvas, yacht.backSpringWorldPosition, yacht.backSpringMooredTo!, isSpring: true);
    }
  }

  void _drawRope(Canvas canvas, Vector2 fromWorld, Vector2 toWorld, {bool isSpring = false}) {
    final Vector2 delta = toWorld - fromWorld;
    final double dist = delta.length;
    if (dist < 1e-6) return;

    final Vector2 along = delta / dist;
    final Vector2 perp = Vector2(-along.y, along.x);

    Vector2 from = fromWorld;
    Vector2 to = toWorld;
    if (isSpring) {
      from = fromWorld + perp * _springOffsetPixels;
      to = toWorld + perp * _springOffsetPixels;
    }

    final paint = Paint()
      ..color = isSpring ? const Color(0xFF8D6E63) : const Color(0xFF5D4037)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final sagThreshold = Constants.ropeSagDistanceFactor * Constants.pixelRatio * 0.9;
    final bool drawSag = !isSpring &&
        dist >= Constants.ropeMinLengthForSagPixels &&
        dist < sagThreshold;
    if (drawSag) {
      final midX = (from.x + to.x) / 2;
      final midY = (from.y + to.y) / 2;
      final sag = (sagThreshold - dist) * Constants.ropeSagFactor;
      final path = Path()
        ..moveTo(from.x, from.y)
        ..quadraticBezierTo(midX, midY + sag, to.x, to.y);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(from.toOffset(), to.toOffset(), paint);
    }
  }
}
