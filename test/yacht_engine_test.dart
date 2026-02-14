import 'dart:math' as math;
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yacht/core/constants.dart';
import 'package:yacht/core/yacht_physics.dart';
import 'package:yacht/core/marina_layout.dart';
import 'package:yacht/core/camera_math.dart';
import 'package:yacht/game/yacht_game.dart';
import 'package:yacht/model/level_config.dart';

// --- Вспомогательная логика коллизий (дублирует условия из YachtPlayer для тестов без запуска Flame) ---
/// Результат определения типа столкновения (для unit-тестов).
enum CollisionOutcome { noseCrash, sideCrash, soft }

/// Чистая функция: по локальной точке удара, размеру яхты и скорости возвращает исход.
/// Физический смысл: сектор носа (x > sizeX*0.3) + критическая скорость дают фатальный исход.
CollisionOutcome resolveCollisionOutcome(
  Vector2 localCollisionPoint,
  double sizeX,
  double velocityLengthMeters,
) {
  bool isNoseHit = localCollisionPoint.x > (sizeX * 0.3);
  bool isHighSpeed = velocityLengthMeters > Constants.maxSafeImpactSpeed;
  if (isNoseHit && isHighSpeed) return CollisionOutcome.noseCrash;
  if (isHighSpeed) return CollisionOutcome.sideCrash;
  return CollisionOutcome.soft;
}

// --- Mock для YachtMasterGame (без загрузки графики и движка) ---
class MockYachtMasterGame extends Mock implements YachtMasterGame {}

void main() {
  group('Physics', () {
    group('Линейная физика', () {
      test('Равновесная скорость: при throttle=0.1 скорость стабилизируется (тяга = сопротивление)', () {
        const double throttle = 0.1;
        const double angle = 0.0;
        const double dt = 1 / 60.0;
        const int steps = 300;

        Vector2 velocity = Vector2.zero();
        Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));

        for (int i = 0; i < steps; i++) {
          Vector2 thrust = YachtPhysics.thrustForce(throttle, angle);
          Vector2 drag = YachtPhysics.dragForce(velocity);
          Vector2 lateral = YachtPhysics.lateralDrag(forwardDir, velocity);
          Vector2 totalForce = thrust + drag + lateral;
          Vector2 accel = totalForce / Constants.yachtMass;
          velocity += accel * dt;
          if (velocity.length > Constants.maxSpeedMeters) {
            velocity = velocity.normalized() * Constants.maxSpeedMeters;
          }
        }

        double speed = velocity.length;
        // Ожидаем: скорость вышла на установившуюся (тяга уравновешена сопротивлением)
        expect(speed, greaterThan(0.3),
            reason: 'При 10% газа установившаяся скорость должна быть заметно выше нуля');
        expect(speed, lessThan(Constants.maxSpeedMeters),
            reason: 'Скорость не должна превышать лимит симуляции');
        // Стабильность: ещё один шаг почти не меняет скорость
        Vector2 thrust = YachtPhysics.thrustForce(throttle, angle);
        Vector2 drag = YachtPhysics.dragForce(velocity);
        Vector2 lateral = YachtPhysics.lateralDrag(forwardDir, velocity);
        Vector2 accel = (thrust + drag + lateral) / Constants.yachtMass;
        double change = (accel * dt).length;
        expect(change, lessThan(0.05),
            reason: 'В установившемся режиме ускорение близко к нулю (равновесие сил)');
      });

      test('Инерция: при сбросе газа в 0 скорость плавно затухает по сопротивлению', () {
        const double angle = 0.0;
        const double dt = 1 / 60.0;
        const int steps = 300;

        Vector2 velocity = Vector2(1.5, 0);
        Vector2 forwardDir = Vector2(math.cos(angle), math.sin(angle));

        for (int i = 0; i < steps; i++) {
          Vector2 drag = YachtPhysics.dragForce(velocity);
          Vector2 lateral = YachtPhysics.lateralDrag(forwardDir, velocity);
          Vector2 accel = (drag + lateral) / Constants.yachtMass;
          velocity += accel * dt;
        }

        expect(velocity.length, lessThan(0.6),
            reason: 'Через ~5 сек без газа скорость затухает за счёт гибридного сопротивления');
        expect(velocity.length, greaterThanOrEqualTo(0),
            reason: 'Скорость не уходит в отрицательную (затухание, а не разгон)');
      });

      test('Боковой дрейф (Lateral Drag): боковая скорость эффективно гасится килем', () {
        Vector2 forwardDir = Vector2(1.0, 0.0);
        Vector2 lateralDir = Vector2(0.0, 1.0);
        Vector2 velocity = lateralDir * 1.0;

        Vector2 lateral = YachtPhysics.lateralDrag(forwardDir, velocity);
        double lateralMag = lateral.length;

        expect(lateralMag, greaterThan(1000),
            reason: 'Сила бокового сопротивления должна быть большой (эффект киля)');
        expect(lateral.dot(lateralDir), lessThan(0),
            reason: 'Сила направлена против боковой скорости (гасит дрейф)');
      });
    });

    group('Вращение (Angular)', () {
      test('Prop Wash: при стоящей лодке, газе и руле угловая скорость растёт (поток на руль)', () {
        const double rudderAngle = 0.5;
        const double speedMeters = 0.0;
        const double throttle = 0.3;

        double torque = YachtPhysics.rudderTorque(rudderAngle, speedMeters, throttle);

        expect(torque, isNot(0),
            reason: 'При нулевой скорости поток от винта (prop wash) создаёт момент на руле');
        expect(torque.sign, equals(rudderAngle.sign),
            reason: 'Направление момента совпадает с отклонением руля');
      });

      test('Prop Walk: при заднем ходе возникает момент в зависимости от типа винта', () {
        const double throttle = -0.5;
        const double speedMeters = 0.0;

        PropellerType saved = Constants.propType;
        Constants.propType = PropellerType.rightHanded;
        double torqueRight = YachtPhysics.propWalkTorque(throttle, speedMeters);

        Constants.propType = PropellerType.leftHanded;
        double torqueLeft = YachtPhysics.propWalkTorque(throttle, speedMeters);

        Constants.propType = saved;

        expect(torqueRight, isNot(0),
            reason: 'При заднем ходе правый винт даёт ненулевой момент (заброс кормы)');
        expect(torqueLeft, isNot(0),
            reason: 'При заднем ходе левый винт тоже даёт момент');
        expect(torqueRight.sign, isNot(torqueLeft.sign),
            reason: 'Правый и левый винты дают противоположное направление момента');
      });

      test('Prop Walk: при малом газе (< 0.05) момент нулевой', () {
        double torque = YachtPhysics.propWalkTorque(0.02, 0.0);
        expect(torque, equals(0),
            reason: 'Порог 0.05 — ниже него эффект заброса не учитывается');
      });
    });

    group('Граничные условия', () {
      test('dt = 0: интеграция не меняет состояние', () {
        Vector2 velocity = Vector2(1.0, 0.0);
        var (steps, stepDt) = YachtPhysics.integrationSteps(
          velocity.length * 0 * Constants.pixelRatio,
          0.0,
        );
        expect(steps, equals(0),
            reason: 'При нулевом перемещении шагов интегрирования быть не должно');
        expect(stepDt, equals(0.0));
      });

      test('throttle = 0: тяга нулевая', () {
        Vector2 thrust = YachtPhysics.thrustForce(0.0, 0.0);
        expect(thrust.length, equals(0.0),
            reason: 'При нулевом газе тяга отсутствует');
      });

      test('Огромный dt: интеграция не создаёт NaN/Infinite', () {
        const double dt = 10.0;
        var (steps, stepDt) = YachtPhysics.integrationSteps(1000.0, dt);
        expect(steps, lessThanOrEqualTo(25),
            reason: 'Число шагов ограничено maxSteps');
        expect(stepDt, greaterThan(0));
        expect(stepDt.isFinite, isTrue);
      });

      test('Нулевая скорость: сопротивление нулевое', () {
        Vector2 drag = YachtPhysics.dragForce(Vector2.zero());
        expect(drag.length, equals(0.0),
            reason: 'При нулевой скорости гибридное сопротивление не действует');
      });

      test('Скорость ниже порога 0.001: сопротивление не считается', () {
        Vector2 drag = YachtPhysics.dragForce(Vector2(0.0005, 0));
        expect(drag.length, equals(0.0),
            reason: 'Порог 0.001 м/с — ниже него сопротивление не включается');
      });
    });

    group('Ветер и швартовый', () {
      test('windForce: при нулевой скорости ветра возвращает нулевую силу', () {
        Vector2 f = YachtPhysics.windForce(0.0, 0.0);
        expect(f.length, equals(0.0),
            reason: 'Нет ветра — нет силы сноса');
      });

      test('windForce: при ненулевом ветре возвращает силу в направлении сноса', () {
        Vector2 f = YachtPhysics.windForce(2.0, 0.0);
        expect(f.length, greaterThan(0),
            reason: 'Скорость ветра 2 м/с даёт ненулевую силу');
        expect(f.x, closeTo(0, 1e-10));
        expect(f.y, greaterThan(0),
            reason: 'При направлении 0 рад снос в положительном Y (компас → экран)');
      });

      test('mooringTension: при нулевом растяжении — нулевое ускорение, damping 1', () {
        var (accel, damping) = YachtPhysics.mooringTension(
          Vector2(1.0, 0.0), 0.0, 100.0, Constants.yachtMass, 1/60.0,
        );
        expect(accel.length, equals(0.0),
            reason: 'Канат не растянут — дополнительной силы нет');
        expect(damping, equals(1.0),
            reason: 'Скорость не гасится');
      });

      test('mooringTension: при растяжении — ускорение к тумбе и damping 0.97', () {
        Vector2 dir = Vector2(1.0, 0.0);
        var (accel, damping) = YachtPhysics.mooringTension(
          dir, 10.0, 100.0, Constants.yachtMass, 1/60.0,
        );
        expect(accel.length, greaterThan(0),
            reason: 'Растяжение каната создаёт силу натяжения');
        expect(accel.x, greaterThan(0),
            reason: 'Ускорение в направлении тумбы (dir)');
        expect(damping, equals(0.97),
            reason: 'Умеренное растяжение — стандартное гашение 0.97');
      });

      test('mooringTension: при большом растяжении (>20% restLength) damping 0.92', () {
        var (_, damping) = YachtPhysics.mooringTension(
          Vector2(1.0, 0.0), 30.0, 100.0, Constants.yachtMass, 1/60.0,
        );
        expect(damping, equals(0.92),
            reason: 'Сильное растяжение — усиленное гашение 0.92');
      });
    });

    group('integrationSteps', () {
      test('При distPixels > 0 возвращает steps >= 1 и положительный stepDt', () {
        var (steps, stepDt) = YachtPhysics.integrationSteps(5.0, 1/60.0);
        expect(steps, greaterThanOrEqualTo(1),
            reason: 'Есть перемещение — хотя бы один шаг');
        expect(stepDt, greaterThan(0),
            reason: 'Шаг по времени положительный');
      });

      test('Ограничение maxSteps: при большом dist не более 25 шагов', () {
        var (steps, _) = YachtPhysics.integrationSteps(1000.0, 1.0);
        expect(steps, lessThanOrEqualTo(25),
            reason: 'Число шагов ограничено maxSteps=25');
      });
    });
  });

  group('Collisions', () {
    test('Сектор носа: X > size.x*0.3 в локальных координатах — удар носом', () {
      const double sizeX = 300.0;
      Vector2 localNose = Vector2(sizeX * 0.35, 0);
      Vector2 localStern = Vector2(sizeX * 0.2, 0);

      CollisionOutcome outcomeNose = resolveCollisionOutcome(
        localNose,
        sizeX,
        1.6,
      );
      CollisionOutcome outcomeStern = resolveCollisionOutcome(
        localStern,
        sizeX,
        1.6,
      );

      expect(outcomeNose, equals(CollisionOutcome.noseCrash),
          reason: 'Точка впереди 0.3*length считается носовым сектором при высокой скорости');
      expect(outcomeStern, equals(CollisionOutcome.sideCrash),
          reason: 'Точка сзади 0.3*length — удар бортом/кормой при высокой скорости');
    });

    test('Критическая скорость: удар бортом > maxSafeImpactSpeed → crash, ниже → soft', () {
      const double sizeX = 300.0;
      Vector2 localSide = Vector2(0.0, 0.0);

      CollisionOutcome highSpeed = resolveCollisionOutcome(
        localSide,
        sizeX,
        1.6,
      );
      CollisionOutcome lowSpeed = resolveCollisionOutcome(
        localSide,
        sizeX,
        0.5,
      );

      expect(highSpeed, equals(CollisionOutcome.sideCrash),
          reason: 'Скорость выше порога (1.5 м/с) вызывает onGameOver (боковой удар)');
      expect(lowSpeed, equals(CollisionOutcome.soft),
          reason: 'Скорость 0.5 м/с ниже порога — обрабатывается как мягкое касание (_handleSoftCollision)');
    });

    test('Граница сектора носа: X = size.x*0.3 не считается носом', () {
      const double sizeX = 300.0;
      Vector2 onBoundary = Vector2(sizeX * 0.3, 0);
      Vector2 justBehind = Vector2(sizeX * 0.3 - 0.01, 0);

      CollisionOutcome boundary = resolveCollisionOutcome(onBoundary, sizeX, 1.6);
      CollisionOutcome behind = resolveCollisionOutcome(justBehind, sizeX, 1.6);

      expect(boundary, equals(CollisionOutcome.sideCrash),
          reason: 'Строго на границе (x = 0.3*size) по условию не нос');
      expect(behind, equals(CollisionOutcome.sideCrash),
          reason: 'Чуть сзади границы — удар бортом/кормой');
    });
  });

  group('MarinaLayout', () {
    test('dockX центрирует причал по ширине мира', () {
      double dockX = MarinaLayout.dockX(1000.0, 5000.0);
      expect(dockX, equals(2000.0),
          reason: 'Причал шириной 1000 по центру 5000: левый край на 2000');
    });

    test('playerBollardXPositions возвращает 2 тумбы для player_slot', () {
      final layout = [
        BoatPlacement(type: 'boat'),
        BoatPlacement(type: 'player_slot'),
        BoatPlacement(type: 'boat'),
      ];
      List<double> xs = MarinaLayout.playerBollardXPositions(
        layout, 100.0, 50.0,
      );
      expect(xs.length, equals(2),
          reason: 'Один слот игрока — две тумбы (носовая и кормовая)');
      expect(xs[0], lessThan(xs[1]),
          reason: 'Первая тумба левее второй в слоте');
    });

    test('playerBollardXPositions без player_slot возвращает пустой список', () {
      final layout = [
        BoatPlacement(type: 'boat'),
        BoatPlacement(type: 'boat'),
      ];
      List<double> xs = MarinaLayout.playerBollardXPositions(layout, 100.0, 50.0);
      expect(xs, isEmpty,
          reason: 'Нет слота игрока — тумб нет');
    });

    test('slotCenterX для индекса 0', () {
      double cx = MarinaLayout.slotCenterX(100.0, 20.0, 150.0, 0);
      expect(cx, equals(100 + 20 + 0 + 75),
          reason: 'Центр первого слота: dockX + edgePadding + 0*step + step/2');
    });

    test('MarinaLayoutParams: dockWidthPixels зависит от slotCount', () {
      const params = MarinaLayoutParams(slotCount: 5);
      expect(params.dockWidthPixels,
          equals(params.slipStepPixels * 5 + params.edgePaddingPixels * 2),
          reason: 'Ширина причала = слипы + два отступа');
    });
  });

  group('CameraMath', () {
    test('targetZoomFromDistanceToDock ограничен zoomMin/zoomMax', () {
      double zoom = CameraMath.targetZoomFromDistanceToDock(10000.0);
      expect(zoom, inInclusiveRange(CameraMath.zoomMin, CameraMath.zoomMax),
          reason: 'Зум не выходит за допустимые границы');
    });

    test('targetZoomSmart ограничен zoomClampMin/zoomClampMax', () {
      double zoom = CameraMath.targetZoomSmart(500.0);
      expect(zoom, inInclusiveRange(CameraMath.zoomClampMin, CameraMath.zoomClampMax),
          reason: 'Умный зум в своих границах');
    });

    test('targetCameraY: причал сверху вьюпорта', () {
      double y = CameraMath.targetCameraY(0, 1000.0);
      expect(y, equals(500.0),
          reason: 'Центр камеры = dockY + половина видимой высоты');
    });

    test('worldHeightAtZoom обратно пропорционален зуму', () {
      double h = CameraMath.worldHeightAtZoom(0.2);
      expect(h, equals(3600.0),
          reason: '720 / 0.2 = 3600 пикселей видимой высоты');
    });
  });
}
