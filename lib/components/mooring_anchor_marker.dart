import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../game/yacht_game.dart';

/// Маркер точки якоря муринга в мировых координатах. Добавляется в мир только при уровне с мурингом.
class MooringAnchorMarker extends PositionComponent with HasGameReference<YachtMasterGame> {
  MooringAnchorMarker({required Vector2 position})
      : super(
          position: position,
          priority: 6,
        );

  @override
  void render(Canvas canvas) {
    final double r = Constants.mooringAnchorMarkerRadiusPixels;
    final fillPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, r, fillPaint);
    canvas.drawCircle(Offset.zero, r, strokePaint);
  }
}
