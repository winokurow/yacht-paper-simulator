import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';

import '../core/constants.dart';
import '../core/game_events.dart';
import '../core/yacht_physics.dart';
import '../game/yacht_game.dart';
import 'dock_component.dart';
import 'moored_yacht.dart';

class YachtPlayer extends PositionComponent with CollisionCallbacks, HasGameReference<YachtMasterGame> {
  Sprite? yachtSprite;

  // Состояние движения (синхронизируется с YachtDynamics)
  double angularVelocity = 0.0;
  double targetRudderAngle = 0.0;
  double _currentRudderAngle = 0.0;
  double throttle = 0.0;
  Vector2 velocity = Vector2.zero();
  double targetThrottle = 0.0;

  // Состояние швартовки
  bool canMoerBow = false;
  bool canMoerStern = false;

  Vector2? bowMooredTo;
  Vector2? sternMooredTo;
  double? bowRopeRestLength;
  double? sternRopeRestLength;

  /// Уведомления о столкновениях/авариях — обрабатываются в [YachtMasterGame].
  void Function(GameEvent)? onGameEvent;

  late final YachtDynamics _dynamics;
  Vector2 get _bowRopeLocal => Vector2(
        size.x / 2 - Constants.ropeBowPositionFactor * size.x,
        size.y * Constants.ropeOffsetFromBoard,
      );
  Vector2 get _sternRopeLocal => Vector2(
        size.x / 2 - Constants.ropeSternPositionFactor * size.x,
        -size.y * Constants.ropeOffsetFromBoard,
      );

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

  /// Последний dt для Position Correction в onCollision (откат на шаг назад).
  double _lastDt = 1 / 60.0;
  /// Время с последнего всплеска (для ограничения частоты частиц).
  double _lastSplashTime = 0.0;
  /// Эффективная тяга (сглаженная) для инерции двигателя — хранится между кадрами.
  double _effectiveThrust = 0.0;

  @override
  Future<void> onLoad() async {
    _dynamics = YachtDynamics();
    yachtSprite = await game.loadSprite('yacht_paper.png');

    // Полигон по форме яхты: острый нос, прямые борта, плоская корма (координаты хитбокса, position: -size/2).
    final List<Vector2> boatShape = [
      Vector2(size.x, size.y / 2),        // нос
      Vector2(size.x * 0.2, 0),           // борт левый
      Vector2(0, size.y * 0.2),            // корма левый угол
      Vector2(0, size.y * 0.8),           // корма правый угол
      Vector2(size.x * 0.2, size.y),     // борт правый
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
    _lastSplashTime += dt;
    if (dt <= 0.1) _lastDt = dt;
    _checkMooringConditions();
    if (dt > 0.1) return;

    final env = YachtEnvironment(
      windSpeed: game.activeWindSpeed,
      windDirection: game.activeWindDirection,
      currentSpeed: game.activeCurrentSpeed,
      currentDirection: game.activeCurrentDirection,
      distanceToDockPixels: _distanceToDockPixels(),
    );
    final state = YachtMotionState(
      position: position,
      angle: angle,
      velocity: velocity,
      angularVelocity: angularVelocity,
      throttle: throttle,
      effectiveThrust: _effectiveThrust,
      currentRudderAngle: _currentRudderAngle,
    );
    final next = _dynamics.step(state, targetThrottle, targetRudderAngle, env, dt);

    position = next.position;
    angle = next.angle;
    velocity = next.velocity;
    angularVelocity = next.angularVelocity;
    throttle = next.throttle;
    _effectiveThrust = next.effectiveThrust;
    _currentRudderAngle = next.currentRudderAngle;

    if (bowMooredTo != null && bowRopeRestLength != null) {
      _applyMooringPhysics(dt, bowMooredTo, _bowRopeLocal, bowRopeRestLength);
    }
    if (sternMooredTo != null && sternRopeRestLength != null) {
      _applyMooringPhysics(dt, sternMooredTo, _sternRopeLocal, sternRopeRestLength);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (intersectionPoints.isEmpty) return;
    if (other is Dock) {
      position -= velocity * (_lastDt * Constants.pixelRatio);
      YachtPhysics.stop((v, a) {
        velocity = v;
        angularVelocity = a;
      });
    }
    if (other is Dock || other is MooredYacht) {
      Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));
      Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
      double lateralSpeed = velocity.dot(lateralDir);
      velocity -= lateralDir * lateralSpeed;
    }
    final worldCollisionPoint = intersectionPoints.first;
    final localCollisionPoint = parentToLocal(worldCollisionPoint);
    bool isNoseHit = localCollisionPoint.x > (size.x * Constants.noseSectorFactor);
    bool isHighSpeed = velocity.length > Constants.maxSafeImpactSpeed;
    if (isNoseHit && isHighSpeed) return;
    if (isHighSpeed) return;
    _handleSoftCollision(worldCollisionPoint, other, applyVelocityChange: false);
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
    // что находится правее (впереди) отметки size.x * noseSectorFactor
    bool isNoseHit = localCollisionPoint.x > (size.x * Constants.noseSectorFactor);

    // Проверка скорости (используем м/с)
    bool isHighSpeed = velocity.length > Constants.maxSafeImpactSpeed;

    if (isNoseHit && isHighSpeed) {
      _triggerCrash(game.l10n?.crashNose ?? 'CRITICAL: Nose collision!');
    } else if (isHighSpeed) {
      _triggerCrash(game.l10n?.crashSide ?? 'ACCIDENT: Side impact too strong.');
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
    onGameEvent?.call(CrashEvent(message));
  }

  static const double _zeroNormalThreshold = Constants.collisionZeroNormalThreshold;

  /// Возвращает мировые координаты центра компонента с учётом anchor.
  static Vector2 _worldCenter(PositionComponent c) {
    final anchorOffset = Vector2(
      c.size.x * (0.5 - c.anchor.x),
      c.size.y * (0.5 - c.anchor.y),
    );
    return c.position + anchorOffset;
  }

  static double _approximateRadius(PositionComponent c) {
    return math.min(c.size.x, c.size.y) * Constants.collisionApproximateRadiusFactor;
  }

  void _handleSoftCollision(Vector2 collisionMid, PositionComponent other, {bool applyVelocityChange = true}) {
    final playerCenter = _worldCenter(this);
    final obstacleCenter = _worldCenter(other);

    // Нормаль: от центра препятствия к центру игрока (игрока выталкиваем наружу).
    Vector2 normal = playerCenter - obstacleCenter;
    final dist = normal.length;
    if (dist < _zeroNormalThreshold) {
      // Центры совпали — используем направление от точки контакта к игроку
      normal = position - collisionMid;
      if (normal.length < _zeroNormalThreshold) {
        velocity = Vector2.zero();
        angularVelocity = 0.0;
        return;
      }
    }
    normal = normal.normalized();

    // Глубина проникновения: сумма «радиусов» минус расстояние между центрами.
    final rPlayer = _approximateRadius(this);
    final rObstacle = _approximateRadius(other);
    double depth = (rPlayer + rObstacle) - dist;
    if (depth < 0) depth = 0;

    // Выталкивание вдоль нормали.
    position += normal * depth;

    if (applyVelocityChange && velocity.length > _zeroNormalThreshold) {
      final vn = velocity.dot(normal);
      if (vn < 0) {
        velocity = velocity - normal * (2 * vn);
        velocity *= Constants.collisionRestitution;
      }
      angularVelocity *= Constants.collisionAngularDamping;
    } else if (applyVelocityChange) {
      velocity = Vector2.zero();
      angularVelocity = 0.0;
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

  /// Минимальная дистанция от центра яхты до прямоугольника причала (в пикселях).
  double _distanceToDockPixels() {
    if (game.dock == null) return double.infinity;
    final d = game.dock!;
    final left = d.position.x;
    final top = d.position.y;
    final right = d.position.x + d.size.x;
    final bottom = d.position.y + d.size.y;
    final cx = position.x.clamp(left, right);
    final cy = position.y.clamp(top, bottom);
    return position.distanceTo(Vector2(cx, cy));
  }

  void _checkMooringConditions() {
    if (game.dock == null) return;
    final d = game.dock!;
    if (d.bollardXPositions.isEmpty) return;

    final double bollardY = d.position.y + d.size.y;
    final List<Vector2> bollards = d.bollardXPositions.map((x) => Vector2(d.position.x + x, bollardY)).toList();
    if (bollards.isEmpty) return;

    Vector2 mBowR = localToParent(Vector2(size.x * 0.4, size.y * 0.35));
    Vector2 mBowL = localToParent(Vector2(size.x * 0.4, -size.y * 0.35));
    Vector2 mSternR = localToParent(Vector2(-size.x * 0.4, size.y * 0.35));
    Vector2 mSternL = localToParent(Vector2(-size.x * 0.4, -size.y * 0.35));

    double dBow = bollards.map((b) => math.min(mBowR.distanceTo(b), mBowL.distanceTo(b))).reduce(math.min);
    double dStern = bollards.map((b) => math.min(mSternR.distanceTo(b), mSternL.distanceTo(b))).reduce(math.min);

    final threshold = Constants.mooringBollardProximityPixels;
    bool speedOk = velocity.length < Constants.mooringSpeedThresholdPixels;

    canMoerBow = dBow < threshold && speedOk && bowMooredTo == null;
    canMoerStern = dStern < threshold && speedOk && sternMooredTo == null;

    if (canMoerBow || canMoerStern) {
      game.showMooringButtons(canMoerBow, canMoerStern);
    } else {
      game.hideMooringButtons();
    }
  }

  void _createSplash(Vector2 impactPoint) {
    if (_lastSplashTime < Constants.splashCooldownSeconds) return;
    _lastSplashTime = 0.0;
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
    _effectiveThrust = 0.0;
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
      Offset(-size.x * Constants.rudderDrawLengthFactor, 0),
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
    final sagThreshold = Constants.ropeSagDistanceFactor * Constants.pixelRatio * 0.9;
    if (dist < sagThreshold) {
      final path = Path()..moveTo(anchorLocal.x, anchorLocal.y);
      path.quadraticBezierTo(
        (anchorLocal.x + bLocal.x) / 2,
        (anchorLocal.y + bLocal.y) / 2 + (Constants.ropeSagDistanceFactor * Constants.pixelRatio - dist) * Constants.ropeSagFactor,
        bLocal.x,
        bLocal.y,
      );
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(anchorLocal.toOffset(), bLocal.toOffset(), paint);
    }
  }
}