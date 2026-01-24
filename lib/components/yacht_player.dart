
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'dart:math';
import 'package:flame/extensions.dart';
import '../game/yacht_game.dart';
import 'MooredYacht.dart';
import 'dock_component.dart';
import 'package:flame/particles.dart';

class YachtPlayer extends PositionComponent with CollisionCallbacks, HasGameReference<YachtMasterGame> {
  // Переменная для хранения изображения бумажной лодки
  Sprite? yachtSprite;

  // Состояние яхты
  double angularVelocity = 0.0;  // Скорость вращения (рад/с)
  double targetRudderAngle = 0.0; // То, что мы выставили на панели
  double _currentRudderAngle = 0.0; // То, где руль сейчас физически
  double throttle = 0.0;
// Теперь скорость — это вектор (x, y) в мировых координатах
  Vector2 velocity = Vector2.zero();

  YachtPlayer({double startAngleDegrees = 0.0}) : super(
    size: Vector2(12.0 * Constants.pixelRatio, 4.0 * Constants.pixelRatio),
    anchor: Anchor.center,
  ) {
    angle = startAngleDegrees * (pi / 180);
  }

  @override
  Future<void> onLoad() async {
    // Загружаем спрайт бумажной лодки
    yachtSprite = await game.loadSprite('yacht_paper.png');

    final w = size.x; // Длина лодки (X)
    final h = size.y; // Ширина корпуса (Y)

    // Описываем точки в ПИКСЕЛЯХ (абсолютные координаты внутри лодки)
    // Важно: (0,0) — это всегда верхний левый угол прямоугольника size
    final boatShape = [
    Vector2(w, h * 0.5),     // 1. Нос (середина правой стороны)
    Vector2(w * 0.8, 0),     // 2. Верхнее "плечо"
    Vector2(0, 0),           // 3. Корма верх (левый верхний угол)
    Vector2(0, h),           // 4. Корма низ (левый нижний угол)
    Vector2(w * 0.8, h),     // 5. Нижнее "плечо"
    ];

    // Добавляем обычный PolygonHitbox (не relative!)
    // Если debugMode = true, этот контур должен идеально обвести спрайт
    add(PolygonHitbox(
    boatShape,
    collisionType: CollisionType.active,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (yachtSprite == null) return;

    // 1. Подготавливаем краску для тени
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
      ..colorFilter = const ColorFilter.mode(Colors.black, BlendMode.srcIn);

    canvas.save();

    // 2. РИСУЕМ ТЕНЬ
    yachtSprite!.render(
      canvas,
      position: Vector2(1.5, 1.5), // Смещение тени
      size: size,
      overridePaint: shadowPaint,
    );

    // 3. РИСУЕМ КОРПУС ЛОДКИ
    yachtSprite!.render(canvas, size: size);

    // 4. РИСУЕМ РУЛЬ
    _renderRudder(canvas);

    canvas.restore();
  }

  void _renderRudder(Canvas canvas) {
    final rudderPaint = Paint()
      ..color = Colors.orange.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Поскольку мы внутри повернутого холста, где лодка уже "смотрит" вправо:
    // Корма находится слева (x = 0), по центру высоты (y = size.y / 2)
    final pivotX = 0.0;
    final pivotY = size.y / 2;

    canvas.save();
    canvas.translate(pivotX, pivotY);

    // Угол поворота пера руля
    canvas.rotate(-_currentRudderAngle);

    // Рисуем перо руля назад от кормы
    final rudderLength = size.x * 0.2;
    canvas.drawLine(
        Offset.zero,
        Offset(-rudderLength, 0),
        rudderPaint
    );

    canvas.restore();
  }


  @override
  void update(double dt) {
    super.update(dt);

    // 1. ИНЕРЦИЯ ШТУРВАЛА
    // Плавно подтягиваем реальный угол руля к выбранному на панели
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
      // Чтобы не проскочить целевое значение
      if ((targetRudderAngle - _currentRudderAngle).sign != rudderDiff.sign) {
        _currentRudderAngle = targetRudderAngle;
      }
    }

    // 2. ВЕКТОРЫ НАПРАВЛЕНИЯ
    Vector2 forwardDir = Vector2(cos(angle), sin(angle));

    // 3. ФИЗИКА ТЯГИ И СОПРОТИВЛЕНИЯ (в логических метрах)
    // Сила двигателя
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);

    // Продольное сопротивление воды
    Vector2 dragForce = velocity * -Constants.dragCoefficient;

    // Боковое сопротивление (убирает бесконечный дрейф боком)
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.dragCoefficient * 15.0);

    // Итоговое ускорение (F = ma => a = F/m)
    Vector2 netForce = thrustForce + dragForce + lateralDrag;
    Vector2 acceleration = netForce / Constants.yachtMass;

    // Обновляем скорость (м/с)
    velocity += acceleration * dt;

    // Лимит скорости 6 узлов (6 м/с)
    if (velocity.length > 6.0) {
      velocity = velocity.normalized() * 6.0;
    }

    // 4. ПЕРЕМЕЩЕНИЕ (Перевод метров в пиксели экрана)
    position += velocity * (dt * Constants.pixelRatio);

    // 5. ВРАЩЕНИЕ (МАНЕВРИРОВАНИЕ)
    // Эффективность руля зависит от скорости + потока от винта (Prop Wash)
    double speedFactor = velocity.length;
    double propWash = throttle.abs() * 1.5;
    double turningPower = (speedFactor + propWash) * Constants.rudderEffect;

    // Крутящий момент зависит от ТЕКУЩЕГО угла руля (с учетом инерции)
    double torque = _currentRudderAngle * turningPower;
    double resistance = -angularVelocity * Constants.angularDrag;

    // Угловое ускорение
    angularVelocity += (torque + resistance) * dt;

    // Ограничение скорости вращения (для стабильности)
    angularVelocity = angularVelocity.clamp(-3.0, 3.0);

    angle += angularVelocity * dt;

    // 6. ПРОВЕРКА ГРАНИЦ
    _containInArea();
  }

  void _containInArea() {
    final bounds = game.playArea;
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    if (position.x < bounds.left + halfWidth) {
      position.x = bounds.left + halfWidth;
      velocity.x = 0;
    } else if (position.x > bounds.right - halfWidth) {
      position.x = bounds.right - halfWidth;
      velocity.x = 0;
    }

    if (position.y < bounds.top + halfHeight) {
      position.y = bounds.top + halfHeight;
      velocity.y = 0;
    } else if (position.y > bounds.bottom - halfHeight) {
      position.y = bounds.bottom - halfHeight;
      velocity.y = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Проверяем, с чем столкнулись
    if (other is Dock || other is MooredYacht) {
      // --- 1. РЕАКЦИЯ НА СТОЛКНОВЕНИЕ (ОТСКОК) ---

      // Если скорость достаточная, делаем отскок
      if (velocity.length > 0.1) {
        // Инвертируем вектор скорости и гасим его энергию (умножаем на -0.3)
        velocity = -velocity * 0.3;

        // Добавляем небольшой случайный поворот при ударе для реализма
        // Не забудьте import 'dart:math'; для Random()
        angularVelocity += (Random().nextDouble() - 0.5) * 1.5;
      } else {
        // Если скорость была почти нулевой (просто притерлись),
        // полностью останавливаем, чтобы не вибрировать
        velocity = Vector2.zero();
      }

      // --- 2. РАЗРЕШЕНИЕ ПЕРЕСЕЧЕНИЯ (ОТТАЛКИВАНИЕ) ---
      // Это главная часть, которая не даст хитбоксам "слипнуться".
      // Мы находим среднюю точку пересечения и отталкиваемся от неё.

      if (intersectionPoints.isNotEmpty) {
        // Находим центр всех точек пересечения
        Vector2 intersectionCenter = intersectionPoints.reduce((a, b) => a + b) / intersectionPoints.length.toDouble();

        // Вектор от точки удара к центру нашей яхты
        Vector2 pushVector = position - intersectionCenter;

        // Нормализуем его, чтобы получить чистое направление
        if (pushVector.length > 0) {
          pushVector.normalize();
        } else {
          // Если центры совпали (редко), отталкиваемся назад по нашему углу
          pushVector = Vector2(-cos(angle), -sin(angle));
        }

        // Физически отодвигаем яхту на небольшое расстояние (например, 2 пикселя)
        // Это гарантированно выведет хитбокс из препятствия
        position += pushVector * 2.0;
      }

      // Сбрасываем газ в нейтраль при ударе
      throttle = 0.0;
    }
  }


  void _createWake(double dt) {
    // Создаем пузырьки только если есть ход или работает винт
    if (velocity.length < 0.1 && throttle.abs() < 0.1) return;

    // Генерируем случайное смещение у кормы
    final random = Random();

    // Позиция "выхлопа" (у кормы)
    // Находим точку за яхтой: берем позицию и вычитаем вектор направления
    Vector2 sternPos = position - (Vector2(cos(angle), sin(angle)) * (size.x / 2));

    game.world.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: (throttle.abs() * 5 + 1).toInt(), // Количество зависит от газа
          lifespan: 1.0, // Живут 1 секунду
          generator: (i) => AcceleratedParticle(
            acceleration: velocity * -0.5, // Пузырьки немного тормозят в воде
            speed: Vector2(random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10),
            position: sternPos.clone(),
            child: CircleParticle(
              radius: random.nextDouble() * 2 + 1,
              paint: Paint()..color = Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Paint getPaperShadowPaint() {
    return Paint()
      ..color = Colors.black.withOpacity(0.3) // Полупрозрачный черный
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0); // Размытие (мягкость тени)
  }

  void _renderShadow(Canvas canvas) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    // Тень рисуется без учета внутренней ротации спрайта
    canvas.drawRect(size.toRect().shift(const Offset(4, 4)), shadowPaint);
  }

}