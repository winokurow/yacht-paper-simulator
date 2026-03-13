import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class ThrottleLever extends PositionComponent with DragCallbacks, HasGameRef<YachtMasterGame> {
  late PositionComponent knob;
  // Увеличили ход рычага с 90 до 180
  final double trackHeight = 180;

  @override
  Future<void> onLoad() async {
    // Увеличиваем общий размер компонента
    size = Vector2(80, trackHeight + 40);
    anchor = Anchor.center;

    // Прорезь стала шире и длиннее
    add(RectangleComponent(
      size: Vector2(8, trackHeight),
      position: Vector2(size.x / 2, 20),
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.white30,
    ));

    // Ручка (кноб) теперь радиусом 36 (было 18)
    knob = CircleComponent(
      radius: 36,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.redAccent..style = PaintingStyle.fill,
    );

    knob.position = Vector2(size.x / 2, size.y / 2);
    add(knob);
  }

  /// Доля хода рычага (0..1), в пределах которой газ = 0 (мёртвая зона в центре).
  static const double _deadZoneFraction = 0.08;

  @override
  void onDragUpdate(DragUpdateEvent event) {
    double newY = knob.position.y + event.localDelta.y;
    double minY = 20.0;
    double maxY = size.y - 20.0;
    knob.position.y = newY.clamp(minY, maxY);

    double range = maxY - minY;
    double normalized = (knob.position.y - minY) / range; // 0 = верх (полный вперёд), 1 = низ (полный назад)
    double raw = 1.0 - normalized * 2.0; // +1..−1

    // Зона нейтрали: если рычаг в пределах ±_deadZoneFraction от центра, газ = 0.
    if (raw.abs() <= _deadZoneFraction) {
      gameRef.yacht.targetThrottle = 0.0;
    } else {
      // Пересчитываем без мёртвой зоны, чтобы при выходе из неё газ начинался с 0.
      final double sign = raw > 0 ? 1.0 : -1.0;
      final double adjusted = (raw.abs() - _deadZoneFraction) / (1.0 - _deadZoneFraction);
      gameRef.yacht.targetThrottle = (sign * adjusted).clamp(-1.0, 1.0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isDragged) {
      double throttle = gameRef.yacht.targetThrottle;
      double minY = 20.0;
      double maxY = size.y - 20.0;
      double range = maxY - minY;
      knob.position.y = minY + ((1.0 - throttle) / 2.0) * range;
    }
  }
}