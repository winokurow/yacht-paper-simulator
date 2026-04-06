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
    if (yacht.sternPortMooredTo != null) {
      _drawRope(canvas, yacht.sternLeftWorld, yacht.sternPortMooredTo!, isSpring: false);
    }
    if (yacht.sternStarboardMooredTo != null) {
      _drawRope(canvas, yacht.sternRightWorld, yacht.sternStarboardMooredTo!, isSpring: false);
    }
    if (yacht.lazyLineAnchor != null) {
      _drawRope(canvas, yacht.bowTipWorldPosition, yacht.lazyLineAnchor!, isSpring: false);
    }
    if (yacht.isAnchorDropped && yacht.anchorPosition != null) {
      _drawAnchorChain(canvas, yacht.bowTipWorldPosition, yacht.anchorPosition!);
    }
    // Baltic style: 4 швартовых к сваям (2 кормовых + 2 носовых).
    if (yacht.balticBowPortMooredTo != null) {
      _drawRope(canvas, yacht.bowPortWorld, yacht.balticBowPortMooredTo!, isSpring: false);
    }
    if (yacht.balticBowStarboardMooredTo != null) {
      _drawRope(canvas, yacht.bowStarboardWorld, yacht.balticBowStarboardMooredTo!, isSpring: false);
    }
  }

  void _drawRope(Canvas canvas, Vector2 fromWorld, Vector2 toWorld, {bool isSpring = false}) {
    final Vector2 delta = toWorld - fromWorld;
    double dist = delta.length;
    // При нулевой длине (нос на якоре) рисуем короткий отрезок, чтобы муринг был виден.
    if (dist < 2.0) {
      dist = 2.0;
      final Vector2 dir = delta.length > 1e-6 ? delta.normalized() : Vector2(1.0, 0.0);
      final Vector2 toWorldAdjusted = fromWorld + dir * 2.0;
      _drawRopeSegment(canvas, fromWorld, toWorldAdjusted, isSpring);
      return;
    }

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
    _drawRopeSegment(canvas, from, to, isSpring, drawSag: drawSag, sagThreshold: sagThreshold, dist: dist);
  }

  /// Якорная цепь: серая при нормальном натяжении, красная при максимальном.
  void _drawAnchorChain(Canvas canvas, Vector2 bowWorld, Vector2 anchorWorld) {
    final double maxChainPixels = Constants.anchorChainMaxLengthMeters * Constants.pixelRatio;
    final double dist = bowWorld.distanceTo(anchorWorld);
    final double ratio = dist / maxChainPixels;
    final Color chainColor = ratio >= Constants.anchorChainTensionWarningRatio
        ? const Color(0xFFD32F2F)
        : const Color(0xFF757575);
    final paint = Paint()
      ..color = chainColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(bowWorld.toOffset(), anchorWorld.toOffset(), paint);
  }

  void _drawRopeSegment(Canvas canvas, Vector2 from, Vector2 to, bool isSpring,
      {bool drawSag = false, double sagThreshold = 0, double dist = 0}) {
    final paint = Paint()
      ..color = isSpring ? const Color(0xFF8D6E63) : const Color(0xFF5D4037)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    if (drawSag && dist >= Constants.ropeMinLengthForSagPixels && dist < sagThreshold) {
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
