import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:yacht/ui/paper_gauge.dart';
import 'package:yacht/ui/steering_wheel.dart';
import 'package:yacht/ui/throttle_lever.dart';
import '../core/constants.dart';
import '../game/yacht_game.dart';

class DashboardBase extends PositionComponent with HasGameRef<YachtMasterGame> {
  late PaperGauge speedGauge;
  late PaperGauge windGauge;
  late ThrottleLever throttle;
  late SteeringWheel wheel;

  final double bottomPanelHeight = 310;
  final double topPanelHeight = 140;

  @override
  Future<void> onLoad() async {
    size = gameRef.camera.viewport.virtualSize;
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    // --- ВЕРХНЯЯ ЛЕВАЯ ПАНЕЛЬ (Приборы) ---
    // Сдвигаем их к левому краю (x: 75 и x: 195)
    speedGauge = PaperGauge(
      label: "KNOTS",
      type: GaugeType.linear,
      minVal: 0,
      maxVal: 10,
      position: Vector2(75, 75),
      size: Vector2(110, 110),
    );
    add(speedGauge);

    windGauge = PaperGauge(
      label: "WIND",
      type: GaugeType.circular,
      minVal: -pi,
      maxVal: pi,
      position: Vector2(195, 75),
      size: Vector2(110, 110),
    );
    add(windGauge);

    // --- НИЖНИЕ ПАНЕЛИ (Без изменений, одинаковая высота) ---
    double bottomY = size.y - (bottomPanelHeight / 2) - 10;

    throttle = ThrottleLever();
    throttle.position = Vector2(85, bottomY);
    add(throttle);

    wheel = SteeringWheel(
      position: Vector2(size.x - 160, bottomY),
    );
    add(wheel);
  }

  @override
  void render(Canvas canvas) {
    // 1. ВЕРХНИЙ ЛЕВЫЙ ОСТРОВ (Информационный)
    _drawIsland(canvas, Rect.fromLTWH(
        10,
        10,
        260, // Компактная ширина под два прибора
        topPanelHeight
    ));

    // 2. ЛЕВЫЙ НИЖНИЙ ОСТРОВ (Газ)
    _drawIsland(canvas, Rect.fromLTWH(
        10,
        size.y - bottomPanelHeight - 10,
        170,
        bottomPanelHeight
    ));

    // 3. ПРАВЫЙ НИЖНИЙ ОСТРОВ (Штурвал)
    _drawIsland(canvas, Rect.fromLTWH(
        size.x - 320,
        size.y - bottomPanelHeight - 10,
        310,
        bottomPanelHeight
    ));
  }

  void _drawIsland(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));

    // Тень
    canvas.drawRRect(
      rrect.shift(const Offset(4, 4)),
      Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Картон
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE0C9A6));

    // Текстура бумаги
    final linePaint = Paint()..color = Colors.black.withOpacity(0.04)..strokeWidth = 1;
    for (double y = rect.top + 20; y < rect.bottom; y += 25) {
      canvas.drawLine(Offset(rect.left + 15, y), Offset(rect.right - 15, y), linePaint);
    }

    // Контур
    canvas.drawRRect(
      rrect.deflate(4),
      Paint()..color = Colors.black.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    double speed = gameRef.yacht.velocity.length / Constants.pixelRatio;
    speedGauge.updateValue(speed, dt);
    windGauge.currentValue = Constants.windDirection;
  }
}