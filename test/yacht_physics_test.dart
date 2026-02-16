import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yacht/core/constants.dart';
import 'package:yacht/core/yacht_physics.dart';

/// Mock для проверки вызова колбэка остановки (использование mocktail в модульных тестах физики).
class MockStopCallback extends Mock {
  void call(Vector2 v, double omega);
}

/// Модульные тесты для класса физики яхты (YachtPhysics, YachtDynamics, YachtMotionState).
/// Зависимости от YachtGame нет: физика опирается только на Constants и чистые функции.
///
/// DI для тестирования игры: если понадобится тестировать YachtMasterGame изолированно,
/// можно внедрить YachtDynamics через конструктор (game принимает [YachtDynamics? dynamics])
/// и/или передавать [void Function(GameEvent)? onGameEvent] при создании игрока, чтобы
/// не зависеть от оверлеев и паузы движка.
void main() {
  setUpAll(() {
    registerFallbackValue(Vector2.zero());
  });

  group('YachtPhysics (статические методы)', () {
    group('Граничные случаи: нулевой ввод (throttle = 0)', () {
      test('thrustForce(0, angle) всегда нулевая при любом угле', () {
        for (final angle in [0.0, math.pi / 2, math.pi, -math.pi / 2]) {
          final thrust = YachtPhysics.thrustForce(0.0, angle);
          expect(thrust.length, equals(0.0),
              reason: 'При throttle=0 тяга отсутствует при угле $angle');
        }
      });

      test('rudderTorque при throttle=0 и speed=0 даёт нулевой момент (нет потока)', () {
        final torque = YachtPhysics.rudderTorque(1.0, 0.0, 0.0);
        expect(torque, equals(0.0),
            reason: 'Нет потока от винта и скорости — момент руля нулевой');
      });

      test('propWalkTorque при throttle=0 нулевой', () {
        expect(YachtPhysics.propWalkTorque(0.0, 0.0), equals(0.0));
        expect(YachtPhysics.propWalkTorque(0.0, 2.0), equals(0.0));
      });
    });

    group('Сопротивление воды (drag)', () {
      test('При высокой скорости сопротивление растёт быстрее линейного (доминирует v²)', () {
        final vLow = Vector2(0.5, 0);
        final vHigh = Vector2(2.0, 0);
        final dragLow = YachtPhysics.dragForce(vLow);
        final dragHigh = YachtPhysics.dragForce(vHigh);
        final ratioSpeed = 2.0 / 0.5;
        final ratioDrag = dragHigh.length / dragLow.length;
        expect(ratioDrag, greaterThan(ratioSpeed),
            reason: 'При v²-доминировании рост силы сопротивления быстрее роста скорости');
      });

      test('Направление сопротивления противоположно скорости', () {
        final velocity = Vector2(1.5, -0.5);
        final drag = YachtPhysics.dragForce(velocity);
        final dirVelocity = velocity.normalized();
        final dirDrag = drag.normalized();
        expect(drag.length, greaterThan(0));
        expect(dirDrag.x, closeTo(-dirVelocity.x, 1e-6));
        expect(dirDrag.y, closeTo(-dirVelocity.y, 1e-6));
      });
    });

    group('Максимальные углы руля', () {
      test('rudderTorque при руле ±1 и ненулевом потоке: момент одного знака с углом', () {
        const speed = 1.0;
        const throttle = 0.3;
        final torquePos = YachtPhysics.rudderTorque(1.0, speed, throttle);
        final torqueNeg = YachtPhysics.rudderTorque(-1.0, speed, throttle);
        expect(torquePos, greaterThan(0),
            reason: 'Руль +1 даёт положительный момент');
        expect(torqueNeg, lessThan(0),
            reason: 'Руль -1 даёт отрицательный момент');
        expect(torquePos, closeTo(-torqueNeg, 1e-9),
            reason: 'Симметрия по знаку руля');
      });

      test('На высокой скорости эффективный поток руля меньше (радиус разворота растёт)', () {
        const rudderAngle = 0.8;
        const throttle = 0.2;
        final torqueLowSpeed = YachtPhysics.rudderTorque(rudderAngle, 0.5, throttle);
        final torqueHighSpeed = YachtPhysics.rudderTorque(rudderAngle, 2.5, throttle);
        final ratioTorque = torqueHighSpeed / torqueLowSpeed;
        final ratioSpeed = 2.5 / 0.5;
        expect(ratioTorque, lessThan(ratioSpeed),
            reason: 'Момент руля на высокой скорости растёт медленнее скорости (effective_flow)');
      });
    });

    group('stop (мгновенная остановка)', () {
      test('stop вызывает setVelocities с нулевыми значениями', () {
        Vector2? capturedV;
        double? capturedOmega;
        YachtPhysics.stop((v, omega) {
          capturedV = v;
          capturedOmega = omega;
        });
        expect(capturedV?.length, equals(0.0));
        expect(capturedOmega, equals(0.0));
      });

      test('stop вызывает переданный callback ровно один раз (mocktail)', () {
        final callback = MockStopCallback();
        when(() => callback(any(), any())).thenReturn(null);
        YachtPhysics.stop(callback);
        verify(() => callback(any(), any())).called(1);
      });
    });
  });

  group('YachtDynamics (интеграция шага)', () {
    YachtMotionState initialState({
      Vector2? position,
      double angle = 0.0,
      Vector2? velocity,
      double angularVelocity = 0.0,
      double throttle = 0.0,
      double effectiveThrust = 0.0,
      double currentRudderAngle = 0.0,
    }) {
      return YachtMotionState(
        position: position ?? Vector2.zero(),
        angle: angle,
        velocity: velocity ?? Vector2.zero(),
        angularVelocity: angularVelocity,
        throttle: throttle,
        effectiveThrust: effectiveThrust,
        currentRudderAngle: currentRudderAngle,
      );
    }

    const env = YachtEnvironment();

    group('Нулевой ввод (throttle = 0)', () {
      test('При targetThrottle=0 и targetRudder=0 скорость затухает, состояние стабилизируется', () {
        final dynamics = YachtDynamics();
        var state = initialState(
          velocity: Vector2(1.0, 0.0),
          throttle: 0.0,
          effectiveThrust: 0.0,
        );
        const dt = 1 / 60.0;
        for (var i = 0; i < 300; i++) {
          state = dynamics.step(state, 0.0, 0.0, env, dt);
        }
        expect(state.velocity.length, lessThan(0.4),
            reason: 'За ~5 с без газа скорость заметно затухает');
        expect(state.throttle, closeTo(0.0, 1e-9));
        expect(state.effectiveThrust, closeTo(0.0, 0.05));
      });

      test('effectiveThrust стремится к 0 при сбросе газа', () {
        final dynamics = YachtDynamics();
        var state = initialState(throttle: 0.8, effectiveThrust: 0.8);
        const dt = 1 / 60.0;
        for (var i = 0; i < 120; i++) {
          state = dynamics.step(state, 0.0, 0.0, env, dt);
        }
        expect(state.effectiveThrust, lessThan(0.2),
            reason: 'За ~2 с эффективная тяга падает к нулю');
      });
    });

    group('Максимальные углы руля', () {
      test('Угловая скорость ограничена maxAngularVelocity при полном руле и газе', () {
        final dynamics = YachtDynamics();
        var state = initialState(
          velocity: Vector2(1.0, 0.0),
          throttle: 0.5,
          effectiveThrust: 0.5,
          currentRudderAngle: 1.0,
        );
        const dt = 1 / 60.0;
        for (var i = 0; i < 200; i++) {
          state = dynamics.step(state, 0.5, 1.0, env, dt);
        }
        expect(state.angularVelocity.abs(), lessThanOrEqualTo(Constants.maxAngularVelocity + 0.01),
            reason: 'Угловая скорость не превышает лимит');
      });

      test('Руль плавно подходит к targetRudderAngle (не мгновенный поворот)', () {
        final dynamics = YachtDynamics();
        var state = initialState(currentRudderAngle: 0.0);
        const dt = 1 / 60.0;
        state = dynamics.step(state, 0.0, 1.0, env, dt);
        expect(state.currentRudderAngle.abs(), lessThan(1.0),
            reason: 'За один кадр руль не достигает ±1 мгновенно');
      });
    });

    group('Граничные случаи шага', () {
      test('При dt > 0.1 состояние не меняется (защита от скачков)', () {
        final dynamics = YachtDynamics();
        final state = initialState(
          position: Vector2(100, 200),
          velocity: Vector2(1.0, 0.0),
        );
        final next = dynamics.step(state, 0.5, 0.0, env, 0.5);
        expect(next.position.x, equals(state.position.x));
        expect(next.position.y, equals(state.position.y));
        expect(next.velocity.x, equals(state.velocity.x));
      });

      test('При высокой начальной скорости линейная скорость ограничена maxSpeedMeters', () {
        final dynamics = YachtDynamics();
        var state = initialState(
          velocity: Vector2(10.0, 0.0),
          throttle: 1.0,
          effectiveThrust: 1.0,
        );
        state = dynamics.step(state, 1.0, 0.0, env, 1 / 60.0);
        expect(state.velocity.length, lessThanOrEqualTo(Constants.maxSpeedMeters + 0.1),
            reason: 'Скорость ограничена лимитом симуляции');
      });

      test('Течение сдвигает позицию при currentSpeed > 0', () {
        final dynamics = YachtDynamics();
        const envCurrent = YachtEnvironment(
          currentSpeed: 0.5,
          currentDirection: 0.0,
        );
        var state = initialState(position: Vector2.zero());
        const dt = 1 / 60.0;
        for (var i = 0; i < 60; i++) {
          state = dynamics.step(state, 0.0, 0.0, envCurrent, dt);
        }
        expect(state.position.x, greaterThan(0),
            reason: 'Течение по направлению 0 рад (cos=1, sin=0) сносит в положительный X');
      });
    });
  });

  group('Столкновения: граничные случаи (resolveCollisionOutcome)', () {
    const double sizeX = 120.0;

    test('Высокая скорость + удар носом → noseCrash', () {
      final outcome = resolveCollisionOutcome(
        Vector2(sizeX * Constants.noseSectorFactor + 1, 0),
        sizeX,
        Constants.maxSafeImpactSpeed + 0.5,
      );
      expect(outcome, equals(CollisionOutcome.noseCrash));
    });

    test('Высокая скорость + удар бортом/кормой → sideCrash', () {
      final outcome = resolveCollisionOutcome(
        Vector2(0, 0),
        sizeX,
        Constants.maxSafeImpactSpeed + 0.3,
      );
      expect(outcome, equals(CollisionOutcome.sideCrash));
    });

    test('Низкая скорость при любом месте удара → soft', () {
      expect(
        resolveCollisionOutcome(Vector2(sizeX * 0.5, 0), sizeX, 0.3),
        equals(CollisionOutcome.soft),
      );
      expect(
        resolveCollisionOutcome(Vector2(0, 0), sizeX, 0.1),
        equals(CollisionOutcome.soft),
      );
    });

    test('Скорость ровно на пороге maxSafeImpactSpeed: боковой удар → sideCrash', () {
      final outcome = resolveCollisionOutcome(
        Vector2(0, 0),
        sizeX,
        Constants.maxSafeImpactSpeed + 0.001,
      );
      expect(outcome, equals(CollisionOutcome.sideCrash));
    });

    test('Скорость чуть ниже порога при ударе носом → soft', () {
      final outcome = resolveCollisionOutcome(
        Vector2(sizeX * 0.5, 0),
        sizeX,
        Constants.maxSafeImpactSpeed - 0.01,
      );
      expect(outcome, equals(CollisionOutcome.soft));
    });
  });
}

/// Результат столкновения для тестов (дублирует логику из yacht_engine_test / YachtPlayer).
enum CollisionOutcome { noseCrash, sideCrash, soft }

CollisionOutcome resolveCollisionOutcome(
  Vector2 localCollisionPoint,
  double sizeX,
  double velocityLengthMeters,
) {
  final isNoseHit = localCollisionPoint.x > (sizeX * Constants.noseSectorFactor);
  final isHighSpeed = velocityLengthMeters > Constants.maxSafeImpactSpeed;
  if (isNoseHit && isHighSpeed) return CollisionOutcome.noseCrash;
  if (isHighSpeed) return CollisionOutcome.sideCrash;
  return CollisionOutcome.soft;
}
