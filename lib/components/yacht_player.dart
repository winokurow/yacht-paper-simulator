import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Состояние швартовки
  late Vector2 _initialPosition;
  late double _initialAngle;
  bool canMoerBow = false;
  bool canMoerStern = false;

  // Точки привязки (мировые и локальные)
  Vector2? bowMooredTo;
  Vector2? sternMooredTo;
  Vector2? bowAnchorPointLocal;
  Vector2? sternAnchorPointLocal;

  // Геттеры для логики игры
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

    final w = size.x;
    final h = size.y;
    final boatShape = [
      Vector2(w, h * 0.5),
      Vector2(w * 0.8, 0),
      Vector2(0, 0),
      Vector2(0, h),
      Vector2(w * 0.8, h),
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

    // 1. Инерция руля
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
    }

    // 2. Расчет сил (Тяга, Сопротивление)
    Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);
    Vector2 dragForce = velocity * -Constants.dragCoefficient;

    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.dragCoefficient * 15.0);

    Vector2 acceleration = (thrustForce + dragForce + lateralDrag) / Constants.yachtMass;
    velocity += acceleration * dt;

    if (velocity.length > 6.0) velocity = velocity.normalized() * 6.0;

    // 3. СУБСТЕППИНГ (Движение без проскоков)
    double totalMovement = (velocity.length * dt * Constants.pixelRatio);
    int steps = (totalMovement / 3.0).ceil().clamp(1, 8);
    double stepDt = dt / steps;

    for (int i = 0; i < steps; i++) {
      position += velocity * (stepDt * Constants.pixelRatio);
      angle += angularVelocity * stepDt; // Дробим вращение для точности хитбокса
    }

    // 4. Физика канатов
    _applyMooringPhysics(dt, bowMooredTo, bowAnchorPointLocal);
    _applyMooringPhysics(dt, sternMooredTo, sternAnchorPointLocal);

    // 5. Маневрирование
    double turningPower = (velocity.length + throttle.abs() * 1.5) * Constants.rudderEffect;
    double torque = _currentRudderAngle * turningPower;
    angularVelocity += (torque - angularVelocity * Constants.angularDrag) * dt;
    angularVelocity = angularVelocity.clamp(-3.0, 3.0);

    _containInArea();
  }

  @override
  void render(Canvas canvas) {
    if (yachtSprite == null) return;

    final destRect = Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y);

    // Тень
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRect(destRect.shift(const Offset(2, 2)), shadowPaint);

    // Спрайт
    yachtSprite!.renderRect(canvas, destRect);

    _renderRudder(canvas);
    _drawRope(canvas, bowMooredTo, bowAnchorPointLocal);
    _drawRope(canvas, sternMooredTo, sternAnchorPointLocal);

    if (game.debugMode) {
      _renderDebug(canvas);
    }
  }

  void _renderRudder(Canvas canvas) {
    final rudderPaint = Paint()..color = Colors.orange.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.save();
    canvas.translate(-size.x / 2, 0);
    canvas.rotate(-_currentRudderAngle);
    canvas.drawLine(Offset.zero, Offset(-size.x * 0.15, 0), rudderPaint);
    canvas.restore();
  }

  void _renderDebug(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x / 2, 0), 4, paint..color = Colors.green);
    canvas.drawCircle(Offset(-size.x / 2, 0), 4, paint..color = Colors.red);

    // Точки крепления (10% от краев, 15% от бортов)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.x * 0.4, size.y * 0.35), 2, paint);
    canvas.drawCircle(Offset(size.x * 0.4, -size.y * 0.35), 2, paint);
    canvas.drawCircle(Offset(-size.x * 0.4, size.y * 0.35), 2, paint);
    canvas.drawCircle(Offset(-size.x * 0.4, -size.y * 0.35), 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Dock || other is MooredYacht) {
      if (intersectionPoints.isNotEmpty) {
        // 1. Находим среднюю точку контакта
        Vector2 collisionMid = intersectionPoints.reduce((a, b) => a + b) / intersectionPoints.length.toDouble();

        // 2. Считаем реальную скорость удара (м/с)
        double impactSpeed = velocity.length / Constants.pixelRatio;

        // 3. Определяем удар носом через расстояние до bowWorldPosition
        // Если точка столкновения ближе к кончику носа, чем ширина яхты — это удар носом
        double distToBow = collisionMid.distanceTo(bowWorldPosition);
        bool hitByBow = distToBow < (size.y * 0.8);

        // ДЕБАГ: Выводит данные в консоль при каждом касании
        print("УДАР! Скорость: ${impactSpeed.toStringAsFixed(2)} м/с, Дист. до носа: ${distToBow.toStringAsFixed(1)}, Носом: $hitByBow");

        // 4. ПРОВЕРКА УСЛОВИЙ ПРОИГРЫША
        if (hitByBow && impactSpeed > 0.5) { // Снизил порог до 0.5 для чувствительности
          print("КРИТИЧЕСКИЙ УДАР НОСОМ!");
          game.onGameOver("Яхта разбита! Прямой удар носом.");
          return;
        }

        if (impactSpeed > 2.5) {
          print("КРИТИЧЕСКИЙ УДАР БОКОМ!");
          game.onGameOver("Пробоина! Слишком большая скорость удара.");
          return;
        }

        // --- Если это просто мягкое касание ---
        _handleSoftCollision(collisionMid, other);
      }
    }
  }

// Вынес логику отскока в отдельный метод для чистоты
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
      // Усиленная жесткость (45.0) + квадратичный рост для стопора
      double tension = strain * 45.0 + (math.pow(strain, 2) * 0.2);

      Vector2 tensionDir = ropeVector.normalized();
      velocity += (tensionDir * tension / Constants.yachtMass) * dt * 160;

      // Hard stop демпфирование
      if (currentLength > 4.0 * Constants.pixelRatio) velocity *= 0.92;
      velocity *= 0.97;
    }
  }

  void _drawRope(Canvas canvas, Vector2? bollardWorld, Vector2? anchorLocal) {
    if (bollardWorld == null || anchorLocal == null) return;

    Vector2 bollardLocal = parentToLocal(bollardWorld);
    Offset start = anchorLocal.toOffset();
    Offset end = bollardLocal.toOffset();
    double dist = (bollardLocal - anchorLocal).length;
    double maxDist = 3.0 * Constants.pixelRatio;

    final paint = Paint()..color = const Color(0xFFEFEBE9)..strokeWidth = 1.5..style = PaintingStyle.stroke;

    if (dist < maxDist * 0.9) {
      final path = Path()..moveTo(start.dx, start.dy);
      double controlY = (start.dy + end.dy) / 2 + (maxDist - dist) * 0.4;
      path.quadraticBezierTo((start.dx + end.dx) / 2, controlY, end.dx, end.dy);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }
  }

  void _checkMooringConditions() {
    if (game.dock.bollardXPositions.isEmpty) return;

    // 1. Получаем мировые координаты тумб
    final double bollardY = game.dock.position.y + game.dock.size.y;
    List<Vector2> bollards = game.dock.bollardXPositions.map((localX) {
      return Vector2(game.dock.position.x + localX, bollardY);
    }).toList();

    // 2. Определяем мировые координаты наших "уток" (10% от края, 15% от борта)
    // Носовые
    Vector2 mooringBowR = localToParent(Vector2(size.x * 0.4, size.y * 0.35));
    Vector2 mooringBowL = localToParent(Vector2(size.x * 0.4, -size.y * 0.35));
    // Кормовые
    Vector2 mooringSternR = localToParent(Vector2(-size.x * 0.4, size.y * 0.35));
    Vector2 mooringSternL = localToParent(Vector2(-size.x * 0.4, -size.y * 0.35));

    // 3. Считаем минимальное расстояние до любой из тумб
    double distBow = double.infinity;
    double distStern = double.infinity;

    for (var b in bollards) {
      // Проверяем носовые утки
      distBow = math.min(distBow, math.min(mooringBowR.distanceTo(b), mooringBowL.distanceTo(b)));
      // Проверяем кормовые утки
      distStern = math.min(distStern, math.min(mooringSternR.distanceTo(b), mooringSternL.distanceTo(b)));
    }

    // 4. УВЕЛИЧИВАЕМ ПОРОГИ для стабильности
    // 3.5 метра - теперь кнопки будут появляться увереннее
    double threshold = 3.5 * Constants.pixelRatio;
    // 1.2 м/с - чуть больше свободы по скорости
    double speedLimit = 1.2 * Constants.pixelRatio;
    bool speedOk = velocity.length < speedLimit;

    // Проверка: мы не должны быть уже пришвартованы
    canMoerBow = distBow < threshold && speedOk && bowMooredTo == null;
    canMoerStern = distStern < threshold && speedOk && sternMooredTo == null;

    // Визуальный дебаг радиуса (помогает понять, где "ловить" кнопку)
    if (game.debugMode && (canMoerBow || canMoerStern)) {
      print("Дистанция: Нос ${ (distBow/Constants.pixelRatio).toStringAsFixed(1) }м, "
          "Корма ${ (distStern/Constants.pixelRatio).toStringAsFixed(1) }м");
    }

    if (canMoerBow || canMoerStern) {
      game.showMooringButtons(canMoerBow, canMoerStern);
    } else {
      game.hideMooringButtons();
    }
  }

  void _containInArea() {
    if (!game.playArea.contains(position.toOffset())) game.onOutOfBounds();
  }

  void resetToInitialState() {
    position = _initialPosition.clone();
    angle = _initialAngle;
    velocity = Vector2.zero();
    angularVelocity = 0.0;
    throttle = 0.0;
    _currentRudderAngle = targetRudderAngle = 0.0;
    bowMooredTo = sternMooredTo = bowAnchorPointLocal = sternAnchorPointLocal = null;
  }

  void _createSplash(Vector2 impactPoint) {
    final rnd = math.Random();

    // Создаем систему частиц
    game.world.add(
      ParticleSystemComponent(
        position: impactPoint,
        particle: Particle.generate(
          count: 15,
          lifespan: 0.8,
          generator: (i) {
            // Случайный вектор разлета
            final angle = rnd.nextDouble() * math.pi * 2;
            final speed = 40.0 + rnd.nextDouble() * 60.0;
            final velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;

            // Используем AcceleratedParticle — он дает физику (замедление)
            return AcceleratedParticle(
              acceleration: velocity * -0.5, // Капли плавно тормозят
              speed: velocity,
              position: Vector2.zero(),
              // Если OpacityParticle не работает, используем простую CircleParticle
              // Она исчезнет мгновенно по истечении lifespan, если не обернуть в прозрачность
              child: CircleParticle(
                radius: 1.0 + rnd.nextDouble() * 2.5,
                paint: Paint()..color = const Color(0xCCEEFFFF),
              ),
            );
          },
        ),
      ),
    );
  }
}