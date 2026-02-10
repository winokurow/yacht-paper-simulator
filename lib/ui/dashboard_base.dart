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
  late TextComponent statusText;

  final double bottomPanelHeight = 310;
  final double topPanelHeight = 140;

  @override
  Future<void> onLoad() async {
    size = gameRef.camera.viewport.virtualSize;
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    // --- ПАНЕЛЬ ПРИБОРОВ (Верхняя левая) ---
    speedGauge = PaperGauge(
      label: "KNOTS",
      type: GaugeType.linear,
      minVal: 0,
      maxVal: 12, // Увеличили до 12 узлов для запаса
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

    // --- НИЖНИЕ ПАНЕЛИ ---
    double bottomY = size.y - (bottomPanelHeight / 2) - 10;

    // Газ
    throttle = ThrottleLever();
    throttle.position = Vector2(85, bottomY);
    add(throttle);

    // Штурвал
    wheel = SteeringWheel(
      position: Vector2(size.x - 160, bottomY),
    );
    add(wheel);

    // Статус-сообщение (Судовой журнал)
    statusText = TextComponent(
      text: gameRef.statusMessage,
      position: Vector2(size.x / 2, 120),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
    add(statusText);
  }

  @override
  void render(Canvas canvas) {
    // 1. Верхний остров (Приборы)
    _drawIsland(canvas, Rect.fromLTWH(10, 10, 260, topPanelHeight));

    // 2. Левый нижний (Газ)
    _drawIsland(canvas, Rect.fromLTWH(10, size.y - bottomPanelHeight - 10, 170, bottomPanelHeight));

    // 3. Правый нижний (Штурвал + Аксиометр)
    _drawIsland(canvas, Rect.fromLTWH(size.x - 320, size.y - bottomPanelHeight - 10, 310, bottomPanelHeight));
  }

  void _drawIsland(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    canvas.drawRRect(rrect.shift(const Offset(4, 4)), Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE0C9A6));

    final linePaint = Paint()..color = Colors.black.withOpacity(0.04)..strokeWidth = 1;
    for (double y = rect.top + 20; y < rect.bottom; y += 25) {
      canvas.drawLine(Offset(rect.left + 15, y), Offset(rect.right - 15, y), linePaint);
    }

    canvas.drawRRect(rrect.deflate(4), Paint()..color = Colors.black.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. ИСПРАВЛЕНИЕ СПИДОМЕТРА
    // velocity.length — это м/с. Умножаем на 1.94, чтобы получить узлы (KNOTS).
    // Больше не делим на pixelRatio!
    double speedKnots = gameRef.yacht.velocity.length * 1.94;
    speedGauge.updateValue(speedKnots, dt);

    // 3. Ветер и Статус
    windGauge.currentValue = gameRef.activeWindDirection;

    if (statusText.text != gameRef.statusMessage) {
      statusText.text = gameRef.statusMessage;
    }
  }
}