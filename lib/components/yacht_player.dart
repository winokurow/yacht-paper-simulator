
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

    // --- 1. ТЕЧЕНИЕ (River Current) ---
    if (game.activeCurrentSpeed > 0) {
      Vector2 currentFlow = Vector2(
          math.cos(game.activeCurrentDirection),
          math.sin(game.activeCurrentDirection)
      ) * game.activeCurrentSpeed * Constants.pixelRatio;

      position += currentFlow * dt; // Снос лодки течением
    }

    // --- 2. УПРАВЛЕНИЕ ГАЗОМ ---
    double throttleChangeSpeed = 1.0;
    if (throttle < targetThrottle) {
      throttle = (throttle + throttleChangeSpeed * dt).clamp(-1.0, 1.0);
    } else if (throttle > targetThrottle) {
      throttle = (throttle - throttleChangeSpeed * dt).clamp(-1.0, 1.0);
    }

    // --- 3. ПЕРЕКЛАДКА РУЛЯ ---
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
    }

    // --- 4. ФИЗИКА ДВИЖЕНИЯ ---
    double speedMeters = velocity.length / Constants.pixelRatio;
    double propWash = (throttle > 0) ? (throttle * Constants.propWashFactor) : 0.0;
    double totalFlow = speedMeters + propWash;

    Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);

    // Сопротивление
    double dragFactor = Constants.dragCoefficient * (1.0 + speedMeters * 0.5);
    Vector2 dragForce = velocity * -dragFactor;

    // Боковое сопротивление (Киль)
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.lateralDragMultiplier * Constants.pixelRatio);

    Vector2 linearAcceleration = (thrustForce + dragForce + lateralDrag) / Constants.yachtMass;
    velocity += linearAcceleration * dt;

    // --- 5. ВРАЩЕНИЕ И ПРОП-ВОЛК ---
    double totalTorque = _currentRudderAngle * totalFlow * Constants.rudderEffect * 1000.0;

    if (throttle.abs() > 0.01) {
      double effectMultiplier = (throttle < 0) ? 1.0 : 0.04;
      double sideDir = (Constants.propType == PropellerType.rightHanded) ? 1.0 : -1.0;
      if (throttle > 0) sideDir *= -1;

      double propWalkFade = (1.0 - (speedMeters / 1.5)).clamp(0.0, 1.0);
      double propWalkTorque = sideDir * throttle.abs() * Constants.propWalkEffect * effectMultiplier * (propWalkFade * propWalkFade) * 500.0;
      totalTorque += propWalkTorque;
    }

    angularVelocity += (totalTorque / Constants.yachtInertia) * dt;
    angularVelocity *= (1.0 - (Constants.angularDrag * dt)).clamp(0.0, 1.0);
    angularVelocity = angularVelocity.clamp(-1.2, 1.2);

    // Движение
    position += velocity * (dt * Constants.pixelRatio);
    angle += angularVelocity * dt;

    // --- 6. ШВАРТОВКА (Physics) ---
    if (bowMooredTo != null) {
      _applyMooringPhysics(dt, bowMooredTo, bowAnchorPointLocal, bowRopeRestLength, true);
    }
    if (sternMooredTo != null) {
      _applyMooringPhysics(dt, sternMooredTo, sternAnchorPointLocal, sternRopeRestLength, false);
    }

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
    velocity = -velocity * 0.2;
    angularVelocity *= 0.5;
    Vector2 pushDir = (position - collisionMid).normalized();
    position += pushDir * 3.0;
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
    canvas.drawRect(drawRect.shift(const Offset(3, 3)),
        Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    yachtSprite!.renderRect(canvas, drawRect);

    // Отрисовка канатов
    if (bowMooredTo != null) _drawRope(canvas, bowMooredTo!, Vector2(size.x * 0.45, 0), bowRopeRestLength!);
    if (sternMooredTo != null) _drawRope(canvas, sternMooredTo!, Vector2(-size.x * 0.45, 0), sternRopeRestLength!);
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