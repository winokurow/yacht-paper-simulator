import 'dart:ui' as ui;
import 'dart:typed_data'; // Нужно для Float64List
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image; // Скрываем Image, чтобы не было конфликтов
import '../game/yacht_game.dart';

class Dock extends PositionComponent with HasGameReference<YachtMasterGame> {
  ui.Image? _dockImage;
  late Paint _dockPaint;

  final List<double> bollardXPositions;

  // Оптимизированные краски
  static final Paint _bollardBasePaint = Paint()..color = Colors.grey[800]!;
  static final Paint _bollardTopPaint = Paint()..color = Colors.grey[600]!;

  Dock({
    required this.bollardXPositions,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    add(RectangleHitbox(
      size: Vector2(size.x, size.y + 5),
      position: Vector2(0, -2),
      collisionType: CollisionType.passive,
    ));
  }

  @override
  Future<void> onLoad() async {
    _dockImage = await game.images.load('dock_texture.png');

    // 1. Вычисляем масштаб, чтобы высота картинки совпала с высотой причала
    // Это уберет "неправильный" вид (растянутость или лишние повторы по вертикали)
    final double scale = size.y / _dockImage!.height;

    // 2. Создаем матрицу с учетом масштаба
    final Float64List matrix = Float64List.fromList([
      scale, 0.0,   0.0, 0.0, // Масштаб по X (чтобы доски не были слишком широкими)
      0.0,   scale, 0.0, 0.0, // Масштаб по Y (подгоняем под высоту причала)
      0.0,   0.0,   1.0, 0.0,
      0.0,   0.0,   0.0, 1.0,
    ]);

    _dockPaint = Paint()
      ..shader = ImageShader(
        _dockImage!,
        ui.TileMode.repeated, // Повторяем по горизонтали
        ui.TileMode.clamp,    // НЕ повторяем по вертикали (зажимаем край)
        matrix,
      )
      ..filterQuality = FilterQuality.low
      ..isAntiAlias = true;
  }

  @override
  void render(Canvas canvas) {
    if (_dockImage == null) return;

    // Округляем для стабильности пикселей
    final rect = Rect.fromLTWH(
        0, 0,
        size.x.roundToDouble(),
        size.y.roundToDouble()
    );

    // 1. Тень
    canvas.drawRect(
        rect.shift(const Offset(3, 3)),
        Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
    );

    // 2. Рисуем причал шейдером (без швов и мерцания)
    canvas.drawRect(rect, _dockPaint);

    // 3. Детали
    _renderDetails(canvas);
  }

  void _renderDetails(Canvas canvas) {
    // Маркерная линия
    final linePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..strokeWidth = 2.5;
    canvas.drawLine(const Offset(0, 2), Offset(size.x, 2), linePaint);

    // Тумбы
    final double bollardRadius = size.y * 0.08;
    final double posY = size.y * 0.7;

    for (final xPos in bollardXPositions) {
      final pos = Offset(xPos, posY);
      canvas.drawCircle(pos, bollardRadius, _bollardBasePaint);
      canvas.drawCircle(pos, bollardRadius * 0.7, _bollardTopPaint);
    }
  }
}