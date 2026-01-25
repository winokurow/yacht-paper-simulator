import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../game/yacht_game.dart';

class Dock extends PositionComponent with HasGameReference<YachtMasterGame> {
Sprite? dockSprite;
static final Paint _bollardBasePaint = Paint()..color = Colors.grey[800]!; // Темно-серое основание
static final Paint _bollardTopPaint = Paint()..color = Colors.grey[600]!;

final List<double> bollardXPositions;

Dock({
  required this.bollardXPositions,
required Vector2 position,
required Vector2 size,
}) : super(position: position, size: size) {
// Используем стандартный хитбокс Flame
add(RectangleHitbox()..collisionType = CollisionType.passive);
}

@override
Future<void> onLoad() async {
// Загружаем спрайт причала
dockSprite = await game.loadSprite('dock_texture.png');
}

@override
void render(Canvas canvas) {
  if (dockSprite == null) return;

  // Настройка краски для гладкого рендеринга без мерцания
  final paint = Paint()
    ..filterQuality = FilterQuality.medium // Улучшает сглаживание при движении
    ..isAntiAlias = true;

  final rect = size.toRect();

  // 1. ТЕНЬ
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
  canvas.drawRect(rect.shift(const Offset(3, 3)), shadowPaint);

  // 2. ТАЙЛИНГ С НАХЛЕСТОМ (Overlapping)
  double sectionWidth = 100.0;
  double currentX = 0;

  while (currentX < size.x) {
    // Добавляем +1.0 к ширине для нахлеста, чтобы не было щелей
    double drawWidth = (size.x - currentX < sectionWidth)
        ? size.x - currentX
        : sectionWidth + 1.0;

    dockSprite!.render(
      canvas,
      position: Vector2(currentX, 0),
      size: Vector2(drawWidth, size.y),
      overridePaint: paint, // Применяем качественную краску
    );

    // Шагаем строго по sectionWidth, создавая микро-нахлест
    currentX += sectionWidth;
  }

  // 3. Линия маркера
  final linePaint = Paint()
    ..color = Colors.yellow.withOpacity(0.7)
    ..strokeWidth = 3;
  canvas.drawLine(const Offset(0, 2), Offset(size.x, 2), linePaint);

  // 2. тумбы
  final double bollardRadius = size.y * 0.075;
  final double topRadius = bollardRadius * 0.7;

  // Сдвиг от края причала (чтобы тумба не висела в воздухе)
  final double edgeMargin = bollardRadius + 2.0;
  final double posY = size.y - edgeMargin;

  // X координаты - расставляем их на 1/3 и 2/3 длины причала
  final Offset pos1 = Offset(size.x / 3, posY);
  final Offset pos2 = Offset(size.x * 2 / 3, posY);

  for (final xPos in bollardXPositions) {
    _drawBollard(canvas, Offset(xPos, posY), bollardRadius, topRadius);
  }
}
void _drawBollard(Canvas canvas, Offset position, double baseRad, double topRad) {
  canvas.drawCircle(position, baseRad, _bollardBasePaint);
  canvas.drawCircle(position, topRad, _bollardTopPaint);
  canvas.drawCircle(position, topRad * 0.3, Paint()..color = Colors.black54);
}
}