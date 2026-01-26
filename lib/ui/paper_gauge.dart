import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// 1. Создаем перечисление для типов приборов
enum GaugeType { linear, circular }

class PaperGauge extends PositionComponent {
  final String label;
  final double minVal;
  final double maxVal;
  final GaugeType type; // Добавляем тип
  double currentValue = 0;
  double _targetValue = 0;
  PaperGauge({
    required this.label,
    required this.minVal,
    required this.maxVal,
    required this.type, // Передаем тип в конструктор
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final center = size / 2;
    final radius = size.x * 0.45;

    // Рисуем подложку (белый круг)
    canvas.drawCircle(center.toOffset(), radius, Paint()..color = Colors.white.withOpacity(0.9));

    // Рисуем шкалу в зависимости от типа
    if (type == GaugeType.linear) {
      _drawLinearScale(canvas, center, radius);
    } else {
      _drawCircularScale(canvas, center, radius);
    }

    _renderNeedle(canvas, center, radius);
    _drawLabel(canvas, center, radius);
  }

  // Метод для плавного обновления
  void updateValue(double target, double dt) {
    _targetValue = target;
    // Коэффициент 3.0 определяет скорость движения стрелки (инерцию)
    // Чем меньше число, тем более "ленивая" стрелка
    currentValue += (_targetValue - currentValue) * 3.0 * dt;
  }

  // Шкала для спидометра (дуга)
  void _drawLinearScale(Canvas canvas, Vector2 center, double radius) {
    final paint = Paint()..color = Colors.black54..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (var i = 0; i <= 8; i++) {
      final angle = (i * (pi * 1.5) / 8) - (pi * 1.25);
      canvas.drawLine(
          Offset(center.x + cos(angle) * radius, center.y + sin(angle) * radius),
          Offset(center.x + cos(angle) * (radius - 5), center.y + sin(angle) * (radius - 5)),
          paint
      );
    }
  }

  // Шкала для ветра (N, S, E, W)
  void _drawCircularScale(Canvas canvas, Vector2 center, double radius) {
    final paint = Paint()..color = Colors.black54..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final angle = i * (pi / 2) - (pi / 2);
      canvas.drawLine(
          Offset(center.x + cos(angle) * radius, center.y + sin(angle) * radius),
          Offset(center.x + cos(angle) * (radius - 8), center.y + sin(angle) * (radius - 8)),
          paint
      );
    }
  }

  void _renderNeedle(Canvas canvas, Vector2 center, double radius) {
    double angle;

    if (type == GaugeType.linear) {
      // Логика спидометра: мапим значение на дугу 270 градусов
      final percent = (currentValue - minVal) / (maxVal - minVal);
      angle = (percent.clamp(0, 1) * (pi * 1.5)) - (pi * 1.25);
    } else {
      // Логика ветра: прямое направление (0 = Север/Вверх)
      // Вычитаем pi/2, так как во Flame 0 радиан — это направление ВПРАВО
      angle = currentValue - (pi / 2);
    }

    final needlePaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final tip = Offset(center.x + cos(angle) * (radius * 0.8), center.y + sin(angle) * (radius * 0.8));
    canvas.drawLine(center.toOffset(), tip, needlePaint);
    canvas.drawCircle(center.toOffset(), 4, Paint()..color = Colors.black);
  }

  void _drawLabel(Canvas canvas, Vector2 center, double radius) {
    final speedText = type == GaugeType.linear
        ? "${currentValue.toStringAsFixed(1)} $label"
        : label;
    final tp = TextPainter(
      text: TextSpan(
        text: speedText,
        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.x - tp.width / 2, center.y + radius * 0.4));
  }
}