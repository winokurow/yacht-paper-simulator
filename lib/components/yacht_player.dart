
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'dart:math';
import 'package:flame/extensions.dart';
import '../game/yacht_game.dart';
import 'dock_component.dart';
import 'package:flame/particles.dart';

class YachtPlayer extends PositionComponent with CollisionCallbacks, HasGameReference<YachtMasterGame> {
  // Переменная для хранения изображения бумажной лодки
  Sprite? yachtSprite;

  // Состояние яхты
  double angularVelocity = 0.0;  // Скорость вращения (рад/с)
  double rudderAngle = 0.0;      // Угол руля (от -1.0 до 1.0)
  double throttle = 0.0;
// Теперь скорость — это вектор (x, y) в мировых координатах
  Vector2 velocity = Vector2.zero();

  YachtPlayer({double startAngleDegrees = 0.0}) : super(
    size: Vector2(12.0 * Constants.pixelRatio, 4.0 * Constants.pixelRatio),
    anchor: Anchor.center,
  ) {
    // Добавляем хитбокс яхте
    add(RectangleHitbox());
    angle = startAngleDegrees * (pi / 180);
  }

  @override
  Future<void> onLoad() async {
    // Загружаем спрайт бумажной лодки
    yachtSprite = await game.loadSprite('yacht_paper.png');

    // Добавляем хитбокс (он остается невидимым, но работает)
    add(RectangleHitbox());
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
    canvas.rotate(-rudderAngle * 0.6);

    // Рисуем перо руля назад от кормы
    final rudderLength = size.x * 0.2;
    canvas.drawLine(
        Offset.zero,
        Offset(-rudderLength, 0),
        rudderPaint
    );

    canvas.restore();
  }


  void update(double dt) {
    super.update(dt);

    // 1. ВЕКТОРЫ
    Vector2 forwardDir = Vector2(cos(angle), sin(angle));

    // 2. ФИЗИКА (в логических метрах/секунду)
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);
    Vector2 dragForce = velocity * -Constants.dragCoefficient;

    // Боковое сопротивление
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.dragCoefficient * 20.0);

    Vector2 netForce = thrustForce + dragForce + lateralDrag;
    Vector2 acceleration = netForce / Constants.yachtMass;

    // Обновляем ЛОГИЧЕСКУЮ скорость (метры в секунду)
    velocity += acceleration * dt;

    // Ограничиваем скорость 6 узлами (6.0 м/с)
    if (velocity.length > 6.0) {
      velocity = velocity.normalized() * 6.0;
    }

    // 3. ПЕРЕМЕЩЕНИЕ (Главное исправление!)
    // Мы переводим метры в пиксели, умножая на Constants.pixelRatio (30.0)
    position += velocity * (dt * Constants.pixelRatio);

    // 4. ВРАЩЕНИЕ
    double speedFactor = velocity.length; // уже в метрах/с
    double propWash = throttle.abs() * 2.0;
    double turningPower = (speedFactor + propWash) * Constants.rudderEffect;

    double torque = rudderAngle * turningPower;
    double angularDrag = -angularVelocity * Constants.angularDrag;

    angularVelocity += (torque + angularDrag) * dt;
    angle += angularVelocity * dt;

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
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Dock) {
      double impactForce = velocity.length;

      // Если удар достаточно сильный, трясем камеру
      if (impactForce > 0.5) {
        // Интенсивность тряски зависит от скорости (макс 10 пикселей)
        double intensity = (impactForce * 5).clamp(2, 15);

        // В Flame 1.x камера трясется через viewfinder
        game.camera.viewfinder.add(
          MoveEffect.by(
            Vector2(intensity, intensity),
            EffectController(
              duration: 0.1,
              reverseDuration: 0.1,
              repeatCount: 2,
              curve: Curves.bounceIn,
            ),
          ),
        );
      }

      // 1. Находим точку удара (среднее арифметическое всех точек пересечения)
      final collisionPoint = intersectionPoints.reduce((a, b) => a + b) / intersectionPoints.length.toDouble();

      // 2. Определяем нормаль (куда направлен "отпор" причала)
      // Упрощенно для прямоугольного причала:
      Vector2 normal;
      if ((collisionPoint.y - other.absolutePosition.y).abs() < 5) {
        normal = Vector2(0, -1); // Удар сверху
      } else if ((collisionPoint.y - (other.absolutePosition.y + other.size.y)).abs() < 5) {
        normal = Vector2(0, 1);  // Удар снизу
      } else if (collisionPoint.x < other.absolutePosition.x) {
        normal = Vector2(-1, 0); // Удар слева
      } else {
        normal = Vector2(1, 0);  // Удар справа
      }

      // 3. РАСЧЕТ ОТСКОКА
      // Используем встроенный метод reflect для вектора скорости
      // Отражаем скорость относительно нормали и умножаем на коэффициент упругости
      if (velocity.dot(normal) < 0) { // Проверяем, что лодка движется К причалу, а не ОТ него
        velocity.reflect(normal);
        velocity *= Constants.restitution;
      }

      // 4. ЭФФЕКТ УДАРА ДЛЯ ИГРОКА
      if (impactForce > Constants.damageThreshold) {
        game.statusMessage = "CRASH! Impact: ${impactForce.toStringAsFixed(1)} m/s";
      } else {
        game.statusMessage = "Soft touch";
      }

      // 5. ПРЕДОТВРАЩЕНИЕ "ЗАЛИПАНИЯ"
      // Немного отодвигаем лодку от причала в сторону нормали, чтобы хитбоксы не застряли друг в друге
      position += normal * 2.0;

      // Гасим угловую скорость при ударе
      angularVelocity *= 0.2;
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