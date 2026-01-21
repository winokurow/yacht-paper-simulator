import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class GridComponent extends Component {
  // Определим область отрисовки (например, 2000x2000 метров)
  final double worldSize = 100000;

  @override
  void render(Canvas canvas) {
    final meterPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final fiveMeterPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.5)
      ..strokeWidth = 2.0;

    // Шаг сетки в пикселях
    double step = Constants.pixelRatio; // 1 метр

    // Рисуем вертикальные и горизонтальные линии
    // Внимание: рисуем в большом диапазоне, чтобы сетка была "бесконечной"
    for (double i = -worldSize; i <= worldSize; i += step) {
      // Каждая 5-я линия жирнее
      final paint = (i % (step * 5) == 0) ? fiveMeterPaint : meterPaint;

      // Вертикальные
      canvas.drawLine(Offset(i, -worldSize), Offset(i, worldSize), paint);
      // Горизонтальные
      canvas.drawLine(Offset(-worldSize, i), Offset(worldSize, i), paint);
    }
  }
}