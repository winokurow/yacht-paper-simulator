import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/yacht_game.dart';

/// Деревянная свая (pile) в воде — статическое препятствие для Baltic-style швартовки.
/// Рисуется как круг в paper-стиле с тенью и текстурой «дерева».
class PileComponent extends PositionComponent
    with HasGameReference<YachtMasterGame>, CollisionCallbacks {
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
  static final Paint _basePaint = Paint()..color = const Color(0xFF6D4C41);
  static final Paint _topPaint = Paint()..color = const Color(0xFF8D6E63);
  static final Paint _ringPaint = Paint()
    ..color = const Color(0xFF4E342E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  PileComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(Constants.pileRadiusPixels * 2),
          anchor: Anchor.center,
          priority: Constants.renderPriorityPile,
        ) {
    add(CircleHitbox(
      radius: Constants.pileRadiusPixels,
      position: Vector2.all(Constants.pileRadiusPixels),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void render(Canvas canvas) {
    final double r = Constants.pileRadiusPixels;
    final Offset center = Offset(r, r);
    canvas.drawCircle(center + const Offset(2, 2), r, _shadowPaint);
    canvas.drawCircle(center, r, _basePaint);
    canvas.drawCircle(center, r * 0.7, _topPaint);
    canvas.drawCircle(center, r * 0.85, _ringPaint);
  }
}
