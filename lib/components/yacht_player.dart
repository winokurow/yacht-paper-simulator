
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/yacht_physics.dart';
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

  // Точки привязки (мировые координаты тумб) и длина каната в момент отдачи
  Vector2? bowMooredTo;
  Vector2? sternMooredTo;
  double? bowRopeRestLength;
  double? sternRopeRestLength;

  // Точки крепления швартовых (для отрисовки и физики): 0.60 длины от носа, 0.98 от носа, смещение от борта
  static const double _ropeOffsetFromBoard = 0.12;
  Vector2 get _bowRopeLocal => Vector2(size.x / 2 - 0.20 * size.x, size.y * _ropeOffsetFromBoard);
  Vector2 get _sternRopeLocal => Vector2(size.x / 2 - 0.98 * size.x, -size.y * _ropeOffsetFromBoard);

  // Геттеры позиций
  Vector2 get bowWorldPosition => localToParent(_bowRopeLocal);
  Vector2 get sternWorldPosition => localToParent(_sternRopeLocal);
  Vector2 get bowRightWorld => localToParent(Vector2(size.x / 2, size.y / 2));
  Vector2 get bowLeftWorld  => localToParent(Vector2(size.x / 2, -size.y / 2));
  Vector2 get sternRightWorld => localToParent(Vector2(-size.x / 2, size.y / 2));
  Vector2 get sternLeftWorld  => localToParent(Vector2(-size.x / 2, -size.y / 2));

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
    _checkMooringConditions();
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

    Vector2 thrust = YachtPhysics.thrustForce(throttle, angle);
    Vector2 wind = YachtPhysics.windForce(game.activeWindSpeed, game.activeWindDirection);
    Vector2 drag = YachtPhysics.dragForce(velocity);
    Vector2 lateral = YachtPhysics.lateralDrag(forwardDir, velocity);

    Vector2 totalForce = thrust + wind + drag + lateral;
    Vector2 linearAcceleration = totalForce / Constants.yachtMass;
    velocity += linearAcceleration * dt;

    // Жесткий ограничитель скорости (на всякий случай)
    if (velocity.length > Constants.maxSpeedMeters) {
      velocity = velocity.normalized() * Constants.maxSpeedMeters;
    }

    // --- 5. ФИЗИКА ВРАЩЕНИЯ ---
    double totalTorque = YachtPhysics.rudderTorque(_currentRudderAngle, speedMeters, throttle) +
        YachtPhysics.propWalkTorque(throttle, speedMeters);
    angularVelocity += (totalTorque / Constants.yachtInertia) * dt;

    // Сопротивление вращению (чтобы лодка не крутилась бесконечно)
    angularVelocity *= (1.0 - (Constants.angularDrag * dt)).clamp(0.0, 1.0);
    angularVelocity = angularVelocity.clamp(-1.2, 1.2);

    // --- 6. ИНТЕГРАЦИЯ ДВИЖЕНИЯ (Субстеппинг) ---
    double distThisFrame = velocity.length * dt * Constants.pixelRatio;
    var (steps, stepDt) = YachtPhysics.integrationSteps(distThisFrame, dt);
    for (int i = 0; i < steps; i++) {
      position += velocity * (stepDt * Constants.pixelRatio);
      angle += angularVelocity * stepDt;
    }

    // 6. ФИЗИКА КАНАТОВ (натяжение только при растяжении каната, не притягиваем к причалу)
    if (bowMooredTo != null && bowRopeRestLength != null) _applyMooringPhysics(dt, bowMooredTo, _bowRopeLocal, bowRopeRestLength);
    if (sternMooredTo != null && sternRopeRestLength != null) _applyMooringPhysics(dt, sternMooredTo, _sternRopeLocal, sternRopeRestLength);

    // --- СТАБИЛИЗАЦИЯ (Анти-дрожание) ---
    // Если скорость меньше 0.05 пикселей в кадр, принудительно обнуляем её
    if (throttle.abs() < 0.01 && velocity.length < 0.05) {
      velocity = Vector2.zero();
      if (angularVelocity.abs() < 0.005) angularVelocity = 0;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (intersectionPoints.isEmpty) return;

    // Берем точку столкновения (мировую)
    final worldCollisionPoint = intersectionPoints.first;

    // --- КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Перевод в локальные координаты яхты ---
    final localCollisionPoint = parentToLocal(worldCollisionPoint);

    // Нос у нас начинается примерно с 80% длины лодки.
    // В локальных координатах (от -size.x/2 до size.x/2) это всё,
    // что находится правее (впереди) отметки size.x * 0.3
    bool isNoseHit = localCollisionPoint.x > (size.x * 0.3);

    // Проверка скорости (используем м/с)
    bool isHighSpeed = velocity.length > Constants.maxSafeImpactSpeed;

    if (isNoseHit && isHighSpeed) {
      // Любое касание носом — это фатально
      _triggerCrash("КРИТИЧЕСКАЯ ОШИБКА: Столкновение носом!");
    } else if (isHighSpeed) {
      // Удар любой другой частью (борт, корма) на высокой скорости
      double speedKnots = velocity.length * 1.94;
      _triggerCrash("АВАРИЯ: Слишком сильный удар бортом)");
    } else {
      // Мягкое касание бортом или кормой при швартовке
      _handleSoftCollision(worldCollisionPoint, other);

      // Визуальный эффект всплеска при касании
      _createSplash(worldCollisionPoint);
    }
  }

  void _triggerCrash(String message) {
    velocity = Vector2.zero();
    angularVelocity = 0;
    game.statusMessage = message;
    // Вызываем метод проигрыша в основной игре
    game.onGameOver(message);
  }

  void _handleSoftCollision(Vector2 collisionMid, PositionComponent other) {
    // 1. ПАДЕНИЕ СКОРОСТИ (Физический эффект удара)
    if (velocity.length > 0.1) {
      // Даем небольшой "отскок" назад (30% от текущей скорости)
      // Это создает визуальный эффект столкновения
      velocity = -velocity * 0.3;

      // Сильно гасим вращение при ударе, чтобы яхту не крутило как волчок
      angularVelocity *= 0.2;
    } else {
      // Если лодка еле ползла — просто останавливаем её
      velocity = Vector2.zero();
    }

    // --- ВНИМАНИЕ: throttle и targetThrottle больше не обнуляются! ---
    // Двигатель продолжает работать на заданном уровне.

    // 2. ВЫТАЛКИВАНИЕ (Collision Resolve)
    // Чтобы лодка не "слипалась" с причалом и не проходила сквозь него,
    // мы принудительно сдвигаем её на несколько пикселей в сторону от удара.
    Vector2 pushDir = (position - collisionMid).normalized();

    if (other is Dock) {
      // Если ударились об причал, всегда выталкиваем в сторону воды (вниз)
      pushDir.y = 1.0;
      pushDir.x *= 0.5;
    }
  }

  void _applyMooringPhysics(double dt, Vector2? bollardWorld, Vector2? anchorLocal, double? restLength) {
    if (bollardWorld == null || anchorLocal == null || restLength == null) return;

    Vector2 anchorWorld = localToParent(anchorLocal);
    Vector2 ropeVector = bollardWorld - anchorWorld;
    double currentLength = ropeVector.length;
    if (currentLength <= restLength) return;

    double strain = currentLength - restLength;
    Vector2 dir = ropeVector.normalized();
    var (accel, damping) = YachtPhysics.mooringTension(
      dir, strain, restLength, Constants.yachtMass, dt,
    );
    velocity += accel;
    velocity *= damping;
  }

  void _checkMooringConditions() {
    if (game.dock!.bollardXPositions.isEmpty) return;

    final double bollardY = game.dock!.position.y + game.dock!.size.y;
    List<Vector2>? bollards = game.dock?.bollardXPositions.map((x) => Vector2(game.dock!.position.x + x, bollardY)).toList();

    Vector2 mBowR = localToParent(Vector2(size.x * 0.4, size.y * 0.35));
    Vector2 mBowL = localToParent(Vector2(size.x * 0.4, -size.y * 0.35));
    Vector2 mSternR = localToParent(Vector2(-size.x * 0.4, size.y * 0.35));
    Vector2 mSternL = localToParent(Vector2(-size.x * 0.4, -size.y * 0.35));

    double? dBow = bollards?.map((b) => math.min(mBowR.distanceTo(b), mBowL.distanceTo(b))).reduce(math.min);
    double? dStern = bollards?.map((b) => math.min(mSternR.distanceTo(b), mSternL.distanceTo(b))).reduce(math.min);

    double threshold = 3.5 * Constants.pixelRatio;
    bool speedOk = velocity.length < 1.2 * Constants.pixelRatio;

    canMoerBow = dBow! < threshold && speedOk && bowMooredTo == null;
    canMoerStern = dStern! < threshold && speedOk && sternMooredTo == null;

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
    if (bowMooredTo != null) _drawRope(canvas, bowMooredTo!, _bowRopeLocal);
    if (sternMooredTo != null) _drawRope(canvas, sternMooredTo!, _sternRopeLocal);
  }

  // Метод для отрисовки пера руля
  void _renderRudder(Canvas canvas) {
    canvas.save();
    // Переносимся к корме яхты (центр по ширине)
    canvas.translate(-size.x / 2, 0);
    // Поворачиваем перо руля (текущий угол из физики)
    canvas.rotate(-_currentRudderAngle);
    // Рисуем перо руля (линия от кормы назад)
    canvas.drawLine(
      Offset.zero,
      Offset(-size.x * 0.18, 0),
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawRope(Canvas canvas, Vector2? bollardWorld, Vector2? anchorLocal) {
    if (bollardWorld == null || anchorLocal == null) return;
    Vector2 bLocal = parentToLocal(bollardWorld);
    double dist = (bLocal - anchorLocal).length;
    final paint = Paint()..color = const Color(0xFFEFEBE9)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    if (dist < 3.0 * Constants.pixelRatio * 0.9) {
      final path = Path()..moveTo(anchorLocal.x, anchorLocal.y);
      path.quadraticBezierTo((anchorLocal.x + bLocal.x) / 2, (anchorLocal.y + bLocal.y) / 2 + (3.0 * Constants.pixelRatio - dist) * 0.4, bLocal.x, bLocal.y);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(anchorLocal.toOffset(), bLocal.toOffset(), paint);
    }
  }
}