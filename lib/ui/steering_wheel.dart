import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/yacht_game.dart';

class SteeringWheel extends SpriteComponent
    with HasGameReference<YachtMasterGame>, DragCallbacks {

  double _visualAngle = 0.0;
  bool _isDragging = false;
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
    _isDragging = true; // Захватываем управление
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
    // Вычисляем вектор от центра штурвала до точки касания
    final center = size / 2;
    final delta = event.localStartPosition - center;

    // Рассчитываем угол. Добавляем pi/2, чтобы "верх" был нулевой точкой
    double targetAngle = atan2(delta.y, delta.x) + pi / 2;

    // Ограничиваем поворот (например, 90 градусов в каждую сторону)
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

    canvas.restore();
  }
}