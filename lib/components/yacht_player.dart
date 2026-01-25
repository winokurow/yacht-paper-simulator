import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
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

  // Состояние для сброса и швартовки
  late Vector2 _initialPosition;
  late double _initialAngle;
  bool canMoerBow = false;
  bool canMoerStern = false;

  // Центральные точки краев (нужны для общей проверки близости)
  Vector2 get bowWorldPosition => localToParent(Vector2(size.x / 2, 0));
  Vector2 get sternWorldPosition => localToParent(Vector2(-size.x / 2, 0));

  // Геттеры углов в МИРОВЫХ координатах (используем localToParent для точности)
  Vector2 get bowRightWorld => localToParent(Vector2(size.x / 2, size.y / 2));
  Vector2 get bowLeftWorld  => localToParent(Vector2(size.x / 2, -size.y / 2));
  Vector2 get sternRightWorld => localToParent(Vector2(-size.x / 2, size.y / 2));
  Vector2 get sternLeftWorld  => localToParent(Vector2(-size.x / 2, -size.y / 2));

  // Точки в мировых координатах, к которым привязаны нос/корма
  Vector2? bowMooredTo;
  Vector2? sternMooredTo;

// Какой именно угол лодки привязан (чтобы канат не прыгал)
  Vector2? bowAnchorPointLocal;
  Vector2? sternAnchorPointLocal;

  // В YachtPlayer.dart
  Vector2 get bowMooringPointWorld => localToParent(Vector2(size.x * 0.4, 0));
  Vector2 get sternMooringPointWorld => localToParent(Vector2(-size.x * 0.4, 0));

  YachtPlayer({double startAngleDegrees = 0.0}) : super(
    // Четко задаем размер при создании
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

    // 1. Описываем точки от 0 до W и от 0 до H (как в самом начале)
    final boatShape = [
      Vector2(w, h * 0.5),     // Нос
      Vector2(w * 0.8, 0),     // Плечо верх
      Vector2(0, 0),           // Корма верх
      Vector2(0, h),           // Корма низ
      Vector2(w * 0.8, h),     // Плечо низ
    ];

    // 2. Добавляем хитбокс и СМЕЩАЕМ его позицию на -size/2
    // Это заставит его "сесть" ровно на спрайт, который мы тоже смещаем в render
    add(PolygonHitbox(
      boatShape,
      position: -size / 2, // КРИТИЧЕСКИ ВАЖНО для Anchor.center
      collisionType: CollisionType.active,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (yachtSprite == null) return;

    // Прямоугольник отрисовки, центрированный в (0,0)
    final destRect = Rect.fromLTWH(
        -size.x / 2,
        -size.y / 2,
        size.x,
        size.y
    );

    // 1. Рисуем тень (чуть смещенную)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRect(destRect.shift(const Offset(2, 2)), shadowPaint);

    // 2. Рисуем спрайт точно в границы destRect
    yachtSprite!.renderRect(canvas, destRect);

    // 3. Руль и дебаг (уже используют (0,0) как центр)
    _renderRudder(canvas);

    if (game.debugMode) {
      // Проверка: зеленая точка должна быть на носу, красная на корме
      canvas.drawCircle(Offset(size.x / 2, 0), 5, Paint()..color = Colors.green);
      canvas.drawCircle(Offset(-size.x / 2, 0), 5, Paint()..color = Colors.red);
      canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.blue); // Центр

      final mooringPaint = Paint()..color = Colors.white;

      // Рисуем маленькие точки там, где «виртуальные утки»
      // Нос
      canvas.drawCircle(Offset(size.x * 0.4, size.y * 0.35), 2, mooringPaint);
      canvas.drawCircle(Offset(size.x * 0.4, -size.y * 0.35), 2, mooringPaint);

      // Корма
      canvas.drawCircle(Offset(-size.x * 0.4, size.y * 0.35), 2, mooringPaint);
      canvas.drawCircle(Offset(-size.x * 0.4, -size.y * 0.35), 2, mooringPaint);
    }

    // Рисуем канаты
    _drawRope(canvas, bowMooredTo, bowAnchorPointLocal);
    _drawRope(canvas, sternMooredTo, sternAnchorPointLocal);
  }

  void _renderRudder(Canvas canvas) {
    final rudderPaint = Paint()
      ..color = Colors.orange.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Точка вращения руля — центр кормы (слева по оси X)
    final pivotX = -size.x / 2;
    final pivotY = 0.0;

    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(-_currentRudderAngle);

    canvas.drawLine(Offset.zero, Offset(-size.x * 0.15, 0), rudderPaint);
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _checkMooringConditions();

    // Физика руля
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
    }

    // Векторное движение
    Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);
    Vector2 dragForce = velocity * -Constants.dragCoefficient;

    // Боковое сопротивление (дрейф)
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.dragCoefficient * 15.0);

    Vector2 acceleration = (thrustForce + dragForce + lateralDrag) / Constants.yachtMass;
    velocity += acceleration * dt;

    // Ограничение скорости (6 м/с)
    if (velocity.length > 6.0) velocity = velocity.normalized() * 6.0;

    position += velocity * (dt * Constants.pixelRatio);

    // --- ЗАЩИТА ОТ ПРОХОДА СКВОЗЬ ПРИЧАЛ ---
    // Если наш причал всегда сверху (вдоль линии dock.y + dock.height)
    final dockEdgeY = game.dock.position.y + game.dock.size.y;

    // Если центр яхты (или её нос) зашел за линию причала
    if (position.y < dockEdgeY + (size.y / 4)) {
      // Мягко возвращаем её назад, если она слишком глубоко
      position.y = dockEdgeY + (size.y / 4);
      // И гасим вертикальную скорость
      if (velocity.y < 0) velocity.y = 0;
    }
    // ПРИМЕНЯЕМ СИЛЫ КАНАТОВ
    _applyMooringPhysics(dt, bowMooredTo, bowAnchorPointLocal);
    _applyMooringPhysics(dt, sternMooredTo, sternAnchorPointLocal);

    // Маневрирование
    double turningPower = (velocity.length + throttle.abs() * 1.5) * Constants.rudderEffect;
    double torque = _currentRudderAngle * turningPower;
    angularVelocity += (torque - angularVelocity * Constants.angularDrag) * dt;
    angularVelocity = angularVelocity.clamp(-3.0, 3.0);
    angle += angularVelocity * dt;

    _containInArea();
  }

  void _checkMooringConditions() {
    if (game.dock.bollardXPositions.isEmpty) return;

    // 1. Получаем мировые координаты всех кнехтов
    // Тумбы стоят на нижнем краю причала (dock.y + dock.height)
    final double bollardY = game.dock.position.y + game.dock.size.y;
    List<Vector2> bollardWorlds = game.dock.bollardXPositions.map((localX) {
      return Vector2(game.dock.position.x + localX, bollardY);
    }).toList();

    // 2. Считаем минимальное расстояние от НОСА до ближайшего кнехта
    // Проверяем оба угла носа (левый и правый)
    double minDistBow = double.infinity;
    for (var bollard in bollardWorlds) {
      double dR = bowRightWorld.distanceTo(bollard);
      double dL = bowLeftWorld.distanceTo(bollard);
      minDistBow = math.min(minDistBow, math.min(dR, dL));
    }

    // 3. Считаем минимальное расстояние от КОРМЫ до ближайшего кнехта
    double minDistStern = double.infinity;
    for (var bollard in bollardWorlds) {
      double dR = sternRightWorld.distanceTo(bollard);
      double dL = sternLeftWorld.distanceTo(bollard);
      minDistStern = math.min(minDistStern, math.min(dR, dL));
    }

    // 4. Условия активации (в метрах)
    double threshold = 2.0 * Constants.pixelRatio; // Увеличим до 2 метров для удобства
    double speedLimit = 0.8 * Constants.pixelRatio;
    bool speedOk = velocity.length < speedLimit;

    canMoerBow = minDistBow < threshold && speedOk && bowMooredTo == null;
    canMoerStern = minDistStern < threshold && speedOk && sternMooredTo == null;

    // Дебаг в консоль, чтобы видеть реальное расстояние до точек
    if (game.debugMode && velocity.length > 0.1) {
      print("До ближайшего кнехта: Нос: ${(minDistBow/Constants.pixelRatio).toStringAsFixed(2)}м, "
          "Корма: ${(minDistStern/Constants.pixelRatio).toStringAsFixed(2)}м");
    }

    // Обновляем кнопки
    if (canMoerBow || canMoerStern) {
      game.showMooringButtons(canMoerBow, canMoerStern);
    } else {
      game.hideMooringButtons();
    }
  }

  void _containInArea() {
    final bounds = game.playArea;
    if (!bounds.contains(position.toOffset())) {
      game.onOutOfBounds();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Dock || other is MooredYacht) {
      // 1. ПРЕРЫВАЕМ ИНЕРЦИЮ
      // Если мы врезались, скорость должна падать мгновенно,
      // чтобы физика update не проталкивала нас дальше в следующем кадре.
      if (velocity.length > 0.1) {
        // Отражаем скорость (отскок) и сильно гасим её
        velocity = -velocity * 0.2;
        angularVelocity *= 0.5;
      } else {
        velocity = Vector2.zero();
      }

      // 2. ГЕОМЕТРИЧЕСКОЕ ВЫТАЛКИВАНИЕ (Separation)
      if (intersectionPoints.isNotEmpty) {
        // Находим центр столкновения
        Vector2 collisionMid = intersectionPoints.reduce((a, b) => a + b) / intersectionPoints.length.toDouble();

        // Вектор отталкивания от точки удара к центру лодки
        Vector2 pushDir = (position - collisionMid);

        // Выталкиваем лодку на расстояние, равное глубине проникновения + запас
        // Это предотвратит "залипание" внутри текстуры
        double pushDistance = 3.0;
        position += pushDir.normalized() * pushDistance;
      }

      // Сбрасываем газ, чтобы не "бурить" причал
      throttle = 0.0;
    }
  }

  void resetToInitialState() {
    position = _initialPosition.clone();
    angle = _initialAngle;
    velocity = Vector2.zero();
    angularVelocity = 0.0;
    throttle = 0.0;
    _currentRudderAngle = 0.0;
    targetRudderAngle = 0.0;
  }

  void _applyMooringPhysics(double dt, Vector2? bollardWorld, Vector2? anchorLocal) {
    if (bollardWorld == null || anchorLocal == null) return;

    Vector2 anchorWorld = localToParent(anchorLocal);
    Vector2 ropeVector = bollardWorld - anchorWorld;
    double currentLength = ropeVector.length;

    double maxAllowedLength = 3.0 * Constants.pixelRatio;

    if (currentLength > maxAllowedLength) {
      // 1. Считаем, насколько канат превысил 3 метра
      double strain = currentLength - maxAllowedLength;

      // 2. СИЛА НАТЯЖЕНИЯ (Увеличиваем коэффициент с 5.0 до 40.0)
      // Добавляем квадрат разницы, чтобы чем дальше тянешь, тем невыносимее была сила
      double tensionStrength = strain * 40.0 + (math.pow(strain, 2) * 0.1);

      Vector2 tensionDirection = ropeVector.normalized();
      Vector2 tensionForce = tensionDirection * tensionStrength;

      // Применяем ускорение (50 -> 150 для резкости)
      velocity += (tensionForce / Constants.yachtMass) * dt * 150;

      // 3. ЖЕСТКИЙ СТОПОР (Hard Limit)
      // Если канат растянулся больше чем на 4.5 метра - это критический предел
      if (currentLength > 4.5 * Constants.pixelRatio) {
        // Проверяем, движется ли лодка ОТ причала
        if (velocity.dot(tensionDirection) < 0) {
          // Гасим ту часть скорости, которая направлена на разрыв каната
          velocity *= 0.8;
        }
      }

      // 4. ДЕМПФИРОВАНИЕ
      // Чтобы лодка не болталась как сумасшедшая на пружине
      velocity *= 0.95;
      angularVelocity *= 0.95;
    }
  }

  void _drawRope(Canvas canvas, Vector2? bollardWorld, Vector2? anchorLocal) {
    if (bollardWorld == null || anchorLocal == null) return;

    Vector2 bollardLocal = parentToLocal(bollardWorld);
    Offset start = anchorLocal.toOffset();
    Offset end = bollardLocal.toOffset();

    final ropePaint = Paint()
      ..color = const Color(0xFFEFEBE9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double currentDist = (bollardLocal - anchorLocal).length;
    double maxDist = 3.0 * Constants.pixelRatio;

    if (currentDist < maxDist * 0.9) {
      // Рисуем кривую Безье (провисание), если лодка близко
      final path = Path();
      path.moveTo(start.dx, start.dy);

      // Точка прогиба вниз
      double controlY = (start.dy + end.dy) / 2 + (maxDist - currentDist) * 0.5;
      path.quadraticBezierTo(
          (start.dx + end.dx) / 2,
          controlY,
          end.dx,
          end.dy
      );
      canvas.drawPath(path, ropePaint);
    } else {
      // Рисуем прямую линию, если канат натянут
      canvas.drawLine(start, end, ropePaint);
    }
  }
}