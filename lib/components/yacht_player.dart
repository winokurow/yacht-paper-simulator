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
  late Vector2 _initialPosition;
  late double _initialAngle;
  bool canMoerBow = false;
  bool canMoerStern = false;

  double? bowRopeRestLength;
  double? sternRopeRestLength;

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

    double throttleChangeSpeed = 1.0; // Скорость перемещения рычага
    if (throttle < targetThrottle) {
      throttle = (throttle + throttleChangeSpeed * dt).clamp(-1.0, 1.0);
    } else if (throttle > targetThrottle) {
      throttle = (throttle - throttleChangeSpeed * dt).clamp(-1.0, 1.0);
    }

    // 1. ПЕРЕКЛАДКА РУЛЯ (Инерция пера)
    // Руль не поворачивается мгновенно, имитируем работу гидропривода
    double rudderDiff = targetRudderAngle - _currentRudderAngle;
    if (rudderDiff.abs() > 0.01) {
      _currentRudderAngle += rudderDiff.sign * Constants.rudderRotationSpeed * dt;
    }

    // 2. РАСЧЕТ ПОТОКА ВОДЫ (Flow)
    // Руль работает от набегающей воды + струя от винта (Prop Wash)
    double speedMeters = velocity.length / Constants.pixelRatio;
    double propWash = (throttle > 0) ? (throttle * Constants.propWashFactor) : 0.0;
    double totalFlow = speedMeters + propWash;

    // 3. СИЛЫ ТЯГИ И ЛИНЕЙНОГО СОПРОТИВЛЕНИЯ
    Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));

    // Тяга двигателя
    Vector2 thrustForce = forwardDir * (throttle * Constants.maxThrust);

    // Сопротивление воды (Линейное + Квадратичное для плавности на малых ходах)
    double dragFactor = Constants.dragCoefficient * (1.0 + speedMeters * 0.5);
    Vector2 dragForce = velocity * -dragFactor;

    // Боковое сопротивление (Киль мешает лодке ехать боком)
    Vector2 lateralDir = Vector2(-forwardDir.y, forwardDir.x);
    double lateralSpeed = velocity.dot(lateralDir);
    Vector2 lateralDrag = lateralDir * (-lateralSpeed * Constants.lateralDragMultiplier * Constants.pixelRatio);

    // Ускорение: F / m
    Vector2 linearAcceleration = (thrustForce + dragForce + lateralDrag) / Constants.yachtMass;
    velocity += linearAcceleration * dt;
    print("Drag Force: ${dragForce.length}");
    // 4. ВРАЩАЮЩИЕ МОМЕНТЫ (Torque)
    double totalTorque = 0.0;

    // Момент от руля
    double rudderTorque = _currentRudderAngle * totalFlow * Constants.rudderEffect * 1000.0;
    totalTorque += rudderTorque;

    // Момент от заброса винта (Prop Walk)
    if (throttle.abs() > 0.01) {
      // 1. Снижаем множитель для переднего хода (с 0.1 до 0.03-0.05)
      double effectMultiplier = (throttle < 0) ? 1.0 : 0.04;

      double sideDir = (Constants.propType == PropellerType.rightHanded) ? 1.0 : -1.0;
      if (throttle > 0) sideDir *= -1;

      // 2. ДЕЛАЕМ ЗАТУХАНИЕ БЫСТРЕЕ
      // Раньше было / 3.0 (эффект жил до 6 узлов).
      // Сделай / 1.5. Теперь на скорости 3 узла (1.5 м/с) заноса не будет совсем.
      double propWalkFade = (1.0 - (speedMeters / 1.5)).clamp(0.0, 1.0);

      // 3. ДОБАВЛЯЕМ КВАДРАТИЧНОЕ ЗАТУХАНИЕ
      // Вместо линейного (propWalkFade) используем (propWalkFade * propWalkFade)
      // Это заставит эффект "отваливаться" очень резко, как только лодка тронулась.
      double finalFade = propWalkFade * propWalkFade;

      double propWalkTorque = sideDir * throttle.abs() * Constants.propWalkEffect * effectMultiplier * finalFade * 500.0;

      totalTorque += propWalkTorque;
    }

    // 5. УГЛОВАЯ ДИНАМИКА И ТОРМОЖЕНИЕ
    // Угловое ускорение
    double angularAcc = totalTorque / Constants.yachtInertia;
    angularVelocity += angularAcc * dt;

    // ТОРМОЖЕНИЕ ВРАЩЕНИЯ (Damping) - чтобы лодка останавливалась сама
    // Если мы не крутим руль, вода быстро гасит вращение 5-тонного корпуса
    double damping = 1.0 - (Constants.angularDrag * dt);
    angularVelocity *= damping.clamp(0.0, 1.0);

    // Лимит вращения для стабильности
    angularVelocity = angularVelocity.clamp(-1.2, 1.2);
    if (angularVelocity.abs() < 0.001) angularVelocity = 0;

    // 6. СУБСТЕППИНГ (Движение)
    // Разбиваем движение на мелкие шаги, чтобы хитбокс не пролетал сквозь причал
    double totalDist = (velocity.length * dt * Constants.pixelRatio);
    int steps = (totalDist / 2.0).ceil().clamp(1, 10);
    double stepDt = dt / steps;

    for (int i = 0; i < steps; i++) {
      position += velocity * (stepDt * Constants.pixelRatio);
      angle += angularVelocity * stepDt;
    }

    // 7. СТАБИЛИЗАЦИЯ (Анти-дрейф при нулевой тяге)
    if (throttle.abs() < 0.01 && velocity.length < 0.05) {
      velocity = Vector2.zero();
    }

// Для носового каната (передаем bowRopeRestLength и true)
    if (bowMooredTo != null) {
      _applyMooringPhysics(dt, bowMooredTo, bowAnchorPointLocal, bowRopeRestLength, true);
    }

// Для кормового каната (передаем sternRopeRestLength и false)
    if (sternMooredTo != null) {
      _applyMooringPhysics(dt, sternMooredTo, sternAnchorPointLocal, sternRopeRestLength, false);
    }
    _checkMooringConditions();
    _containInArea();
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

  void _applyMooringPhysics(double dt, Vector2? bollardWorld, Vector2? anchorLocal, double? restLength, bool isBow) {
    if (bollardWorld == null || anchorLocal == null || restLength == null) return;

    Vector2 anchorWorld = localToParent(anchorLocal);
    Vector2 ropeVector = bollardWorld - anchorWorld;
    double currentDistance = ropeVector.length;

    // 1. ПРОВЕРКА НА РАЗРЫВ
    // Если лодка уплыла слишком далеко от точки швартовки (например, на 10 метров больше длины каната)
    if (currentDistance > restLength + (Constants.maxRopeExtension * Constants.pixelRatio)) {
      if (isBow) {
        bowMooredTo = null;
        bowRopeRestLength = null;
      } else {
        sternMooredTo = null;
        sternRopeRestLength = null;
      }
      return; // Канат лопнул
    }

    // 2. ФИЗИКА НАТЯЖЕНИЯ
    if (currentDistance > restLength + 2.0) { // 2 пикселя запаса на "провис"
      double stretch = currentDistance - restLength;
      ropeVector.normalize();

      // УВЕЛИЧИВАЕМ ЖЕСТКОСТЬ: Чем сильнее растянут, тем мощнее тяга (прогрессия)
      double stiffness = 400.0;
      double forceMag = stretch * stiffness;

      // Если лодка прет на газу, увеличиваем силу сопротивления
      Vector2 force = ropeVector * forceMag;

      // Демпфирование (тормоз), чтобы не было бесконечных качелей
      Vector2 dampingForce = velocity * 60.0;

      // ПРИМЕНЯЕМ СИЛУ
      // Убираем деление массы на 1000, если лодка кажется слишком легкой
      velocity += (force - dampingForce) * dt / (Constants.yachtMass / 500);

      // Угловая стабилизация (чтобы не крутилась)
      angularVelocity *= math.pow(0.01, dt).toDouble();
    }
  }

  void _checkMooringConditions() {
    if (game.dock.bollardXPositions.isEmpty) return;

    // 1. СИНХРОНИЗАЦИЯ: Используем тот же коэффициент 0.88, что и в отрисовке
    final double bollardY = game.dock.position.y + (game.dock.size.y * 0.88);

    // Создаем список мировых координат кнехтов
    List<Vector2> bollards = game.dock.bollardXPositions
        .map((x) => Vector2(game.dock.position.x + x, bollardY))
        .toList();

    // 2. ТОЧКИ КРЕПЛЕНИЯ (Мировые координаты точек на бортах)
    // Убедись, что 0.4 и 0.35 не слишком "глубоко" в корпусе.
    // Если лодка 12м, то 0.4 от центра — это 1.2м от носа.
    Vector2 mBowR = localToParent(Vector2(size.x * 0.4, size.y * 0.35));
    Vector2 mBowL = localToParent(Vector2(size.x * 0.4, -size.y * 0.35));
    Vector2 mSternR = localToParent(Vector2(-size.x * 0.4, size.y * 0.35));
    Vector2 mSternL = localToParent(Vector2(-size.x * 0.4, -size.y * 0.35));

    // 3. ПОИСК МИНИМАЛЬНОЙ ДИСТАНЦИИ
    double dBow = bollards.map((b) =>
        math.min(mBowR.distanceTo(b), mBowL.distanceTo(b))).reduce(math.min);

    double dStern = bollards.map((b) =>
        math.min(mSternR.distanceTo(b), mSternL.distanceTo(b))).reduce(math.min);

    // 4. ПОРОГИ (Thresholds)
    // 3.5 метра — хороший порог, но скорость 1.2 м/с (2.3 узла) для швартовки
    // может быть великовата. Оставим пока так.
    double distanceThreshold = 6 * Constants.pixelRatio;

    // Дистанция для ПОКАЗА кнопок (например, 8.5 метров)
    double showThreshold = 8.5 * Constants.pixelRatio;

    // Дистанция для СКРЫТИЯ кнопок (чуть больше, чтобы не мерцало)
    double hideThreshold = 10.0 * Constants.pixelRatio;

    // Если кнопки УЖЕ горят, используем порог скрытия, если нет — порог показа
    double currentThresholdBow = canMoerBow ? hideThreshold : showThreshold;
    double currentThresholdStern = canMoerStern ? hideThreshold : showThreshold;

    bool speedOk = velocity.length < (0.8 * Constants.pixelRatio);

    canMoerBow = dBow < currentThresholdBow && speedOk && bowMooredTo == null;
    canMoerStern = dStern < currentThresholdStern && speedOk && sternMooredTo == null;

    // Вызываем методы игры
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
    if (bowMooredTo != null) {
      _drawRope(canvas, bowMooredTo, bowAnchorPointLocal, bowRopeRestLength);
    }

    if (sternMooredTo != null) {
      _drawRope(canvas, sternMooredTo, sternAnchorPointLocal, sternRopeRestLength);
    }

    if (game.debugMode) _renderDebugDistances(canvas);
  }

  void _renderRudder(Canvas canvas) {
    canvas.save();
    canvas.translate(-size.x / 2, 0);
    canvas.rotate(-_currentRudderAngle);
    canvas.drawLine(Offset.zero, Offset(-size.x * 0.15, 0), Paint()..color = Colors.orange..strokeWidth = 2.0);
    canvas.restore();
  }

  void _drawRope(Canvas canvas, Vector2? bollardWorld, Vector2? anchorLocal, double? restLength) {
    if (bollardWorld == null || anchorLocal == null || restLength == null) return;

    Vector2 bLocal = parentToLocal(bollardWorld);
    double dist = (bLocal - anchorLocal).length;

    // Рассчитываем степень натяжения (0.0 - провис, 1.0 - норма, >1.0 - растяжение)
    double tension = dist / restLength;

    // Цвет меняется с белого на красный при сильном натяжении
    Color ropeColor = Color.lerp(
        const Color(0xFFEFEBE9), // Светлый (норма)
        Colors.redAccent,        // Красный (натяжение)
        ((tension - 1.0) * 5.0).clamp(0.0, 1.0) // Начинает краснеть после 100% длины
    )!;

    final paint = Paint()
      ..color = ropeColor
      ..strokeWidth = 1.5 + (tension > 1.0 ? (tension - 1.0) * 2 : 0) // Толстеет при натяжении
      ..style = PaintingStyle.stroke;

    // ЛОГИКА ОТРИСОВКИ:
    // Если лодка ближе, чем длина каната — рисуем провис
    if (dist < restLength * 0.95) {
      final path = Path()..moveTo(anchorLocal.x, anchorLocal.y);

      // Глубина провиса зависит от того, насколько "лишнего" каната осталось
      double sagAmount = (restLength - dist) * 0.5;

      // Точка изгиба (контрольная точка Безье)
      path.quadraticBezierTo(
          (anchorLocal.x + bLocal.x) / 2,
          (anchorLocal.y + bLocal.y) / 2 + sagAmount, // Канат провисает вниз
          bLocal.x,
          bLocal.y
      );
      canvas.drawPath(path, paint);
    } else {
      // Если натянут — рисуем прямую линию
      canvas.drawLine(anchorLocal.toOffset(), bLocal.toOffset(), paint);
    }
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
    targetThrottle = value;
  }

  void _renderDebugDistances(Canvas canvas) {
    if (game.dock.bollardXPositions.isEmpty) return;

    final double bollardY = game.dock.position.y + (game.dock.size.y * 0.88);

    // Точки на лодке (в локальных координатах для отрисовки)
    final bowPointLocal = Vector2(size.x * 0.45, size.y * 0.48);
    final sternPointLocal = Vector2(-size.x * 0.45, size.y * 0.48);

    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Ищем ближайшие кнехты
    for (var xPos in game.dock.bollardXPositions) {
      Vector2 bWorld = Vector2(game.dock.position.x + xPos, bollardY);

      // Переводим мировую позицию кнехта в локальную систему координат лодки
      Vector2 bLocal = parentToLocal(bWorld);

      // Расстояние до носовой точки
      double dist = bLocal.distanceTo(bowPointLocal);

      // Рисуем линию только если кнехт относительно близко (например, < 150 пикселей)
      if (dist < 150) {
        canvas.drawLine(bowPointLocal.toOffset(), bLocal.toOffset(), paint);

        // Подписываем расстояние
        _drawText(canvas, dist.toStringAsFixed(1), bLocal.toOffset());
      }
    }
  }

// Вспомогательный метод для вывода текста на канвас
  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(5, -15));
  }
}