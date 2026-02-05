
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'package:flame/extensions.dart';
import '../game/yacht_game.dart';
import 'MooredYacht.dart';
import 'dock_component.dart';

class YachtPlayer extends PositionComponent with CollisionCallbacks, HasGameReference<YachtMasterGame> {
  Sprite? yachtSprite;

  // Физика
  double angularVelocity = 0.0;
  double targetRudderAngle = 0.0;
  double _currentRudderAngle = 0.0;
  double throttle = 0.0;
  Vector2 velocity = Vector2.zero();
  double targetThrottle = 0.0;

  // Состояние швартовки
  bool canMoerBow = false;
  bool canMoerStern = false;
  double? bowRopeRestLength;
  double? sternRopeRestLength;

  Vector2? bowMooredTo;
  Vector2? sternMooredTo;
  Vector2? bowAnchorPointLocal;
  Vector2? sternAnchorPointLocal;

  // Геттеры позиций
  Vector2 get bowWorldPosition => localToParent(Vector2(size.x / 2, 0));
  Vector2 get sternWorldPosition => localToParent(Vector2(-size.x / 2, 0));
  Vector2 get bowRightWorld => localToParent(Vector2(size.x * 0.4, size.y * 0.4));
  Vector2 get bowLeftWorld  => localToParent(Vector2(size.x * 0.4, -size.y * 0.4));
  Vector2 get sternRightWorld => localToParent(Vector2(-size.x * 0.4, size.y * 0.4));
  Vector2 get sternLeftWorld  => localToParent(Vector2(-size.x * 0.4, -size.y * 0.4));

  YachtPlayer({double startAngleDegrees = 0.0}) : super(
    size: Vector2(12.0 * Constants.pixelRatio, 4.0 * Constants.pixelRatio),
    anchor: Anchor.center,
  ) {
    angle = startAngleDegrees * (math.pi / 180);
  }

  @override
  Future<void> onLoad() async {
    yachtSprite = await game.loadSprite('yacht_paper.png');

    final boatShape = [
      Vector2(size.x, size.y * 0.5),
      Vector2(size.x * 0.8, 0),
      Vector2(0, 0),
      Vector2(0, size.y),
      Vector2(size.x * 0.8, size.y),
    ];

    add(PolygonHitbox(
      boatShape,
      position: -size / 2,
      collisionType: CollisionType.active,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Защита от больших скачков времени (например, при сворачивании окна)
    if (dt > 0.1) return;

    // --- 1. ТЕЧЕНИЕ (River Current) ---
    if (game.activeCurrentSpeed > 0) {
      Vector2 currentFlow = Vector2(
          math.cos(game.activeCurrentDirection),
          math.sin(game.activeCurrentDirection)
      ) * game.activeCurrentSpeed;

      // Смещение позиции течением (переводим метры в пиксели)
      position += currentFlow * (dt * Constants.pixelRatio);
    }

    // --- 2. УПРАВЛЕНИЕ ГАЗОМ (Плавное изменение) ---
    double throttleChangeSpeed = 1.2;
    if ((throttle - targetThrottle).abs() > 0.01) {
      throttle += (targetThrottle > throttle ? 1 : -1) * throttleChangeSpeed * dt;
      throttle = throttle.clamp(-1.0, 1.0);
    }

    // --- 3. ПЕРЕКЛАДКА РУЛЯ (Плавный поворот пера) ---
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
    }

    // --- 4. ФИЗИКА ЛИНЕЙНОГО ДВИЖЕНИЯ ---
    double speedMeters = velocity.length;
    Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));

    // А) Тяга двигателя
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);

    // Б) Гибридное сопротивление воды (Drag)
    // Линейное (вязкое) + Квадратичное (инерционное)
    Vector2 dragForce = Vector2.zero();
    if (speedMeters > 0.001) {
      double dragMag = (speedMeters * Constants.linearDragCoefficient) +
          (speedMeters * speedMeters * Constants.quadraticDragCoefficient);
      dragForce = velocity.normalized() * (-dragMag);
    }

    // В) Боковое сопротивление (Эффект киля)
    // Предотвращает дрейф яхты боком
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.yachtMass * Constants.lateralDragMultiplier);

    // Г) Суммируем силы и находим ускорение (a = F / m)
    Vector2 totalForce = thrustForce + dragForce + lateralDrag;
    Vector2 linearAcceleration = totalForce / Constants.yachtMass;

    // Обновляем вектор скорости (в метрах в секунду)
    velocity += linearAcceleration * dt;

    // Жесткий ограничитель скорости (на всякий случай)
    if (velocity.length > Constants.maxSpeedMeters) {
      velocity = velocity.normalized() * Constants.maxSpeedMeters;
    }

    // --- 5. ФИЗИКА ВРАЩЕНИЯ ---

    // Поток воды через руль (скорость хода + поток от винта)
    double propWash = throttle.abs() * Constants.propWashFactor;
    double totalFlow = speedMeters + propWash;

    // Момент вращения от руля
    double rudderTorque = _currentRudderAngle * totalFlow * Constants.rudderEffect * 800;
    double totalTorque = rudderTorque;

    // Эффект заброса кормы (Prop Walk)
    if (throttle.abs() > 0.05) {
      double sideSign = (Constants.propType == PropellerType.rightHanded) ? -1.0 : 1.0;
      double walkIntensity = (throttle < 0) ? 1.0 : 0.15; // Назад эффект сильнее

      // Затухание эффекта с ростом скорости
      double fadeFactor = (1.0 - (speedMeters / 4.0)).clamp(0.0, 1.0);
      double propWalkTorque = sideSign * throttle.sign * Constants.propWalkEffect * walkIntensity * (fadeFactor * fadeFactor) * 2000;

      totalTorque += propWalkTorque;
    }

    // Применяем вращающий момент к угловой скорости
    angularVelocity += (totalTorque / Constants.yachtInertia) * dt;

    // Сопротивление вращению (чтобы лодка не крутилась бесконечно)
    angularVelocity *= (1.0 - (Constants.angularDrag * dt)).clamp(0.0, 1.0);
    angularVelocity = angularVelocity.clamp(-1.2, 1.2);

    // --- 6. ИНТЕГРАЦИЯ ДВИЖЕНИЯ (Субстеппинг) ---
    // Переводим метры в пиксели только на этом этапе
    double distThisFrame = velocity.length * dt * Constants.pixelRatio;
    if (distThisFrame > 0.001) {
      // Разбиваем путь на шаги по 2 пикселя для точности коллизий
      int steps = (distThisFrame / 2.0).ceil().clamp(1, 10);
      double stepDt = dt / steps;

      for (int i = 0; i < steps; i++) {
        position += velocity * (stepDt * Constants.pixelRatio);
        angle += angularVelocity * stepDt;
      }
    }

    // --- 7. ШВАРТОВКА (Физика канатов) ---
    if (bowMooredTo != null) {
      _applyMooringPhysics(dt, bowMooredTo, bowAnchorPointLocal, bowRopeRestLength, true);
    }
    if (sternMooredTo != null) {
      _applyMooringPhysics(dt, sternMooredTo, sternAnchorPointLocal, sternRopeRestLength, false);
    }

    // Проверка условий завершения швартовки
    _checkMooringConditions();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Dock || other is MooredYacht) {
      if (intersectionPoints.isNotEmpty) {
        Vector2 collisionMid = intersectionPoints.reduce((a, b) => a + b) / intersectionPoints.length.toDouble();
        double impactSpeed = velocity.length / Constants.pixelRatio;

        if (impactSpeed > 0.8) _createSplash(collisionMid);

        // Проверка критических повреждений
        if (impactSpeed > 2.5) {
          game.onGameOver("Hull breached! Too much impact speed.");
          return;
        }

        double distToBow = collisionMid.distanceTo(bowWorldPosition);
        if (distToBow < (size.y * 0.8) && impactSpeed > 0.6) {
          game.onGameOver("Vessel lost! Direct bow collision.");
          return;
        }

        _handleSoftCollision(collisionMid, other);
      }
    }
  }

  void _handleSoftCollision(Vector2 collisionMid, PositionComponent other) {
    // Останавливаем тягу двигателя при ударе
    throttle = 0;
    targetThrottle = 0;

    // Гасим скорость и даем небольшой отскок
    if (velocity.length > 0.1) {
      velocity = -velocity * 0.3; // Отскок 30%
      angularVelocity *= 0.4;
    } else {
      velocity = Vector2.zero();
    }

    // Выталкиваем лодку из объекта, чтобы хитбоксы не перекрывались
    Vector2 pushDir = (position - collisionMid).normalized();

    // Если это причал, всегда выталкиваем "вниз" (в сторону моря)
    if (other is Dock) {
      pushDir.y = 1.0;
      pushDir.x *= 0.5;
    }

    // Увеличиваем силу выталкивания до 5-7 пикселей
    position += pushDir * 6.0;
  }

  void _applyMooringPhysics(double dt, Vector2? bollardWorld, Vector2? anchorLocal, double? restLength, bool isBow) {
    if (bollardWorld == null || anchorLocal == null || restLength == null) return;

    Vector2 anchorWorld = localToParent(anchorLocal);
    Vector2 ropeVector = bollardWorld - anchorWorld;
    double currentDistance = ropeVector.length;

    // Разрыв каната
    if (currentDistance > restLength + (Constants.maxRopeExtension * Constants.pixelRatio)) {
      if (isBow) {
        bowMooredTo = null;
        game.updateStatus("Bow rope snapped!");
      } else {
        sternMooredTo = null;
        game.updateStatus("Stern rope snapped!");
      }
      return;
    }

    // Натяжение
    if (currentDistance > restLength) {
      double stretch = currentDistance - restLength;
      Vector2 force = ropeVector.normalized() * (stretch * 400.0);
      velocity += (force - velocity * 50.0) * dt / (Constants.yachtMass / 500);
      angularVelocity *= math.pow(0.05, dt).toDouble();
    }
  }

  void _checkMooringConditions() {
    // Если на уровне нет причала (открытое море), выключаем логику швартовки
    if (game.dock == null || game.playerBollards.isEmpty) {
      canMoerBow = false;
      canMoerStern = false;
      return;
    }

    final double bollardY = game.dock!.position.y + (game.dock!.size.y * 0.88);
    List<Vector2> bollards = game.playerBollards
        .map((x) => Vector2(game.dock!.position.x + x, bollardY))
        .toList();

    Vector2 mBow = localToParent(Vector2(size.x * 0.4, 0));
    Vector2 mStern = localToParent(Vector2(-size.x * 0.4, 0));

    double dBow = bollards.map((b) => mBow.distanceTo(b)).reduce(math.min);
    double dStern = bollards.map((b) => mStern.distanceTo(b)).reduce(math.min);

    double threshold = 6.5 * Constants.pixelRatio;
    bool speedOk = velocity.length < (1.0 * Constants.pixelRatio);

    canMoerBow = dBow < threshold && speedOk && bowMooredTo == null;
    canMoerStern = dStern < threshold && speedOk && sternMooredTo == null;

    if (canMoerBow || canMoerStern) {
      game.showMooringButtons(canMoerBow, canMoerStern);
    } else {
      game.hideMooringButtons();
    }
  }

  void _createSplash(Vector2 impactPoint) {
    final rnd = math.Random();
    game.world.add(ParticleSystemComponent(
      position: impactPoint,
      particle: Particle.generate(
        count: 10,
        lifespan: 0.6,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 100),
          speed: Vector2(rnd.nextDouble() * 100 - 50, -rnd.nextDouble() * 80),
          child: CircleParticle(radius: 2, paint: Paint()..color = Colors.white70),
        ),
      ),
    ));
  }

  void resetToInitialState() {
    velocity = Vector2.zero();
    angularVelocity = 0.0;
    throttle = 0.0;
    targetThrottle = 0.0;
    _currentRudderAngle = 0.0;
    targetRudderAngle = 0.0;
    bowMooredTo = sternMooredTo = null;
    bowRopeRestLength = sternRopeRestLength = null;
  }

  @override
  void render(Canvas canvas) {
    if (yachtSprite == null) return;

    final drawRect = Rect.fromLTWH(-size.x/2, -size.y/2, size.x, size.y);

    // Тень
// --- 1. РИСУЕМ ТЕНЬ (По форме спрайта) ---
    canvas.save();
    // Сдвигаем тень на несколько пикселей (например, 3 вправо и 3 вниз)
    canvas.translate(3, 3);

    // Создаем кисть для тени:
    final shadowPaint = Paint()
    // BlendMode.srcIn использует прозрачность спрайта, но заменяет цвет на указанный (черный полупрозрачный)
      ..colorFilter = const ColorFilter.mode(Colors.black54, BlendMode.srcIn)
    // Небольшое размытие для мягкости краев
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Рисуем спрайт с использованием "теневой" кисти
    yachtSprite!.renderRect(canvas, drawRect, overridePaint: shadowPaint);

    canvas.restore();

    // --- 2. РИСУЕМ САМУ ЯХТУ ---
    // Рисуем спрайт поверх тени обычной кистью
    yachtSprite!.renderRect(canvas, drawRect);

    // 3. ВОЗВРАЩАЕМ РУЛЬ (Отрисовка пера руля)
    _renderRudder(canvas);

    // Отрисовка канатов
    if (bowMooredTo != null) _drawRope(canvas, bowMooredTo!, Vector2(size.x * 0.45, 0), bowRopeRestLength!);
    if (sternMooredTo != null) _drawRope(canvas, sternMooredTo!, Vector2(-size.x * 0.45, 0), sternRopeRestLength!);
  }

  // Метод для отрисовки пера руля
  void _renderRudder(Canvas canvas) {
    canvas.save();
    // Переносимся к корме яхты
    canvas.translate(-size.x / 2, 0);
    // Поворачиваем перо руля (используем текущий угол из физики)
    canvas.rotate(-_currentRudderAngle);

    // Рисуем оранжевую линию руля
    canvas.drawLine(
      Offset.zero,
      Offset(-size.x * 0.18, 0), // Руль стал чуть длиннее и заметнее
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 3.0 // Чуть толще для "бумажного" стиля
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawRope(Canvas canvas, Vector2 bollardWorld, Vector2 anchorLocal, double restLength) {
    Vector2 bLocal = parentToLocal(bollardWorld);
    double dist = (bLocal - anchorLocal).length;

    final paint = Paint()
      ..color = dist > restLength ? Colors.redAccent : const Color(0xFFEFEBE9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (dist < restLength * 0.9) {
      final path = Path()..moveTo(anchorLocal.x, anchorLocal.y);
      path.quadraticBezierTo((anchorLocal.x + bLocal.x)/2, (anchorLocal.y + bLocal.y)/2 + (restLength - dist)*0.5, bLocal.x, bLocal.y);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(anchorLocal.toOffset(), bLocal.toOffset(), paint);
    }
  }
}