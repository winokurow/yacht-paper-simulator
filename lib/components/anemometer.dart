import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';

class Anemometer extends PositionComponent {
  Anemometer() : super(size: Vector2(100, 100), position: Vector2(20, 100));

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final radius = size.x / 2;

    // Рисуем циферблат
    canvas.drawCircle(center, radius, Paint()..color = Colors.black54);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white..style = PaintingStyle.stroke);

    // Рисуем стрелку ветра (True Wind)
    final windPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Направление стрелки
    double windAngle = Constants.windDirection;
    canvas.drawLine(
      center,
      center + Offset(cos(windAngle) * radius * 0.8, sin(windAngle) * radius * 0.8),
      windPaint,
    );

    // Метка "N" или "Wind"
    TextSpan span = TextSpan(style: TextStyle(color: Colors.white, fontSize: 12), text: 'WIND');
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, radius + 15));
  }
}