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
import '../model/level_config.dart';
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

  // Состояние швартовки (2 или 4 линии в зависимости от уровня)
  bool canMoerBow = false;
  bool canMoerStern = false;
  bool canMoerForwardSpring = false;
  bool canMoerBackSpring = false;
  bool canMoerSternPort = false;
  bool canMoerSternStarboard = false;
  bool canMoerLazyLine = false;

  Vector2? bowMooredTo;
  Vector2? sternMooredTo;
  Vector2? forwardSpringMooredTo;
  Vector2? backSpringMooredTo;
  Vector2? sternPortMooredTo;
  Vector2? sternStarboardMooredTo;
  Vector2? lazyLineAnchor;

  /// Якорь (уровень 4): позиция сброшенного якоря в мировых координатах.
  bool isAnchorDropped = false;
  Vector2? anchorPosition;

  double? bowRopeRestLength;
  double? sternRopeRestLength;
  double? forwardSpringRestLength;
  double? backSpringRestLength;
  double? sternPortRestLength;
  double? sternStarboardRestLength;
  double? lazyLineRestLength;

  /// Уведомления о столкновениях/авариях — обрабатываются в [YachtMasterGame].
  void Function(GameEvent)? onGameEvent;

  late final YachtDynamics _dynamics;
  /// Для уровня 1 — борт к причалу (отрицательный Y); для уровней 2–3 — как было.
  double get _ropeBoardOffsetY => size.y * Constants.ropeOffsetFromBoard *
      (game.currentLevel?.id == 1 ? -1.0 : 1.0);
  /// Точка крепления носового швартового (и носового шпринга).
  Vector2 get _bowRopeLocal => Vector2(
        size.x / 2 - Constants.ropeBowPositionFactor * size.x,
        _ropeBoardOffsetY,
      );
  /// Точка крепления кормового швартового (и кормового шпринга).
  Vector2 get _sternRopeLocal => Vector2(
        size.x / 2 - Constants.ropeSternPositionFactor * size.x,
        _ropeBoardOffsetY,
      );
  /// Носовой шпринг крепится к той же точке, что и носовой швартовый.
  Vector2 get _forwardSpringRopeLocal => _bowRopeLocal;
  /// Кормовой шпринг крепится к той же точке, что и кормовой швартовый.
  Vector2 get _backSpringRopeLocal => _sternRopeLocal;
  /// Кормовой левый (порт) — для уровня 3: при корме к причалу левый борт → левый кнехт (локально +y).
  Vector2 get _sternPortRopeLocal => Vector2(-size.x / 2, size.y * Constants.ropeSternEdgeFactor);
  /// Кормовой правый (старборд) — для уровня 3: правый борт → правый кнехт (локально -y).
  Vector2 get _sternStarboardRopeLocal => Vector2(-size.x / 2, -size.y * Constants.ropeSternEdgeFactor);
  /// Кончик носа (по центру) — точка крепления муринга (ленивого конца) для уровня 3.
  Vector2 get _bowTipLocal => Vector2(size.x / 2, 0);

  // Геттеры позиций креплений
  Vector2 get bowWorldPosition => localToParent(_bowRopeLocal);
  /// Мировые координаты кончика носа — точка крепления муринга (уровень 3).
  Vector2 get bowTipWorldPosition => localToParent(_bowTipLocal);
  Vector2 get sternWorldPosition => localToParent(_sternRopeLocal);
  Vector2 get forwardSpringWorldPosition => localToParent(_forwardSpringRopeLocal);
  Vector2 get backSpringWorldPosition => localToParent(_backSpringRopeLocal);
  Vector2 get bowRightWorld => localToParent(Vector2(size.x / 2, size.y / 2));
  Vector2 get bowLeftWorld  => localToParent(Vector2(size.x / 2, -size.y / 2));
  Vector2 get sternRightWorld => localToParent(_sternStarboardRopeLocal);
  Vector2 get sternLeftWorld  => localToParent(_sternPortRopeLocal);

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
  /// Контакт с причалом: для подавления prop walk и проекции скорости по нормали (ось вращения в точке контакта).
  bool _isTouchingDock = false;
  Vector2? _lastDockNormal;
  /// Контакт с другой яхтой (MooredYacht): подавляем prop walk и используем точку контакта как ось вращения.
  bool _isTouchingOtherYacht = false;
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

    // Течение реализовано как смещение позиции, а не как сила — канаты не могут его уравновесить.
    // Подавляем течение, когда яхта полностью пришвартована.
    final double effectiveCurrentSpeed = _hasAnyMooringLineAttached()
        ? 0.0
        : game.activeCurrentSpeed;

    final env = YachtEnvironment(
      windSpeed: game.activeWindSpeed,
      windDirection: game.activeWindDirection,
      currentSpeed: effectiveCurrentSpeed,
      currentDirection: game.activeCurrentDirection,
      distanceToDockPixels: _isTouchingDock ? 0 : _distanceToDockPixels(),
      isTouchingDock: _isTouchingDock,
      isTouchingOtherYacht: _isTouchingOtherYacht,
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

    if (_isTouchingDock && _lastDockNormal != null) {
      final n = _lastDockNormal!;
      final vn = velocity.dot(n);
      if (vn < 0) velocity -= n * vn;
    }

    if (bowMooredTo != null && bowRopeRestLength != null) {
      _applyMooringPhysics(dt, bowMooredTo, _bowRopeLocal, bowRopeRestLength);
    }
    if (sternMooredTo != null && sternRopeRestLength != null) {
      _applyMooringPhysics(dt, sternMooredTo, _sternRopeLocal, sternRopeRestLength);
    }
    final Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));
    if (forwardSpringMooredTo != null && forwardSpringRestLength != null) {
      _applySpringLongitudinal(dt, forwardSpringMooredTo!, _forwardSpringRopeLocal, forwardSpringRestLength!, forwardDir);
    }
    if (backSpringMooredTo != null && backSpringRestLength != null) {
      _applySpringLongitudinal(dt, backSpringMooredTo!, _backSpringRopeLocal, backSpringRestLength!, forwardDir);
    }

    if (game.currentLevel?.mooringSetup.hasMooring == true) {
      if (sternPortMooredTo != null && sternPortRestLength != null) {
        _applyMooringPhysics(dt, sternPortMooredTo, _sternPortRopeLocal, sternPortRestLength);
      }
      if (sternStarboardMooredTo != null && sternStarboardRestLength != null) {
        _applyMooringPhysics(dt, sternStarboardMooredTo, _sternStarboardRopeLocal, sternStarboardRestLength);
      }
      if (lazyLineAnchor != null && lazyLineRestLength != null) {
        final (Vector2 accel, double damping) = YachtPhysics.lazyLineTension(
          lazyLineAnchor!,
          bowTipWorldPosition,
          lazyLineRestLength!,
          Constants.yachtMass,
          dt,
        );
        velocity += accel;
        velocity *= damping;
      }
    }

    if (isAnchorDropped && anchorPosition != null) {
      final double maxChainPixels = Constants.anchorChainMaxLengthMeters * Constants.pixelRatio;
      final (Vector2 accel, double damping) = YachtPhysics.anchorChainTension(
        anchorPosition!,
        bowTipWorldPosition,
        maxChainPixels,
        Constants.yachtMass,
        dt,
      );
      velocity += accel;
      velocity *= damping;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (intersectionPoints.isEmpty) return;
    if (other is Dock) {
      _isTouchingDock = true;
      position -= velocity * (_lastDt * Constants.pixelRatio);
      _lastDockNormal = _depenetrateFromDock(other);
      // Не обнулять скорость полностью — иначе яхта «прилипает» и не может отойти.
      // Убираем только компоненту скорости в направлении причала.
      if (_lastDockNormal != null) {
        final n = _lastDockNormal!;
        final vn = velocity.dot(n);
        if (vn < 0) velocity -= n * vn;
      }
    }
    if (other is MooredYacht) {
      _isTouchingOtherYacht = true;
      position -= velocity * (_lastDt * Constants.pixelRatio);
    }    

    if (other is Dock )  {
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
    if (other is Dock) return;
    if (other is MooredYacht) {
      _depenetrateAndCancelNormalVelocity(worldCollisionPoint, other);
    } else {
      _handleSoftCollision(worldCollisionPoint, other, applyVelocityChange: false, usePivotAtContact: false);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Dock) {
      _isTouchingDock = false;
      _lastDockNormal = null;
    }
    if (other is MooredYacht) {
      _isTouchingOtherYacht = false;
    }
  }

  /// Депенетрация от причала: сдвиг яхты по нормали столкновения так, чтобы хитбоксы не пересекались.
  /// Использует AABB яхты и прямоугольник причала. Возвращает нормаль (от причала к яхте) для проекции скорости.
  Vector2? _depenetrateFromDock(Dock dock) {
    final yl = position.x - size.x / 2;
    final yr = position.x + size.x / 2;
    final yt = position.y - size.y / 2;
    final yb = position.y + size.y / 2;
    final dl = dock.position.x;
    final dt = dock.position.y;
    final dr = dock.position.x + dock.size.x;
    final db = dock.position.y + dock.size.y;
    final overlapL = yr - dl;
    final overlapR = dr - yl;
    final overlapT = yb - dt;
    final overlapB = db - yt;
    if (overlapL <= 0 || overlapR <= 0 || overlapT <= 0 || overlapB <= 0) return null;
    final depthX = overlapL < overlapR ? overlapL : overlapR;
    final depthY = overlapT < overlapB ? overlapT : overlapB;
    Vector2 push;
    if (depthX <= depthY) {
      push = overlapL < overlapR ? Vector2(-depthX, 0) : Vector2(depthX, 0);
    } else {
      push = overlapT < overlapB ? Vector2(0, -depthY) : Vector2(0, depthY);
    }
    position += push;
    return push.normalized();
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
      _handleSoftCollision(worldCollisionPoint, other, usePivotAtContact: other is MooredYacht);

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

  void _handleSoftCollision(Vector2 collisionMid, PositionComponent other, {bool applyVelocityChange = true, bool usePivotAtContact = false}) {
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

    // Выталкивание вдоль нормали (центр масс не смещается внутрь препятствия).
    position += normal * depth;

    if (usePivotAtContact) {
      // Ось вращения в точке контакта: v_contact = v_cm + ω×r = 0 => v_cm = -ω×r.
      // В 2D: ω×r = (-ω*r.y, ω*r.x), значит v_cm = (ω*r.y, -ω*r.x), r = collisionMid - position.
      final Vector2 r = collisionMid - position;
      velocity = Vector2(angularVelocity * r.y, -angularVelocity * r.x);
      angularVelocity *= Constants.collisionAngularDamping;
    } else if (applyVelocityChange && velocity.length > _zeroNormalThreshold) {
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

  /// Контакт с другой яхтой (MooredYacht): депенетрация по AABB и гашение скорости по нормали.
  /// Не подменяем скорость на pivot и не гасим угловую каждый кадр — иначе яхта «прилипает».
  void _depenetrateAndCancelNormalVelocity(Vector2 collisionMid, PositionComponent other) {
    final normal = _depenetrateFromMooredYacht(other);
    if (normal != null) {
      final vn = velocity.dot(normal);
      if (vn < 0) velocity -= normal * vn;
    }
  }

  /// Депенетрация от другой яхты (MooredYacht) по AABB. Игровая яхта — повёрнутый прямоугольник.
  /// Возвращает нормаль (от MooredYacht к игроку) для гашения скорости.
  Vector2? _depenetrateFromMooredYacht(PositionComponent other) {
    final (double yl, double yt, double yr, double yb) = _playerAABB();
    final ol = other.position.x - other.size.x / 2;
    final ot = other.position.y - other.size.y / 2;
    final or = other.position.x + other.size.x / 2;
    final ob = other.position.y + other.size.y / 2;
    final overlapL = yr - ol;
    final overlapR = or - yl;
    final overlapT = yb - ot;
    final overlapB = ob - yt;
    if (overlapL <= 0 || overlapR <= 0 || overlapT <= 0 || overlapB <= 0) return null;
    final depthX = overlapL < overlapR ? overlapL : overlapR;
    final depthY = overlapT < overlapB ? overlapT : overlapB;
    Vector2 push;
    if (depthX <= depthY) {
      push = overlapL < overlapR ? Vector2(-depthX, 0) : Vector2(depthX, 0);
    } else {
      push = overlapT < overlapB ? Vector2(0, -depthY) : Vector2(0, depthY);
    }
    position += push;
    return push.normalized();
  }

  /// AABB игровой яхты с учётом поворота: (left, top, right, bottom).
  (double, double, double, double) _playerAABB() {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final hx = size.x / 2;
    final hy = size.y / 2;
    final c1 = position.x + (hx * cosA - hy * sinA);
    final c2 = position.x + (hx * cosA + hy * sinA);
    final c3 = position.x + (-hx * cosA - hy * sinA);
    final c4 = position.x + (-hx * cosA + hy * sinA);
    final xMin = math.min(math.min(c1, c2), math.min(c3, c4));
    final xMax = math.max(math.max(c1, c2), math.max(c3, c4));
    final d1 = position.y + (hx * sinA + hy * cosA);
    final d2 = position.y + (hx * sinA - hy * cosA);
    final d3 = position.y + (-hx * sinA + hy * cosA);
    final d4 = position.y + (-hx * sinA - hy * cosA);
    final yMin = math.min(math.min(d1, d2), math.min(d3, d4));
    final yMax = math.max(math.max(d1, d2), math.max(d3, d4));
    return (xMin, yMin, xMax, yMax);
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

  /// Шпринг: натяжение только вдоль продольной оси (ограничивает движение вперёд/назад).
  void _applySpringLongitudinal(double dt, Vector2 bollardWorld, Vector2 anchorLocal, double restLength, Vector2 forwardDir) {
    Vector2 anchorWorld = localToParent(anchorLocal);
    Vector2 ropeVector = bollardWorld - anchorWorld;
    double currentLength = ropeVector.length;
    if (currentLength <= restLength) return;

    double strain = currentLength - restLength;
    Vector2 dir = ropeVector.normalized();
    var (accel, damping) = YachtPhysics.mooringSpringLongitudinal(
      dir, strain, restLength, forwardDir, Constants.yachtMass, dt,
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

  /// Пересчёт видимости кнопок швартовки (вызывать после отдачи/приёма конца, чтобы оверлей обновился).
  void refreshMooringConditions() => _checkMooringConditions();

  void _checkMooringConditions() {
    if (game.dock == null) return;
    final d = game.dock!;
    if (d.bollardXPositions.isEmpty) return;

    final double bollardY = d.position.y + (d.size.y * Dock.bollardYFactor);
    final List<Vector2> bollards = d.bollardXPositions.map((x) => Vector2(d.position.x + x, bollardY)).toList();
    if (bollards.isEmpty) return;

    final int lineCount = game.currentLevel?.mooringLinesCount ?? 2;
    final threshold = Constants.mooringBollardProximityPixels;
    final bool speedOk = velocity.length < Constants.mooringSpeedThresholdPixels;
    final bool hasMooring = game.currentLevel?.mooringSetup.hasMooring == true;

    if (lineCount >= 4 && bollards.length >= 4) {
      Vector2 mBow = localToParent(_bowRopeLocal);
      Vector2 mFwdSpring = localToParent(_forwardSpringRopeLocal);
      Vector2 mBackSpring = localToParent(_backSpringRopeLocal);
      Vector2 mStern = localToParent(_sternRopeLocal);
      canMoerBow = mBow.distanceTo(bollards[0]) < threshold && speedOk && bowMooredTo == null;
      canMoerForwardSpring = mFwdSpring.distanceTo(bollards[1]) < threshold && speedOk && forwardSpringMooredTo == null;
      canMoerBackSpring = mBackSpring.distanceTo(bollards[2]) < threshold && speedOk && backSpringMooredTo == null;
      canMoerStern = mStern.distanceTo(bollards[3]) < threshold && speedOk && sternMooredTo == null;
      canMoerSternPort = false;
      canMoerSternStarboard = false;
      canMoerLazyLine = false;
    } else if (game.currentLevel?.mooringSetup.hasAnchor == true && bollards.length >= 2) {
      if (isAnchorDropped && sternPortMooredTo != null && sternStarboardMooredTo != null) {
        game.hideMooringButtons();
        return;
      }
      canMoerBow = false;
      canMoerStern = false;
      canMoerForwardSpring = false;
      canMoerBackSpring = false;
      canMoerLazyLine = false;

      final Vector2 mSternPort = sternLeftWorld;
      final Vector2 mSternStarboard = sternRightWorld;
      canMoerSternPort = mSternPort.distanceTo(bollards[0]) < threshold && speedOk && sternPortMooredTo == null;
      canMoerSternStarboard = mSternStarboard.distanceTo(bollards[1]) < threshold && speedOk && sternStarboardMooredTo == null;

      final bool showSternPort = canMoerSternPort || sternPortMooredTo != null;
      final bool showSternStarboard = canMoerSternStarboard || sternStarboardMooredTo != null;
      final bool showAnchorDrop = !isAnchorDropped && game.isYachtInAnchorDropZone();
      if (showSternPort || showSternStarboard || showAnchorDrop) {
        game.showMooringButtonsAnchor(showSternPort, showSternStarboard, showAnchorDrop);
      } else {
        game.hideMooringButtons();
      }
      return;
    } else if (hasMooring && bollards.length >= 2 && game.mooringAnchorPositionPixels != null) {
      // Все три конца закреплены — скрываем кнопки швартовки (уровень 3).
      if (sternPortMooredTo != null && sternStarboardMooredTo != null && lazyLineAnchor != null) {
        game.hideMooringButtons();
        return;
      }
      Vector2 mSternPort = sternLeftWorld;
      Vector2 mSternStarboard = sternRightWorld;
      Vector2 mBowTip = bowTipWorldPosition;
      canMoerBow = false;
      canMoerStern = false;
      canMoerForwardSpring = false;
      canMoerBackSpring = false;
      // Левый борт (порт) → левый кнехт [0], правый (старборд) → правый кнехт [1].
      canMoerSternPort = mSternPort.distanceTo(bollards[0]) < threshold && speedOk && sternPortMooredTo == null;
      canMoerSternStarboard = mSternStarboard.distanceTo(bollards[1]) < threshold && speedOk && sternStarboardMooredTo == null;
      final double anchorThreshold = Constants.mooringAnchorProximityPixels;
      canMoerLazyLine = mBowTip.distanceTo(game.mooringAnchorPositionPixels!) < anchorThreshold && speedOk && lazyLineAnchor == null;

      final bool showSternPort = canMoerSternPort || sternPortMooredTo != null;
      final bool showSternStarboard = canMoerSternStarboard || sternStarboardMooredTo != null;
      // Кнопка муринга появляется только после отдачи первого швартового (кормовой порт или старборд).
      final bool atLeastOneSternGiven = sternPortMooredTo != null || sternStarboardMooredTo != null;
      final bool showLazyLine = atLeastOneSternGiven;
      if (showSternPort || showSternStarboard || showLazyLine) {
        game.showMooringButtonsThreeLines(showSternPort, showSternStarboard, showLazyLine);
      } else {
        game.hideMooringButtons();
      }
      return;
    } else {
      Vector2 mBowR = localToParent(Vector2(size.x * 0.4, size.y * 0.35));
      Vector2 mBowL = localToParent(Vector2(size.x * 0.4, -size.y * 0.35));
      Vector2 mSternR = localToParent(Vector2(-size.x * 0.4, size.y * 0.35));
      Vector2 mSternL = localToParent(Vector2(-size.x * 0.4, -size.y * 0.35));
      double dBow = bollards.map((b) => math.min(mBowR.distanceTo(b), mBowL.distanceTo(b))).reduce(math.min);
      double dStern = bollards.map((b) => math.min(mSternR.distanceTo(b), mSternL.distanceTo(b))).reduce(math.min);
      canMoerBow = dBow < threshold && speedOk && bowMooredTo == null;
      canMoerStern = dStern < threshold && speedOk && sternMooredTo == null;
      canMoerForwardSpring = false;
      canMoerBackSpring = false;
      canMoerSternPort = false;
      canMoerSternStarboard = false;
      canMoerLazyLine = false;
    }

    final bool showBow = canMoerBow || bowMooredTo != null;
    final bool showStern = canMoerStern || sternMooredTo != null;
    final bool showFwdSpring = canMoerForwardSpring || forwardSpringMooredTo != null;
    final bool showBackSpring = canMoerBackSpring || backSpringMooredTo != null;
    if (showBow || showStern || showFwdSpring || showBackSpring) {
      game.showMooringButtons(showBow, showStern, showFwdSpring, showBackSpring);
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

  /// Есть ли хотя бы один закреплённый швартовый/шпринг/муринг/якорь.
  bool _hasAnyMooringLineAttached() {
    return bowMooredTo != null ||
        sternMooredTo != null ||
        forwardSpringMooredTo != null ||
        backSpringMooredTo != null ||
        sternPortMooredTo != null ||
        sternStarboardMooredTo != null ||
        lazyLineAnchor != null ||
        isAnchorDropped;
  }

  void resetToInitialState() {
    velocity = Vector2.zero();
    angularVelocity = 0.0;
    throttle = 0.0;
    targetThrottle = 0.0;
    _effectiveThrust = 0.0;
    _currentRudderAngle = 0.0;
    targetRudderAngle = 0.0;
    bowMooredTo = sternMooredTo = forwardSpringMooredTo = backSpringMooredTo = null;
    bowRopeRestLength = sternRopeRestLength = forwardSpringRestLength = backSpringRestLength = null;
    isAnchorDropped = false;
    anchorPosition = null;
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

    // 3. РУЛЬ (перо руля). Швартовые и шпринги рисует [RopeRenderer] в мировых координатах.
    _renderRudder(canvas);
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

}