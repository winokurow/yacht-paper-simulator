import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:yacht/ui/paper_gauge.dart';
import 'package:yacht/ui/steering_wheel.dart';
import 'package:yacht/ui/throttle_lever.dart';

import '../core/constants.dart';
import '../game/yacht_game.dart';

class DashboardBase extends PositionComponent with HasGameReference<YachtMasterGame> {
  late PaperGauge speedGauge;
  late PaperGauge windGauge;

  DashboardBase() : super(priority: 100);

  @override
  Future<void> onLoad() async {
    size = Vector2(600, 140);
    anchor = Anchor.bottomCenter;

// Спидометр
    speedGauge = PaperGauge(
      label: "KNOTS",
      type: GaugeType.linear, // Линейная шкала
      minVal: 0,
      maxVal: 8,
      position: Vector2(size.x * 0.3, size.y * 0.5),
      size: Vector2(100, 100),
    );

// Ветроуказатель
    windGauge = PaperGauge(
      label: "WIND",
      type: GaugeType.circular, // Круговая шкала
      minVal: -pi,
      maxVal: pi,
      position: Vector2(size.x * 0.5, size.y * 0.5),
      size: Vector2(100, 100),
    );

    add(speedGauge);
    add(windGauge);

    // Рычаг газа слева
    final throttle = ThrottleLever(
      position: Vector2(size.x * 0.12, size.y * 0.5),
    );
    add(throttle);

    // Добавляем штурвал справа
    final wheel = SteeringWheel(
    position: Vector2(size.x * 0.82, size.y * 0.5),
    );
    add(wheel);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Переводим пиксели в "узлы"
    // Делим на pixelRatio, чтобы получить чистые единицы скорости
    double actualKnots = game.yacht.velocity.length / Constants.pixelRatio;

    // 2. Вместо прямой установки, передаем значение для сглаживания
    // (нам нужно добавить поле targetValue в PaperGauge или сглаживать здесь)
    speedGauge.updateValue(actualKnots, dt);

    // Ветер (направление обычно не требует сильного сглаживания)
    windGauge.currentValue = Constants.windDirection;

    // Обновляем скорость: перевод пикселей/сек в узлы
    speedGauge.currentValue = game.yacht.velocity.length;

    // Обновляем ветер: направление ветра
    windGauge.currentValue = Constants.windDirection;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(gameSize.x / 2, gameSize.y - 10);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // 1. Рисуем тень (картон приподнят над столом)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(const Offset(5, 5)), const Radius.circular(12)),
        shadowPaint
    );

    // 2. Рисуем основную текстуру картона (светло-бежевый)
    final cardboardPaint = Paint()..color = const Color(0xFFE0C9A6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        cardboardPaint
    );

    // 3. Декоративный "карандашный" кант по краю
    final borderPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(8)),
        borderPaint
    );

    // 4. Имитация текстуры бумаги (несколько легких линий)
    _drawPaperTexture(canvas);
  }

  void _drawPaperTexture(Canvas canvas) {
    final texturePaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Рисуем пару горизонтальных линий, как на оберточной бумаге
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(20, size.y * 0.25 * i),
        Offset(size.x - 20, size.y * 0.25 * i),
        texturePaint,
      );
    }
  }
}