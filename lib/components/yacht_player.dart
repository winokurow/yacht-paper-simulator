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
  double _targetThrottle = 0.0;

  // Состояние швартовки
  late Vector2 _initialPosition;
  late double _initialAngle;
  bool canMoerBow = false;
  bool canMoerStern = false;

  // Точки привязки
  Vector2? bowMooredTo;
  Vector2? sternMooredTo;
  Vector2? bowAnchorPointLocal;
  Vector2? sternAnchorPointLocal;

  // Геттеры позиций
  Vector2 get bowWorldPosition => localToParent(Vector2(size.x / 2, 0));
  Vector2 get sternWorldPosition => localToParent(Vector2(-size.x / 2, 0));
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
    _initialPosition = position.clone();
    _initialAngle = angle;
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

    // 1. Плавно двигаем throttle к _targetThrottle
    // Коэффициент 0.5 заставит газ набираться медленно
    double throttleSpeed = 0.8;
    if (throttle < _targetThrottle) {
      throttle = (throttle + throttleSpeed * dt).clamp(-1.0, 1.0);
    } else if (throttle > _targetThrottle) {
      throttle = (throttle - throttleSpeed * dt).clamp(-1.0, 1.0);
    }

    // 1. ИНЕРЦИЯ РУЛЯ (Перекладка пера)
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
    }

    // 2. РАСЧЕТ СИЛ (Тяга и Сопротивление)
    Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));

    // 1. Тяга винта
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);

    // Боковой дрейф
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.dragCoefficient * 15.0);
// 2. Сопротивление (Drag)
// Нам нужно, чтобы сопротивление росло так, чтобы оно быстро гасило малую тягу
    double speed = velocity.length;
// Коэффициент сопротивления теперь "подстраивается" под скорость
    Vector2 dragForce = velocity * -(Constants.dragCoefficient * (1.0 + speed));

// 3. Результат
    Vector2 acceleration = (thrustForce + dragForce + lateralDrag) / Constants.yachtMass;
    velocity += acceleration * dt;


    // Рассчитываем максимально возможную скорость для текущего газа
    // Если throttle = 0.2, то макс. скорость будет 20% от абсолютного максимума
    double currentMaxSpeed = throttle.abs() * Constants.maxSpeed;

    if (velocity.length > currentMaxSpeed) {
      // Плавное торможение до лимита, определяемого газом
      velocity = velocity.normalized() * currentMaxSpeed;
    }

    // 3. ЗАБРОС ВИНТОМ (Prop Walk)
    if (throttle != 0) {
      double effectMultiplier = (throttle < 0) ? 1.0 : 0.1;
      double direction = (Constants.propType == PropellerType.rightHanded) ? 1.0 : -1.0;
      if (throttle > 0) direction *= -1;

      double propWalkStrength = throttle.abs() * Constants.propWalkEffect * effectMultiplier;
      double speedFactor = (1.0 - (velocity.length / (5.0 * Constants.pixelRatio))).clamp(0.0, 1.0);
      angularVelocity += direction * propWalkStrength * speedFactor * dt;
    }

    // 4. ЭФФЕКТИВНОСТЬ РУЛЯ (Flow speed over rudder)
    // Переводим скорость из пикселей в "метры" для расчетов
    double hullSpeed = velocity.length / Constants.pixelRatio;
    // Поток от винта (Prop Wash) — работает только на переднем ходу
    double propWash = (throttle > 0) ? (throttle * Constants.propWashFactor) : 0.0;

    // ИТОГОВАЯ СКОРОСТЬ ПОТОКА:
    // Добавляем множитель (например, 2.0), чтобы скорость хода сильнее влияла на руль
    double flowSpeed = (hullSpeed * 4.0) + propWash;

    // Коэффициент эффективности руля
    double turningPower = flowSpeed * Constants.rudderEffect;

    // Вращающий момент (Torque)
    double torque = _currentRudderAngle * turningPower;
    angularVelocity += (torque - angularVelocity * Constants.angularDrag) * dt;
    angularVelocity = angularVelocity.clamp(-2.5, 2.5); // Немного увеличим макс. скорость вращения

    // 5. СУБСТЕППИНГ (Движение без проскоков)
    double totalMovement = (velocity.length * dt * Constants.pixelRatio);
    int steps = (totalMovement / 3.0).ceil().clamp(1, 8);
    double stepDt = dt / steps;

    for (int i = 0; i < steps; i++) {
      position += velocity * (stepDt * Constants.pixelRatio);
      angle += angularVelocity * stepDt;
    }

    // 6. ФИЗИКА КАНАТОВ
    _applyMooringPhysics(dt, bowMooredTo, bowAnchorPointLocal);
    _applyMooringPhysics(dt, sternMooredTo, sternAnchorPointLocal);

    _containInArea();

    // --- СТАБИЛИЗАЦИЯ (Анти-дрожание) ---
    // Если скорость меньше 0.05 пикселей в кадр, принудительно обнуляем её
    if (throttle.abs() < 0.01 && velocity.length < 0.05) {
      velocity = Vector2.zero();
      if (angularVelocity.abs() < 0.005) angularVelocity = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Dock || other is MooredYacht) {
      if (intersectionPoints.isNotEmpty) {
        Vector2 collisionMid = intersectionPoints.reduce((a, b) => a + b) / intersectionPoints.length.toDouble();
        double impactSpeed = velocity.length / Constants.pixelRatio;

        // Эффект всплеска при ощутимом ударе
        if (impactSpeed > 0.8) {
          _createSplash(collisionMid);
        }

        double distToBow = collisionMid.distanceTo(bowWorldPosition);
        bool hitByBow = distToBow < (size.y * 0.8);

        // Проверка проигрыша
        if (hitByBow && impactSpeed > 0.5) {
          game.onGameOver("Яхта разбита! Прямой удар носом.");
          return;
        }
        if (impactSpeed > 2.5) {
          game.onGameOver("Пробоина! Слишком большая скорость удара.");
          return;
        }

        _handleSoftCollision(collisionMid, other);
      }
    }
  }

  void _handleSoftCollision(Vector2 collisionMid, PositionComponent other) {
    throttle = 0.0;
    if (velocity.length > 0.1) {
      velocity = -velocity * 0.2;
      angularVelocity *= 0.5;
    } else {
      velocity = Vector2.zero();
    }
    Vector2 pushDir = (position - collisionMid).normalized();
    if (other is Dock && pushDir.y < 0) pushDir.y = 1.0;
    position += pushDir * 4.0;
  }

  void _applyMooringPhysics(double dt, Vector2? bollardWorld, Vector2? anchorLocal) {
    if (bollardWorld == null || anchorLocal == null) return;

    Vector2 anchorWorld = localToParent(anchorLocal);
    Vector2 ropeVector = bollardWorld - anchorWorld;
    double currentLength = ropeVector.length;
    double maxLen = 3.0 * Constants.pixelRatio;

    if (currentLength > maxLen) {
      double strain = currentLength - maxLen;
      double tension = strain * 45.0 + (math.pow(strain, 2) * 0.2);
      Vector2 tensionDir = ropeVector.normalized();
      velocity += (tensionDir * tension / Constants.yachtMass) * dt * 160;
      if (currentLength > 4.0 * Constants.pixelRatio) velocity *= 0.92;
      velocity *= 0.97;
    }
  }

  void _checkMooringConditions() {
    if (game.dock.bollardXPositions.isEmpty) return;

    final double bollardY = game.dock.position.y + game.dock.size.y;
    List<Vector2> bollards = game.dock.bollardXPositions.map((x) => Vector2(game.dock.position.x + x, bollardY)).toList();

    Vector2 mBowR = localToParent(Vector2(size.x * 0.4, size.y * 0.35));
    Vector2 mBowL = localToParent(Vector2(size.x * 0.4, -size.y * 0.35));
    Vector2 mSternR = localToParent(Vector2(-size.x * 0.4, size.y * 0.35));
    Vector2 mSternL = localToParent(Vector2(-size.x * 0.4, -size.y * 0.35));

    double dBow = bollards.map((b) => math.min(mBowR.distanceTo(b), mBowL.distanceTo(b))).reduce(math.min);
    double dStern = bollards.map((b) => math.min(mSternR.distanceTo(b), mSternL.distanceTo(b))).reduce(math.min);

    double threshold = 3.5 * Constants.pixelRatio;
    bool speedOk = velocity.length < 1.2 * Constants.pixelRatio;

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
        count: 15,
        lifespan: 0.8,
        generator: (i) {
          final velocity = Vector2(math.cos(rnd.nextDouble() * 6.28), math.sin(rnd.nextDouble() * 6.28)) * (40.0 + rnd.nextDouble() * 60.0);
          return AcceleratedParticle(
            acceleration: velocity * -0.5,
            speed: velocity,
            child: CircleParticle(
              radius: 1.0 + rnd.nextDouble() * 2.5,
              paint: Paint()..color = const Color(0xCCEEFFFF),
            ),
          );
        },
      ),
    ));
  }

  @override
  void render(Canvas canvas) {
    if (yachtSprite == null) return;

    // ХИТРОСТЬ: Округляем позицию отрисовки до целых пикселей.
    // Это убирает "мерцание" краев при микро-движениях.
    final drawRect = Rect.fromLTWH(
        (-size.x / 2).roundToDouble(),
        (-size.y / 2).roundToDouble(),
        size.x.roundToDouble(),
        size.y.roundToDouble()
    );

    // Рисуем тень
    canvas.drawRect(
        drawRect.shift(const Offset(2, 2)),
        Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
    );

    // Рисуем спрайт
    yachtSprite!.renderRect(canvas, drawRect);

    _renderRudder(canvas);
    _drawRope(canvas, bowMooredTo, bowAnchorPointLocal);
    _drawRope(canvas, sternMooredTo, sternAnchorPointLocal);

    if (game.debugMode) _renderDebug(canvas);
  }

  void _renderRudder(Canvas canvas) {
    canvas.save();
    canvas.translate(-size.x / 2, 0);
    canvas.rotate(-_currentRudderAngle);
    canvas.drawLine(Offset.zero, Offset(-size.x * 0.15, 0), Paint()..color = Colors.orange..strokeWidth = 2.0);
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

  void _renderDebug(Canvas canvas) {
    final p = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x/2, 0), 4, p..color = Colors.green);
    canvas.drawCircle(Offset(-size.x/2, 0), 4, p..color = Colors.red);
    p.color = Colors.white;
    canvas.drawCircle(Offset(size.x * 0.4, size.y * 0.35), 2, p);
    canvas.drawCircle(Offset(size.x * 0.4, -size.y * 0.35), 2, p);
    canvas.drawCircle(Offset(-size.x * 0.4, size.y * 0.35), 2, p);
    canvas.drawCircle(Offset(-size.x * 0.4, -size.y * 0.35), 2, p);
  }

  void _containInArea() {
    if (!game.playArea.contains(position.toOffset())) game.onOutOfBounds();
  }

  void resetToInitialState() {
    position = _initialPosition.clone();
    angle = _initialAngle;
    velocity = Vector2.zero();
    angularVelocity = throttle = _currentRudderAngle = targetRudderAngle = 0.0;
    bowMooredTo = sternMooredTo = bowAnchorPointLocal = sternAnchorPointLocal = null;
  }

  void setThrottle(double value) {
    _targetThrottle = value;
  }
}