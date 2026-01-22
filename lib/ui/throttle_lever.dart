import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class ThrottleLever extends PositionComponent
    with HasGameReference<YachtMasterGame>, DragCallbacks {

  // Внутренние параметры для отрисовки
  final double trackHeight = 100.0;
  final double handleSize = 40.0;

  // Позиция рычага (0.0 - нейтраль, 1.0 - полный вперед, -1.0 - полный назад)
  double _currentValue = 0.0;

  ThrottleLever({required Vector2 position}) : super(
    position: position,
    size: Vector2(50, 120), // Размер всей области рычага
    anchor: Anchor.center,
  );

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // 1. Получаем локальную Y-координату касания относительно центра трека
    // Инвертируем Y, так как в координатах экрана "вниз" — это плюс
    double localY = event.localStartPosition.y - (size.y / 2);

    // 2. Рассчитываем значение (зажимаем между -1 и 1)
    // Делим на половину высоты трека
    _currentValue = -(localY / (trackHeight / 2)).clamp(-1.0, 1.0);

    // 3. Передаем значение яхте
    game.yacht.throttle = _currentValue;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // 1. Рисуем "прорезь" в картоне
    final trackPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 8, height: trackHeight),
        const Radius.circular(4),
      ),
      trackPaint,
    );

    // 2. Рисуем метки (F, N, R)
    _drawLabels(canvas);

    // 3. Рисуем сам рычаг (рукоятку)
    _drawHandle(canvas, center);
  }

  void _drawHandle(Canvas canvas, Offset center) {
    // Вычисляем смещение рукоятки на основе текущего газа
    double yOffset = -_currentValue * (trackHeight / 2);
    final handlePos = center + Offset(0, yOffset);

    // Тень рукоятки
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(handlePos + const Offset(2, 2), handleSize / 2, shadowPaint);

    // Сама рукоятка (белая бумага)
    final handlePaint = Paint()..color = const Color(0xFFFDF5E6);
    canvas.drawCircle(handlePos, handleSize / 2, handlePaint);

    // Ободок
    canvas.drawCircle(handlePos, handleSize / 2, Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  void _drawLabels(Canvas canvas) {
    final textStyle = const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold);

    _drawText(canvas, "F", Offset(size.x / 2 + 15, size.y / 2 - 45), textStyle);
    _drawText(canvas, "N", Offset(size.x / 2 + 15, size.y / 2 - 5), textStyle);
    _drawText(canvas, "R", Offset(size.x / 2 + 15, size.y / 2 + 35), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, offset);
  }
}