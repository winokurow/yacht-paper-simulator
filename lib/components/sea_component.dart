import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class Sea extends SpriteComponent with HasGameReference<YachtMasterGame> {
  Sea({required Vector2 size}) : super(size: size, priority: -5);

  @override
  Future<void> onLoad() async {
    // Загружаем текстуру синей бумаги
    sprite = await game.loadSprite('sea_paper.png');
  }

  @override
  void render(Canvas canvas) {
    // 1. Рисуем тень всего "листа воды" на столе
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    // Тень чуть больше, так как лист моря большой
    canvas.drawRect(size.toRect().shift(const Offset(8, 8)), shadowPaint);

    // 2. Рисуем саму текстуру бумаги
    super.render(canvas);

    // 3. Опционально: Добавим эффект "карандашных" волн
    _drawHandDrawnWaves(canvas);
  }

  void _drawHandDrawnWaves(Canvas canvas) {
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Можно нарисовать несколько декоративных дуг, имитирующих волны
    // Для простоты оставим текстуру бумаги основной
  }
}