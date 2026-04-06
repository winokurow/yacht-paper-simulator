import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';

import '../core/constants.dart';
import '../core/game_events.dart';
import '../core/marina_layout.dart';
import '../core/yacht_physics.dart';
import '../game/yacht_game.dart';
import '../model/level_config.dart';
import 'dock_component.dart';
import 'moored_yacht.dart';
import 'pile_component.dart';

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

  /// Baltic style (уровень 5): носовые концы к причалу.
  Vector2? balticBowPortMooredTo;
  Vector2? balticBowStarboardMooredTo;
  double? balticBowPortRestLength;
  double? balticBowStarboardRestLength;
  bool canMoerBalticBowPort = false;
  bool canMoerBalticBowStarboard = false;

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
  /// Alongside (linesOnly) — борт к причалу (отрицательный Y); для остальных — как было.
  double get _ropeBoardOffsetY => size.y * Constants.ropeOffsetFromBoard *
      (game.currentLevel?.mooringSetup == MooringSetup.linesOnly ? -1.0 : 1.0);
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
  /// Кормовой левый (порт) — для уровня 3: при корме к причалу левый борт → левый кнехт (локально -y).
  Vector2 get _sternPortRopeLocal => Vector2(-size.x / 2, -size.y * Constants.ropeSternEdgeFactor);
  /// Кормовой правый (старборд) — для уровня 3: правый борт → правый кнехт (локально +y).
  Vector2 get _sternStarboardRopeLocal => Vector2(-size.x / 2, size.y * Constants.ropeSternEdgeFactor);
  /// Кончик носа (по центру) — точка крепления муринга (ленивого конца) для уровня 3.
  Vector2 get _bowTipLocal => Vector2(size.x / 2, 0);
  /// Носовой порт (Baltic): крепление на том же X, что и обычный носовой швартовый, левый борт (локально -y).
  Vector2 get _bowPortRopeLocal => Vector2(_bowRopeLocal.x, -size.y * Constants.ropeSternEdgeFactor);
  /// Носовой старборд (Baltic): правый борт (локально +y).
  Vector2 get _bowStarboardRopeLocal => Vector2(_bowRopeLocal.x, size.y * Constants.ropeSternEdgeFactor);

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
  /// Мировые координаты носового порта (Baltic).
  Vector2 get bowPortWorld => localToParent(_bowPortRopeLocal);
  /// Мировые координаты носового старборда (Baltic).
  Vector2 get bowStarboardWorld => localToParent(_bowStarboardRopeLocal);

  YachtPlayer({double startAngleDegrees = 0.0}) : super(
    size: Vector2(12.0 * Constants.pixelRatio, 4.0 * Constants.pixelRatio),
    anchor: Anchor.center,
    priority: Constants.renderPriorityPlayerYacht,
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

    // Baltic style (уровень 5): 2 кормовых к сваям + 2 носовых к причалу.
    if (game.currentLevel?.mooringSetup.isBaltic == true) {
      if (sternPortMooredTo != null && sternPortRestLength != null) {
        _applyMooringPhysics(dt, sternPortMooredTo, _sternPortRopeLocal, sternPortRestLength);
      }
      if (sternStarboardMooredTo != null && sternStarboardRestLength != null) {
        _applyMooringPhysics(dt, sternStarboardMooredTo, _sternStarboardRopeLocal, sternStarboardRestLength);
      }
      if (balticBowPortMooredTo != null && balticBowPortRestLength != null) {
        _applyMooringPhysics(dt, balticBowPortMooredTo, _bowPortRopeLocal, balticBowPortRestLength);
      }
      if (balticBowStarboardMooredTo != null && balticBowStarboardRestLength != null) {
        _applyMooringPhysics(dt, balticBowStarboardMooredTo, _bowStarboardRopeLocal, balticBowStarboardRestLength);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (intersectionPoints.isEmpty) return;
    if (other is Dock) {
      _isTouchingDock = true;
      _lastDockNormal = _depenetrateFromDock(other);
      if (_lastDockNormal != null) {
        final n = _lastDockNormal!;
        final vn = velocity.dot(n);
        if (vn < 0) velocity -= n * vn;
      }
    }
    if (other is MooredYacht) {
      _isTouchingOtherYacht = true;
    }
    if (other is PileComponent) {
      _depenetrateFromPile(other);
      return;
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
  /// Использует rotated AABB яхты и прямоугольник причала. Возвращает нормаль (от причала к яхте).
  Vector2? _depenetrateFromDock(Dock dock) {
    final (double yl, double yt, double yr, double yb) = _playerAABB();
    final double dl = dock.position.x;
    final double dt_ = dock.position.y;
    final double dr = dock.position.x + dock.size.x;
    final double db = dock.position.y + dock.size.y;
    final double overlapL = yr - dl;
    final double overlapR = dr - yl;
    final double overlapT = yb - dt_;
    final double overlapB = db - yt;
    if (overlapL <= 0 || overlapR <= 0 || overlapT <= 0 || overlapB <= 0) return null;
    final double depthX = overlapL < overlapR ? overlapL : overlapR;
    final double depthY = overlapT < overlapB ? overlapT : overlapB;
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

  /// Столкновение со сваей: выталкивание по нормали от центра сваи + гашение скорости в сторону столба.
  void _depenetrateFromPile(PileComponent pile) {
    final Vector2 pileCenter = pile.position;
    final double pileR = Constants.pileRadiusPixels;
    final double yachtR = math.min(size.x, size.y) / 2;
    final Vector2 diff = position - pileCenter;
    final double dist = diff.length;
    if (dist < 1e-6) {
      position += Vector2(0, -(pileR + yachtR));
      velocity = Vector2.zero();
      return;
    }
    final Vector2 normal = diff / dist;
    final double overlap = (pileR + yachtR) - dist;
    if (overlap > 0) {
      position += normal * overlap;
    }
    final double vn = velocity.dot(normal);
    if (vn < 0) {
      velocity -= normal * vn;
      velocity *= Constants.collisionRestitution;
    }
    angularVelocity *= Constants.collisionAngularDamping;
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

  /// Депенетрация от другой яхты (MooredYacht) по AABB.
  /// Учитывает поворот обоих объектов. Возвращает нормаль (от MooredYacht к игроку).
  Vector2? _depenetrateFromMooredYacht(PositionComponent other) {
    final (double yl, double yt, double yr, double yb) = _playerAABB();

    // AABB пришвартованной яхты с учётом её поворота.
    final double cosO = math.cos(other.angle).abs();
    final double sinO = math.sin(other.angle).abs();
    final double ohx = other.size.x / 2;
    final double ohy = other.size.y / 2;
    final double oxExt = ohx * cosO + ohy * sinO;
    final double oyExt = ohx * sinO + ohy * cosO;
    final double ol = other.position.x - oxExt;
    final double ot = other.position.y - oyExt;
    final double or_ = other.position.x + oxExt;
    final double ob = other.position.y + oyExt;

    final double overlapL = yr - ol;
    final double overlapR = or_ - yl;
    final double overlapT = yb - ot;
    final double overlapB = ob - yt;
    if (overlapL <= 0 || overlapR <= 0 || overlapT <= 0 || overlapB <= 0) return null;
    final double depthX = overlapL < overlapR ? overlapL : overlapR;
    final double depthY = overlapT < overlapB ? overlapT : overlapB;
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
    final int lineCount = game.currentLevel?.mooringLinesCount ?? 2;
    final bool speedOk = velocity.length < Constants.mooringSpeedThresholdPixels;
    final bool hasMooring = game.currentLevel?.mooringSetup.hasMooring == true;

    // Baltic style (уровень 5): только сваи, кнехты не используются; каждая кнопка — по расстоянию до своей сваи.
    if (game.currentLevel?.mooringSetup.isBaltic == true && game.pilePositionsPixels.length >= 4) {
      if (sternPortMooredTo != null && sternStarboardMooredTo != null &&
          balticBowPortMooredTo != null && balticBowStarboardMooredTo != null) {
        game.hideMooringButtons();
        return;
      }
      canMoerBow = false;
      canMoerStern = false;
      canMoerForwardSpring = false;
      canMoerBackSpring = false;
      canMoerLazyLine = false;

      final double pileThreshold = Constants.pileMooringProximityPixels;
      final Vector2 mSternPort = sternLeftWorld;
      final Vector2 mSternStarboard = sternRightWorld;
      canMoerSternPort = mSternPort.distanceTo(game.pilePositionsPixels[0]) < pileThreshold && speedOk && sternPortMooredTo == null;
      canMoerSternStarboard = mSternStarboard.distanceTo(game.pilePositionsPixels[1]) < pileThreshold && speedOk && sternStarboardMooredTo == null;

      final Vector2 mBowPort = bowPortWorld;
      final Vector2 mBowStarboard = bowStarboardWorld;
      canMoerBalticBowPort = mBowPort.distanceTo(game.pilePositionsPixels[2]) < pileThreshold && speedOk && balticBowPortMooredTo == null;
      canMoerBalticBowStarboard = mBowStarboard.distanceTo(game.pilePositionsPixels[3]) < pileThreshold && speedOk && balticBowStarboardMooredTo == null;

      final bool showAftPort = canMoerSternPort || sternPortMooredTo != null;
      final bool showAftStarboard = canMoerSternStarboard || sternStarboardMooredTo != null;
      final bool showBowPort = canMoerBalticBowPort || balticBowPortMooredTo != null;
      final bool showBowStarboard = canMoerBalticBowStarboard || balticBowStarboardMooredTo != null;
      if (showAftPort || showAftStarboard || showBowPort || showBowStarboard) {
        game.showMooringButtonsBaltic(showAftPort, showAftStarboard, showBowPort, showBowStarboard);
      } else {
        game.hideMooringButtons();
      }
      return;
    }

    final List<Vector2> bollards = d.bollardWorldPositions;
    if (bollards.isEmpty) return;

    final double threshold = Constants.mooringBollardProximityPixels;

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
      if (MarinaLayout.narrowSternUsesVerticalFingerBollardPairing(game.currentLevel)) {
        final (upper, lower) = MarinaLayout.sternFingerDockUpperLowerBollards(bollards[0], bollards[1]);
        canMoerSternPort = mSternPort.distanceTo(lower) < threshold && speedOk && sternPortMooredTo == null;
        canMoerSternStarboard =
            mSternStarboard.distanceTo(upper) < threshold && speedOk && sternStarboardMooredTo == null;
      } else {
        final double pD0 = mSternPort.distanceTo(bollards[0]);
        final double pD1 = mSternPort.distanceTo(bollards[1]);
        canMoerSternPort = math.min(pD0, pD1) < threshold && speedOk && sternPortMooredTo == null;
        final double sD0 = mSternStarboard.distanceTo(bollards[0]);
        final double sD1 = mSternStarboard.distanceTo(bollards[1]);
        canMoerSternStarboard = math.min(sD0, sD1) < threshold && speedOk && sternStarboardMooredTo == null;
      }

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
      if (MarinaLayout.narrowSternUsesVerticalFingerBollardPairing(game.currentLevel)) {
        final (upper, lower) = MarinaLayout.sternFingerDockUpperLowerBollards(bollards[0], bollards[1]);
        canMoerSternPort = mSternPort.distanceTo(lower) < threshold && speedOk && sternPortMooredTo == null;
        canMoerSternStarboard =
            mSternStarboard.distanceTo(upper) < threshold && speedOk && sternStarboardMooredTo == null;
      } else {
        final double portD0 = mSternPort.distanceTo(bollards[0]);
        final double portD1 = mSternPort.distanceTo(bollards[1]);
        canMoerSternPort = math.min(portD0, portD1) < threshold && speedOk && sternPortMooredTo == null;
        final double stbdD0 = mSternStarboard.distanceTo(bollards[0]);
        final double stbdD1 = mSternStarboard.distanceTo(bollards[1]);
        canMoerSternStarboard = math.min(stbdD0, stbdD1) < threshold && speedOk && sternStarboardMooredTo == null;
      }
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
    } else if (bollards.length >= 2) {
      // Классическая швартовка (2 линии): кнопка появляется только у соответствующего кнехта.
      final Vector2 mBow = localToParent(_bowRopeLocal);
      final Vector2 mStern = localToParent(_sternRopeLocal);
      final Vector2 bowBollard = mBow.distanceTo(bollards[0]) <= mBow.distanceTo(bollards[1]) ? bollards[0] : bollards[1];
      final Vector2 sternBollard = bowBollard == bollards[0] ? bollards[1] : bollards[0];
      canMoerBow = mBow.distanceTo(bowBollard) < threshold && speedOk && bowMooredTo == null;
      canMoerStern = mStern.distanceTo(sternBollard) < threshold && speedOk && sternMooredTo == null;
      canMoerForwardSpring = false;
      canMoerBackSpring = false;
      canMoerSternPort = false;
      canMoerSternStarboard = false;
      canMoerLazyLine = false;
    } else {
      canMoerBow = false;
      canMoerStern = false;
      canMoerForwardSpring = false;
      canMoerBackSpring = false;
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
        isAnchorDropped ||
        balticBowPortMooredTo != null ||
        balticBowStarboardMooredTo != null;
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
    sternPortMooredTo = sternStarboardMooredTo = null;
    sternPortRestLength = sternStarboardRestLength = null;
    lazyLineAnchor = null;
    lazyLineRestLength = null;
    isAnchorDropped = false;
    anchorPosition = null;
    balticBowPortMooredTo = balticBowStarboardMooredTo = null;
    balticBowPortRestLength = balticBowStarboardRestLength = null;
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