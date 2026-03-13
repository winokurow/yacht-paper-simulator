import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class SteeringWheel extends SpriteComponent
    with HasGameReference<YachtMasterGame>, DragCallbacks {

  double _visualAngle = 0.0;
  bool _isDragging = false;
  /// Текущая позиция пальца в локальных координатах (накапливаем localDelta, т.к. DragUpdateEvent не даёт localPosition).
  Vector2 _dragCurrentPosition = Vector2.zero();

  SteeringWheel({required Vector2 position}) : super(
    position: position,
    size: Vector2(280, 280), // Размер области штурвала
    anchor: Anchor.center,   // Важно: позиция на панели будет центром штурвала
  );

  @override
  void update(double dt) {
    super.update(dt);

    // СВЯЗКА С КЛАВИАТУРОЙ
    // Если игрок НЕ тянет штурвал пальцем/мышкой,
    // штурвал визуально повторяет targetRudderAngle из логики яхты
    if (!_isDragging) {
      // Переводим нормализованное значение (-1.0...1.0) обратно в радианы (-pi/2...pi/2)
      _visualAngle = game.yacht.targetRudderAngle * (pi / 2);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _dragCurrentPosition = event.localPosition.clone();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false; // Отпускаем управление для клавиатуры
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('steering_wheel_paper.png');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // В DragUpdateEvent нет localPosition — накапливаем localDelta от начала жеста.
    _dragCurrentPosition.add(event.localDelta);

    final center = size / 2;
    final delta = _dragCurrentPosition - center;
    final double dist = delta.length;
    if (dist < 20) return;

    // Угол от «12 часов» (вверх), по часовой = вправо, против = влево.
    // atan2(dx, -dy): вверх→0, вправо→+π/2, влево→-π/2, вниз→±π.
    double targetAngle = atan2(delta.x, -delta.y);

    _visualAngle = targetAngle.clamp(-pi / 2, pi / 2);
    if (_visualAngle.abs() < 0.08) {
      _visualAngle = 0;
    }
    // Передаем значение в физику лодки (-1.0 ... 1.0)
    game.yacht.targetRudderAngle = (_visualAngle / (pi / 2)).clamp(-1.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    // 1. Центр компонента для отрисовки
    final centerOffset = Offset(size.x / 2, size.y / 2);
    // Увеличиваем радиус тени и смещение
    canvas.drawCircle(centerOffset + const Offset(8, 8), size.x / 2 - 20,
        Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // 3. ВРАЩЕНИЕ СПРАЙТА
    canvas.save();

    // Переносим начало координат в центр для вращения
    canvas.translate(centerOffset.dx, centerOffset.dy);
    canvas.rotate(_visualAngle);
    // Возвращаем координаты обратно, чтобы спрайт отрисовался корректно
    canvas.translate(-centerOffset.dx, -centerOffset.dy);

    // Рисуем сам спрайт штурвала
    super.render(canvas);

    // --- ДОБАВЛЯЕМ МЕТКУ ЦЕНТРА (Красная лента на штурвале) ---
    final markPaint = Paint()
      ..color = const Color(0xFFD32F2F) // Красный акцент
      ..style = PaintingStyle.fill;

    // Рисуем небольшой прямоугольник на верхнем ободе штурвала
    // Он будет вращаться вместе со спрайтом
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.x / 2, 5), // Позиция вверху штурвала
        width: 10,
        height: 5,
      ),
      markPaint,
    );

    canvas.restore();
  }
}